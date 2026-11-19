import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/utils/app_snackbar.dart';

/// Layar Diagnostics & Runtime System Log Viewer (Pertemuan 10)
/// Memungkinkan penguji/dosen memeriksa log runtime aplikasi langsung dari Release APK.
class SystemLogScreen extends StatefulWidget {
  const SystemLogScreen({super.key});

  @override
  State<SystemLogScreen> createState() => _SystemLogScreenState();
}

class _SystemLogScreenState extends State<SystemLogScreen> {
  String _selectedLevel = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LogEntry> _filterLogs(List<LogEntry> allLogs) {
    return allLogs.where((log) {
      final matchesLevel = _selectedLevel == 'ALL' || log.level.label == _selectedLevel;
      final matchesSearch = _searchQuery.isEmpty ||
          log.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.tag.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (log.error != null && log.error!.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesLevel && matchesSearch;
    }).toList();
  }

  void _copyAllLogs(List<LogEntry> logs) {
    final text = AppLogger.exportLogsAsText(logs: logs);
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.showSuccess(context, 'Berhasil menyalin ${logs.length} log ke clipboard');
  }

  Future<void> _confirmClearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bersihkan Semua Log?'),
        content: const Text(
          'Seluruh riwayat log runtime aplikasi akan dihapus dari memori dan penyimpanan SQLite lokal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Log'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppLogger.clearLogs();
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Semua log sistem berhasil dibersihkan');
      }
    }
  }

  void _showLogDetail(LogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildLevelBadge(log.level),
                  const SizedBox(width: 8),
                  Text(
                    '[${log.tag}]',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Salin Log Ini',
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: log.toString()));
                      Navigator.pop(ctx);
                      AppSnackBar.showSuccess(context, 'Entri log berhasil disalin');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Waktu: ${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(log.timestamp)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Divider(height: 24),
              const Text(
                'Pesan Log:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              SelectableText(
                log.message,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              if (log.error != null && log.error!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Detail Error:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: SelectableText(
                    log.error!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontFamily: 'monospace'),
                  ),
                ),
              ],
              if (log.stackTrace != null && log.stackTrace!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Stack Trace:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    log.stackTrace!,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(LogLevel level) {
    Color bg;
    Color fg;
    switch (level) {
      case LogLevel.info:
        bg = Colors.blue.shade50;
        fg = AppColors.primaryBlue;
        break;
      case LogLevel.warning:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case LogLevel.error:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case LogLevel.fatal:
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs & Tracing'),
        actions: [
          ValueListenableBuilder<List<LogEntry>>(
            valueListenable: AppLogger.logsNotifier,
            builder: (_, allLogs, _) {
              final filtered = _filterLogs(allLogs);
              return Row(
                children: [
                  Semantics(
                    label: 'Salin Seluruh Log',
                    button: true,
                    child: IconButton(
                      tooltip: 'Salin Log',
                      icon: const Icon(Icons.copy_all_rounded),
                      onPressed: filtered.isEmpty ? null : () => _copyAllLogs(filtered),
                    ),
                  ),
                  Semantics(
                    label: 'Bersihkan Riwayat Log',
                    button: true,
                    child: IconButton(
                      tooltip: 'Hapus Log',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: allLogs.isEmpty ? null : _confirmClearLogs,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter dan Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari log berdasarkan modul atau pesan...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),

                // Filter Level Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['ALL', 'INFO', 'WARNING', 'ERROR', 'FATAL'].map((level) {
                      final isSelected = _selectedLevel == level;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(level),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedLevel = level);
                            }
                          },
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textDark),
                          ),
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Log List View
          Expanded(
            child: ValueListenableBuilder<List<LogEntry>>(
              valueListenable: AppLogger.logsNotifier,
              builder: (context, allLogs, _) {
                final filteredLogs = _filterLogs(allLogs);

                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            allLogs.isEmpty
                                ? 'Belum Ada Log Tercatat'
                                : 'Tidak ada log dengan filter "$_selectedLevel"',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            allLogs.isEmpty
                                ? 'Aktivitas sistem dan request aplikasi akan dicatat otomatis di sini.'
                                : 'Coba ganti filter level atau kata kunci pencarian.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredLogs.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF334155) : AppColors.cardBorder,
                  ),
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final timeFormatted = DateFormat('HH:mm:ss.SSS').format(log.timestamp);

                    return Semantics(
                      label: 'Entri log level ${log.level.label} modul ${log.tag}',
                      button: true,
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLevelBadge(log.level),
                            const SizedBox(height: 2),
                            Text(
                              timeFormatted,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Text(
                              '[${log.tag}]',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                log.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        subtitle: log.error != null
                            ? Text(
                                'Error: ${log.error}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                        onTap: () => _showLogDetail(log),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
