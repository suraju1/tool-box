import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/view/user_profile_screen.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/web_ui/view/web_filter_dialog.dart';
import 'package:tool_bocs/features/web_ui/view/web_save_to_collection_dialog.dart';
import 'package:tool_bocs/features/web_ui/view/web_sort_dialog.dart';
import 'package:tool_bocs/features/trades/widgets/report_post_sheet.dart';

class WebTakeScreen extends StatefulWidget {
  const WebTakeScreen({super.key});

  @override
  State<WebTakeScreen> createState() => _WebTakeScreenState();
}

class _WebTakeScreenState extends State<WebTakeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tradeController = context.read<TradeController>();
      final authController = context.read<AuthController>();

      tradeController.setCurrentUserId(authController.currentUser?.id);
      tradeController.fetchGivePosts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TradeController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(isNarrow ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER / SEARCH SECTION
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 16 : 24,
                    vertical: isNarrow ? 20 : 32,
                  ),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.whatDoYouWantTo1,
                        style: TextStyle(
                          fontSize: isNarrow ? 20 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!
                            .discoverAmazingToolsAndItems,
                        style: TextStyle(
                          fontSize: isNarrow ? 14 : 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Search bar — always full width
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            controller.setSearchQuery(value, type: 'give');
                          },
                          decoration: const InputDecoration(
                            icon: Icon(Icons.search, color: Colors.grey),
                            hintText: "Search items (e.g. Lawn Mower, Tent)...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Buttons — wraps on narrow screens
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              WebFilterDialog.show(context,
                                  initialPostType: 'give');
                            },
                            icon: const Icon(Icons.filter_alt_outlined),
                            label: Text(AppLocalizations.of(context)!.filter),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).cardColor,
                              foregroundColor:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isNarrow ? 16 : 24,
                                  vertical: isNarrow ? 12 : 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                          Consumer<TradeController>(
                            builder: (context, tc, _) {
                              final hasSort =
                                  tc.selectedDistanceSort.isNotEmpty &&
                                          tc.selectedDistanceSort !=
                                              'Nearest First' ||
                                      tc.selectedDateSort.isNotEmpty;
                              return ElevatedButton.icon(
                                onPressed: () {
                                  WebSortDialog.show(context,
                                      initialPostType: 'give');
                                },
                                icon: const Icon(Icons.sort),
                                label:
                                    Text(AppLocalizations.of(context)!.sortBy),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasSort
                                      ? Colors.black
                                      : Theme.of(context).cardColor,
                                  foregroundColor: hasSort
                                      ? Colors.white
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isNarrow ? 16 : 24,
                                      vertical: isNarrow ? 12 : 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: hasSort
                                          ? Colors.black
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.createGivePost,
                                arguments: "Create Take Post",
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: Text(
                                AppLocalizations.of(context)!.requestAnItem),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isNarrow ? 16 : 24,
                                  vertical: isNarrow ? 12 : 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isNarrow ? 24 : 40),

                // RESULTS COUNT
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.availableItemsNearby,
                      style: TextStyle(
                        fontSize: isNarrow ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Showing ${controller.givePosts.length} Results",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // PRODUCTS GRID
                if (controller.isGiveLoading && controller.givePosts.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (controller.givePosts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!
                                .noItemsFoundMatchingYour,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 16),
                          )
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isNarrow ? 280 : 320,
                      mainAxisExtent: 420,
                      crossAxisSpacing: isNarrow ? 12 : 20,
                      mainAxisSpacing: isNarrow ? 12 : 20,
                    ),
                    itemCount: controller.givePosts.length,
                    itemBuilder: (context, index) {
                      return _WebTakeCard(post: controller.givePosts[index]);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WebTakeCard extends StatelessWidget {
  final PostModel post;
  const _WebTakeCard({required this.post});

  Widget _buildPostMenu(BuildContext context, PostModel post, bool isOwner) {
    return PopupMenuButton<String>(
      color: Theme.of(context).cardColor,
      surfaceTintColor: Colors.transparent,
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
                    UserProfileScreen(userId: post.userId.toString()),
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
                .fetchGivePosts(); // Refresh list to remove hidden post
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
              context.read<TradeController>().fetchGivePosts(); // Refresh feed
            } else {
              ToastService.showErrorToast(
                  context, success.message ?? 'Error blocking user');
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

  @override
  Widget build(BuildContext context) {
    final imagePath = post.itemImages.isNotEmpty ? post.itemImages.first : '';
    final authController = context.read<AuthController>();
    final isOwner = authController.currentUser?.id == post.userId;
    final actionLabel = isOwner ? 'Offers' : 'Take';

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.productDetails,
          arguments: post.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? greyColor.withOpacity(0.1)
                : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.03)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 10,
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
                children: [
                  Container(
                    width: double.infinity,
                    color: greyColor.withOpacity(0.1),
                    child: imagePath.isNotEmpty
                        ? AppCachedImage(
                            imageUrl: imagePath,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            radius: 0,
                          )
                        : const Icon(Icons.handyman,
                            size: 50, color: Colors.grey),
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
                          "${(post.userName ?? 'User').split(' ').first} is giving",
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
