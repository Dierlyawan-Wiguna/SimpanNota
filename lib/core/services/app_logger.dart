import 'dart:async';
import 'package:flutter/foundation.dart';
import '../local/database_helper.dart';

enum LogLevel {
  info,
  warning,
  error,
  fatal;

  String get label {
    switch (this) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }

  static LogLevel fromString(String val) {
    switch (val.toUpperCase()) {
      case 'WARNING':
      case 'WARN':
        return LogLevel.warning;
      case 'ERROR':
        return LogLevel.error;
      case 'FATAL':
        return LogLevel.fatal;
      case 'INFO':
      default:
        return LogLevel.info;
    }
  }
}

class LogEntry {
  final int? id;
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? error;
  final String? stackTrace;

  LogEntry({
    this.id,
    DateTime? timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.label,
      'tag': tag,
      'message': message,
      'error': error,
      'stackTrace': stackTrace,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as int?,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      level: LogLevel.fromString(map['level'] as String? ?? 'INFO'),
      tag: map['tag'] as String? ?? 'APP',
      message: map['message'] as String? ?? '',
      error: map['error'] as String?,
      stackTrace: map['stackTrace'] as String?,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] [${level.label}] [$tag] $message');
    if (error != null && error!.isNotEmpty) {
      buffer.write('\n  Error: $error');
    }
    if (stackTrace != null && stackTrace!.isNotEmpty) {
      buffer.write('\n  Stack: $stackTrace');
    }
    return buffer.toString();
  }
}

/// Runtime Logging & Tracing Service untuk SimpanNota (Pertemuan 10)
/// Mendukung pencatatan real-time in-memory buffer dan penyimpanan persisten di SQLite.
class AppLogger {
  AppLogger._();

  static const int maxInMemoryLogs = 500;
  static final List<LogEntry> _inMemoryLogs = [];
  static final ValueNotifier<List<LogEntry>> logsNotifier = ValueNotifier<List<LogEntry>>([]);

  /// Menyaring data sensitif (password, secret, token, apiKey) agar tidak pernah tercetak di log
  static String sanitize(String input) {
    var output = input;
    output = output.replaceAllMapped(
      RegExp(r'''(password|token|secret|apiKey|anonKey|key)\s*[:=]\s*["']?([^"',\s]+)["']?''', caseSensitive: false),
      (match) => '${match.group(1)}=[REDACTED]',
    );
    return output;
  }

  static void info(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  static void warning(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, tag, message, error, stackTrace);
  }

  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message, error, stackTrace);
  }

  static void fatal(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, tag, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final sanitizedMessage = sanitize(message);
    final errorStr = error == null ? null : sanitize(error.toString());
    final stackStr = stackTrace?.toString();

    final entry = LogEntry(
      level: level,
      tag: tag,
      message: sanitizedMessage,
      error: errorStr,
      stackTrace: stackStr,
    );

    // Update buffer in-memory
    _inMemoryLogs.insert(0, entry);
    if (_inMemoryLogs.length > maxInMemoryLogs) {
      _inMemoryLogs.removeLast();
    }
    logsNotifier.value = List.unmodifiable(_inMemoryLogs);

    // Cetak ke console pada debug mode
    if (kDebugMode) {
      debugPrint('[${level.label}] [$tag] $sanitizedMessage');
      if (errorStr != null) {
        debugPrint('  Error: $errorStr');
      }
    }

    // Persistensi ke SQLite secara asynchronous (fail-safe)
    _persistLog(entry);
  }

  static Future<void> _persistLog(LogEntry entry) async {
    try {
      await DatabaseHelper.instance.insertSystemLog(entry.toMap());
    } catch (_) {
      // Pada lingkungan unit test atau sebelum SQLite aktif, biarkan gagal tanpa crash
    }
  }

  static List<LogEntry> get inMemoryLogs => List.unmodifiable(_inMemoryLogs);

  static Future<List<LogEntry>> getPersistentLogs({LogLevel? level, String? tag}) async {
    try {
      final rows = await DatabaseHelper.instance.getSystemLogs(level: level?.label);
      var logs = rows.map((e) => LogEntry.fromMap(e)).toList();
      if (tag != null && tag.isNotEmpty && tag != 'ALL') {
        logs = logs.where((e) => e.tag.toUpperCase() == tag.toUpperCase()).toList();
      }
      return logs;
    } catch (_) {
      // Fallback ke in-memory jika SQLite tidak tersedia
      var logs = _inMemoryLogs;
      if (level != null) {
        logs = logs.where((e) => e.level == level).toList();
      }
      if (tag != null && tag.isNotEmpty && tag != 'ALL') {
        logs = logs.where((e) => e.tag.toUpperCase() == tag.toUpperCase()).toList();
      }
      return logs;
    }
  }

  static Future<void> clearLogs() async {
    _inMemoryLogs.clear();
    logsNotifier.value = [];
    try {
      await DatabaseHelper.instance.clearSystemLogs();
    } catch (_) {}
  }

  /// Ekspor seluruh log menjadi teks terformat untuk disalin ke clipboard
  static String exportLogsAsText({List<LogEntry>? logs}) {
    final target = logs ?? _inMemoryLogs;
    if (target.isEmpty) return 'Tidak ada log tercatat.';
    final buffer = StringBuffer();
    buffer.writeln('=== SIMPANNOTA RUNTIME SYSTEM LOGS ===');
    buffer.writeln('Total Log: ${target.length}');
    buffer.writeln('Waktu Ekspor: ${DateTime.now().toIso8601String()}');
    buffer.writeln('======================================\n');
    for (final log in target) {
      buffer.writeln(log.toString());
      buffer.writeln('--------------------------------------');
    }
    return buffer.toString();
  }
}
