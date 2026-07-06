import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/shimmer_controller.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/core/widgets/user_review_dialog.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/model/user_profile_model.dart';
import 'package:tool_bocs/features/profile/widgets/review_item_widget.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/web_ui/view/web_save_to_collection_dialog.dart';

class WebUserProfileScreen extends StatefulWidget {
  final String? userId;

  const WebUserProfileScreen({super.key, this.userId});

  @override
  State<WebUserProfileScreen> createState() => _WebUserProfileScreenState();
}

class _WebUserProfileScreenState extends State<WebUserProfileScreen> {
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
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new,
              color: context.textColor, size: 20),
        ),
        title: Text(
          AppLocalizations.of(context)!.sellerProfile,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: FontFamily.openSans,
            color: context.textColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: (shimmer.isLoading ||
              _isLocalLoading ||
              (userProfile == null && profileController.errorMessage == null))
          ? const Center(child: CircularProgressIndicator())
          : userProfile == null
              ? Center(
                  child: Text(
                    profileController.errorMessage ?? 'User profile not found',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textColor, fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 48),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Profile Info, Actions, Trade History)
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProfileHeaderCard(context, userProfile),
                                  const SizedBox(height: 24),
                                  if (userProfile.showTradeHistory != 0) ...[
                                    _buildTradeHistoryCard(
                                        context, userProfile),
                                    const SizedBox(height: 24),
                                  ],
                                  _buildMarksCard(context, userProfile),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                            // Right Column (Bio, Reviews, Rate)
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (userProfile.userDetails.bio != null &&
                                      userProfile
                                          .userDetails.bio!.isNotEmpty) ...[
                                    _buildBioCard(context, userProfile),
                                    const SizedBox(height: 24),
                                  ],
                                  _buildReviewsCard(context, userProfile),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeaderCard(
      BuildContext context, UserProfileModel profile) {
    final details = profile.userDetails;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: context.primaryColor.withOpacity(0.2), width: 4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: AppCachedImage(
                imageUrl: details.image ?? '',
                userName: details.fullName,
                width: 140,
                height: 140,
                fit: BoxFit.cover,
                radius: 70,
                placeholderBgColor: context.primaryColor.withOpacity(0.1),
                placeholderTextColor: context.textColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            details.fullName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: FontFamily.openSans,
            ),
          ),
          const SizedBox(height: 8),
          if (details.giverType != null || details.takerType != null)
            Text(
              [details.giverType, details.takerType]
                  .where((e) => e != null && e!.isNotEmpty)
                  .join(' - '),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleSaveUser(profile),
                  icon: Icon(
                      _isUserSaved ? Icons.bookmark : Icons.bookmark_border),
                  label: Text(_isUserSaved ? 'Saved' : 'Save'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: _isUserSaved
                            ? context.primaryColor
                            : context.dividerColor,
                        width: 2),
                    foregroundColor:
                        _isUserSaved ? context.primaryColor : context.textColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleBlockUser(profile),
                  icon: const Icon(Icons.block),
                  label: Text(AppLocalizations.of(context)!.block),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSaveUser(UserProfileModel profile) async {
    WebSaveToCollectionDialog.show(context, profile.userDetails.id);
  }

  void _handleBlockUser(UserProfileModel profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.blockUser),
        content: Text(
            'Are you sure you want to block ${profile.userDetails.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.block,
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final response = await context
          .read<ProfileController>()
          .blockUser(profile.userDetails.id);
      if (!mounted) return;
      if (response.success) {
        ToastService.showSuccessToast(context, 'User blocked successfully');
        Navigator.pop(context);
      } else {
        ToastService.showErrorToast(context, response.message);
      }
    }
  }

  Widget _buildTradeHistoryCard(
      BuildContext context, UserProfileModel profile) {
    final stats = profile.tradeStats;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.tradeHistory,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textColor),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', stats.totalTrades.toString(), Colors.blue,
                  Icons.handshake),
              _buildStatItem('Sent', stats.sentOffers.toString(), Colors.red,
                  Icons.outbox_outlined),
              _buildStatItem('Received', stats.receivedOffers.toString(),
                  Colors.orange, Icons.move_to_inbox_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: context.textColor)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildMarksCard(BuildContext context, UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppLocalizations.of(context)!.communityMarks,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textColor)),
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(profile.userDetails.totalLikes.toString(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: 24),
              Icon(Icons.thumb_down_alt_outlined, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(profile.userDetails.totalDislikes.toString(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard(BuildContext context, UserProfileModel profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.bio,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.textColor)),
          const SizedBox(height: 16),
          Text(
            profile.userDetails.bio!,
            style: TextStyle(
                fontSize: 16, color: Colors.grey.shade700, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsCard(BuildContext context, UserProfileModel profile) {
    final reviews = profile.reviews;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(AppLocalizations.of(context)!.reviews,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.textColor)),
                  if (profile.isRated != true) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => UserReviewDialog(
                            userId: profile.userDetails.id,
                            userName: profile.userDetails.fullName,
                          ),
                        );
                      },
                      icon: const Icon(Icons.star_rate_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.rateThisPerson),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    '${profile.userDetails.totalReviews} Reviews',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(AppLocalizations.of(context)!.noReviewsYet,
                    style:
                        TextStyle(fontSize: 16, color: Colors.grey.shade500)),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length > 5 ? 5 : reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (context, index) =>
                  _buildWebReviewItem(context, reviews[index]),
            ),
            if (reviews.length > 5) ...[
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.allReviews,
                        arguments: profile);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.viewAllReviews,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.primaryColor),
                  ),
                ),
              ),
            ]
          ],
        ],
      ),
    );
  }

  Widget _buildWebReviewItem(BuildContext context, Review review) {
    return InkWell(
      onTap: () {
        if (review.reviewerId != null) {
          ProfileController.navigateToUserProfile(context, review.reviewerId!);
        }
      },
      hoverColor: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.dividerColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AppCachedImage(
                imageUrl: review.reviewerImage ?? '',
                userName: review.reviewerName,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                radius: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.reviewerName ?? 'User',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.textColor),
                ),
                const SizedBox(height: 6),
                if (review.feedbackLabel != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      review.feedbackLabel!,
                      style: TextStyle(
                          fontSize: 12,
                          color: context.primaryColor,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  review.comment?.isNotEmpty == true
                      ? review.comment!
                      : 'No message provided',
                  style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
