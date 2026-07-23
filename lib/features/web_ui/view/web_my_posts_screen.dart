import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/date_util.dart';
import 'package:tool_bocs/features/web_ui/widgets/web_screen_header.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/core/services/toast_service.dart';

class WebMyPostsScreen extends StatefulWidget {
  final String? initialFilter;
  const WebMyPostsScreen({super.key, this.initialFilter});

  @override
  State<WebMyPostsScreen> createState() => _WebMyPostsScreenState();
}

class _WebMyPostsScreenState extends State<WebMyPostsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialFilter != null) {
        context.read<ProfileController>().getMyPosts(
              postType: _getPostTypeFromLabel(widget.initialFilter!),
              label: widget.initialFilter!,
            );
      } else {
        context.read<ProfileController>().getMyPosts();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProfileController>().loadMoreMyPosts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebScreenHeader(
                title: AppLocalizations.of(context)!.myPostsTitle,
                actions: [
                  PopupMenuButton<void>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: Theme.of(context).cardColor,
                    surfaceTintColor: Colors.transparent,
                    elevation: 4,
                    icon: Icon(Icons.info_outline, color: context.primaryColor),
                    itemBuilder: (context) => [
                      PopupMenuItem<void>(
                        enabled: false,
                        padding: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.manageYourPosts,
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF111311),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!
                                    .seeAllActiveInactivePosts,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppLocalizations.of(context)!
                                    .viewOffersNotifications,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<void>(
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            Navigator.pushNamed(context, AppRoutes.helpSupport);
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.help_outline,
                                size: 18, color: context.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.helpSupport,
                              style: TextStyle(
                                color: context.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Consumer<ProfileController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading && controller.myPosts.isEmpty) {
                      return _buildLoadingState();
                    }

                    if (controller.errorMessage != null &&
                        controller.myPosts.isEmpty) {
                      return _buildErrorState(
                          controller.errorMessage!, controller);
                    }

                    return RefreshIndicator(
                      onRefresh: () => controller.getMyPosts(
                        postType: _getPostTypeFromLabel(
                            controller.selectedMyPostsFilter),
                        label: controller.selectedMyPostsFilter,
                      ),
                      child: ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          _buildFilters(controller),
                          const SizedBox(height: 24),
                          if (_getFilteredPosts(controller).isEmpty)
                            _buildEmptyState(context)
                          else ...[
                            _buildPostList(controller),
                            if (controller.isPaginationLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PostModel> _getFilteredPosts(ProfileController controller) {
    final allPosts = controller.myPosts;
    if (controller.selectedMyPostsFilter == 'Active') {
      return allPosts.where((p) => p.status.toLowerCase() == 'active').toList();
    } else if (controller.selectedMyPostsFilter == 'Inactive') {
      return allPosts.where((p) => p.status.toLowerCase() != 'active').toList();
    }
    return allPosts;
  }

  Widget _buildSummaryCard(
      String count, String label, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: greyColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(ProfileController controller) {
    return Row(
      children: [
        _buildFilterChip('All', controller),
        const SizedBox(width: 12),
        _buildFilterChip('Active', controller),
        const SizedBox(width: 12),
        _buildFilterChip('Inactive', controller),
      ],
    );
  }

  Widget _buildFilterChip(String label, ProfileController controller) {
    bool isSelected = controller.selectedMyPostsFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        controller.getMyPosts(
          postType: _getPostTypeFromLabel(label),
          label: label,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : Colors.grey.withOpacity(0.2)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getPostTypeFromLabel(String label) {
    if (label.trim() == 'Gives') return 'give';
    if (label.trim() == 'Takes') return 'take';
    return 'all';
  }

  Widget _buildPostList(ProfileController controller) {
    final filteredPosts = _getFilteredPosts(controller);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 420,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: filteredPosts.length < 3 ? 3 : filteredPosts.length,
      itemBuilder: (context, index) {
        if (index < filteredPosts.length) {
          return _buildPostCard(context, filteredPosts[index]);
        } else {
          return _buildEmptyCardPlaceholder();
        }
      },
    );
  }

  Widget _buildEmptyCardPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: greyColor.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const ShimmerBox(height: 28, width: 200),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 2 ? 24.0 : 0),
                child: const ShimmerBox(
                    height: 120, width: double.infinity, radius: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: const [
            ShimmerBox(height: 48, width: 80, radius: 30),
            SizedBox(width: 12),
            ShimmerBox(height: 48, width: 100, radius: 30),
            SizedBox(width: 12),
            ShimmerBox(height: 48, width: 100, radius: 30),
          ],
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 420,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: 6,
          itemBuilder: (context, index) =>
              const ShimmerBox(height: 320, width: double.infinity, radius: 16),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, ProfileController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.getMyPosts(),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noPostsFound,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.tryChangingFilterOrCreatePost,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.createGivePost),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              AppLocalizations.of(context)!.createPostLabel,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post) {
    bool isActive = post.status.toLowerCase() == 'active';
    String imagePath = post.itemImages.isNotEmpty ? post.itemImages.first : '';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.productDetails,
          arguments: post.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section (Title, Details Button, and Status Toggle)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      post.itemName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: context.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (isActive) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!
                                    .deactivatePost),
                                content: Text(AppLocalizations.of(context)!
                                    .areYouSureYouWant5),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                        AppLocalizations.of(context)!.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .deactivate,
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              final success = await context
                                  .read<TradeController>()
                                  .deactivatePost(post.id);
                              if (success && context.mounted) {
                                ToastService.showSuccessToast(
                                    context, 'Post deactivated successfully');
                                context.read<ProfileController>().getMyPosts();
                              } else if (context.mounted) {
                                ToastService.showErrorToast(
                                    context,
                                    context
                                            .read<TradeController>()
                                            .errorMessage ??
                                        'Error deactivating post');
                              }
                            }
                          } else {
                            final success = await context
                                .read<TradeController>()
                                .reactivatePost(post.id);
                            if (success && context.mounted) {
                              ToastService.showSuccessToast(
                                  context, 'Post reactivated successfully');
                              context.read<ProfileController>().getMyPosts();
                            } else if (context.mounted) {
                              ToastService.showErrorToast(
                                  context,
                                  context
                                          .read<TradeController>()
                                          .errorMessage ??
                                      'Error reactivating post');
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                isActive ? Colors.green : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isActive)
                                Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                isActive ? 'Active' : 'Inactive',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Image Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: imagePath.isNotEmpty
                      ? AppCachedImage(
                          imageUrl: imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          radius: 0,
                          errorWidget: Icon(Icons.image_outlined,
                              size: 48, color: Colors.grey.shade400),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(Icons.image_outlined,
                              size: 48, color: Colors.grey.shade400),
                        ),
                ),
              ),
            ),

            // Bottom Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.grey, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        DateUtil.formatTimeAgo(post.createdAt),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.notifications,
                        arguments: post.id,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.viewOffers,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
