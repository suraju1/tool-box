import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tool_bocs/features/web_ui/view/web_logout_dialog.dart';

class WebSidebar extends StatelessWidget {
  const WebSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BottomNavBarController>();
    final theme = Theme.of(context);
    String? currentRoute = ModalRoute.of(context)?.settings.name;

    String activeRoute = AppRoutes.home;
    if (currentRoute != null && currentRoute != AppRoutes.splash) {
      activeRoute = currentRoute;
    }

    int mappedIndex = 0;
    if (activeRoute == AppRoutes.home)
      mappedIndex = 0;
    else if (activeRoute == AppRoutes.webGive)
      mappedIndex = 1;
    else if (activeRoute == AppRoutes.webTake)
      mappedIndex = 2;
    else if (activeRoute == AppRoutes.chat)
      mappedIndex = 3;
    else if (activeRoute == AppRoutes.webProfile) mappedIndex = 4;

    if (mappedIndex != controller.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setIndex(mappedIndex);
      });
    }

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
            right: BorderSide(
                color: context.isDarkMode
                    ? Colors.white12
                    : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (activeRoute != AppRoutes.home) {
                controller.setIndex(0);
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Image.asset(
                  'assets/logo_transperant.png',
                  height: 35,
                  fit: BoxFit.contain,
                  color: context.textColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _NavItem(
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view,
                    title: AppLocalizations.of(context)!.home,
                    isSelected: activeRoute == AppRoutes.home,
                    onTap: () {
                      if (activeRoute != AppRoutes.home) {
                        controller.setIndex(0);
                        Navigator.pushReplacementNamed(context, AppRoutes.home);
                      }
                    },
                  ),
                  _NavItem(
                    icon: Icons.upload_outlined,
                    activeIcon: Icons.upload,
                    title: AppLocalizations.of(context)!.giveLabel,
                    isSelected: activeRoute == AppRoutes.webGive,
                    onTap: () {
                      if (activeRoute != AppRoutes.webGive) {
                        controller.setIndex(1);
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.webGive);
                      }
                    },
                  ),
                  _NavItem(
                    icon: Icons.download_outlined,
                    activeIcon: Icons.download,
                    title: AppLocalizations.of(context)!.takeLabel,
                    isSelected: activeRoute == AppRoutes.webTake,
                    onTap: () {
                      if (activeRoute != AppRoutes.webTake) {
                        controller.setIndex(2);
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.webTake);
                      }
                    },
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    title: AppLocalizations.of(context)!.chat,
                    isSelected: activeRoute == AppRoutes.chat,
                    onTap: () {
                      if (activeRoute != AppRoutes.chat) {
                        controller.setIndex(3);
                        Navigator.pushReplacementNamed(context, AppRoutes.chat);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Divider(
                        color: context.isDarkMode
                            ? Colors.white12
                            : const Color(0xFFEEEEEE),
                        height: 1),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    title: AppLocalizations.of(context)!.profile,
                    isSelected: activeRoute == AppRoutes.webProfile,
                    onTap: () {
                      if (activeRoute != AppRoutes.webProfile) {
                        controller.setIndex(4);
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.webProfile);
                      }
                    },
                  ),
                  _NavItem(
                    icon: Icons.image_outlined,
                    activeIcon: Icons.image,
                    title: AppLocalizations.of(context)!.myPostsTitle,
                    isSelected: activeRoute == AppRoutes.myPosts,
                    onTap: () {
                      if (activeRoute != AppRoutes.myPosts) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.myPosts);
                      }
                    },
                  ),
                  _NavItem(
                    icon: Icons.stars_outlined,
                    activeIcon: Icons.stars,
                    title: AppLocalizations.of(context)!.mySubscription,
                    isSelected: activeRoute == AppRoutes.mySubscription,
                    onTap: () {
                      if (activeRoute != AppRoutes.mySubscription) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.mySubscription);
                      }
                    },
                  ),
                  _NavItem(
                    icon: Icons.sync,
                    activeIcon: Icons.sync,
                    title: AppLocalizations.of(context)!.transactionHistory,
                    isSelected: activeRoute == AppRoutes.transactionHistory,
                    onTap: () {
                      if (activeRoute != AppRoutes.transactionHistory) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.transactionHistory);
                      }
                    },
                  ),
                  _NavItem(
                    icon: Icons.bookmark_border,
                    activeIcon: Icons.bookmark,
                    title: AppLocalizations.of(context)!.savedProfiles,
                    isSelected: activeRoute == AppRoutes.savedUsers,
                    onTap: () {
                      if (activeRoute != AppRoutes.savedUsers) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.savedUsers);
                      }
                    },
                  ),
                  _NavItem(
                    icon: Icons.block_outlined,
                    activeIcon: Icons.block,
                    title: AppLocalizations.of(context)!.blockedUsers,
                    isSelected: activeRoute == AppRoutes.blockedUsers,
                    onTap: () {
                      if (activeRoute != AppRoutes.blockedUsers) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.blockedUsers);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Divider(
                        color: context.isDarkMode
                            ? Colors.white12
                            : const Color(0xFFEEEEEE),
                        height: 1),
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    title: AppLocalizations.of(context)!.settings,
                    isSelected: activeRoute == AppRoutes.settings,
                    onTap: () {
                      if (activeRoute != AppRoutes.settings) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.settings);
                      }
                    },
                  ),
                  _NavItem(
                    icon: Icons.logout_outlined,
                    activeIcon: Icons.logout,
                    title: AppLocalizations.of(context)!.logout,
                    isSelected: false,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const WebLogoutDialog(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? context.textColor.withOpacity(0.08)
                : isHovered
                    ? Colors.grey.withOpacity(0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.isSelected ? widget.activeIcon : widget.icon,
                color: widget.isSelected
                    ? context.textColor
                    : (isHovered ? context.textColor : context.subTextColor),
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  color: widget.isSelected
                      ? context.textColor
                      : (isHovered ? context.textColor : context.subTextColor),
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
