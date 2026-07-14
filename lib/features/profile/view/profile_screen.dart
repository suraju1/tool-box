import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';
import 'package:tool_bocs/core/widgets/logout_dialog.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/model/user_profile_model.dart';
import 'package:tool_bocs/features/profile/view/setting_screen.dart';
import 'package:tool_bocs/features/profile/widgets/review_item_widget.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/services/firebase_notification_service.dart';
import 'package:tool_bocs/core/controller/theme_controller.dart';
import 'package:tool_bocs/core/controller/language_controller.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final bool isTab;
  final bool isDrawer;
  const ProfileScreen({
    super.key,
    this.isTab = true,
    this.isDrawer = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUserId = context.read<AuthController>().currentUser?.id;
      if (currentUserId != null) {
        final success = await context
            .read<ProfileController>()
            .getUserProfile(currentUserId, isOwnProfile: true);
        // Sync name and profile image to Firestore so chat screens show the real avatar
        if (success && mounted) {
          final profile = context.read<ProfileController>().ownProfile;
          FirebaseNotificationService.syncProfileData(
            fullName: profile?.userDetails.fullName,
            profileImageUrl: profile?.userDetails.image,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final profile = profileController.ownProfile;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: (profileController.isLoading ||
              (profile == null && profileController.errorMessage == null))
          ? _buildShimmer(context)
          : profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profileController.errorMessage ??
                            'User profile not found',
                        style: TextStyle(color: context.textColor),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          final currentUserId =
                              context.read<AuthController>().currentUser?.id;
                          if (currentUserId != null) {
                            context
                                .read<ProfileController>()
                                .getUserProfile(currentUserId);
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  ),
                )
              : widget.isDrawer
                  ? SingleChildScrollView(
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDrawerHeader(context, profile),
                            Divider(color: context.dividerColor, height: 1),
                            _buildDrawerMenu(context),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(context, profile),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              children: [
                                SizedBox(height: 10.h),
                                _buildMarksOfSurajSection(profile),
                                SizedBox(height: 10.h),
                                _buildNewTradeHistoryStats(context, profile),
                                SizedBox(height: 40.h),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Shimmer
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.appBarColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r),
                bottomRight: Radius.circular(30.r),
              ),
            ),
            padding: EdgeInsets.fromLTRB(16.w, 50.h, 16.w, 30.h),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(height: 24.h, width: 100.w),
                    ShimmerBox(height: 30.h, width: 80.w, radius: 8.r),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    ShimmerBox(height: 96.r, width: 96.r, radius: 48.r),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(height: 24.h, width: 120.w),
                          SizedBox(height: 8.h),
                          ShimmerBox(height: 16.h, width: 150.w),
                          SizedBox(height: 12.h),
                          ShimmerBox(height: 32.h, width: 140.w, radius: 10.r),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 15.h),
                // Bio Section Shimmer
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 20.h, width: 60.w),
                      SizedBox(height: 12.h),
                      ShimmerBox(height: 14.h, width: double.infinity),
                      SizedBox(height: 8.h),
                      ShimmerBox(height: 14.h, width: double.infinity),
                      SizedBox(height: 8.h),
                      ShimmerBox(height: 14.h, width: 200.w),
                    ],
                  ),
                ),
                SizedBox(height: 15.h),
                // Reviews Section Shimmer
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(height: 20.h, width: 140.w),
                          ShimmerBox(height: 16.h, width: 100.w),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        children: [
                          ShimmerBox(height: 50.r, width: 50.r, radius: 25.r),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerBox(height: 16.h, width: 100.w),
                                SizedBox(height: 8.h),
                                ShimmerBox(height: 12.h, width: 80.w),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15.h),
                // Trade History Shimmer
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ShimmerBox(height: 20.h, width: 120.w),
                      ),
                      SizedBox(height: 15.h),
                      Row(
                        children: [
                          Expanded(
                            child: ShimmerBox(
                              height: 100.h,
                              width: double.infinity,
                              radius: 10.r,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: ShimmerBox(
                              height: 100.h,
                              width: double.infinity,
                              radius: 10.r,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      ShimmerBox(
                          height: 100.h, width: double.infinity, radius: 10.r),
                    ],
                  ),
                ),
                SizedBox(height: 15.h),
                // Settings List Shimmer
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: List.generate(
                        5,
                        (index) => Column(
                              children: [
                                Row(
                                  children: [
                                    ShimmerBox(
                                        height: 24.h, width: 24.w, radius: 4.r),
                                    SizedBox(width: 16.w),
                                    ShimmerBox(height: 18.h, width: 150.w),
                                    const Spacer(),
                                    ShimmerBox(
                                        height: 16.h, width: 16.w, radius: 8.r),
                                  ],
                                ),
                                if (index < 4) ...[
                                  SizedBox(height: 12.h),
                                  Divider(
                                      height: 1,
                                      color: Colors.grey.withOpacity(0.1)),
                                  SizedBox(height: 12.h),
                                ],
                              ],
                            )),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfileModel profile) {
    final user = profile.userDetails;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
        border: Border(
          bottom: BorderSide(color: context.dividerColor, width: 1.w),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 50.h, 16.w, 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              // Back Button (same left position)
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 22,
                  color: context.textColor,
                ),
              ),

              // Center Title
              Expanded(
                child: Center(
                  child: Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ),
              ),

              IconButton(
                tooltip: 'Edit Profile',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.editProfile),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 22.sp,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.dividerColor, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38.r),
                      child: AppCachedImage(
                        imageUrl: user.image ?? '',
                        userName: user.fullName,
                        width: 76.r,
                        height: 76.r,
                        fit: BoxFit.cover,
                        radius: 38.r,
                        placeholderBgColor:
                            context.primaryColor.withOpacity(0.1),
                        placeholderTextColor: context.textColor,
                      ),
                    ),
                  ),
                  // hide camera icon from here
                  // Positioned(
                  //   bottom: 2.h,
                  //   right: 6.w,
                  //   child: Container(
                  //     padding: EdgeInsets.all(4.w),
                  //     decoration: BoxDecoration(
                  //       color: context.surfaceColor,
                  //       shape: BoxShape.circle,
                  //     ),
                  //     child: Icon(Icons.camera_alt,
                  //         color: context.primaryColor, size: 16.sp),
                  //   ),
                  // ),
                ],
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final profileType = [user.giverType, user.takerType]
                            .where((e) => e != null && e!.isNotEmpty)
                            .join(' - ');
                        final displayText = profileType.isEmpty
                            ? 'Goods Giver - Goods Taker'
                            : profileType;
                        return Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: FontFamily.openSans,
                            ),
                          ),
                        );
                      },
                    ),
                    if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: context.textColor.withOpacity(0.75),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: FontFamily.openSans,
                            height: 1.25,
                          ),
                          children: _buildBioTextSpans(
                            user.bio!.trim(),
                            context,
                          ),
                        ),
                        softWrap: true,
                      ),
                    ],
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: context.isDarkMode
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: 20.sp,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 12.w),
                          Flexible(
                            child: Text(
                              "${AppLocalizations.of(context)!.creditBalance}${user.remainingBalance ?? '50.00'}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 14.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildBioTextSpans(String bio, BuildContext context) {
    final spans = <TextSpan>[];
    final linkStyle = TextStyle(
      color: Colors.blue.shade700,
      fontSize: 12.sp,
      fontWeight: FontWeight.w700,
      fontFamily: FontFamily.openSans,
      height: 1.25,
      decoration: TextDecoration.underline,
    );
    final normalStyle = TextStyle(
      color: context.textColor.withOpacity(0.75),
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      fontFamily: FontFamily.openSans,
      height: 1.25,
    );
    final pattern = RegExp(
      r'\[([^\]]+)\]\((https?:\/\/[^)\s]+|www\.[^)\s]+)\)|https?:\/\/[^\s]+|www\.[^\s]+|@[A-Za-z0-9._]{2,30}',
    );

    var lastIndex = 0;
    for (final match in pattern.allMatches(bio)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: bio.substring(lastIndex, match.start),
          style: normalStyle,
        ));
      }

      final markdownLabel = match.group(1);
      final markdownUrl = match.group(2);
      final rawText = match.group(0) ?? '';
      final displayText = markdownLabel ?? rawText;
      final url = markdownUrl ?? _bioUrlFromText(rawText);

      spans.add(TextSpan(
        text: displayText,
        style: linkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () => _openBioLink(displayText, url),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < bio.length) {
      spans.add(TextSpan(text: bio.substring(lastIndex), style: normalStyle));
    }

    return spans;
  }

  String _bioUrlFromText(String text) {
    final cleanText = text.replaceAll(RegExp(r'[.,;:!?]+$'), '');
    if (cleanText.startsWith('@')) {
      return 'https://www.instagram.com/${cleanText.substring(1)}';
    }
    if (cleanText.startsWith('www.')) {
      return 'https://$cleanText';
    }
    return cleanText;
  }

  void _openBioLink(String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProfileBioLinkScreen(title: title, url: url),
      ),
    );
  }

  Widget _buildMarksOfSurajSection(UserProfileModel profile) {
    final reviews = profile.reviews;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color:
            context.isDarkMode ? Colors.grey.shade900 : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Marks of ${profile.userDetails.fullName.split(' ').first}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.thumb_up_alt_outlined,
                      size: 18.sp, color: context.textColor),
                  SizedBox(width: 4.w),
                  Text("${profile.userDetails.totalLikes ?? 0}",
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: context.textColor)),
                  SizedBox(width: 12.w),
                  Icon(Icons.thumb_down_alt_outlined,
                      size: 18.sp, color: context.textColor),
                  SizedBox(width: 4.w),
                  Text("${profile.userDetails.totalDislikes ?? 0}",
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: context.textColor)),
                ],
              )
            ],
          ),
          SizedBox(height: 16.h),
          if (reviews.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                "No reviews found.",
                style: TextStyle(
                    color: context.isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontSize: 14.sp),
              ),
            )
          else
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final review = reviews[index];
                final bool isPositive =
                    (review.userReaction ?? '').toLowerCase() != 'dislike' &&
                        (review.rating is int
                                ? review.rating as int
                                : int.tryParse(review.rating.toString()) ??
                                    0) >=
                            3;

                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: greyColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color:
                              isPositive ? const Color(0xFF65B741) : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(isPositive ? Icons.check : Icons.close,
                            color: Colors.white, size: 20.sp),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.feedbackLabel ?? "Review",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                  color: context.textColor),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              review.comment?.isNotEmpty == true
                                  ? "- ${review.comment}"
                                  : "- No comments",
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 11.sp),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    context
                                        .read<ProfileController>()
                                        .toggleReviewReaction(
                                            review.id, 'like');
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: review.userReaction == 'like'
                                          ? (context.isDarkMode
                                              ? Colors.white
                                              : Colors.black)
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: context.isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text("True: ${review.likesCount}",
                                        style: TextStyle(
                                            color: review.userReaction == 'like'
                                                ? (context.isDarkMode
                                                    ? Colors.black
                                                    : Colors.white)
                                                : (context.isDarkMode
                                                    ? Colors.white
                                                    : Colors.black),
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                InkWell(
                                  onTap: () {
                                    context
                                        .read<ProfileController>()
                                        .toggleReviewReaction(
                                            review.id, 'dislike');
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: review.userReaction == 'dislike'
                                          ? (context.isDarkMode
                                              ? Colors.white
                                              : Colors.black)
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: context.isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                        "False: ${review.dislikesCount}",
                                        style: TextStyle(
                                            color:
                                                review.userReaction == 'dislike'
                                                    ? (context.isDarkMode
                                                        ? Colors.black
                                                        : Colors.white)
                                                    : (context.isDarkMode
                                                        ? Colors.white
                                                        : Colors.black),
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildNewTradeHistoryStats(
      BuildContext context, UserProfileModel profile) {
    final tradeStats = profile.tradeStats;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
            context.isDarkMode ? Colors.grey.shade900 : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.tradeHistory,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.tradeHistory),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16.sp,
                    color: context.textColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                  child: _buildNewTradeHistoryCard(
                Icons.sync,
                Colors.greenAccent.shade700,
                "${tradeStats?.totalTrades ?? 0}",
                AppLocalizations.of(context)!.totalTrades,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.tradeHistory),
              )),
              SizedBox(width: 8.w),
              Expanded(
                  child: _buildNewTradeHistoryCard(
                      Icons.outbox_outlined,
                      Colors.orange,
                      "${tradeStats?.sentOffers ?? 0}",
                      AppLocalizations.of(context)!.sentOffers)),
              SizedBox(width: 8.w),
              Expanded(
                  child: _buildNewTradeHistoryCard(
                      Icons.move_to_inbox_outlined,
                      Colors.red,
                      "${tradeStats?.receivedOffers ?? 0}",
                      AppLocalizations.of(context)!.receivedOffers)),
            ],
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              AppLocalizations.of(context)!
                  .profileSavedBy(profile.userDetails.savedCount.toString()),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: context.isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade800,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNewTradeHistoryCard(
      IconData icon, Color iconColor, String value, String title,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: greyColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28.sp),
            SizedBox(height: 12.h),
            Text(
              value,
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: context.textColor),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        final languageController = context.watch<LanguageController>();
        final currentLocale = languageController.locale.languageCode;

        return Container(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.selectLanguage,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 20.h),
              _buildLanguageOption(
                context,
                title: 'English',
                isSelected: currentLocale == 'en',
                onTap: () {
                  languageController.setLanguage('en');
                  Navigator.pop(context);
                },
              ),
              _buildLanguageOption(
                context,
                title: 'हिन्दी (Hindi)',
                isSelected: currentLocale == 'hi',
                onTap: () {
                  languageController.setLanguage('hi');
                  Navigator.pop(context);
                },
              ),
              _buildLanguageOption(
                context,
                title: 'मराठी (Marathi)',
                isSelected: currentLocale == 'mr',
                onTap: () {
                  languageController.setLanguage('mr');
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          color: isSelected ? context.primaryColor : context.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: context.primaryColor)
          : null,
    );
  }

  Widget _buildProfileSettingItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey.shade600, size: 24.sp),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: context.textColor,
          fontFamily: FontFamily.openSans,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.sp,
        color: greyColor,
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, UserProfileModel profile) {
    final user = profile.userDetails;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.dividerColor, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: AppCachedImage(
                    imageUrl: user.image ?? '',
                    userName: user.fullName,
                    width: 60.r,
                    height: 60.r,
                    fit: BoxFit.cover,
                    radius: 30.r,
                    placeholderBgColor: context.primaryColor.withOpacity(0.1),
                    placeholderTextColor: context.textColor,
                  ),
                ),
              ),
              Consumer<ThemeController>(
                builder: (context, themeController, _) {
                  final isDark = themeController.themeMode == ThemeMode.dark ||
                      (themeController.themeMode == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark);
                  return GestureDetector(
                    onTap: () => themeController
                        .setTheme(isDark ? ThemeMode.light : ThemeMode.dark),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.amber.withOpacity(0.15)
                            : Colors.indigo.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.amber.withOpacity(0.4)
                              : Colors.indigo.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.wb_sunny_outlined
                            : Icons.dark_mode_outlined,
                        color: isDark ? Colors.amber : Colors.indigo,
                        size: 22.sp,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            user.fullName,
            style: TextStyle(
              color: context.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: FontFamily.openSans,
            ),
          ),
          Builder(
            builder: (context) {
              final profileType = [user.giverType, user.takerType]
                  .where((e) => e != null && e!.isNotEmpty)
                  .join(' - ');
              final displayText = profileType.isEmpty
                  ? 'Goods Giver - Goods Taker'
                  : profileType;
              return Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: FontFamily.openSans,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              color:
                  context.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.credit_card,
                  size: 20.sp,
                  color: Colors.orange,
                ),
                SizedBox(width: 12.w),
                Flexible(
                  child: Text(
                    "${AppLocalizations.of(context)!.creditBalance}${user.remainingBalance ?? '0.00'}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14.sp,
                      fontFamily: FontFamily.openSans,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenu(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10.h),
        _buildDrawerMenuItem(
          context,
          icon: Icons.person_outline,
          label: AppLocalizations.of(context)!.profile,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ProfileScreen(isTab: false, isDrawer: false),
              ),
            );
          },
        ),
        _buildDrawerMenuItem(
          context,
          icon: Icons.post_add_outlined,
          label: AppLocalizations.of(context)!.myPosts,
          onTap: () => Navigator.pushNamed(context, AppRoutes.myPosts),
        ),
        _buildDrawerMenuItem(
          context,
          icon: Icons.card_membership_outlined,
          label: AppLocalizations.of(context)!.mySubscription,
          onTap: () => Navigator.pushNamed(context, AppRoutes.mySubscription),
        ),
        _buildDrawerMenuItem(
          context,
          icon: Icons.sync_alt,
          label: AppLocalizations.of(context)!.transactionHistory,
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.transactionHistory),
        ),
        _buildDrawerMenuItem(
          context,
          icon: Icons.bookmark_border,
          label: AppLocalizations.of(context)!.savedProfiles,
          onTap: () => Navigator.pushNamed(context, AppRoutes.savedUsers),
        ),
        _buildDrawerMenuItem(
          context,
          icon: Icons.block_outlined,
          label: AppLocalizations.of(context)!.blockedUsers,
          onTap: () => Navigator.pushNamed(context, AppRoutes.blockedUsers),
        ),
        SizedBox(height: 10.h),
        Divider(color: context.dividerColor, height: 1),
        SizedBox(height: 10.h),
        _buildDrawerMenuItem(
          context,
          icon: Icons.settings_outlined,
          label: AppLocalizations.of(context)!.settings,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingScreen()),
          ),
        ),
        _buildDrawerMenuItem(
          context,
          icon: Icons.login_outlined,
          label: AppLocalizations.of(context)!.logout,
          onTap: () => showDialog(
            context: context,
            builder: (context) => const LogoutDialog(),
          ),
          itemColor: Colors.red,
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildDrawerMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? itemColor,
  }) {
    final color = itemColor ?? context.textColor;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 0),
      leading: Icon(icon, color: color, size: 28.sp),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: FontFamily.openSans,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.dividerColor,
    );
  }

  void _showThemeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.scaffoldBg,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      builder: (context) {
        return Consumer<ThemeController>(
          builder: (context, themeController, child) {
            return Container(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 36.h),
              decoration: BoxDecoration(
                color: context.scaffoldBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grab handle
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.appearance,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: FontFamily.openSans,
                              color: context.textColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Choose your preferred look',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: context.subTextColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? Colors.white10
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(8.w),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close,
                              color: context.textColor, size: 20.sp),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                          color: context.dividerColor.withOpacity(0.5)),
                      boxShadow: context.isDarkMode
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        _buildThemeOption(
                          context,
                          title: 'Light Mode',
                          subtitle: 'Clean and bright',
                          icon: Icons.light_mode_outlined,
                          mode: ThemeMode.light,
                          currentMode: themeController.themeMode,
                        ),
                        Divider(
                            height: 1,
                            thickness: 1,
                            color: context.dividerColor),
                        _buildThemeOption(
                          context,
                          title: 'Dark Mode',
                          subtitle: 'Easy on the eyes',
                          icon: Icons.dark_mode_outlined,
                          mode: ThemeMode.dark,
                          currentMode: themeController.themeMode,
                        ),
                        Divider(
                            height: 1,
                            thickness: 1,
                            color: context.dividerColor),
                        _buildThemeOption(
                          context,
                          title: 'System Default',
                          subtitle: 'Follows your device setting',
                          icon: Icons.settings_brightness_outlined,
                          mode: ThemeMode.system,
                          currentMode: themeController.themeMode,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
  }) {
    final isSelected = currentMode == mode;
    return InkWell(
      onTap: () => context.read<ThemeController>().setTheme(mode),
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.primaryColor.withOpacity(0.12)
                    : context.isDarkMode
                        ? Colors.white10
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: isSelected ? context.primaryColor : context.subTextColor,
                size: 26.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: FontFamily.openSans,
                      color:
                          isSelected ? context.primaryColor : context.textColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check,
                    color: context.onPrimaryColor, size: 14.sp),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBioLinkScreen extends StatefulWidget {
  final String title;
  final String url;

  const _ProfileBioLinkScreen({
    required this.title,
    required this.url,
  });

  @override
  State<_ProfileBioLinkScreen> createState() => _ProfileBioLinkScreenState();
}

class _ProfileBioLinkScreenState extends State<_ProfileBioLinkScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            fontFamily: FontFamily.openSans,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
