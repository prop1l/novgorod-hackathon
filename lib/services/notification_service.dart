import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

import '../models/achievement.dart';
import '../models/place.dart';

/// Локальные уведомления о местах (payload — id места) и о достижениях.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'places_nearby';
  static const _channelName = 'Исторические места рядом';

  /// Вызывается при тапе по уведомлению, пока приложение запущено.
  void Function(String placeId)? onOpenPlace;

  /// Возвращает id места, если приложение запустили тапом по уведомлению (cold start).
  Future<String?> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = response.payload;
        if (id != null && id.isNotEmpty) onOpenPlace?.call(id);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      return launch!.notificationResponse?.payload;
    }
    return null;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  Future<void> showPlace(Place place) async {
    final picture = await _assetToFile(place.photoOld ?? place.photoNow);
    await _plugin.show(
      id: place.id.hashCode & 0x7fffffff,
      title: 'Рядом: ${place.name}',
      body: place.short,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Сообщает, когда вы проходите мимо исторического места',
          importance: Importance.high,
          priority: Priority.high,
          largeIcon: picture == null ? null : FilePathAndroidBitmap(picture),
          styleInformation: picture == null
              ? BigTextStyleInformation(place.short)
              : BigPictureStyleInformation(
                  FilePathAndroidBitmap(picture),
                  summaryText: place.short,
                  hideExpandedLargeIcon: true,
                ),
        ),
        iOS: DarwinNotificationDetails(
          // iOS прикладывает к уведомлению только JPEG, PNG и GIF — WebP-фото показываем без картинки.
          attachments: picture == null || picture.endsWith('.webp')
              ? null
              : [DarwinNotificationAttachment(picture)],
        ),
      ),
      payload: place.id,
    );
  }

  /// Префикс payload для уведомлений о достижениях, чтобы отличать их от id мест.
  static const achievementPayload = 'achievement:';

  Future<void> showAchievement(Achievement a) async {
    await _plugin.show(
      id: ('achievement_${a.id}'.hashCode & 0x7fffffff),
      title: 'Новое достижение: ${a.title}',
      body: a.description,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Достижения',
          channelDescription: 'Сообщает о полученных достижениях',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: '$achievementPayload${a.id}',
    );
  }

  /// Уведомлениям нужен файл на диске, а фото лежат в assets — копируем во временную папку.
  Future<String?> _assetToFile(String? asset) async {
    if (asset == null) return null;
    try {
      final data = await rootBundle.load(asset);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/notif_${asset.split('/').last}');
      if (!await file.exists()) {
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
