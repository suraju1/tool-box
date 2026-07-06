import 'dart:async';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/api/api_constants.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/core/widgets/share_button.dart';
import 'package:tool_bocs/core/services/share_service.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/util/date_util.dart';
import 'package:tool_bocs/features/trades/widgets/report_post_sheet.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int postId;
  const ProductDetailsScreen({super.key, required this.postId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradeController>().fetchPostDetails(widget.postId);
    });
  }

  void _startAutoPlay(int imageCount) {
    _autoPlayTimer?.cancel(); // Cancel existing timer if any
    if (imageCount <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextIndex = (_currentImageIndex + 1) % imageCount;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.textColor,
            size: 20.sp,
          ),
        ),
        centerTitle: true,
        title: Consumer<TradeController>(
          builder: (context, controller, child) {
            return Text(
              controller.selectedPost?.itemName ?? AppLocalizations.of(context)!.productDetails,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                fontFamily: FontFamily.openSans,
                color: context.textColor,
              ),
            );
          },
        ),
        actions: [
          // Share button — visible once post data loads
          Consumer<TradeController>(
            builder: (context, controller, child) {
              final post = controller.selectedPost;
              if (post == null) return const SizedBox.shrink();
              return Row(
                children: [
                  Consumer<AuthController>(
                    builder: (context, authController, _) {
                      final isOwner =
                          authController.currentUser?.id == post.userId;
                      return PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            color: context.textColor, size: 20.sp),
                        onSelected: (value) async {
                          if (value == 'share') {
                            try {
                              await ShareService().sharePost(
                                context,
                                post: post,
                                includeImage: true,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ToastService.showErrorToast(context, 'Unable to share. Try again.');
                              }
                            }
                          } else if (value == 'report') {
                            ReportPostSheet.show(context, post.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share_outlined, color: context.textColor, size: 20.sp),
                                SizedBox(width: 10.w),
                                Text(AppLocalizations.of(context)!.sharePost, style: TextStyle(color: context.textColor)),
                              ],
                            ),
                          ),
                          if (!isOwner)
                            PopupMenuItem<String>(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(Icons.report_problem_outlined, color: Colors.red, size: 20.sp),
                                  SizedBox(width: 10.w),
                                  Text(AppLocalizations.of(context)!.reportPost, style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: Consumer2<TradeController, LocationController>(
        builder: (context, controller, locationController, child) {
          if (controller.errorMessage != null) {
            return Center(child: Text(controller.errorMessage!));
          }

          if (widget.postId == 0) {
            return Center(
              child: Text(AppLocalizations.of(context)!.errorNoPostIdProvided),
            );
          }

          if (controller.isLoading ||
              controller.selectedPost?.id != widget.postId) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = controller.selectedPost;
          if (post == null) {
            return Center(
                child: Text(AppLocalizations.of(context)!.postNotFound));
          }

          // Start autoplay if not started and multiple images
          if (_autoPlayTimer == null && post.itemImages.length > 1) {
            _startAutoPlay(post.itemImages.length);
          }

          final List<String> images =
              post.itemImages.isNotEmpty ? post.itemImages : [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                _buildOwnerProfile(post),
                SizedBox(height: 10.h),
                if (images.isNotEmpty)
                  _buildImageCarousel(images, post.itemCategory, post.tradeType)
                else
                  Stack(
                    children: [
                      Container(
                        height: 320.h,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50.sp,
                          color: Colors.grey,
                        ),
                      ),
                      Positioned(
                        top: 10.h,
                        left: 10.w,
                        child: _buildCategoryTag(post.itemCategory),
                      ),
                      Positioned(
                        top: 10.h,
                        right: 10.w,
                        child: _buildTradeTypeTag(post.tradeType),
                      ),
                    ],
                  ),
                Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.itemName,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: FontFamily.openSans,
                          color: context.textColor,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        AppLocalizations.of(context)!.description,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: FontFamily.openSans,
                          color: context.textColor,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.itemNote.isNotEmpty
                                ? post.itemNote
                                : AppLocalizations.of(context)!.noDescriptionProvided,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: context.subTextColor,
                              height: 1.6,
                              fontFamily: FontFamily.openSans,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 15.h),
                          _buildLocationDisplay(post, locationController),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: context.dividerColor),
                          boxShadow: context.isDarkMode
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              AppLocalizations.of(context)!.itemCondition,
                              post.itemCondition,
                              Icons.info_outline,
                            ),
                            SizedBox(height: 8.h),
                            _buildDetailRow(
                              AppLocalizations.of(context)!.tradeType,
                              post.tradeType,
                              Icons.swap_horiz_rounded,
                            ),
                            SizedBox(height: 8.h),
                            _buildDetailRow(
                              AppLocalizations.of(context)!.itemSource,
                              post.itemSource,
                              Icons.source_outlined,
                            ),
                          ],
                        ),
                      ),
                      if (_isPriceReturn(post) ||
                          _hasReturnItemDetails(post)) ...[
                        SizedBox(height: 15.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: context.dividerColor),
                            boxShadow: context.isDarkMode
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isPriceReturn(post)) ...[
                                _buildReturnHeader(post),
                                SizedBox(height: 8.h),
                                _buildDetailRow(
                                  AppLocalizations.of(context)!.priceRange,
                                  '₹${post.priceMin} - ₹${post.priceMax}',
                                  Icons.monetization_on_outlined,
                                  true,
                                ),
                              ] else if (_hasReturnItemDetails(post)) ...[
                                _buildReturnHeader(post),
                                SizedBox(height: 8.h),
                                if (post.returnItemImages.isNotEmpty) ...[
                                  SizedBox(
                                    height: 120.h,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: post.returnItemImages.length,
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 4.w),
                                      separatorBuilder: (_, __) =>
                                          SizedBox(width: 12.w),
                                      itemBuilder: (context, index) {
                                        final imageUrl =
                                            post.returnItemImages[index];
                                        return GestureDetector(
                                          onTap: () => _openReturnImagePreview(
                                            post.returnItemImages,
                                            index,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: AppCachedImage(
                                              imageUrl: imageUrl,
                                              height: 120.h,
                                              width: 120.h,
                                              fit: BoxFit.cover,
                                              radius: 12.r,
                                              errorWidget: Container(
                                                height: 120.h,
                                                width: 120.h,
                                                decoration: BoxDecoration(
                                                  color: context.isDarkMode
                                                      ? Colors.white10
                                                      : Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.r),
                                                ),
                                                child: Icon(
                                                  Icons
                                                      .image_not_supported_outlined,
                                                  color: Colors.grey,
                                                  size: 30.sp,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 15.h),
                                ],
                                if (post.returnItemName != null)
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.itemName,
                                    post.returnItemName!,
                                  ),
                                if (post.returnItemCondition != null) ...[
                                  SizedBox(height: 8.h),
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.condition,
                                    post.returnItemCondition!,
                                  ),
                                ],
                                if (post.returnItemSource != null) ...[
                                  SizedBox(height: 8.h),
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.itemSource,
                                    post.returnItemSource!,
                                  ),
                                ],
                                if (post.returnItemDescription != null &&
                                    post.returnItemDescription!.isNotEmpty) ...[
                                  SizedBox(height: 8.h),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.description,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: context.subTextColor,
                                          fontFamily: FontFamily.openSans,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        post.returnItemDescription!,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          color: context.textColor,
                                          fontFamily: FontFamily.openSans,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer2<TradeController, AuthController>(
        builder: (context, tradeController, authController, child) {
          final post = tradeController.selectedPost;
          if (post == null) return const SizedBox.shrink();

          // Hide the bottom bar entirely if the post is completed
          if (post.status.toLowerCase() == 'completed') {
            return const SizedBox.shrink();
          }

          // Hide the response button for owners, but show "View Offers" if they have responses
          if (authController.currentUser?.id == post.userId) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(top: BorderSide(color: context.dividerColor)),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.notifications,
                    arguments: post.id,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context)!.viewOffers,
                  style: TextStyle(
                    color: context.onPrimaryColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: FontFamily.openSans,
                  ),
                ),
              ),
            );
          }

          // removed has_responded check so the button is always visible for active posts

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(top: BorderSide(color: context.dividerColor)),
            ),
            child: ElevatedButton(
              onPressed: () {
                // not required for now directly offer screen(becaue we consider first step as create post)
                // Navigator.pushNamed(context, AppRoutes.tradeStep1);
                Navigator.pushNamed(context, AppRoutes.tradeOffer); //tradeStep1
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    (post.postType.toLowerCase() == 'take' ||
                            post.postType.toLowerCase() == 'taking')
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: context.onPrimaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    (post.postType.toLowerCase() == 'take' ||
                            post.postType.toLowerCase() == 'taking')
                        ? AppLocalizations.of(context)!.giveIt
                        : AppLocalizations.of(context)!.takeIt,
                    style: TextStyle(
                      color: context.onPrimaryColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images, String category, String tradeType) {
    return Column(
      children: [
        Container(
          height: 320.h,
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imagePath = images[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: AppCachedImage(
                      imageUrl: imagePath,
                      fit: BoxFit.contain,
                      width: 1.sw - 40.w,
                      height: 320.h,
                      radius: 20.r,
                      errorWidget: Image.asset(
                        'assets/iphone.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  );
                },
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 12.h,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentImageIndex == index ? 24.w : 8.w,
                        height: 6.h,
                        margin: EdgeInsets.symmetric(horizontal: 3.w),
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      );
                    }),
                  ),
                ),
              Positioned(
                top: 10.h,
                left: 10.w,
                child: _buildCategoryTag(category),
              ),
              Positioned(
                top: 10.h,
                right: 10.w,
                child: _buildTradeTypeTag(tradeType),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTag(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: label.toLowerCase().contains('goods')
            ? Colors.blue.shade700
            : label.toLowerCase().contains('services')
                ? Colors.green.shade700
                : label.toLowerCase().contains('money')
                    ? Colors.orange.shade700
                    : context.isDarkMode
                        ? Colors.white
                        : Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: (label.toLowerCase().contains('goods') ||
                  label.toLowerCase().contains('services') ||
                  label.toLowerCase().contains('money'))
              ? Colors.white
              : context.isDarkMode
                  ? Colors.black
                  : Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          fontFamily: FontFamily.openSans,
        ),
      ),
    );
  }

  Widget _buildTradeTypeTag(String tradeType) {
    if (tradeType.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        tradeType,
        style: TextStyle(
          color: context.isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          fontFamily: FontFamily.openSans,
        ),
      ),
    );
  }

  Widget _buildLocationDisplay(
      PostModel post, LocationController locationController) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded,
              color: context.primaryColor, size: 18.sp),
          SizedBox(width: 8.w),
          //keep commented for now

          /*Expanded(
            child: Text(
              post.distanceKm != null
                  ? '${post.distanceKm!.toStringAsFixed(1)} km away from ${post.pickupArea}'
                  : post.pickupArea,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: context.textColor,
                fontFamily: FontFamily.openSans,
              ),
            ),
          ), */

          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (post.distanceKm != null) ...[
                    TextSpan(
                      text: '${post.distanceKm!.toStringAsFixed(1)} km ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: context.textColor,
                      ),
                    ),
                    TextSpan(
                      text:
                          'away from ${locationController.address ?? 'Current Location'}',
                    ),
                  ] else
                    TextSpan(
                      text: post.pickupArea,
                    ),
                ],
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: context.textColor,
                  fontFamily: FontFamily.openSans,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openReturnImagePreview(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReturnImagePreviewScreen(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  bool _isPriceReturn(PostModel post) {
    final type = post.returnType.trim().toLowerCase();
    return type == 'price' ||
        type == 'money' ||
        type == 'cash' ||
        type == 'amount';
  }

  bool _hasReturnItemDetails(PostModel post) {
    return post.returnItemImages.isNotEmpty ||
        (post.returnItemName?.trim().isNotEmpty ?? false) ||
        (post.returnItemCategory?.trim().isNotEmpty ?? false) ||
        (post.returnItemCondition?.trim().isNotEmpty ?? false) ||
        (post.returnItemSource?.trim().isNotEmpty ?? false) ||
        (post.returnItemDescription?.trim().isNotEmpty ?? false);
  }

  String _titleCase(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildReturnHeader(PostModel post) {
    final returnType = _titleCase(post.returnType);
    final category = _titleCase(post.returnItemCategory ?? '');

    return Row(
      children: [
        Text(
          returnType.isEmpty ? AppLocalizations.of(context)!.returnInReturnFallback : AppLocalizations.of(context)!.returnInReturn(returnType),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            fontFamily: FontFamily.openSans,
            color: context.textColor,
          ),
        ),
        if (category.isNotEmpty) ...[
          SizedBox(width: 12.w),
          const Spacer(),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 140.w),
            child: Text(
              category,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                fontFamily: FontFamily.openSans,
                color: context.textColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value,
      [IconData? icon, bool isPrice = false]) {
    return Row(
      crossAxisAlignment:
          isPrice ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: context.primaryColor, size: 18.sp),
          ),
          SizedBox(width: 12.w),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.subTextColor.withOpacity(0.8),
            fontFamily: FontFamily.openSans,
          ),
        ),
        const Spacer(),
        Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: context.textColor,
            fontFamily: FontFamily.openSans,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }

  Widget _buildOwnerProfile(post) {
    return InkWell(
      onTap: () {
        ProfileController.navigateToUserProfile(context, post.userId);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: context.dividerColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: context.primaryColor.withOpacity(0.2), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: post.userImage != null && post.userImage!.isNotEmpty
                    ? AppCachedImage(
                        imageUrl: post.userImage!,
                        userName: post.userName,
                        width: 56.r,
                        height: 56.r,
                        fit: BoxFit.cover,
                        radius: 28.r,
                      )
                    : _buildLetterPlaceholder(post.userName, 56.r),
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          post.userName.isNotEmpty
                              ? post.userName
                              : 'User id-${post.userId}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: FontFamily.openSans,
                            color: context.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: (post.postType.toLowerCase() == 'take' ||
                                  post.postType.toLowerCase() == 'taking')
                              ? const Color(0xFFFFE8E8)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          (post.postType.toLowerCase() == 'take' ||
                                  post.postType.toLowerCase() == 'taking')
                              ? 'Taking'
                              : 'Giving',
                          style: TextStyle(
                            color: (post.postType.toLowerCase() == 'take' ||
                                    post.postType.toLowerCase() == 'taking')
                                ? const Color(0xFFD32F2F)
                                : const Color(0xFF2E7D32),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            textBaseline: TextBaseline.alphabetic,
                            fontFamily: FontFamily.openSans,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      // Container(
                      //   padding: EdgeInsets.symmetric(
                      //       horizontal: 6.w, vertical: 2.h),
                      //   decoration: BoxDecoration(
                      //     color: Colors.amber.withOpacity(0.1),
                      //     borderRadius: BorderRadius.circular(4.r),
                      //   ),
                      //   child: Row(
                      //     children: [
                      //       Icon(Icons.star_rounded,
                      //           color: Colors.amber, size: 14.sp),
                      //       SizedBox(width: 2.w),
                      //       Text(
                      //         post.userRating?.toString() ?? '4.8',
                      //         style: TextStyle(
                      //           fontSize: 12.sp,
                      //           fontWeight: FontWeight.w700,
                      //           color: context.textColor,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // SizedBox(width: 8.w),
                      Builder(
                        builder: (context) {
                          String distanceText = '- km away';
                          if (post.distanceKm != null) {
                            if (post.distanceKm! < 1.0) {
                              distanceText = '${(post.distanceKm! * 1000).toInt()} mtrs away';
                            } else {
                              distanceText = AppLocalizations.of(context)!.kmAway(post.distanceKm!.toStringAsFixed(1));
                            }
                          }
                          return Text(
                            distanceText,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: context.subTextColor,
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      Text(
                        DateUtil.formatTimeAgo(post.createdAt),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: context.subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterPlaceholder(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.trim().isNotEmpty
            ? name.trim().substring(0, 1).toUpperCase()
            : '?',
        style: TextStyle(
          color: context.primaryColor,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ReturnImagePreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ReturnImagePreviewScreen({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ReturnImagePreviewScreen> createState() =>
      _ReturnImagePreviewScreenState();
}

class _ReturnImagePreviewScreenState extends State<_ReturnImagePreviewScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialIndex.clamp(0, widget.images.length - 1).toInt();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: SizedBox.expand(
                      child: AppCachedImage(
                        imageUrl: widget.images[index],
                        fit: BoxFit.contain,
                        radius: 0,
                        errorWidget: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white54,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8.h,
              left: 8.w,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                top: 18.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${widget.images.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
