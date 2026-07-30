import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tool_bocs/features/profile/model/user_profile_model.dart';
import 'package:tool_bocs/features/profile/widgets/review_item_widget.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';

class AllReviewsScreen extends StatelessWidget {
  final UserProfileModel profile;
  const AllReviewsScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final reviews = profile.reviews;
    final averageRating = profile.userDetails.averageRating;
    final totalReviews = profile.userDetails.totalReviews;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.appBarColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: context.textColor, size: 20.sp),
        ),
        title: Text(
          'Reviews & Ratings',
          style: TextStyle(
            color: context.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            fontFamily: FontFamily.openSans,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(
                bottom: BorderSide(color: context.dividerColor, width: 1.w),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Total Reviews',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                    fontFamily: FontFamily.openSans,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '$totalReviews reviews',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: context.subTextColor,
                    fontWeight: FontWeight.w400,
                    fontFamily: FontFamily.openSans,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reviews.isEmpty
                ? Center(
                    child: Text(
                      'No reviews yet',
                      style: TextStyle(
                        color: context.subTextColor,
                        fontSize: 14.sp,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(16.w),
                    itemCount: reviews.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 12.h),
                    itemBuilder: (context, index) =>
                        ReviewItemWidget(review: reviews[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
