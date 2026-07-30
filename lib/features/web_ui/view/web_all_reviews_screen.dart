import 'package:flutter/material.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/model/user_profile_model.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
class WebAllReviewsScreen extends StatelessWidget {
  final UserProfileModel profile;
  const WebAllReviewsScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final reviews = profile.reviews;
    final averageRating = profile.userDetails.averageRating;
    final totalReviews = profile.userDetails.totalReviews;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
              maxWidth:
                  800), // Narrower constraint for reviews list looks better
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  children: [
                    _buildRatingSummary(
                        context, averageRating, totalReviews.toString()),
                    const SizedBox(height: 32),
                    if (reviews.isEmpty)
                      _buildEmptyState(context)
                    else
                      ...reviews
                          .map((review) => _buildReviewItem(context, review))
                          .toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            splashRadius: 24,
          ),
          const SizedBox(width: 16),
          Text(
            AppLocalizations.of(context)!.reviewsRatings,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(
      BuildContext context, String averageRating, String totalReviews) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            averageRating,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Icon(
                index < (double.tryParse(averageRating) ?? 0).floor()
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Based on $totalReviews reviews',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noReviewsYet,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Review review) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPositive = (review.userReaction ?? '').toLowerCase() != 'dislike' &&
        (review.rating is int
            ? review.rating as int
            : int.tryParse(review.rating.toString()) ?? 0) >= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFF65B741) : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(isPositive ? Icons.check : Icons.close,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review.comment?.isNotEmpty == true
                      ? "- ${review.comment}"
                      : "- No comments",
                  style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                      fontSize: 14),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InkWell(
                      onTap: () {
                        context
                            .read<ProfileController>()
                            .toggleReviewReaction(review.id, 'like');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: review.userReaction == 'like'
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          border: Border.all(
                              color: isDark ? Colors.white : Colors.black),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("True: ${review.likesCount}",
                            style: TextStyle(
                                color: review.userReaction == 'like'
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark ? Colors.white : Colors.black),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        context
                            .read<ProfileController>()
                            .toggleReviewReaction(review.id, 'dislike');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: review.userReaction == 'dislike'
                              ? (isDark ? Colors.white : Colors.black)
                              : Colors.transparent,
                          border: Border.all(
                              color: isDark ? Colors.white : Colors.black),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("False: ${review.dislikesCount}",
                            style: TextStyle(
                                color: review.userReaction == 'dislike'
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark ? Colors.white : Colors.black),
                                fontSize: 12,
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
  }
}
