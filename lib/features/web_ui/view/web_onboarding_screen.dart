import 'dart:async';
//import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/splash/controller/on_bording_controller.dart';
import 'package:tool_bocs/features/splash/model/on_bording_model.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';

class WebOnboardingScreen extends StatefulWidget {
  const WebOnboardingScreen({super.key});

  @override
  State<WebOnboardingScreen> createState() => _WebOnboardingScreenState();
}

class _WebOnboardingScreenState extends State<WebOnboardingScreen> {
  late PageController _pageController;
  Timer? _redirectTimer;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<OnBoardingController>();
      controller.addListener(_onControllerUpdate);
      controller.fetchOnboardingData();
    });
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final controller = context.read<OnBoardingController>();
      if (controller.onBoardingList.isNotEmpty && _pageController.hasClients) {
        int nextPage = controller.currentPage + 1;
        if (nextPage >= controller.onBoardingList.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _onControllerUpdate() {
    final controller = context.read<OnBoardingController>();
    if (!controller.isLoading &&
        controller.errorMessage != null &&
        controller.onBoardingList.isEmpty &&
        mounted) {
      _redirectTimer?.cancel();
      _redirectTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      });
    } else if (controller.onBoardingList.isNotEmpty && _autoPlayTimer == null) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _autoPlayTimer?.cancel();
    final controller = context.read<OnBoardingController>();
    controller.removeListener(_onControllerUpdate);
    _pageController.dispose();
    super.dispose();
  }

  void _handlingOnPageChanged(int page) {
    context.read<OnBoardingController>().setCurrentPage(page);
    _startAutoPlay(); // Reset timer on manual swipe
  }

  Widget _buildPageIndicator(int count, int currentPage) {
    List<Widget> children = [];
    for (int i = 0; i < count; i++) {
      children.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: i == currentPage ? 32.0 : 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: i == currentPage
                ? context.primaryColor
                : context.primaryColor.withOpacity(0.2),
          ),
        ),
      );
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnBoardingController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.onBoardingList.isEmpty) {
          return Scaffold(
            backgroundColor: context.scaffoldBg,
            body: Center(
                child: CircularProgressIndicator(color: context.primaryColor)),
          );
        }

        if (controller.errorMessage != null &&
            controller.onBoardingList.isEmpty) {
          return Scaffold(
            backgroundColor: context.scaffoldBg,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Server starting up...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Redirecting to login in 3 seconds...',
                    style: TextStyle(fontSize: 14, color: context.subTextColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _redirectTimer?.cancel();
                          controller.fetchOnboardingData();
                        },
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          _redirectTimer?.cancel();
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.login);
                        },
                        child: Text(AppLocalizations.of(context)!.goToLogin),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        final onboardingList = controller.onBoardingList;
        if (onboardingList.isEmpty) {
          return Scaffold(
            backgroundColor: context.scaffoldBg,
            body: Center(
                child: CircularProgressIndicator(color: context.primaryColor)),
          );
        }

        return Scaffold(
          backgroundColor: context.scaffoldBg,
          body: Row(
            children: [
              // Left Pane: Illustration Carousel
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: context.isDarkMode
                          ? [const Color(0xFF1A1A1D), const Color(0xFF2D2D35)]
                          : [const Color(0xFFF0F4FF), const Color(0xFFE2E9FB)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          itemCount: onboardingList.length,
                          controller: _pageController,
                          onPageChanged: _handlingOnPageChanged,
                          itemBuilder: (context, index) {
                            final slide = onboardingList[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 64.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Animated wrapper for image
                                  TweenAnimationBuilder<double>(
                                    key: ValueKey(index),
                                    tween: Tween(begin: 0.8, end: 1.0),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeOutBack,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: child,
                                      );
                                    },
                                    child: Container(
                                      height: 400,
                                      constraints:
                                          const BoxConstraints(maxWidth: 500),
                                      child:
                                          slide.imageUrl.startsWith('assets/')
                                              ? Image.asset(slide.imageUrl,
                                                  fit: BoxFit.contain)
                                              : AppCachedImage(
                                                  imageUrl: slide.imageUrl,
                                                  height: 400.0,
                                                  width: double.infinity,
                                                  fit: BoxFit.contain,
                                                ),
                                    ),
                                  ),
                                  const SizedBox(height: 48),
                                  if (slide.title.isNotEmpty)
                                    Text(
                                      slide.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontFamily: FontFamily.openSans,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: context.textColor,
                                      ),
                                    ),
                                  if (slide.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 20.0, left: 32.0, right: 32.0),
                                      child: Text(
                                        slide.description,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: context.subTextColor,
                                          fontFamily: FontFamily.openSans,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 60.0),
                        child: _buildPageIndicator(
                            onboardingList.length, controller.currentPage),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Pane: Welcome & Action
              Expanded(
                flex: 4,
                child: Container(
                  color: context.surfaceColor,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48.0, vertical: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 80,
                                width: 80,
                                margin: const EdgeInsets.only(bottom: 32),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? Colors.grey[850]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/logo_transperant.png',
                                  color: context.isDarkMode
                                      ? Colors.white
                                      : context.primaryColor,
                                ),
                              ),
                            ),
                            Text(
                              'Welcome to Toolucs',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                fontFamily: FontFamily.openSans,
                                letterSpacing: -1,
                                height: 1.15,
                                color: context.textColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'The ultimate platform to trade, lend, and borrow tools in your community.',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: FontFamily.openSans,
                                color: context.subTextColor,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 56),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, AppRoutes.login);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: FontFamily.openSans,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'By continuing, you agree to our Terms of Service and Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.subTextColor.withOpacity(0.6),
                                height: 1.5,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
