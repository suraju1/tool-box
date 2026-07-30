import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/model/user_profile_model.dart';
import 'package:tool_bocs/util/colors.dart';

class ReviewItemWidget extends StatelessWidget {
  final Review review;
  const ReviewItemWidget({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final bool isPositive =
        (review.userReaction ?? '').toLowerCase() != 'dislike' &&
            (review.rating is int
                    ? review.rating as int
                    : int.tryParse(review.rating.toString()) ?? 0) >=
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
              color: isPositive ? const Color(0xFF65B741) : Colors.red,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        review.feedbackLabel ?? "Review",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: context.textColor),
                      ),
                    ),
                  ],
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
