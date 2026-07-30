import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/subscription/controller/subscription_controller.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/core/widgets/user_review_dialog.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/features/web_ui/view/web_chat_screen.dart';

class WebTradeSuccessScreen extends StatefulWidget {
  const WebTradeSuccessScreen({super.key});

  @override
  State<WebTradeSuccessScreen> createState() => _WebTradeSuccessScreenState();
}

class _WebTradeSuccessScreenState extends State<WebTradeSuccessScreen> {
  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    final tradeController = context.watch<TradeController>();
    final subscriptionController = context.watch<SubscriptionController>();
    final authController = context.watch<AuthController>();
    final response = tradeController.selectedResponse;
    final isOwner = authController.currentUser?.id == response?.posterUserId;
    final posterName = response?.posterName ?? 'the owner';
    final otherUserId = isOwner ? response?.responderId : response?.posterUserId;
    final otherUserName =
        isOwner ? response?.responderName : (response?.posterName ?? 'User');
    final otherUserImage =
        isOwner ? response?.responderImage : response?.posterImage;

    final creditFee =
        subscriptionController.mySubscription?.postPrice.split('.').first ??
            tradeController.lastTradeCompletion?.amount.toString() ??
            '5';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: context.dividerColor.withOpacity(0.5)),
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
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle,
                        color: Colors.green, size: 100),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    AppLocalizations.of(context)!.tradeConfirmed1,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      fontFamily: FontFamily.openSans,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your trade request has been sent to $posterName. You can now chat with them to coordinate the handover.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: context.subTextColor,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  if (tradeController.lastTradeCompletion != null) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.scaffoldBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: context.primaryColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Trade ID',
                            '#${tradeController.lastTradeCompletion!.tradeId}',
                            context,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Credit',
                            '$creditFee Credits',
                            context,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (response != null && otherUserId != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebChatScreen(
                                otherUserId: otherUserId.toString(),
                                otherUserName: otherUserName ?? 'User',
                                otherUserImage: otherUserImage,
                                tradeResponse: response,
                              ),
                            ),
                          );
                        } else {
                          Navigator.pushReplacementNamed(context, AppRoutes.chat);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Colors.white, size: 20),
                      label: Text(
                        response != null
                            ? AppLocalizations.of(context)!
                                .chatWith(otherUserName ?? 'User')
                            : AppLocalizations.of(context)!.chat,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, AppRoutes.bottomNavBar, (route) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.surfaceColor,
                        side: BorderSide(color: context.primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(AppLocalizations.of(context)!.goToHome,
                          style: TextStyle(
                              color: context.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
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

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: context.subTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: context.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
