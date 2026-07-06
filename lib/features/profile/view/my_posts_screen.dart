import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/core/widgets/skeleton_widgets.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/util/date_util.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';

class MyPostsScreen extends StatefulWidget {
  final String? initialFilter;
  const MyPostsScreen({super.key, this.initialFilter});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.appBarColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              Icon(Icons.arrow_back_ios, color: context.textColor, size: 20.sp),
        ),
        title: Text(
          AppLocalizations.of(context)!.myPostsTitle,
          style: TextStyle(
            color: context.textColor,
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            fontFamily: FontFamily.openSans,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<void>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
            color: Theme.of(context).cardColor,
            surfaceTintColor: Colors.transparent,
            elevation: 4,
            icon:
                Icon(Icons.info_outline, color: context.textColor, size: 24.sp),
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                enabled: false,
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.manageYourPosts,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF111311),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        AppLocalizations.of(context)!.seeAllActiveInactivePosts,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        AppLocalizations.of(context)!.viewOffersNotifications,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12.sp,
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
                        size: 18.sp, color: context.textColor),
                    SizedBox(width: 8.w),
                    Text(
                      AppLocalizations.of(context)!.helpSupport,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 13.sp,
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
      body: Consumer<ProfileController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.myPosts.isEmpty) {
            return _buildLoadingState();
          }

          if (controller.errorMessage != null && controller.myPosts.isEmpty) {
            return _buildErrorState(controller.errorMessage!);
          }

          return RefreshIndicator(
            onRefresh: () => controller.getMyPosts(
              postType: _getPostTypeFromLabel(controller.selectedMyPostsFilter),
              label: controller.selectedMyPostsFilter,
            ),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 10.h),
                _buildFilters(controller),
                if (_getFilteredPosts(controller).isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildPostList(controller),
                  if (controller.isPaginationLoading)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  SizedBox(height: 20.h),
                ],
              ],
            ),
          );
        },
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

  Widget _buildFilters(ProfileController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildFilterChip('All', AppLocalizations.of(context)!.allPostsTab, controller),
          _buildFilterChip('Active', AppLocalizations.of(context)!.activePostsTab, controller),
          _buildFilterChip('Inactive', AppLocalizations.of(context)!.inactivePostsTab, controller),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String displayLabel, ProfileController controller) {
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
        margin: EdgeInsets.only(right: 12.w),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.grey.withOpacity(0.5),
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 14.sp,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.grey.shade300 : Colors.black),
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
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: filteredPosts.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        return _buildPostCard(context, filteredPosts[index]);
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: const ProductCardSkeleton(),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(color: context.textColor, fontSize: 16.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => context.read<ProfileController>().getMyPosts(),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.only(top: 50.h),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 80.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context)!.noPostsFound,
              style: TextStyle(
                color: context.subTextColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              AppLocalizations.of(context)!.tryChangingFilterOrCreatePost,
              style: TextStyle(
                color: greyColor,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.createGivePost),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text(
                AppLocalizations.of(context)!.createPostLabel,
                style: TextStyle(
                    color: context.onPrimaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post) {
    final imagePath = post.itemImages.isNotEmpty ? post.itemImages.first : '';
    final isActive = post.status.toLowerCase() == 'active';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      post.itemName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: context.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (isActive) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!.deactivatePost),
                                content: const Text(
                                    'Are you sure you want to deactivate this post? Deactivating it will permanently delete your post.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(AppLocalizations.of(context)!.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(AppLocalizations.of(context)!.deactivate,
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              final success = await context
                                  .read<TradeController>()
                                  .deletePost(post.id);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Post deactivated successfully')));
                                context.read<ProfileController>().getMyPosts();
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(context
                                                .read<TradeController>()
                                                .errorMessage ??
                                            'Error deactivating post')));
                              }
                            }
                          } else {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reactivate Post'),
                                content: const Text(
                                    'Are you sure you want to reactivate this post? It will become visible to others again.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(AppLocalizations.of(context)!.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Reactivate',
                                        style: TextStyle(color: Colors.green)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              final success = await context
                                  .read<TradeController>()
                                  .reactivatePost(post.id);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Post reactivated successfully')));
                                context.read<ProfileController>().getMyPosts();
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(context
                                                .read<TradeController>()
                                                .errorMessage ??
                                            'Error reactivating post')));
                              }
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 85.w,
                          height: 26.h,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                alignment: isActive
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      isActive ? 'Active' : 'Inactive',
                                      key: ValueKey<bool>(isActive),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                alignment: isActive
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                                  child: Container(
                                    width: 14.w,
                                    height: 14.w,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                width: double.infinity,
                height: 200.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                clipBehavior: Clip.hardEdge,
                child: imagePath.isNotEmpty
                    ? AppCachedImage(
                        imageUrl: imagePath,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        radius: 8.r,
                        errorWidget:
                            Image.asset('assets/iphone.png', fit: BoxFit.cover),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child:
                            Icon(Icons.image, size: 48.sp, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey, size: 16.sp),
                      SizedBox(width: 6.w),
                      Text(
                        DateUtil.formatTimeAgo(post.createdAt),
                        style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.notifications,
                        arguments: post.id,
                      );
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'View Offers',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
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
