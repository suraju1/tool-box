import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/features/profile/model/user_profile_model.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';

class WebProfileScreen extends StatelessWidget {
  const WebProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    final profileController = context.watch<ProfileController>();
    final profileUser = profileController.ownProfile?.userDetails;

    if (user == null) {
      return Center(
          child: Text(AppLocalizations.of(context)!.pleaseLogInToView));
    }

    final String fullName = profileUser?.fullName ?? user.fullName;
    final String bioText = profileUser?.bio ??
        "Passionate about buying & selling new and used products\nExploring the best deals and connecting with trusted sellers on TryIt Marketplace.";

    final Color cardBgColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade900
        : const Color(0xFFF3F4F6);

    final Color innerCardBgColor = Theme.of(context).cardColor;
    final bool isNarrow = MediaQuery.of(context).size.width < 1100;
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.myProfile,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: FontFamily.openSans,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),

          // TOP CARD
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: greyColor.withOpacity(0.2)),
            ),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileDetails(
                          context, profileUser, fullName, isMobile),
                      const SizedBox(height: 32),
                      _buildBioBox(context, bioText, innerCardBgColor),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left profile details
                      Expanded(
                        flex: 5,
                        child: _buildProfileDetails(
                            context, profileUser, fullName, isMobile),
                      ),
                      const SizedBox(width: 32),
                      // Right Bio box
                      Expanded(
                        flex: 4,
                        child: _buildBioBox(context, bioText, innerCardBgColor),
                      ),
                    ],
                  ),
          ),

          SizedBox(height: isMobile ? 16 : 24),

          isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMarksOfSuraj(
                        context,
                        fullName,
                        innerCardBgColor,
                        cardBgColor,
                        isMobile,
                        profileController.ownProfile?.reviews ?? [],
                        profileUser),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildTradeHistory(context, innerCardBgColor, cardBgColor,
                        isMobile, profileController.ownProfile?.tradeStats),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildMarksOfSuraj(
                          context,
                          fullName,
                          innerCardBgColor,
                          cardBgColor,
                          isMobile,
                          profileController.ownProfile?.reviews ?? [],
                          profileUser),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: _buildTradeHistory(
                          context,
                          innerCardBgColor,
                          cardBgColor,
                          isMobile,
                          profileController.ownProfile?.tradeStats),
                    ),
                  ],
                ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(BuildContext context, dynamic profileUser,
      String fullName, bool isMobile) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(profileUser, fullName, isMobile),
              const SizedBox(height: 24),
              _buildProfileTextAndButtons(
                  context, profileUser, fullName, isMobile),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(profileUser, fullName, isMobile),
              const SizedBox(width: 32),
              Expanded(
                child: _buildProfileTextAndButtons(
                    context, profileUser, fullName, isMobile),
              ),
            ],
          );
  }

  Widget _buildAvatar(dynamic profileUser, String fullName, bool isMobile) {
    final double size = isMobile ? 100 : 140;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: AppCachedImage(
          imageUrl: profileUser?.image ?? '',
          userName: fullName,
          width: size,
          height: size,
          fit: BoxFit.cover,
          radius: size / 2,
        ),
      ),
    );
  }

  Widget _buildProfileTextAndButtons(BuildContext context, dynamic profileUser,
      String fullName, bool isMobile) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          fullName,
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: FontFamily.openSans,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          [profileUser?.giverType, profileUser?.takerType]
                  .where((e) => e != null && e.isNotEmpty)
                  .join(' - ')
                  .isEmpty
              ? "Good Giver - Money Taker"
              : [profileUser?.giverType, profileUser?.takerType]
                  .where((e) => e != null && e.isNotEmpty)
                  .join(' - '),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontFamily: FontFamily.openSans,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.editProfile);
                },
                icon: const Icon(Icons.edit, size: 16),
                label: Text(AppLocalizations.of(context)!.editProfile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(
                    color: isDark ? Colors.white : Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(30),
                color: Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.credit_card,
                      size: 18, color: isDark ? Colors.white : Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    "Credit Balance: ${profileUser?.remainingBalance ?? '50.00'}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBioBox(
      BuildContext context, String bioText, Color innerCardBgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.bio,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: innerCardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: greyColor.withOpacity(0.2)),
          ),
          child: Text(
            bioText,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarksOfSuraj(
      BuildContext context,
      String fullName,
      Color innerCardBgColor,
      Color cardBgColor,
      bool isMobile,
      List<Review> reviews,
      UserDetails? profileUser) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  "Marks of ${fullName.split(' ').first}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.thumb_up_alt_outlined, size: 24),
                  const SizedBox(width: 8),
                  Text("${profileUser?.totalLikes ?? 0}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 24),
                  const Icon(Icons.thumb_down_alt_outlined, size: 24),
                  const SizedBox(width: 8),
                  Text("${profileUser?.totalDislikes ?? 0}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(AppLocalizations.of(context)!.noReviewsFound,
                  style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 16)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
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
                  padding: EdgeInsets.all(isMobile ? 12 : 20),
                  decoration: BoxDecoration(
                    color: innerCardBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: greyColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isPositive ? const Color(0xFF65B741) : Colors.red,
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
                            Text(
                              review.feedbackLabel ?? "Review",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
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
                                  fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                InkWell(
                                  onTap: () {
                                    context
                                        .read<ProfileController>()
                                        .toggleReviewReaction(
                                            review.id, 'like');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: review.userReaction == 'like'
                                          ? const Color(0xFF65B741)
                                          : (isDark
                                              ? Colors.grey.shade800
                                              : Colors.black),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text("True:${review.likesCount}",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    context
                                        .read<ProfileController>()
                                        .toggleReviewReaction(
                                            review.id, 'dislike');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: review.userReaction == 'dislike'
                                          ? Colors.red
                                          : (isDark
                                              ? Colors.grey.shade900
                                              : Colors.white),
                                      border: Border.all(
                                          color:
                                              review.userReaction == 'dislike'
                                                  ? Colors.red
                                                  : (isDark
                                                      ? Colors.grey.shade700
                                                      : Colors.black)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                        "False: ${review.dislikesCount}",
                                        style: TextStyle(
                                            color:
                                                review.userReaction == 'dislike'
                                                    ? Colors.white
                                                    : (isDark
                                                        ? Colors.white
                                                        : Colors.black),
                                            fontSize: 10,
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

  Widget _buildTradeHistory(BuildContext context, Color innerCardBgColor,
      Color cardBgColor, bool isMobile, TradeStats? tradeStats) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.tradeHistory,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = isMobile
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 32) / 3;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                      width: cardWidth,
                      child: _buildTradeHistoryCard(
                          Icons.sync,
                          Colors.greenAccent.shade700,
                          "${tradeStats?.totalTrades ?? 0}",
                          AppLocalizations.of(context)!.totalTrades,
                          innerCardBgColor,
                          isDark,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.tradeHistory))),
                  SizedBox(
                      width: cardWidth,
                      child: _buildTradeHistoryCard(
                          Icons.outbox_outlined,
                          Colors.orange,
                          "${tradeStats?.sentOffers ?? 0}",
                          AppLocalizations.of(context)!.sentOffers,
                          innerCardBgColor,
                          isDark,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.tradeHistory))),
                  SizedBox(
                      width: cardWidth,
                      child: _buildTradeHistoryCard(
                          Icons.move_to_inbox_outlined,
                          Colors.red,
                          "${tradeStats?.receivedOffers ?? 0}",
                          AppLocalizations.of(context)!.receivedOffers,
                          innerCardBgColor,
                          isDark,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.tradeHistory))),
                ],
              );
            },
          ),
          const SizedBox(height: 48),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border, size: 24),
              label: Text(AppLocalizations.of(context)!.saveProfile),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              AppLocalizations.of(context)!.yourProfileIsSavedBy,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTradeHistoryCard(IconData icon, Color iconColor, String value,
      String title, Color bgColor, bool isDark, {VoidCallback? onTap}) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 36),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
