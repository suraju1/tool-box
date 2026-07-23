import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tool_bocs/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:tool_bocs/core/services/notification_service.dart';
import 'package:tool_bocs/core/services/storage_service.dart';
import 'package:tool_bocs/features/login_and_signup/model/user_model.dart';
import 'package:tool_bocs/features/profile/service/profile_service.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Initialize Firebase if needed (crucial for background isolates)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase already initialized or failed in background: $e");
  }

  debugPrint("--- Background Message Received ---");
  debugPrint("Message ID: ${message.messageId}");
  debugPrint("Data: ${message.data}");
  debugPrint("Notification: ${message.notification?.title} - ${message.notification?.body}");

  // 2. Show local notification ONLY IF it is a data-only message (where message.notification is null).
  // When message.notification != null, the OS automatically displays a system notification in background/terminated state.
  // Showing a local notification when message.notification != null causes duplicate notifications!
  if (message.notification == null && message.data.isNotEmpty) {
    final notificationService = NotificationService();
    // We must re-init local notifications in the background isolate
    await notificationService.init();

    // Map common chat fields from data if notification is null
    String title = message.notification?.title ?? 
                   message.data['title'] ?? 
                   message.data['otherUserName'] ?? 
                   'New Message';
    
    String body = message.notification?.body ?? 
                  message.data['body'] ?? 
                  message.data['content'] ?? 
                  message.data['message'] ?? 
                  'You have a new message';

    await notificationService.showNotification(
      id: message.messageId.hashCode,
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }
}

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Background Message Handler (Registered in main.dart)
      // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
              'Message also contained a notification: ${message.notification}');

          // Show local notification
          _notificationService.showNotification(
            id: message.messageId.hashCode,
            title: message.notification!.title ?? 'New Message',
            body: message.notification!.body ?? '',
            payload: jsonEncode(message.data), // Pass data as payload
          );
        }
      });

      // 4. Message Opened App Handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        debugPrint('Message data: ${message.data}');

        // Navigation logic
        _notificationService
            .handleNotificationPayload(jsonEncode(message.data));
      });

      // 4.1. Get initial message if app was terminated
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App was opened from a terminated state via notification');
        _notificationService
            .handleNotificationPayload(jsonEncode(initialMessage.data));
      }

      // 5. Get and Save Token (Fire and forget, do not block initialization)
      saveTokenToFirestore().catchError((e) {
        debugPrint("Error in background saveTokenToFirestore: $e");
      });

      // 6. Listen for Token Refresh
      _firebaseMessaging.onTokenRefresh.listen((token) async {
        final userData = await StorageService.getUserData();
        if (userData != null) {
          final user = UserModel.fromJson(jsonDecode(userData));
          await _saveToken(token, user.id.toString(), fullName: user.fullName);
          await _syncTokenToBackend(token);
        }
      });
    }
  }

  Future<void> saveTokenToFirestore({String? profileImageUrl}) async {
    // Get current user
    final userData = await StorageService.getUserData();
    if (userData != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(userData));
        String userId = user.id.toString();

        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveToken(token, userId,
              fullName: user.fullName, profileImageUrl: profileImageUrl);
          await _syncTokenToBackend(token);
        }
      } catch (e) {
        debugPrint("Error saving FCM token: $e");
      }
    }
  }

  Future<void> _syncTokenToBackend(String token) async {
    try {
      final tokenSaved = await StorageService.getAuthToken();
      if (tokenSaved != null && tokenSaved.isNotEmpty) {
        await ProfileService().updateGeneralProfile({'fcm_token': token});
        debugPrint("FCM token successfully synced with MySQL Backend");
      }
    } catch (e) {
      debugPrint("Error syncing FCM token with MySQL Backend: $e");
    }
  }

  Future<void> _saveToken(String token, String userId,
      {String? fullName, String? profileImageUrl}) async {
    Map<String, dynamic> data = {
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fullName != null) {
      data['fullName'] = fullName;
    }
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      data['profileImage'] = profileImageUrl;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));

    debugPrint(
        "User data (including FCM token) saved to Firestore for user $userId");
  }

  /// Sync profile name and image directly to Firestore without needing FCM token.
  /// Call this whenever the user updates their profile.
  static Future<void> syncProfileData({
    String? fullName,
    String? profileImageUrl,
  }) async {
    try {
      final userData = await StorageService.getUserData();
      if (userData == null) return;

      final user = UserModel.fromJson(jsonDecode(userData));
      final String userId = user.id.toString();

      final Map<String, dynamic> data = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (fullName != null && fullName.isNotEmpty) {
        data['fullName'] = fullName;
      }
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        data['profileImage'] = profileImageUrl;
      }

      if (data.length > 1) {
        // At least one real field besides updatedAt
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(data, SetOptions(merge: true));
        debugPrint("Profile data synced to Firestore for user $userId: $data");
      }
    } catch (e) {
      debugPrint("Error syncing profile data to Firestore: $e");
    }
  }

  /// Get current FCM token
  static Future<String?> getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }
}
