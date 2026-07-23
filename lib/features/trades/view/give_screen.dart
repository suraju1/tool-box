import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/widgets/filter_bottom_sheet.dart';
import 'package:tool_bocs/core/widgets/sort_bottom_sheet.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';
import 'package:tool_bocs/core/widgets/skeleton_widgets.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart'; // Import for ScrollDirection
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/core/widgets/popup_menu_arrow_shape.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/util/date_util.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/home/view/product_details_screen.dart';
import 'package:tool_bocs/features/trades/widgets/report_post_sheet.dart';
import 'package:tool_bocs/features/profile/view/user_profile_screen.dart';
import 'package:tool_bocs/features/profile/view/save_to_collection_sheet.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';

class GiveScreen extends StatefulWidget {
  const GiveScreen({super.key});

  @override
  State<GiveScreen> createState() => _GiveScreenState();
}

class _GiveScreenState extends State<GiveScreen> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locationController = context.read<LocationController>();
      final tradeController = context.read<TradeController>();
      final authController = context.read<AuthController>();

      tradeController.setCurrentUserId(authController.currentUser?.id);

      // Reset filters when navigating to this screen
      tradeController.resetFilters();

      // Sync user-selected location (loaded from Hive in LocationController)
      tradeController.setLocation(
        locationController.latitude,
        locationController.longitude,
      );

      tradeController.fetchTakePosts();
    });
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<TradeController>().loadMoreTakePosts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tradeController = context.watch<TradeController>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Builder(builder: (context) {
        // Proactively sync location from LocationController if it exists but is missing in TradeController
        final locationController = context.read<LocationController>();
        final controller = context.read<TradeController>();
        if (locationController.hasLocation && !controller.hasLocation) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.setLocation(
              locationController.latitude,
              locationController.longitude,
            );
            controller.fetchTakePosts(refresh: true);
          });
        }

        return tradeController.isTakeLoading &&
                tradeController.takePosts.isEmpty
            ? _buildShimmer(context)
            : Stack(
                children: [
                  Column(
                    children: [
                      SizedBox(height: 15.h),
                      _buildHeader(context),
                      Divider(
                        color: context.dividerColor,
                        height: 0.h,
                        thickness: 0.5,
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await context
                                .read<TradeController>()
                                .fetchTakePosts(refresh: true);
                          },
                          child: tradeController.takePosts.isEmpty &&
                                  !tradeController.isTakeLoading
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(height: 100.h),
                                    Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.search_off,
                                              size: 64.sp, color: Colors.grey),
                                          SizedBox(height: 16.h),
                                          Text(
                                            'No posts found matching your filters',
                                            style: TextStyle(
                                              color: context.subTextColor,
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  controller: _scrollController,
                                  padding:
                                      EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 100.h),
                                  itemCount: tradeController.takePosts.length +
                                      1 +
                                      (tradeController.isTakeLoadMoreRunning
                                          ? 1
                                          : 0),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return _buildResultHeader(context,
                                          tradeController.takePosts.length);
                                    }

                                    if (index ==
                                        tradeController.takePosts.length + 1) {
                                      return Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(
                                              color: context.primaryColor),
                                        ),
                                      );
                                    }

                                    final post =
                                        tradeController.takePosts[index - 1];
                                    // Build exchange info text
                                    final rType = post.returnType.toLowerCase().trim();
                                    final rMin = post.priceMin;
                                    final rMax = post.priceMax;
                                    final rName = post.returnItemName ?? '';
                                    final rCat = post.returnItemCategory ?? '';
                                    String exchangeText;
                                    if (rType == 'exchange' || rType == 'item') {
                                      exchangeText = 'In exchange for: ';
                                      if (rName.isNotEmpty) {
                                        exchangeText += rName;
                                        if (rCat.isNotEmpty) exchangeText += ' ($rCat)';
                                      } else if (rCat.isNotEmpty) {
                                        exchangeText += rCat;
                                      } else {
                                        exchangeText += 'Item';
                                      }
                                    } else if (rType == 'free') {
                                      exchangeText = 'Free';
                                    } else {
                                      if (rMin != null && rMax != null && rMax != rMin) {
                                        exchangeText = 'In exchange for: ₹${rMin.toStringAsFixed(0)} - ₹${rMax.toStringAsFixed(0)} (Money)';
                                      } else {
                                        exchangeText = 'In exchange for: ₹${rMin?.toStringAsFixed(0) ?? 0} (Money)';
                                      }
                                    }
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 6.h),
                                      child: _buildProductCard(
                                        context,
                                        id: post.id,
                                        userId: post.userId,
                                        title: post.itemName,
                                        owner: post.userName.isNotEmpty
                                            ? post.userName
                                            : 'User ${post.userId}',
                                        category: post.itemCategory,
                                        distance: post.distanceKm != null
                                            ? '${post.distanceKm!.toStringAsFixed(1)} km away'
                                            : '- km away',
                                        rating: post.userRating?.toString() ??
                                            '4.8',
                                        actionLabel:
                                            post.postType.toLowerCase() ==
                                                    'give'
                                                ? 'Take'
                                                : 'Give',
                                        description: exchangeText,
                                        imagePath: post.itemImages.isNotEmpty
                                            ? post.itemImages.first
                                            : null,
                                        postType: post.postType,
                                        createdAt: post.createdAt,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
      }),
    );
  }

  Widget _buildResultHeader(BuildContext context, int count) {
    return Container(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.nearbyItems,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.showingResults(count),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: context.subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8.w, MediaQuery.of(context).padding.top + 6.h, 8.w, 6.h),
      color: context.scaffoldBg,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45.h,
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFFF5F7F9),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: context.isDarkMode
                            ? Colors.white24
                            : Colors.grey.shade300,
                        width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      context
                          .read<TradeController>()
                          .setSearchQuery(value, type: 'take');
                    },
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      hintText:
                          AppLocalizations.of(context)!.searchWhatYouWantToGive,
                      hintStyle: TextStyle(
                          color: context.subTextColor, fontSize: 14.sp),
                      prefixIcon: Icon(Icons.search,
                          color: context.subTextColor, size: 20.sp),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<void>(
                offset: const Offset(-200, 50),
                shape: PopupMenuArrowShape(borderRadius: 12.r),
                color: Theme.of(context).cardColor,
                surfaceTintColor: Colors.transparent,
                elevation: 4,
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
                            AppLocalizations.of(context)!.seeWhatPeopleWantAround,
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: FontFamily.openSans,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            AppLocalizations.of(context)!.seeExistingPostsByTakers,
                            style: TextStyle(
                              color: context.subTextColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: FontFamily.openSans,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            AppLocalizations.of(context)!.respondToPostsMentionWhat1,
                            style: TextStyle(
                              color: context.subTextColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: FontFamily.openSans,
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
                            fontFamily: FontFamily.openSans,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  margin: EdgeInsets.only(left: 8.w),
                  height: 45.h,
                  width: 45.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFFF5F7F9),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: context.isDarkMode
                          ? Colors.white24
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: context.primaryColor,
                    size: 22.sp,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.createGivePost,
                    arguments: "Create Give Post",
                  );
                },
                child: _buildAddPostButton(context),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              InkWell(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      const FilterBottomSheet(initialPostType: 'take'),
                ),
                child: _buildFilterButton(context),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      const SortBottomSheet(initialPostType: 'take'),
                ),
                child: _buildSortButton(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPostButton(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      height: 45.h,
      width: 45.h,
      margin: EdgeInsets.only(left: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.add,
        color: context.onPrimaryColor,
        size: 24.sp,
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return Container(
      height: 42.h,
      margin: EdgeInsets.only(left: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(
            color: context.isDarkMode ? Colors.white24 : Colors.grey.shade300,
            width: 1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_outlined,
            color: context.textColor,
            size: 18.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            AppLocalizations.of(context)!.filterLabel,
            style: TextStyle(
              color: context.textColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              fontFamily: FontFamily.openSans,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(BuildContext context) {
    return Consumer<TradeController>(
      builder: (context, controller, _) {
        final hasCustomSort = controller.selectedSort != 'Nearest First';
        return Container(
          height: 42.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: hasCustomSort ? context.primaryColor : context.surfaceColor,
            border: Border.all(
                color: hasCustomSort
                    ? context.primaryColor
                    : context.isDarkMode
                        ? Colors.white24
                        : Colors.grey.shade300,
                width: 1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort,
                color: hasCustomSort ? context.onPrimaryColor : context.textColor,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                AppLocalizations.of(context)!.sortByLabel,
                style: TextStyle(
                  color: hasCustomSort ? context.onPrimaryColor : context.textColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: FontFamily.openSans,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context, {
    required int id,
    required int userId,
    required String title,
    required String owner,
    required String category,
    required String distance,
    required String rating,
    required String actionLabel,
    String? description,
    String? imagePath,
    String? postType,
    required String createdAt,
  }) {
    final authController = context.read<AuthController>();
    final isOwner = authController.currentUser?.id == userId;
    final finalActionLabel = isOwner ? AppLocalizations.of(context)!.offersLabel : actionLabel;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.productDetails, arguments: id);
      },
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.dividerColor),
          boxShadow: [
            BoxShadow(
              color: greyColorWithOpacity0_4,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 136.w,
              height: 154.w,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imagePath != null
                      ? AppCachedImage(
                          imageUrl: imagePath,
                          width: 136.w,
                          height: 154.w,
                          fit: BoxFit.cover,
                          radius: 12.r,
                          errorWidget: Image.asset('assets/iphone.png',
                              fit: BoxFit.cover),
                        )
                      : Image.asset('assets/iphone.png', fit: BoxFit.cover),
                  Positioned(
                    top: 8.h,
                    left: 4.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: category.toLowerCase().contains('goods')
                            ? Colors.blue.shade700
                            : category.toLowerCase().contains('services')
                                ? Colors.green.shade700
                                : category.toLowerCase().contains('money')
                                    ? Colors.orange.shade700
                                    : context.isDarkMode
                                        ? Colors.white
                                        : Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: (category.toLowerCase().contains('goods') ||
                                  category.toLowerCase().contains('services') ||
                                  category.toLowerCase().contains('money'))
                              ? Colors.white
                              : context.isDarkMode
                                  ? Colors.black
                                  : Colors.white,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: FontFamily.openSans,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          postType?.toLowerCase() == 'give' ? AppLocalizations.of(context)!.userIsGiving(owner.split(' ').first) : AppLocalizations.of(context)!.userIsTaking(owner.split(' ').first),
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: context.subTextColor,
                            fontWeight: FontWeight.w600,
                            fontFamily: FontFamily.openSans,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12.sp, color: greyColor),
                          SizedBox(width: 2.w),
                          Text(
                            distance,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: context.subTextColor,
                              fontWeight: FontWeight.w400,
                              fontFamily: FontFamily.openSans,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          _buildPostMenu(
                              context, id, userId, owner, title, isOwner),
                        ],
                      ),
                    ],
                  ),
                  //  SizedBox(height: 2.h),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: FontFamily.openSans,
                      color: context.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // SizedBox(height: 1.h),
                  // Row(
                  //   children: [
                  //     Icon(Icons.label_outline,
                  //         size: 13.sp, color: context.subTextColor),
                  //     SizedBox(width: 4.w),
                  //     Text(
                  //       category,
                  //       style: TextStyle(
                  //         fontSize: 10.sp,
                  //         color: context.subTextColor,
                  //         fontWeight: FontWeight.w600,
                  //         fontFamily: FontFamily.openSans,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  if (description != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: context.subTextColor,
                        fontWeight: FontWeight.w400,
                        fontFamily: FontFamily.openSans,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Icon(Icons.person,
                          color: context.primaryColor, size: 16.sp),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                owner.split(' ').first,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: context.textColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: FontFamily.openSans,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "• ${DateUtil.formatTimeAgo(createdAt)}",
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  // Row(
                  //   children: [
                  //     Text(
                  //       rating,
                  //       style: TextStyle(
                  //         fontSize: 12.sp,
                  //         fontWeight: FontWeight.w600,
                  //         fontFamily: FontFamily.openSans,
                  //         color: context.textColor,
                  //       ),
                  //     ),
                  //     SizedBox(width: 4.w),
                  //     Row(
                  //       children: List.generate(5, (index) {
                  //         return Icon(Icons.star,
                  //             color: Colors.amber, size: 16.sp);
                  //       }),
                  //     ),
                  //   ],
                  // ),
                  SizedBox(height: 3.h),
                  InkWell(
                    onTap: () {
                      if (isOwner) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.notifications,
                          arguments: id,
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.productDetails,
                          arguments: id,
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 34.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        finalActionLabel,
                        style: TextStyle(
                          color: context.onPrimaryColor,
                          fontWeight: FontWeight.w700,
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

  Widget _buildShimmer(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(8.w, 80.h, 8.w, 4.h),
          color: context.scaffoldBg,
          child: Row(
            children: [
              Expanded(child: ShimmerBox(height: 45.h, width: double.infinity)),
              SizedBox(width: 12.w),
              ShimmerBox(height: 45.h, width: 45.h, radius: 8.r),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            itemCount: 4,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: const HorizontalProductCardSkeleton(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostMenu(BuildContext context, int postId, int userId,
      String userName, String itemName, bool isOwner) {
    return PopupMenuButton<String>(
      color: context.surfaceColor,
      surfaceTintColor: Colors.transparent,
      icon: Icon(Icons.more_vert, color: context.textColor, size: 20.sp),
      padding: EdgeInsets.zero,
      onSelected: (value) async {
        final profileController = context.read<ProfileController>();
        switch (value) {
          case 'profile':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UserProfileScreen(userId: userId.toString()),
              ),
            );
            break;
          case 'save':
            SaveToCollectionBottomSheet.show(context, userId);
            break;
          case 'share':
            Share.share(
                'Check out $userName\'s trade: $itemName\nDownload the app to see more!');
            break;
          case 'hide':
            context.read<TradeController>().hidePost(postId);
            if (mounted) {
              ToastService.showSuccessToast(context, 'Post hidden');
              context
                  .read<TradeController>()
                  .fetchTakePosts(); // Refresh list to remove hidden post
            }
            break;
          case 'report':
            ReportPostSheet.show(context, postId);
            break;
          case 'block':
            final success = await profileController.blockUser(userId);
            if (success.success && mounted) {
              ToastService.showSuccessToast(
                  context, 'User blocked successfully');
              context.read<TradeController>().fetchTakePosts(); // Refresh feed
            } else if (mounted) {
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
              child: Text(AppLocalizations.of(context)!.reportPost, style: TextStyle(color: Colors.red)),
            ),
        ];
      },
    );
  }
}
