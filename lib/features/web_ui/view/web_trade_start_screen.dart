import 'package:flutter/gestures.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
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

class WebTradeStartScreen extends StatefulWidget {
  const WebTradeStartScreen({super.key});

  @override
  State<WebTradeStartScreen> createState() => _WebTradeStartScreenState();
}

class _WebTradeStartScreenState extends State<WebTradeStartScreen> {
  String _selectedMeetingPreference = 'Come to me';
  bool _isAcceptSelected = true;
  final bool _showMoreDetails =
      true; // Default to true on web for better visibility

  @override
  Widget build(BuildContext context) {
    final tradeController = context.watch<TradeController>();
    final authController = context.watch<AuthController>();
    final response = tradeController.selectedResponse;
    final post = tradeController.selectedPost;
    final isOwner = authController.currentUser?.id == response?.posterUserId;

    if (response == null) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: _buildAppBar(context),
        body: Center(
            child: Text(AppLocalizations.of(context)!.noResponseSelected)),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepper(),
                const SizedBox(height: 32),

                // Main Trade Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: context.dividerColor.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTradeBegunHeader(response),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child:
                                _buildTradeDetailsText(response, post, isOwner),
                          ),
                          const SizedBox(width: 32),
                          if (response.responseType != 'price' &&
                              response.responseType.toLowerCase() != 'free' &&
                              !(response.responseType.toLowerCase() == 'existing' &&
                                  post != null &&
                                  post.returnType.toLowerCase() == 'free'))
                            Expanded(
                              flex: 2,
                              child: _buildItemDetailCardWeb(response, post, isOwner),
                            ),
                        ],
                      ),
                      if (response.status == 'rejected' &&
                          response.rejectedReason != null) ...[
                        const SizedBox(height: 24),
                        _buildRejectionReason(response),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Area for Pending trades
                if (response.status == 'pending') ...[
                  if (isOwner)
                    _buildAcceptRejectSectionWeb(response)
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.waitingForThePostOwner,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],

                const SizedBox(height: 40),

                // Bottom Action Button
                if ((response.status == 'pending' && isOwner) ||
                    (response.status == 'accepted' ||
                        response.status == 'meeting_set' ||
                        response.status == 'paid'))
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildBottomAction(tradeController),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.surfaceColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: context.textColor),
      ),
      title: Text(
        AppLocalizations.of(context)!.tradeRequest,
        style: TextStyle(
          color: context.textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: context.dividerColor.withOpacity(0.5),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _buildStepSegment(isActive: true),
        _buildStepSegment(isActive: true),
        _buildStepSegment(isActive: true),
        _buildStepSegment(isActive: false),
      ],
    );
  }

  Widget _buildStepSegment({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? context.primaryColor : greyColorWithOpacity0_4,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTradeBegunHeader(TradeResponseModel response) {
    return Row(
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
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontFamily: FontFamily.openSans,
          ),
        ),
        _buildStatusBadge(response.status),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeDetailsText(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: context.subTextColor,
              fontSize: 20,
              height: 1.6,
              fontFamily: FontFamily.openSans,
            ),
            children: [
              TextSpan(
                text: isOwner ? '${response.responderName} ' : 'You ',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: context.textColor),
                recognizer: isOwner
                    ? (TapGestureRecognizer()
                      ..onTap = () => ProfileController.navigateToUserProfile(
                          context, response.responderId))
                    : null,
              ),
              TextSpan(
                  text:
                      isOwner ? 'responded to your post\n' : 'responded to '),
              if (!isOwner)
                TextSpan(
                  text: '${response.posterName ?? 'the owner'}\'s post\n',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: context.textColor),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => ProfileController.navigateToUserProfile(
                        context, response.posterUserId),
                ),
              if (isGivePost) ...[
                const TextSpan(text: 'Taking '),
                TextSpan(
                  text: post?.itemName ?? 'your product',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: context.textColor),
                ),
                const TextSpan(text: '\n'),
                TextSpan(text: offeringText),
              ] else ...[
                const TextSpan(text: 'Providing '),
                TextSpan(
                  text: post?.itemName ?? 'the product',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: context.textColor),
                ),
                const TextSpan(text: '\n'),
                TextSpan(text: offeringText),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemDetailCardWeb(TradeResponseModel response, dynamic post, bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showProductDetailsDialogWeb(context, response, post, isOwner),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 16),
          Text(
            response.itemName ?? 'Price Offer',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textColor),
          ),
          const SizedBox(height: 4),
          Text(
            response.itemCondition ??
                (response.responseType == 'price' ? 'Cash Offer' : 'Unknown'),
            style: TextStyle(
                fontSize: 14,
                color: context.primaryColor,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              response.responseType.toUpperCase(),
              style: TextStyle(
                color: context.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetailsDialogWeb(
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

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Product Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: FontFamily.openSans,
                          color: ctx.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, color: ctx.textColor),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: ctx.dividerColor),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (images.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: ctx.scaffoldBg,
                            image: DecorationImage(
                              image: NetworkImage(AppCachedImage.getFormattedUrl(images.first)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (images.length > 1) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 70,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: ctx.primaryColor, width: 2),
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
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: ctx.scaffoldBg,
                            image: const DecorationImage(
                              image: AssetImage('assets/iphone.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              productName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: FontFamily.openSans,
                                color: ctx.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: ctx.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              response.responseType.toUpperCase(),
                              style: TextStyle(
                                color: ctx.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ctx.primaryColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ctx.primaryColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: ctx.primaryColor.withOpacity(0.2),
                              backgroundImage: response.responderImage != null && response.responderImage!.isNotEmpty
                                  ? NetworkImage(AppCachedImage.getFormattedUrl(response.responderImage!))
                                  : null,
                              child: (response.responderImage == null || response.responderImage!.isEmpty)
                                  ? Icon(Icons.person, color: ctx.primaryColor, size: 24)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partnerRoleText,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: ctx.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    post != null ? 'In exchange for: ${post.itemName ?? "Post Item"}' : 'Trade Request Item',
                                    style: TextStyle(
                                      fontSize: 13,
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
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailSectionChipWeb(ctx, 'Category', category, Icons.category_outlined),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDetailSectionChipWeb(ctx, 'Condition', condition, Icons.verified_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: FontFamily.openSans,
                          color: ctx.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: ctx.scaffoldBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ctx.dividerColor),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 15,
                            color: ctx.textColor.withOpacity(0.85),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSectionChipWeb(BuildContext ctx, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ctx.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ctx.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: ctx.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: ctx.subTextColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ctx.textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReason(TradeResponseModel response) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.reasonForRejection1,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            response.rejectedReason!,
            style: TextStyle(
                fontSize: 15,
                color: context.textColor.withOpacity(0.8),
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptRejectSectionWeb(TradeResponseModel response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.reviewRespond,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: FontFamily.openSans,
            color: context.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.acceptTheOfferAndChoose1,
          style: TextStyle(fontSize: 16, color: context.subTextColor),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInteractionCard(
                isSelected: _isAcceptSelected,
                onTap: () => setState(() => _isAcceptSelected = true),
                title: 'Accept Offer',
                subtitle: 'Notify ${response.responderName} and set location',
                icon: Icons.check_circle_outline,
                activeColor: Colors.green,
                content: _isAcceptSelected
                    ? Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.meetingPreference,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.textColor),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildPreferenceChipWeb('Come to me'),
                                _buildPreferenceChipWeb('I Pick Up'),
                                _buildPreferenceChipWeb('Centre Point'),
                              ],
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildInteractionCard(
                isSelected: !_isAcceptSelected,
                onTap: () => setState(() => _isAcceptSelected = false),
                title: AppLocalizations.of(context)!.rejectOffer,
                subtitle: 'Decline this proposal permanently',
                icon: Icons.cancel_outlined,
                activeColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractionCard({
    required bool isSelected,
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    Widget? content,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(0.05)
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : context.dividerColor.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon,
                      color: isSelected ? activeColor : greyColor, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? activeColor : context.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                              fontSize: 13, color: context.subTextColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isSelected ? activeColor : greyColor,
                          width: 2),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: activeColor),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              if (content != null) content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceChipWeb(String label) {
    bool isSelected = _selectedMeetingPreference == label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedMeetingPreference = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? context.primaryColor : context.scaffoldBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    isSelected ? context.primaryColor : context.dividerColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? context.onPrimaryColor : context.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
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

    return SizedBox(
      width: 240,
      height: 54,
      child: ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () => _handleSubmit(context, controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: controller.isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: context.onPrimaryColor, strokeWidth: 2),
              )
            : Text(
                isAlreadyAccepted && isOwner ? 'Go to Chat' : 'Submit Decision',
                style: TextStyle(
                    color: context.onPrimaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
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
      _showConfirmationDialogWeb(context, controller);
    } else {
      _updateStatus(context, controller, 'rejected');
    }
  }

  Future<void> _updateStatus(
      BuildContext context, TradeController controller, String status,
      {String? preference}) async {
    final response = controller.selectedResponse;
    if (response == null) return;

    String? meetingType;
    if (status == 'accepted' && preference != null) {
      if (preference == 'Come to me') {
        meetingType = 'come_to_me';
      } else if (preference == 'I Pick Up') {
        meetingType = 'i_pick_up';
      } else if (preference == 'Centre Point') {
        meetingType = 'centre_point';
      } else {
        meetingType = preference.toLowerCase().replaceAll(' ', '_');
      }
    }

    final success = await controller.updateResponseStatus(
      responseId: response.id,
      status: status,
      meetingType: meetingType,
    );

    if (success && mounted) {
      if (status == 'accepted') {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close dialog
        }
        _showAcceptedSuccessDialogWeb(context);
      } else {
        ToastService.showSuccessToast(context, 'Trade Rejected');
        Navigator.pop(context);
      }
    } else if (mounted) {
      ToastService.showErrorToast(
          context, controller.errorMessage ?? 'Action failed');
    }
  }

  void _showAcceptedSuccessDialogWeb(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.surfaceColor,
        contentPadding: const EdgeInsets.all(40),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 32),
            Text(AppLocalizations.of(context)!.tradeAccepted,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.thePartnerWillNowBe,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppLocalizations.of(context)!.done,
                    style:
                        TextStyle(color: context.onPrimaryColor, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialogWeb(
      BuildContext context, TradeController controller) {
    final response = controller.selectedResponse;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.confirmAcceptance,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: context.textColor),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Are you sure you want to accept this offer?\nPartner: ${response?.responderName}\nOffer: ${response?.itemName ?? (response?.responseType == 'price' ? 'Cash' : 'Free')}',
                style: TextStyle(
                    fontSize: 16, height: 1.6, color: context.textColor),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      side: BorderSide(color: context.dividerColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.cancel,
                        style:
                            TextStyle(color: context.textColor, fontSize: 15)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _updateStatus(
                        context, controller, 'accepted',
                        preference: _selectedMeetingPreference),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.confirm,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
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
