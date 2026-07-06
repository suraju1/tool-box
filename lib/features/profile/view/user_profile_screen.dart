import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/shimmer_controller.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';
import 'package:tool_bocs/core/widgets/user_review_dialog.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/core/widgets/popup_menu_arrow_shape.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/model/user_profile_model.dart';
import 'package:tool_bocs/features/profile/view/blocked_users_screen.dart';
import 'package:tool_bocs/features/profile/view/save_to_collection_sheet.dart';
import 'package:tool_bocs/features/profile/view/saved_users_screen.dart';
import 'package:tool_bocs/features/profile/widgets/review_item_widget.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/services/toast_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId;

  const UserProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isUserSaved = false;
  UserProfileModel? _userProfile;
  bool _isLocalLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int? targetUserId;
      if (widget.userId != null) {
        targetUserId = int.tryParse(widget.userId!);
      } else {
        // Fallback to current user
        targetUserId = context.read<AuthController>().currentUser?.id;
      }

      final currentUserId = context.read<AuthController>().currentUser?.id;
      final isOwnProfile = targetUserId == currentUserId;

      if (targetUserId != null) {
        setState(() => _isLocalLoading = true);
        context
            .read<ProfileController>()
            .getUserProfile(targetUserId, isOwnProfile: isOwnProfile)
            .then((success) {
          if (success) {
            final profile = context.read<ProfileController>().userProfile;
            if (profile != null) {
              setState(() {
                _userProfile = profile;
                _isUserSaved = profile.isSaved ?? false;
              });
            }
          }
          if (!success) {
            final error = context.read<ProfileController>().errorMessage;
            if (error != null && error.toLowerCase().contains("private")) {
              if (mounted) {
                ToastService.showErrorToast(context, error);
                Navigator.of(context).pop();
              }
            }
          }
          if (mounted) {
            setState(() => _isLocalLoading = false);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shimmer = context.watch<ShimmerController>();
    final profileController = context.watch<ProfileController>();
    UserProfileModel? userProfile = _userProfile;
    if (_userProfile != null) {
      if (profileController.viewedProfile?.userDetails.id == _userProfile!.userDetails.id) {
        userProfile = profileController.viewedProfile;
      } else if (profileController.ownProfile?.userDetails.id == _userProfile!.userDetails.id) {
        userProfile = profileController.ownProfile;
      }
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: (shimmer.isLoading ||
              _isLocalLoading ||
              (userProfile == null && profileController.errorMessage == null))
          ? _buildShimmer(context)
          : userProfile == null
              ? Center(
                  child: Text(
                    profileController.errorMessage ?? 'User profile not found',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textColor),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(children: [
                    _buildHeader(context, userProfile),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          SizedBox(height: 15.h),
                          _buildBioSection(userProfile),
                          if (userProfile.isRated != true) ...[
                            SizedBox(height: 15.h),
                            //rate this person now button
                            _buildRateThisPersonButton(context, userProfile),
                          ],

                          SizedBox(height: 15.h),
                          _buildReviewsSection(userProfile),
                          if (userProfile.showTradeHistory != 0) ...[
                            SizedBox(height: 15.h),
                            _buildTradeHistoryStats(context, userProfile),
                          ],
                          SizedBox(height: 20.h),
                          // _buildSettingsList(context),
                          _saveUserButton(context),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ]),
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
              border: Border(
                  bottom: BorderSide(color: context.dividerColor, width: 1.w)),
            ),
            padding: EdgeInsets.fromLTRB(25.w, 50.h, 25.w, 40.h),
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
                                  radius: 10.r)),
                          SizedBox(width: 16.w),
                          Expanded(
                              child: ShimmerBox(
                                  height: 100.h,
                                  width: double.infinity,
                                  radius: 10.r)),
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
                                      height: 1, color: context.dividerColor),
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
    final details = profile.userDetails;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appBarColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
        border: Border(
          bottom: BorderSide(color: context.dividerColor, width: 1.w),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 40.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back_ios, color: context.textColor),
              ),
              Text(
                'Profile',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: FontFamily.openSans,
                ),
              ),
              //report and block
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  if (value == 'block') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: context.surfaceColor,
                        title: Text(
                          'Block User',
                          style: TextStyle(
                            color: context.textColor,
                            fontFamily: FontFamily.openSans,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to block ${details.fullName}?',
                          style: TextStyle(
                            color: context.textColor,
                            fontFamily: FontFamily.openSans,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: context.subTextColor),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Block',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final response = await context
                          .read<ProfileController>()
                          .blockUser(details.id);
                      if (response.success) {
                        if (context.mounted) {
                          ToastService.showSuccessToast(
                              context, response.message);
                          Navigator.pop(context); // Go back after blocking
                        }
                      } else {
                        if (context.mounted) {
                          ToastService.showErrorToast(
                              context, response.message);
                        }
                      }
                    }
                  } else if (value == 'report') {
                    // Handle report
                  }
                },
                offset: const Offset(0, 55),
                shape: PopupMenuArrowShape(
                  borderRadius: 10.r,
                ),
                color: context.surfaceColor,
                elevation: 4,
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    // padding: EdgeInsets.zero,
                    value: 'block',
                    height: 40.h,
                    child: Center(
                      child: Text(
                        'Block',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: FontFamily.openSans,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuDivider(height: 1),
                  PopupMenuItem<String>(
                    value: 'report',
                    height: 40.h,
                    child: Center(
                      child: Text(
                        'Report',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: FontFamily.openSans,
                        ),
                      ),
                    ),
                  ),
                ],
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Icon(
                    Icons.more_vert,
                    color: context.textColor,
                    size: 28.sp,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.dividerColor, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(48.r),
                  child: AppCachedImage(
                    imageUrl: details.image ?? '',
                    userName: details.fullName,
                    width: 96.r,
                    height: 96.r,
                    fit: BoxFit.cover,
                    radius: 48.r,
                    placeholderBgColor: context.primaryColor.withOpacity(0.1),
                    placeholderTextColor: context.textColor,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                details.fullName,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: FontFamily.openSans,
                ),
              ),
              if (details.giverType != null || details.takerType != null)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    [details.giverType, details.takerType]
                        .where((e) => e != null && e!.isNotEmpty)
                        .join(' - '),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(UserProfileModel profile) {
    final bio = profile.userDetails.bio;
    if (bio == null || bio.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: context.dividerColor, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bio',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              fontFamily: FontFamily.openSans,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            bio,
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: context.subTextColor,
              fontSize: 12.sp,
              height: 1.3,
              fontFamily: FontFamily.openSans,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(UserProfileModel profile) {
    final reviews = profile.reviews;
    final averageRating = profile.userDetails.averageRating;
    final totalReviews = profile.userDetails.totalReviews;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: context.dividerColor, width: 1.w),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews & Ratings',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$totalReviews Reviews',
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: context.textColor),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (reviews.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                'No reviews yet',
                style: TextStyle(
                  color: context.subTextColor,
                  fontSize: 14.sp,
                  fontFamily: FontFamily.openSans,
                ),
              ),
            )
          else ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300.h),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: reviews.length > 3 ? 3 : reviews.length,
                separatorBuilder: (_, __) => Divider(color: context.dividerColor),
                itemBuilder: (context, index) => ReviewItemWidget(review: reviews[index]),
              ),
            ),
          ],
          if (reviews.length > 3)
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.allReviews,
                  arguments: profile,
                );
              },
              child: Text(
                'View All Reviews',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  fontFamily: FontFamily.openSans,
                  color: context.primaryColor,
                ),
              ),
            ),
          SizedBox(height: 8.h),
          _buildMarksRow(profile),
        ],
      ),
    );
  }

  Widget _buildMarksRow(UserProfileModel profile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.white10 : greyColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Text(
            'Marks',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: context.textColor,
              fontFamily: FontFamily.openSans,
            ),
          ),
          const Spacer(),
          _buildMarkCount(Icons.thumb_up_alt_outlined,
              profile.userDetails.totalLikes, Colors.green),
          SizedBox(width: 14.w),
          _buildMarkCount(Icons.thumb_down_alt_outlined,
              profile.userDetails.totalDislikes, Colors.red),
        ],
      ),
    );
  }

  Widget _buildMarkCount(IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15.sp),
        SizedBox(width: 4.w),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: context.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTradeHistoryStats(
      BuildContext context, UserProfileModel profile) {
    final stats = profile.tradeStats;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Trade History',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                fontFamily: FontFamily.openSans,
                color: context.textColor,
              ),
            ),
          ),
          SizedBox(height: 15.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Total Trades',
                    stats.totalTrades.toString(),
                    Colors.blue,
                    Icons.handshake),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                    'Sent Offers',
                    stats.sentOffers.toString(),
                    Colors.red,
                    Icons.outbox_outlined),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                    'Received Offers',
                    stats.receivedOffers.toString(),
                    Colors.orange,
                    Icons.move_to_inbox_outlined),
              ),
            ],
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.white10 : greyColor.withOpacity(0.1),
        border: Border.all(color: context.dividerColor),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28.sp),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: context.primaryColor,
              fontFamily: FontFamily.openSans,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: context.textColor,
              fontWeight: FontWeight.w500,
              fontFamily: FontFamily.openSans,
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveUserButton(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final isSaving = profileController.isLoading;

    return GestureDetector(
      onTap: isSaving
          ? null
          : () async {
              if (_userProfile != null) {
                if (_isUserSaved) {
                  final response = await profileController.unsaveUser(_userProfile!.userDetails.id);
                  if (context.mounted) {
                    if (response.success) {
                      setState(() {
                        _isUserSaved = false;
                      });
                      ToastService.showSuccessToast(context, 'User removed from saved');
                    } else {
                      ToastService.showErrorToast(context, response.message ?? 'Failed to unsave');
                    }
                  }
                } else {
                  SaveToCollectionBottomSheet.show(context, _userProfile!.userDetails.id).then((_) {
                    final targetUserId = _userProfile!.userDetails.id;
                    final currentUserId = context.read<AuthController>().currentUser?.id;
                    final isOwnProfile = targetUserId == currentUserId;
                    context.read<ProfileController>().getUserProfile(targetUserId, isOwnProfile: isOwnProfile).then((success) {
                      if (success) {
                        final profile = context.read<ProfileController>().userProfile;
                        if (profile != null && mounted) {
                          setState(() {
                            _userProfile = profile;
                            _isUserSaved = profile.isSaved ?? false;
                          });
                        }
                      }
                    });
                  });
                }
              }
            },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 60.w),
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        alignment: Alignment.centerLeft,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.primaryColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSaving)
              SizedBox(
                height: 20.r,
                width: 20.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.onPrimaryColor,
                ),
              )
            else
              Icon(
                _isUserSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 25.sp,
                color: context.onPrimaryColor,
              ),
            SizedBox(width: 8.w),
            Text(
              _isUserSaved ? 'Saved' : 'Save User',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: context.onPrimaryColor,
                fontFamily: FontFamily.openSans,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildRateThisPersonButton(BuildContext context, UserProfileModel profile) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => UserReviewDialog(
            userId: profile.userDetails.id,
            userName: profile.userDetails.fullName,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        margin: EdgeInsets.symmetric(horizontal: 45.w),
        decoration: BoxDecoration(
          color: context.primaryColor,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: greyColorWithOpacity0_4,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'Rate This Person',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            fontFamily: FontFamily.openSans,
            color: context.onPrimaryColor,
          ),
        ),
      ),
    );
  }
}
