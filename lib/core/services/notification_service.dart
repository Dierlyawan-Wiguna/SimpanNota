import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    try {
      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification tapped with payload: ${details.payload}');
        },
      );
      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');

      // Meminta izin notifikasi untuk Android 13+ (API 33+)
      await requestPermissions();
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<bool?> requestPermissions() async {
    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        return await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
    return false;
  }

  Future<void> showReceiptSavedNotification({
    required String productName,
    required String storeName,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'simpan_nota_channel_id',
            'SimpanNota Notifikasi',
            channelDescription:
                'Notifikasi status berhasil simpan nota belanja',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final int notificationId = DateTime.now().millisecondsSinceEpoch
          .remainder(100000);

      await flutterLocalNotificationsPlugin.show(
        id: notificationId,
        title: 'Nota Berhasil Disimpan! 🎉',
        body: 'Nota "$productName" di "$storeName" tersimpan di sistem.',
        notificationDetails: notificationDetails,
      );
      debugPrint('Notification sent successfully: $productName');
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Menjadwalkan pengingat garansi (Scheduled Notification)
  /// Pengingat otomatis diatur pada H-7 sebelum masa garansi berakhir pada pukul 09:00.
  /// Jika sisa waktu garansi kurang dari 7 hari namun masih di masa depan, dijadwalkan pada H-1.
  Future<void> scheduleWarrantyExpiryNotification({
    required int receiptId,
    required String productName,
    required String storeName,
    required DateTime expirationDate,
  }) async {
    try {
      final now = DateTime.now();
      if (expirationDate.isBefore(now)) {
        // Garansi sudah kedaluwarsa, tidak perlu menjadwalkan notifikasi
        return;
      }

      // Hitung tanggal pengingat (Default: H-7 sebelum expiration date, jam 09:00 pagi)
      DateTime reminderDate = DateTime(
        expirationDate.year,
        expirationDate.month,
        expirationDate.day - 7,
        9, // 09:00 pagi
        0,
      );

      // Jika H-7 sudah lewat (misal durasi garansi singkat),
      // jadwalkan untuk H-1 pada pukul 09:00 pagi
      if (reminderDate.isBefore(now)) {
        reminderDate = DateTime(
          expirationDate.year,
          expirationDate.month,
          expirationDate.day - 1,
          9,
          0,
        );
      }

      // Jika bahkan H-1 sudah lewat tapi expirationDate masih di masa depan, jadwalkan 5 menit dari sekarang
      if (reminderDate.isBefore(now)) {
        reminderDate = now.add(const Duration(minutes: 5));
      }

      // Batasi jika tanggal pengingat melebihi tanggal kedaluwarsa
      if (reminderDate.isAfter(expirationDate)) {
        reminderDate = expirationDate.subtract(const Duration(hours: 2));
      }

      if (reminderDate.isBefore(now)) {
        return;
      }

      final scheduledTZ = tz.TZDateTime.from(reminderDate, tz.local);

      const AndroidNotificationDetails
      androidDetails = AndroidNotificationDetails(
        'simpan_nota_reminder_channel',
        'Pengingat Garansi Produk',
        channelDescription:
            'Pemberitahuan terjadwal menjelang masa berlaku garansi nota habis',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final notifId = receiptId.abs() % 100000;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: notifId,
        title: '⚠️ Garansi Segera Berakhir!',
        body: 'Garansi barang "$productName" ($storeName) akan segera habis.',
        scheduledDate: scheduledTZ,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint(
        'Scheduled notification set for $productName at $scheduledTZ (ID: $notifId)',
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Membatalkan notifikasi terjadwal berdasarkan ID nota
  Future<void> cancelNotification(int receiptId) async {
    try {
      final notifId = receiptId.abs() % 100000;
      await flutterLocalNotificationsPlugin.cancel(id: notifId);
      debugPrint('Cancelled notification ID: $notifId');
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }
}
