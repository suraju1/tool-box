import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/features/chat/view/chat_screen.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/trades/model/trade_response_model.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/subscription/controller/subscription_controller.dart';
import 'package:tool_bocs/core/services/toast_service.dart';

class WebTradeCompletionScreen extends StatefulWidget {
  const WebTradeCompletionScreen({super.key});

  @override
  State<WebTradeCompletionScreen> createState() =>
      _WebTradeCompletionScreenState();
}

class _WebTradeCompletionScreenState extends State<WebTradeCompletionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionController>().fetchMySubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tradeController = context.watch<TradeController>();
    final response = tradeController.selectedResponse;

    if (response == null) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body:
            Center(child: Text(AppLocalizations.of(context)!.noTradeSelected)),
      );
    }

    final authController = context.watch<AuthController>();
    final isOwner = authController.currentUser?.id == response.posterUserId;

    if (isOwner) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: _buildAppBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('As the post owner, you\'ll need to complete this step.',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        otherUserId: response.responderId.toString(),
                        otherUserName: response.responderName,
                        tradeResponse: response,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(AppLocalizations.of(context)!.goToChat,
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    // Guard for responders: Only allowed if status is accepted, paid, or completed
    if (response.status != 'accepted' &&
        response.status != 'paid' &&
        response.status != 'completed') {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: _buildAppBar(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock, size: 80, color: Colors.orange),
                const SizedBox(height: 32),
                Text(
                  response.status == 'rejected'
                      ? 'Trade Rejected'
                      : 'Waiting for Owner',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  response.status == 'rejected'
                      ? 'This trade offer was rejected by the owner.'
                      : 'You can only complete the trade once the owner has accepted your offer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.subTextColor,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: Text(AppLocalizations.of(context)!.goBack,
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    bool isPaid = response.paymentStatus == 'paid' ||
        response.status == 'paid' ||
        response.status == 'completed';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepper(context),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: context.dividerColor.withOpacity(0.5)),
                    boxShadow: context.isDarkMode
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            )
                          ],
                  ),
                  child: Column(
                    children: [
                      _buildHandshakeBanner(),
                      const SizedBox(height: 48),
                      _buildTradeSummary(response),
                      const SizedBox(height: 32),
                      _buildChatTicketCard(response, isPaid, tradeController),
                      const SizedBox(height: 48),
                      _buildBottomAction(tradeController, isPaid),
                    ],
                  ),
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
      centerTitle: false,
      title: Text(
        AppLocalizations.of(context)!.completeTheTrade,
        style: TextStyle(
          color: context.textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: context.dividerColor.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildStepper(BuildContext context) {
    return Row(
      children: [
        _buildStepSegment(isActive: true),
        _buildStepSegment(isActive: true),
        _buildStepSegment(isActive: true),
        _buildStepSegment(isActive: true),
      ],
    );
  }

  Widget _buildStepSegment({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive
              ? context.primaryColor
              : context.dividerColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildHandshakeBanner() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/TradeAccepted.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTradeSummary(TradeResponseModel response) {
    final tradeController = context.watch<TradeController>();
    final post = tradeController.selectedPost;
    bool isGivePost = post?.postType == 'give';

    String offeringText = '';
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

    if (isGivePost) {
      if (offeringType == 'price') {
        offeringText = 'Paying ₹${ps?.toInt()} - ₹${pe?.toInt()}';
      } else if (offeringType == 'item') {
        offeringText = 'Offering ${itm ?? 'an item'}';
      } else {
        offeringText = 'Giving Nothing in return';
      }
    } else {
      if (offeringType == 'price') {
        offeringText = 'Asking for ₹${ps?.toInt()} - ₹${pe?.toInt()}';
      } else if (offeringType == 'item') {
        offeringText = 'Providing ${itm ?? 'an item'}';
      } else {
        offeringText = 'Providing for free';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: context.subTextColor,
            fontSize: 18,
            fontFamily: FontFamily.openSans,
            height: 1.6,
          ),
          children: [
            const TextSpan(text: 'Your offer was '),
            TextSpan(
              text: 'ACCEPTED',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Colors.green.shade700),
            ),
            const TextSpan(text: ' -\n'),
            TextSpan(text: 'You are $offeringText\n'),
            const TextSpan(text: 'in exchange for '),
            TextSpan(
              text: post?.itemName ?? 'the product',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: context.textColor),
            ),
            const TextSpan(
                text: '.\nYou will receive the product once completed.'),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTicketCard(TradeResponseModel response, bool isPaid,
      TradeController tradeController) {
    final post = tradeController.selectedPost;
    final otherUserName = post?.userName ?? 'Owner';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                otherUserId: response.posterUserId.toString(),
                otherUserName: response.posterName ?? 'Owner',
                tradeResponse: response,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E61CC).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline,
                    color: Color(0xFF1E61CC), size: 28),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  'Chat with $otherUserName',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textColor),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(TradeController controller, bool isPaid) {
    final subscription = context.watch<SubscriptionController>().mySubscription;
    final creditFee = subscription?.postPrice.split('.').first ?? '5';

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: controller.isLoading
            ? null
            : () {
                if (!isPaid) {
                  _showClosureConfirmation(context, controller, creditFee);
                } else {
                  Navigator.pushNamed(context, AppRoutes.tradeDetails);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: controller.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                isPaid ? 'View Trade Details' : 'Close Trade & Pay Fee',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  void _showClosureConfirmation(
      BuildContext context, TradeController controller, String creditFee) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppLocalizations.of(context)!.closeTrade,
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontFamily: FontFamily.openSans,
              fontSize: 24),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'A fee of $creditFee credits is required to close this trade. Do you wish to proceed?',
            style: TextStyle(
                fontSize: 16, color: context.subTextColor, height: 1.5),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                  color: context.subTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handlePayment(context, controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)!.yesProceed,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment(
      BuildContext context, TradeController controller) async {
    final response = controller.selectedResponse;
    if (response == null) return;

    final success = await controller.processTradePayment(response.id);
    if (success && mounted) {
      ToastService.showSuccessToast(
          context, 'Payment Successful! Chat unlocked.');
      Navigator.pushReplacementNamed(context, AppRoutes.tradeSuccess);
    } else if (mounted) {
      ToastService.showErrorToast(
        context,
        controller.errorMessage ?? 'Payment failed',
      );
    }
  }
}
