import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/shimmer_controller.dart';
import 'package:tool_bocs/features/home/view/home_screen.dart';
import 'package:tool_bocs/features/profile/view/profile_screen.dart';
import 'package:tool_bocs/features/trades/view/give_screen.dart';
import 'package:tool_bocs/features/trades/view/take_screen.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/features/chat/view/chat_list_screen.dart';
import 'package:tool_bocs/features/chat/controller/chat_service.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import '../controller/bottom_navbar_controller.dart';
import 'package:tool_bocs/core/widgets/responsive_layout.dart';
import 'package:tool_bocs/features/web_ui/view/web_home_screen.dart';
import 'package:tool_bocs/features/web_ui/layout/web_dashboard_wrapper.dart';

class BottomNavBarScreen extends StatelessWidget {
  const BottomNavBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BottomNavBarController>();

    final List<Widget> screens = [
      const HomeScreen(),
      const GiveScreen(),
      const TakeScreen(),
      const ChatListScreen(),
    ];

    final mobileScaffold = Builder(
      builder: (context) => Scaffold(
        drawer: Drawer(
          width: 1.sw * 0.85,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: const ProfileScreen(isTab: false, isDrawer: true),
        ),
        body: PageView(
          controller: controller.pageController,
          onPageChanged: (index) {
            controller.onPageChanged(index);
            // Optional: reset shimmer on page change
            context.read<ShimmerController>().reset();
          },
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.currentIndex < screens.length ? controller.currentIndex : 0,
          onTap: (index) {
            controller.setIndex(index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: context.primaryColor,
          unselectedItemColor: greyColor,
          selectedLabelStyle:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
          unselectedLabelStyle:
              TextStyle(fontWeight: FontWeight.normal, fontSize: 12.sp),
          items: [
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                isSelected: false,
                child: Icon(
                  Icons.dashboard_outlined,
                  color: greyColor,
                  size: 24.sp,
                ),
              ),
              activeIcon: _buildAnimatedIcon(
                isSelected: true,
                child: Icon(
                  Icons.dashboard,
                  color: context.primaryColor,
                  size: 24.sp,
                ),
              ),
              label: AppLocalizations.of(context)!.home,
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                isSelected: false,
                child: Icon(
                  Icons.file_upload_outlined,
                  color: greyColor,
                  size: 24.sp,
                ),
              ),
              activeIcon: _buildAnimatedIcon(
                isSelected: true,
                child: Icon(
                  Icons.file_upload,
                  color: context.primaryColor,
                  size: 24.sp,
                ),
              ),
              label: AppLocalizations.of(context)!.give,
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                isSelected: false,
                child: Icon(
                  Icons.file_download_outlined,
                  color: greyColor,
                  size: 24.sp,
                ),
              ),
              activeIcon: _buildAnimatedIcon(
                isSelected: true,
                child: Icon(
                  Icons.file_download,
                  color: context.primaryColor,
                  size: 24.sp,
                ),
              ),
              label: AppLocalizations.of(context)!.take,
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                isSelected: false,
                child: StreamBuilder<int>(
                  stream: ChatService().getTotalUnreadCount(),
                  builder: (context, snapshot) {
                    int count = snapshot.data ?? 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          color: greyColor,
                          size: 24.sp,
                        ),
                        if (count > 0)
                          Positioned(
                            right: -5,
                            top: -5,
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                color: context.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: context.onPrimaryColor, width: 1.5),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16.r,
                                minHeight: 16.r,
                              ),
                              child: Center(
                                child: Text(
                                  count > 99 ? '99+' : count.toString(),
                                  style: TextStyle(
                                    color: context.onPrimaryColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              activeIcon: _buildAnimatedIcon(
                isSelected: true,
                child: StreamBuilder<int>(
                  stream: ChatService().getTotalUnreadCount(),
                  builder: (context, snapshot) {
                    int count = snapshot.data ?? 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.message,
                          color: context.primaryColor,
                          size: 24.sp,
                        ),
                        if (count > 0)
                          Positioned(
                            right: -5,
                            top: -5,
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                color: context.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: context.onPrimaryColor, width: 1.5),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16.r,
                                minHeight: 16.r,
                              ),
                              child: Center(
                                child: Text(
                                  count > 99 ? '99+' : count.toString(),
                                  style: TextStyle(
                                    color: context.onPrimaryColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              label: AppLocalizations.of(context)!.chat,
            ),
          ],
        ),
      ),
    );

    return ResponsiveLayout(
      mobileScreen: mobileScaffold,
      webScreen: const WebDashboardWrapper(child: WebHomeScreen()),
    );
  }

  Widget _buildAnimatedIcon({
    required Widget child,
    required bool isSelected,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: isSelected ? 300 : 200),
      tween: Tween<double>(
        begin: isSelected ? 0.9 : 1.18,
        end: isSelected ? 1.18 : 1.0,
      ),
      curve: isSelected ? Curves.easeOutBack : Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }
}
