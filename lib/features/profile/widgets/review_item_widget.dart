import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/model/user_profile_model.dart';
import 'package:tool_bocs/util/colors.dart';

class ReviewItemWidget extends StatelessWidget {
  final Review review;
  const ReviewItemWidget({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: InkWell(
        onTap: () {
          if (review.reviewerId != null) {
            ProfileController.navigateToUserProfile(
                context, review.reviewerId!);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: context.primaryColor.withOpacity(0.1), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25.r),
                child: AppCachedImage(
                  imageUrl: review.reviewerImage ?? '',
                  userName: review.reviewerName,
                  width: 50.r,
                  height: 50.r,
                  fit: BoxFit.cover,
                  radius: 25.r,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.reviewerName ?? 'User',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: context.textColor),
                  ),
                  Row(
                    children: [
                      if (review.feedbackLabel != null) ...[
                        Builder(
                          builder: (context) {
                            final isPositive = review.feedbackLabel == 'Friendly' || review.feedbackLabel == 'Professional';
                            return Row(
                              children: [
                                Icon(
                                  isPositive ? Icons.check_circle : Icons.cancel,
                                  color: isPositive ? Colors.green : Colors.red,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  review.feedbackLabel!,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  if (review.comment != null && review.comment!.isNotEmpty)
                    Text(
                      review.comment!,
                      style: TextStyle(
                          fontSize: 12.sp, color: context.subTextColor),
                    ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          context
                              .read<ProfileController>()
                              .toggleReviewReaction(review.id, 'like');
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
                              .toggleReviewReaction(review.id, 'dislike');
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
                          child: Text("False: ${review.dislikesCount}",
                              style: TextStyle(
                                  color: review.userReaction == 'dislike'
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
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
