import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/view/user_profile_screen.dart';
import 'package:tool_bocs/features/web_ui/view/web_user_profile_screen.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/trades/widgets/report_post_sheet.dart';
import 'package:tool_bocs/features/web_ui/view/web_save_to_collection_dialog.dart';

class WebProductCard extends StatelessWidget {
  final PostModel post;
  final double? width;

  const WebProductCard({super.key, required this.post, this.width});

  Widget _buildExchangeInfo(BuildContext context) {
    final type = post.returnType.toLowerCase().trim();
    final min = post.priceMin;
    final max = post.priceMax;
    final name = post.returnItemName ?? '';
    final category = post.returnItemCategory ?? '';

    if (type == 'exchange' || type == 'item') {
      String text = 'In exchange for: ';
      if (name.isNotEmpty) {
        text += name;
        if (category.isNotEmpty) text += ' ($category)';
      } else if (category.isNotEmpty) {
        text += category;
      } else {
        text += 'Item';
      }
      return Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } else if (type == 'free') {
      return Text(
        AppLocalizations.of(context)!.freeLabel,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    } else {
      String text = 'In exchange for: ₹${min?.toStringAsFixed(0) ?? 0} (Money)';
      if (min != null && max != null && max != min) {
        text =
            'In exchange for: ₹${min.toStringAsFixed(0)} - ₹${max.toStringAsFixed(0)} (Money)';
      }
      return Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget _buildPostMenu(BuildContext context, PostModel post, bool isOwner) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
      ),
      padding: EdgeInsets.zero,
      onSelected: (value) async {
        final profileController = context.read<ProfileController>();
        switch (value) {
          case 'profile':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WebUserProfileScreen(userId: post.userId.toString()),
              ),
            );
            break;
          case 'save':
            WebSaveToCollectionDialog.show(context, post.userId);
            break;
          case 'share':
            Share.share(
                'Check out ${post.userName}\'s trade: ${post.itemName}\nDownload the app to see more!');
            break;
          case 'hide':
            context.read<TradeController>().hidePost(post.id);
            if (!context.mounted) return;
            ToastService.showSuccessToast(context, 'Post hidden');
            context
                .read<TradeController>()
                .fetchHomePosts(); // Refresh list to remove hidden post
            break;
          case 'report':
            ReportPostSheet.show(context, post.id);
            break;
          case 'block':
            final success = await profileController.blockUser(post.userId);
            if (!context.mounted) return;
            if (success.success) {
              ToastService.showSuccessToast(
                  context, 'User blocked successfully');
              context.read<TradeController>().fetchHomePosts(); // Refresh feed
            } else {
              ToastService.showErrorToast(context, success.message);
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          if (!isOwner)
            PopupMenuItem<String>(
              value: 'profile',
              child: Text(AppLocalizations.of(context)!.viewSellerProfile),
            ),
          if (!isOwner)
            PopupMenuItem<String>(
              value: 'save',
              child: Text(AppLocalizations.of(context)!.saveSeller),
            ),
          PopupMenuItem<String>(
            value: 'share',
            child: Text(AppLocalizations.of(context)!.sharePost),
          ),
          PopupMenuItem<String>(
            value: 'hide',
            child: Text(AppLocalizations.of(context)!.hidePost),
          ),
          if (!isOwner)
            PopupMenuItem<String>(
              value: 'block',
              child: Text(AppLocalizations.of(context)!.blockUser),
            ),
          if (!isOwner)
            PopupMenuItem<String>(
              value: 'report',
              child: Text(AppLocalizations.of(context)!.reportPost,
                  style: TextStyle(color: Colors.red)),
            ),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = post.itemImages.isNotEmpty ? post.itemImages.first : '';
    final isTake = post.postType.toLowerCase() == 'take' ||
        post.postType.toLowerCase() == 'taking';
    final authController = context.read<AuthController>();
    final isOwner = authController.currentUser?.id == post.userId;
    final actionLabel = isOwner ? 'Offers' : (isTake ? 'Give' : 'Take');

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.productDetails,
          arguments: post.id,
        );
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Container(
                      color: greyColor.withOpacity(0.1),
                      child: imagePath.isNotEmpty
                          ? AppCachedImage(
                              imageUrl: imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              radius: 0,
                            )
                          : const Icon(Icons.image_outlined,
                              size: 50, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: post.itemCategory.toLowerCase().contains('goods')
                            ? Colors.blue.shade700
                            : post.itemCategory
                                    .toLowerCase()
                                    .contains('services')
                                ? Colors.green.shade700
                                : post.itemCategory
                                        .toLowerCase()
                                        .contains('money')
                                    ? Colors.orange.shade700
                                    : Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.itemCategory,
                        style: TextStyle(
                          color: (post.itemCategory
                                      .toLowerCase()
                                      .contains('goods') ||
                                  post.itemCategory
                                      .toLowerCase()
                                      .contains('services') ||
                                  post.itemCategory
                                      .toLowerCase()
                                      .contains('money'))
                              ? Colors.white
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildPostMenu(context, post, isOwner),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${(post.userName ?? 'User').split(' ').first}'s ${isTake ? 'Taking' : 'Giving'}",
                          style: TextStyle(color: greyColor, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.distanceKm != null
                                ? '${post.distanceKm!.toStringAsFixed(1)} km away'
                                : '- km away',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          post.itemName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildExchangeInfo(context),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (isOwner) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.notifications,
                              arguments: post.id,
                            );
                          } else {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.productDetails,
                              arguments: post.id,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(actionLabel),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
