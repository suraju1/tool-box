import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/core/controller/shimmer_controller.dart';
import 'package:tool_bocs/core/controller/theme_controller.dart';
import 'package:tool_bocs/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:tool_bocs/features/chat/controller/chat_controller.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/splash/controller/on_bording_controller.dart';
import 'package:tool_bocs/firebase_options.dart';
import 'package:tool_bocs/util/connectivity_service.dart';
import 'package:tool_bocs/core/services/notification_service.dart';
import 'package:tool_bocs/core/services/firebase_notification_service.dart';
import 'package:tool_bocs/core/services/deep_link_handler.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/address/controller/address_controller.dart';
import 'package:tool_bocs/features/subscription/controller/subscription_controller.dart';
import 'package:tool_bocs/features/notifications/controller/notification_controller.dart';
import 'package:tool_bocs/features/trades/controller/wallet_controller.dart';
import 'package:tool_bocs/core/controller/language_controller.dart';
import 'package:tool_bocs/core/services/storage_service.dart';
import 'package:tool_bocs/core/api/api_client.dart';

import 'app.dart';
import 'package:tool_bocs/core/widgets/web_responsive_wrapper.dart';

import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make system navigation bar transparent for edge-to-edge UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Clear image cache on startup to remove any corrupted 0-byte files
  await DefaultCacheManager().emptyCache();

  await Hive.initFlutter();
  await Hive.openBox('location_box');
  ConnectivityService().initialize();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint(
        "FIREBASE INIT SUCCESS. Project ID: ${Firebase.app().options.projectId}");

    // Register background handler BEFORE any other notification initialization
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    debugPrint(
        "Please ensure you have added google-services.json (Android) or GoogleService-Info.plist (iOS)");
  }

  // Do not await these services here because they might request permissions
  // which block the UI indefinitely if awaited before runApp
  NotificationService()
      .init()
      .catchError((e) => debugPrint("Notification init error: $e"));
  FirebaseNotificationService()
      .init()
      .catchError((e) => debugPrint("Firebase Notification init error: $e"));

  // Initialize deep link handler for shared URL handling
  DeepLinkHandler()
      .init()
      .catchError((e) => debugPrint("DeepLink init error: $e"));

  // Restore API token for web deep links or hot restarts before first request
  try {
    final token = await StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      ApiClient().setAuthToken(token);
    }
  } catch (e) {
    debugPrint("Failed to restore auth token: $e");
  }

  runApp(
    WebResponsiveWrapper(
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
                create: (_) => ShimmerController()), //shimmer controller
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => OnBoardingController()),
            ChangeNotifierProvider(create: (_) => BottomNavBarController()),
            ChangeNotifierProvider(create: (_) => ChatController()),
            ChangeNotifierProvider(
                create: (_) => AuthController()), // Auth controller
            ChangeNotifierProvider(
                create: (_) => LocationController()), // Location controller
            ChangeNotifierProvider(
                create: (_) => TradeController()), // Trade controller
            ChangeNotifierProvider(
                create: (_) => ProfileController()), // Profile controller
            ChangeNotifierProvider(
                create: (_) => AddressController()), // Address controller
            ChangeNotifierProvider(
                create: (_) =>
                    SubscriptionController()), // Subscription controller
            ChangeNotifierProvider(
                create: (_) =>
                    NotificationController()), // Notification controller
            ChangeNotifierProvider(
                create: (_) => WalletController()), // Wallet controller
            ChangeNotifierProvider(
                create: (_) => LanguageController()), // Language controller
          ],
          child: const ToolUcsApp(),
        ),
        child: const SizedBox(), // prevent black screen
      ),
    ),
  );
}
