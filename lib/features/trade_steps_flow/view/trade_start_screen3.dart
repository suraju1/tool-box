import 'package:flutter/gestures.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/trades/model/trade_response_model.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/chat/view/chat_screen.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/core/services/toast_service.dart';

class TradeStartScreen extends StatefulWidget {
  const TradeStartScreen({super.key});

  @override
  State<TradeStartScreen> createState() => _TradeStartScreenState();
}

class _TradeStartScreenState extends State<TradeStartScreen> {
  String _selectedMeetingPreference = 'Come to me';
  bool _isAcceptSelected = true;
  bool _showMoreDetails = false;

  @override
  Widget build(BuildContext context) {
    final tradeController = context.watch<TradeController>();
    final authController = context.watch<AuthController>();
    final response = tradeController.selectedResponse;
    final post = tradeController.selectedPost;
    final isOwner = authController.currentUser?.id == response?.posterUserId;

    if (response == null) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Center(child: Text(AppLocalizations.of(context)!.noResponseSelected)),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 100.h),
            child: Column(
              children: [
                _buildStepper(),
                Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTradeBegunCard(response, post, isOwner),
                      SizedBox(height: 24.h),
                      if (response.status == 'pending' && isOwner) ...[
                        Text(
                          'Meeting Preferences',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: FontFamily.openSans,
                            color: context.textColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Accept the offer and choose a handover location',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: context.subTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        _buildAcceptRejectSection(response),
                      ] else if (response.status == 'pending' && !isOwner) ...[
                        SizedBox(height: 30.h),
                        Center(
                          child: Text(
                            'Waiting for ${response.posterName ?? 'owner'} to respond...',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: context.subTextColor,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (response.status == 'rejected' &&
                          response.rejectedReason != null) ...[
                        SizedBox(height: 12.h),
                        Text(
                          'Reason for rejection:',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          response.rejectedReason!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: context.subTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if ((response.status == 'pending' && isOwner) ||
              (response.status == 'accepted' ||
                  response.status == 'meeting_set' ||
                  response.status == 'paid'))
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomAction(tradeController),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.scaffoldBg,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: context.textColor, size: 20.sp),
      ),
      centerTitle: true,
      title: Text(
        'Trade Request',
        style: TextStyle(
          color: context.textColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      color: context.scaffoldBg,
      padding: EdgeInsets.only(bottom: 10.h, left: 10.w, right: 10.w),
      child: Row(
        children: [
          _buildStepSegment(isActive: true),
          _buildStepSegment(isActive: true),
          _buildStepSegment(isActive: true),
          _buildStepSegment(isActive: false),
        ],
      ),
    );
  }

  Widget _buildStepSegment({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 5.h,
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: isActive ? context.primaryColor : greyColorWithOpacity0_4,
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  Widget _buildTradeBegunCard(
      TradeResponseModel response, dynamic post, bool isOwner) {
    bool isGivePost = post?.postType == 'give';
    String offeringText = '';

    if (isGivePost) {
      String offeringType = response.responseType.toLowerCase();
      double? ps = response.priceRangeStart;
      double? pe = response.priceRangeEnd;
      String? itm = response.itemName;

      if (offeringType == 'existing' && post != null) {
        if (post.returnType.toLowerCase() == 'price') {
          offeringType = 'price';
          ps = ps ?? post.priceMin;
          pe = pe ?? post.priceMax;
        } else if (post.returnType.toLowerCase() == 'free') {
          offeringType = 'free';
        } else {
          offeringType = 'item';
          itm = itm ?? post.returnItemName;
        }
      }

      if (offeringType == 'price') {
        offeringText = 'Paying ₹${ps?.toInt()} - ₹${pe?.toInt()}';
      } else if (offeringType == 'item') {
        offeringText = 'Offering ${itm ?? 'an item'}';
      } else {
        offeringText = 'Giving Nothing in return';
      }
    } else {
      String offeringType = response.responseType.toLowerCase();
      double? ps = response.priceRangeStart;
      double? pe = response.priceRangeEnd;
      String? itm = response.itemName;

      if (offeringType == 'price') {
        offeringText = 'Asking for ₹${ps?.toInt()} - ₹${pe?.toInt()}';
      } else if (offeringType == 'item') {
        offeringText = 'Asking for ${itm ?? 'an item'}';
      } else {
        offeringText = 'Offering for free';
      }
    }

    bool isFreeReturn = offeringText == 'Giving Nothing in return' ||
        offeringText == 'Offering for free' ||
        response.responseType.toLowerCase() == 'free' ||
        (response.responseType.toLowerCase() == 'existing' &&
            post != null &&
            post.returnType.toLowerCase() == 'free');

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                response.status == 'rejected'
                    ? 'Offer Rejected'
                    : response.status == 'accepted' || response.status == 'paid'
                        ? 'Trade Accepted'
                        : 'Trade Initiated',
                style: TextStyle(
                  color: response.status == 'rejected'
                      ? Colors.red
                      : context.primaryColor,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  fontFamily: FontFamily.openSans,
                ),
              ),
              _buildStatusBadge(response.status),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: context.subTextColor,
                          fontSize: 16.sp,
                          fontFamily: FontFamily.openSans,
                        ),
                        children: [
                          TextSpan(
                            text:
                                isOwner ? '${response.responderName} ' : 'You ',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: context.textColor,
                                fontSize: 15.sp),
                            recognizer: isOwner
                                ? (TapGestureRecognizer()
                                  ..onTap = () =>
                                      ProfileController.navigateToUserProfile(
                                          context, response.responderId))
                                : null,
                          ),
                          TextSpan(
                            text: isOwner
                                ? 'responded to your post\n'
                                : 'responded to ',
                            style: TextStyle(
                              fontSize: 14.sp,
                            ),
                          ),
                          if (!isOwner)
                            TextSpan(
                              text:
                                  '${response.posterName ?? 'the owner'}\'s post\n',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: context.textColor,
                                  fontSize: 14.sp),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    ProfileController.navigateToUserProfile(
                                        context, response.posterUserId),
                            ),
                          if (isGivePost) ...[
                            const TextSpan(text: 'Taking '),
                            TextSpan(
                              text: post?.itemName ?? 'your product',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: context.textColor),
                            ),
                            const TextSpan(text: '\n'),
                            TextSpan(text: offeringText),
                          ] else ...[
                            const TextSpan(text: 'Providing '),
                            TextSpan(
                              text: post?.itemName ?? 'the product',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: context.textColor),
                            ),
                            const TextSpan(text: '\n'),
                            TextSpan(text: offeringText),
                          ],
                        ],
                      ),
                    ),
                    if (response.responseType != 'price' && !isFreeReturn)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _showMoreDetails = !_showMoreDetails,
                          ),
                          child: Text(
                            _showMoreDetails ? 'Less Details' : 'More Details',
                            style: TextStyle(
                              color: context.primaryColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (response.responseType != 'price') ...[
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: () => _showProductDetailsBottomSheet(context, response, post, isOwner),
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      image: DecorationImage(
                        image: response.itemImages.isNotEmpty
                            ? NetworkImage(AppCachedImage.getFormattedUrl(
                                response.itemImages.first))
                            : (response.givingItemImages != null &&
                                    response.givingItemImages!.isNotEmpty)
                                ? NetworkImage(AppCachedImage.getFormattedUrl(
                                    response.givingItemImages!.first))
                                : (response.postItemImages.isNotEmpty)
                                    ? NetworkImage(AppCachedImage.getFormattedUrl(
                                        response.postItemImages.first))
                                : (post != null && post.itemImages.isNotEmpty)
                                    ? NetworkImage(AppCachedImage.getFormattedUrl(
                                        post.itemImages.first))
                                    : const AssetImage('assets/iphone.png')
                                        as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_showMoreDetails && response.responseType != 'price' && !isFreeReturn) ...[
            SizedBox(height: 16.h),
            _buildItemDetailMiniCard(response, post, isOwner),
          ],
          if (response.status == 'rejected' &&
              response.rejectedReason != null) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.red.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red, size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Status Note',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    response.rejectedReason!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.textColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'rejected':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case 'accepted':
      case 'paid':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Accepted';
        icon = Icons.check_circle_outline;
        break;
      default:
        bgColor = context.primaryColor.withOpacity(0.1);
        textColor = context.primaryColor;
        label = 'Pending';
        icon = Icons.access_time_outlined;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14.sp),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailMiniCard(TradeResponseModel response, dynamic post, bool isOwner) {
    return GestureDetector(
      onTap: () => _showProductDetailsBottomSheet(context, response, post, isOwner),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 70.w,
              height: 70.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                image: DecorationImage(
                  image: response.itemImages.isNotEmpty
                      ? NetworkImage(AppCachedImage.getFormattedUrl(
                          response.itemImages.first))
                      : (response.givingItemImages != null &&
                              response.givingItemImages!.isNotEmpty)
                          ? NetworkImage(AppCachedImage.getFormattedUrl(
                              response.givingItemImages!.first))
                          : (response.postItemImages.isNotEmpty)
                              ? NetworkImage(AppCachedImage.getFormattedUrl(
                                  response.postItemImages.first))
                          : (context.read<TradeController>().selectedPost !=
                                      null &&
                                  context
                                      .read<TradeController>()
                                      .selectedPost!
                                      .itemImages
                                      .isNotEmpty)
                              ? NetworkImage(AppCachedImage.getFormattedUrl(
                                  context
                                      .read<TradeController>()
                                      .selectedPost!
                                      .itemImages
                                      .first))
                              : const AssetImage('assets/iphone.png')
                                  as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response.itemName ?? 'Price Offer',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: context.textColor,
                    ),
                  ),
                  Text(
                    response.itemCondition ??
                        (response.responseType == 'price'
                            ? 'Cash Offer'
                            : 'Unknown'),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.subTextColor,
                        fontFamily: FontFamily.openSans,
                      ),
                      children: [
                        const TextSpan(text: 'Category : '),
                        TextSpan(
                            text: response.itemCategory ?? 'Other',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      response.responseType.toUpperCase(),
                      style: TextStyle(
                        color: context.onPrimaryColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
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

  void _showProductDetailsBottomSheet(
    BuildContext context,
    TradeResponseModel response,
    dynamic post,
    bool isOwner,
  ) {
    final List<String> images = response.itemImages.isNotEmpty
        ? response.itemImages
        : (response.givingItemImages != null &&
                response.givingItemImages!.isNotEmpty)
            ? response.givingItemImages!
            : (response.postItemImages.isNotEmpty
                ? response.postItemImages
                : (post != null && post.itemImages != null && post.itemImages.isNotEmpty
                    ? List<String>.from(post.itemImages)
                    : []));

    final String productName = response.itemName ??
        (response.responseType == 'price'
            ? 'Cash / Price Offer'
            : (post?.returnItemName ?? post?.itemName ?? 'Product Item'));

    final String category = response.itemCategory ?? 'Other';
    final String condition = response.itemCondition ?? 'Like New';
    final String description = (response.itemDescription != null && response.itemDescription!.trim().isNotEmpty)
        ? response.itemDescription!
        : 'No detailed description provided for this item.';

    final String partnerRoleText = isOwner
        ? 'Offered by ${response.responderName}'
        : 'Your offer to ${response.posterName ?? "owner"}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: ctx.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: ctx.dividerColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Product Details',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: FontFamily.openSans,
                        color: ctx.textColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ctx.dividerColor.withOpacity(0.3),
                      ),
                      child: Icon(Icons.close, size: 20.sp, color: ctx.textColor),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Divider(height: 1, color: ctx.dividerColor),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (images.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        height: 240.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          color: ctx.scaffoldBg,
                          image: DecorationImage(
                            image: NetworkImage(AppCachedImage.getFormattedUrl(images.first)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (images.length > 1) ...[
                        SizedBox(height: 12.h),
                        SizedBox(
                          height: 60.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            separatorBuilder: (_, __) => SizedBox(width: 8.w),
                            itemBuilder: (context, index) {
                              return Container(
                                width: 60.w,
                                height: 60.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: ctx.primaryColor, width: 1.5.w),
                                  image: DecorationImage(
                                    image: NetworkImage(AppCachedImage.getFormattedUrl(images[index])),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        width: double.infinity,
                        height: 180.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          color: ctx.scaffoldBg,
                          image: const DecorationImage(
                            image: AssetImage('assets/iphone.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 20.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            productName,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              fontFamily: FontFamily.openSans,
                              color: ctx.textColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: ctx.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            response.responseType.toUpperCase(),
                            style: TextStyle(
                              color: ctx.primaryColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: ctx.primaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: ctx.primaryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20.r,
                            backgroundColor: ctx.primaryColor.withOpacity(0.2),
                            backgroundImage: response.responderImage != null && response.responderImage!.isNotEmpty
                                ? NetworkImage(AppCachedImage.getFormattedUrl(response.responderImage!))
                                : null,
                            child: (response.responderImage == null || response.responderImage!.isEmpty)
                                ? Icon(Icons.person, color: ctx.primaryColor, size: 22.sp)
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  partnerRoleText,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: ctx.textColor,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  post != null ? 'In exchange for: ${post.itemName ?? "Post Item"}' : 'Trade Request Item',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: ctx.subTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailSectionChip(ctx, 'Category', category, Icons.category_outlined),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildDetailSectionChip(ctx, 'Condition', condition, Icons.verified_outlined),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: FontFamily.openSans,
                        color: ctx.textColor,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: ctx.scaffoldBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: ctx.dividerColor),
                      ),
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: ctx.textColor.withOpacity(0.85),
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSectionChip(BuildContext ctx, String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ctx.scaffoldBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ctx.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: ctx.primaryColor),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11.sp, color: ctx.subTextColor, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: ctx.textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptRejectSection(TradeResponseModel response) {
    return Column(
      children: [
        _buildInteractionCard(
          isSelected: _isAcceptSelected,
          onTap: () => setState(() => _isAcceptSelected = true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Accept Offer (Notify ${response.responderName})',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: FontFamily.openSans,
                        color: context.textColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildRadioButton(isActive: _isAcceptSelected),
                ],
              ),
              if (_isAcceptSelected) ...[
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPreferenceChip(context, 'Come to me'),
                    _buildPreferenceChip(context, 'I Pick Up'),
                    _buildPreferenceChip(context, 'Centre Point'),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 12.h),
        _buildInteractionCard(
          isSelected: !_isAcceptSelected,
          onTap: () => setState(() => _isAcceptSelected = false),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reject Offer',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: FontFamily.openSans,
                  color: context.textColor,
                ),
              ),
              _buildRadioButton(isActive: !_isAcceptSelected),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionCard(
      {required bool isSelected,
      required Widget child,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDarkMode ? Colors.white10 : const Color(0xFFF1F6FF))
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? context.primaryColor.withOpacity(0.1)
                : context.dividerColor,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildRadioButton({required bool isActive}) {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? context.primaryColor : context.dividerColor,
          width: 2.w,
        ),
      ),
      child: isActive
          ? Center(
              child: Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.primaryColor,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPreferenceChip(BuildContext context, String label) {
    bool isSelected = _selectedMeetingPreference == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedMeetingPreference = label),
      child: Container(
        width: 100.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor : context.surfaceColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
              color: isSelected ? context.primaryColor : context.dividerColor),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: greyColorWithOpacity0_4,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? context.onPrimaryColor : context.subTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(TradeController controller) {
    final response = controller.selectedResponse;
    final authController = context.read<AuthController>();
    final isOwner = authController.currentUser?.id == response?.posterUserId;
    final isAlreadyAccepted = response?.status == 'accepted' ||
        response?.status == 'meeting_set' ||
        response?.status == 'paid';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: context.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: greyColorWithOpacity0_4,
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () => _handleSubmit(context, controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          minimumSize: Size(double.infinity, 50.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          elevation: 0,
        ),
        child: controller.isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: CircularProgressIndicator(
                    color: context.onPrimaryColor, strokeWidth: 2))
            : Text(
                isAlreadyAccepted && isOwner 
                    ? ((response?.paymentStatus == 'paid' || response?.status == 'paid' || response?.status == 'completed') ? 'Go to Chat' : 'Continue') 
                    : 'Continue',
                style: TextStyle(
                  color: context.onPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
      ),
    );
  }

  void _handleSubmit(BuildContext context, TradeController controller) {
    final response = controller.selectedResponse;
    if (response == null) return;

    if (response.status == 'accepted' ||
        response.status == 'meeting_set' ||
        response.status == 'paid') {
      final authController = context.read<AuthController>();
      final isOwner = authController.currentUser?.id == response.posterUserId;

      if (isOwner) {
        if (response.paymentStatus == 'paid' || response.status == 'paid') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                otherUserId: response.responderId.toString(),
                otherUserName: response.responderName,
                tradeResponse: response,
              ),
            ),
          );
        } else {
          Navigator.pushNamed(context, AppRoutes.tradeDetails,
              arguments: response.id);
        }
      } else {
        Navigator.pushNamed(context, AppRoutes.tradeCompletion);
      }
      return;
    }

    if (_isAcceptSelected) {
      _showConfirmationDialog(context, controller);
    } else {
      // Direct reject
      _updateStatus(context, controller, 'rejected');
    }
  }

  Future<void> _updateStatus(
      BuildContext context, TradeController controller, String status,
      {String? preference}) async {
    final response = controller.selectedResponse;
    if (response == null) return;

    // Map label to backend value
    String? meetingType;
    if (status == 'accepted' && preference != null) {
      if (preference == 'Come to me') {
        meetingType = 'come_to_me';
      } else if (preference == 'I Pick Up')
        meetingType = 'i_pick_up';
      else if (preference == 'Centre Point')
        meetingType = 'centre_point';
      else
        meetingType = preference.toLowerCase().replaceAll(' ', '_');
    }

    final success = await controller.updateResponseStatus(
      responseId: response.id,
      status: status, // status is already 'accepted' or 'rejected'
      meetingType: meetingType,
    );

    if (success && mounted) {
      if (status == 'accepted') {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close dialog if open
        }
        _showAcceptedSuccessDialog(context);
      } else {
        ToastService.showSuccessToast(context, 'Trade Rejected');
        Navigator.pop(context);
      }
    } else if (mounted) {
      ToastService.showErrorToast(
        context,
        controller.errorMessage ?? 'Action failed',
      );
    }
  }

  void _showAcceptedSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: context.surfaceColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.tradeAccepted,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
                'The partner will now be notified to pay and start the chat.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(color: context.onPrimaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context, TradeController controller) {
    final response = controller.selectedResponse;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.surfaceColor,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child:
                      Icon(Icons.close, color: context.textColor, size: 24.sp),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Are you sure you want to accept this offer?\nPartner: ${response?.responderName}\nOffer: ${response?.itemName ?? (response?.responseType == 'price' ? 'Cash' : 'Free')}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: context.dividerColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(
                          context, controller, 'accepted',
                          preference: _selectedMeetingPreference),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            context.primaryColor, // Specific blue from SS
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Yes',
                        style: TextStyle(
                          color: context.onPrimaryColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
