import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/routes/navigator_key.dart';
import 'package:flutter/material.dart';
import 'package:tool_bocs/features/chat/view/chat_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          handleNotificationPayload(response.payload!);
        }
      },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.requestNotificationsPermission();

      // Create high priority channel explicitly
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'chat_channel',
        'Chat Notifications',
        description: 'Notifications for new messages',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  void handleNotificationPayload(String payload, {int retryCount = 0}) {
    debugPrint("Handling notification payload: $payload (retry: $retryCount)");
    if (navigatorKey.currentState == null) {
      if (retryCount < 10) {
        debugPrint("[NotificationService] Navigator not ready, queueing retry for: $payload");
        Future.delayed(const Duration(milliseconds: 500), () {
          handleNotificationPayload(payload, retryCount: retryCount + 1);
        });
        return;
      } else {
        debugPrint("[NotificationService] Navigator still null after 10 retries. Aborting navigation.");
        return;
      }
    }

    try {
      // 1. Try to parse as JSON (FCM style)
      try {
        final Map<String, dynamic> data = jsonDecode(payload);

        // Check for chat notification
        if (data.containsKey('chatRoomId') || data['type'] == 'chat') {
          final String chatRoomId = data['chatRoomId'] ?? '';
          final String otherUserId = data['otherUserId']?.toString() ?? '';
          final String otherUserName = data['otherUserName'] ?? 'Chat';

          if (chatRoomId.isNotEmpty && otherUserId.isNotEmpty) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatRoomId: chatRoomId,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                ),
              ),
            );
            return;
          }
        }

        // Check for post/response notification
        final dynamic postIdRaw =
            data['post_id'] ?? data['giveaway_id'] ?? data['postId'];
        if (postIdRaw != null) {
          final int? postId = int.tryParse(postIdRaw.toString());
          if (postId != null) {
            navigatorKey.currentState?.pushNamed(
              AppRoutes.notifications,
              arguments: postId,
            );
            return;
          }
        }

        // Fallback for any other JSON data - just go to general notifications
        navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
        return;
      } catch (e) {
        // Not JSON or parse failed, continue to legacy format
        debugPrint("Payload is not JSON or failed to parse: $e");
      }

      // 2. Legacy pipe-separated format (roomId|senderId|senderName)
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final chatRoomId = parts[0];
        final otherUserId = parts[1];
        final otherUserName = parts.length >= 3 ? parts[2] : 'Chat';

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoomId: chatRoomId,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
            ),
          ),
        );
      } else {
        // Fallback: if there's any payload but doesn't match formats, just go to notifications
        navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
      }
    } catch (e) {
      debugPrint("Error in handleNotificationPayload: $e");
      // Last resort fallback
      navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notifications for new messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }
}
