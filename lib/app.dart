import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/routes/app_route_pages.dart';
import 'core/constants/app_theme.dart';
import 'core/controller/theme_controller.dart';
import 'package:tool_bocs/features/network_connectivity/view/connectivity_wrapper.dart';
import 'package:tool_bocs/routes/navigator_key.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:tool_bocs/core/controller/language_controller.dart';
import 'routes/app_routes.dart';

class ToolUcsApp extends StatelessWidget {
  const ToolUcsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    final languageController = context.watch<LanguageController>();

    return ConnectivityWrapper(
      child: MaterialApp(
        title: 'TOOLUCS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            // Support drag scrolling on desktop/web
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
        ),
        navigatorKey: navigatorKey,
        initialRoute: AppRoutes.splash,
        routes: AppPages.routes,
        locale: languageController.locale,
        builder: (context, child) {
          return SafeArea(
            top:
                false, // Keep app bars under the status bar correctly if they handle it
            bottom:
                true, // Prevent content from going behind system navigation buttons
            child: child ?? const SizedBox.shrink(),
          );
        },
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
          Locale('mr'),
        ],
      ),
    );
  }
}
