import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';

import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/core/widgets/filter_bottom_sheet.dart';
import 'package:tool_bocs/core/widgets/sort_bottom_sheet.dart';
import 'package:tool_bocs/core/widgets/popup_menu_arrow_shape.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';
import 'package:tool_bocs/core/widgets/skeleton_widgets.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/util/date_util.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/home/view/product_details_screen.dart';
import 'package:tool_bocs/features/trades/widgets/report_post_sheet.dart';
import 'package:tool_bocs/features/profile/view/user_profile_screen.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/view/save_to_collection_sheet.dart';

class TakeScreen extends StatefulWidget {
  const TakeScreen({super.key});

  @override
  State<TakeScreen> createState() => _TakeScreenState();
}

class _TakeScreenState extends State<TakeScreen> {
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
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

      tradeController.fetchGivePosts();
    });
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<TradeController>().loadMoreGivePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Consumer<TradeController>(
        builder: (context, controller, child) {
          // Proactively sync location from LocationController if it exists but is missing in TradeController
          final locationController = context.read<LocationController>();
          if (locationController.hasLocation && !controller.hasLocation) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.setLocation(
                locationController.latitude,
                locationController.longitude,
              );
              controller.fetchGivePosts(refresh: true);
            });
          }

          if (controller.isGiveLoading && controller.givePosts.isEmpty) {
            return _buildShimmer(context);
          }

          if (controller.errorMessage != null && controller.givePosts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                await controller.fetchGivePosts(refresh: true);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 200.h),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(controller.errorMessage!),
                        ElevatedButton(
                          onPressed: () => controller.fetchGivePosts(),
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
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
                    await controller.fetchGivePosts(refresh: true);
                  },
                  child: controller.givePosts.isEmpty &&
                          !controller.isGiveLoading
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
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
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 100.h),
                          itemCount: controller.givePosts.length +
                              (controller.isGiveLoadMoreRunning ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 6.h),
                          itemBuilder: (context, index) {
                            if (index == controller.givePosts.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (index == 0) {
                              return Column(
                                children: [
                                  _buildResultHeader(
                                    context,
                                    controller.givePosts.length,
                                  ),
                                  _buildProductCard(
                                    context,
                                    controller.givePosts[index],
                                  ),
                                ],
                              );
                            }

                            return _buildProductCard(
                              context,
                              controller.givePosts[index],
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
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
                          .setSearchQuery(value, type: 'give');
                    },
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      hintText:
                          AppLocalizations.of(context)!.searchWhatYouWantToTake,
                      hintStyle: TextStyle(
                        color: context.subTextColor,
                        fontSize: 14.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: context.subTextColor,
                        size: 20.sp,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<void>(
                offset: const Offset(-200, 50),
                shape: PopupMenuArrowShape(borderRadius: 12.r),
                color: Colors.white,
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
                            AppLocalizations.of(context)!.seeWhatPeopleAreGiving,
                            style: TextStyle(
                              color: const Color(0xFF111311),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: FontFamily.openSans,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            AppLocalizations.of(context)!.seeExistingPostsByGivers,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: FontFamily.openSans,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            AppLocalizations.of(context)!.respondToPostsMentionWhat2,
                            style: TextStyle(
                              color: Colors.grey.shade700,
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
                            size: 18.sp, color: context.primaryColor),
                        SizedBox(width: 8.w),
                        Text(
                          AppLocalizations.of(context)!.helpSupport,
                          style: TextStyle(
                            color: context.primaryColor,
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
                    arguments: "Create Take Post",
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
                      const FilterBottomSheet(initialPostType: 'give'),
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
                      const SortBottomSheet(initialPostType: 'give'),
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

  Widget _buildProductCard(BuildContext context, PostModel post) {
    final imagePath = post.itemImages.isNotEmpty ? post.itemImages.first : '';
    final authController = context.read<AuthController>();
    final isOwner = authController.currentUser?.id == post.userId;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.productDetails,
          arguments: post.id,
        );
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
                  imagePath.isNotEmpty
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
                                    : context.isDarkMode
                                        ? Colors.white
                                        : Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4.r),
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
                          post.postType.toLowerCase() == 'give' ? AppLocalizations.of(context)!.userIsGiving((post.userName ?? 'User').split(' ').first) : AppLocalizations.of(context)!.userIsTaking((post.userName ?? 'User').split(' ').first),
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
                          Icon(
                            Icons.location_on_outlined,
                            size: 12.sp,
                            color: greyColor,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            post.distanceKm != null
                                ? '${post.distanceKm!.toStringAsFixed(1)} km away'
                                : '- km away',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: context.subTextColor,
                              fontWeight: FontWeight.w400,
                              fontFamily: FontFamily.openSans,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          _buildPostMenu(context, post.id, post.userId,
                              post.userName, post.itemName, isOwner),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    post.itemName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: FontFamily.openSans,
                      color: context.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Builder(builder: (context) {
                    final type = post.returnType.toLowerCase().trim();
                    final min = post.priceMin;
                    final max = post.priceMax;
                    final name = post.returnItemName ?? '';
                    final category = post.returnItemCategory ?? '';
                    if (type == 'exchange' || type == 'item') {
                      String text = AppLocalizations.of(context)!.inExchangeFor;
                      if (name.isNotEmpty) {
                        text += name;
                        if (category.isNotEmpty) text += ' ($category)';
                      } else if (category.isNotEmpty) {
                        text += category;
                      } else {
                        text += AppLocalizations.of(context)!.itemLabel;
                      }
                      return Text(
                        text,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontFamily: FontFamily.openSans,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    } else if (type == 'free') {
                      return Text(
                        AppLocalizations.of(context)!.freeLabel,
                        style: TextStyle(
                          color: context.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                          fontFamily: FontFamily.openSans,
                        ),
                      );
                    } else {
                      String text =
                          '${AppLocalizations.of(context)!.inExchangeFor}₹${min?.toStringAsFixed(0) ?? 0} ${AppLocalizations.of(context)!.moneyLabel}';
                      if (min != null && max != null && max != min) {
                        text =
                            '${AppLocalizations.of(context)!.inExchangeFor}₹${min.toStringAsFixed(0)} - ₹${max.toStringAsFixed(0)} ${AppLocalizations.of(context)!.moneyLabel}';
                      }
                      return Text(
                        text,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontFamily: FontFamily.openSans,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                  }),
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
                                post.userName.split(' ').first,
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
                              "• ${DateUtil.formatTimeAgo(post.createdAt)}",
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
                  //dont show rating
                  // SizedBox(height: 2.h),
                  // Row(
                  //   children: [
                  //     Text(
                  //       post.userRating?.toString() ?? '4.8',
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
                  //         return Icon(
                  //           Icons.star,
                  //           color: Colors.amber,
                  //           size: 16.sp,
                  //         );
                  //       }),
                  //     ),
                  //   ],
                  // ),
                  SizedBox(height: 3.h),
                  (() {
                    final actionLabel = isOwner
                        ? AppLocalizations.of(context)!.offersLabel
                        : (post.postType.toLowerCase() == 'give' ||
                                post.postType.toLowerCase() == 'giving'
                            ? AppLocalizations.of(context)!.takeLabel
                            : AppLocalizations.of(context)!.giveLabel);

                    return InkWell(
                      onTap: () {
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
                          actionLabel,
                          style: TextStyle(
                            color: context.onPrimaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    );
                  })(),
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
              Expanded(
                child: ShimmerBox(height: 45.h, width: double.infinity),
              ),
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
                  .fetchGivePosts(); // Refresh list to remove hidden post
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
              context.read<TradeController>().fetchGivePosts(); // Refresh feed
            } else if (mounted) {
              ToastService.showErrorToast(
                  context, success.message ?? 'Error blocking user');
            }
            break;
          case 'delete':
            final success =
                await context.read<TradeController>().deletePost(postId);
            if (success && mounted) {
              ToastService.showSuccessToast(
                  context, 'Post deleted successfully');
            } else if (mounted) {
              ToastService.showErrorToast(
                  context,
                  context.read<TradeController>().errorMessage ??
                      'Error deleting post');
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
          if (isOwner)
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(AppLocalizations.of(context)!.deletePost, style: TextStyle(color: Colors.red)),
            ),
        ];
      },
    );
  }
}
