import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/subscription/controller/subscription_controller.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/core/widgets/user_review_dialog.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/features/chat/view/chat_screen.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';

class TradeSuccessScreen extends StatefulWidget {
  const TradeSuccessScreen({super.key});

  @override
  State<TradeSuccessScreen> createState() => _TradeSuccessScreenState();
}

class _TradeSuccessScreenState extends State<TradeSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showReviewDialog();
    });
  }

  void _showReviewDialog() {
    final tradeController = context.read<TradeController>();
    final authController = context.read<AuthController>();
    final response = tradeController.selectedResponse;
    if (response == null) return;

    final isOwner = authController.currentUser?.id == response.posterUserId;
    final otherUserId = isOwner ? response.responderId : response.posterUserId;
    final otherUserName = isOwner ? response.responderName : response.posterName;

    if (otherUserId != null) {
      showDialog(
        context: context,
        builder: (context) => UserReviewDialog(
          userId: int.tryParse(otherUserId.toString()) ?? 0,
          userName: otherUserName ?? 'User',
        ),
      );
    }
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
        tradeController.lastTradeCompletion?.amount.toString() ?? '20';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle,
                    color: context.primaryColor, size: 80.sp),
              ),
              SizedBox(height: 32.h),
              Text(
                'Trade Confirmed !',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: FontFamily.openSans,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Your trade request has been sent to $posterName. You can now chat with them to coordinate the handover.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.subTextColor,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              if (tradeController.lastTradeCompletion != null) ...[
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12.r),
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
                      SizedBox(height: 8.h),
                      _buildDetailRow(
                        'Credit',
                        '$creditFee Credits',
                        context,
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 48.h),
              _buildActionButton(
                context,
                label: response != null
                    ? AppLocalizations.of(context)!
                        .chatWith(otherUserName ?? 'User')
                    : AppLocalizations.of(context)!.chat,
                icon: Icons.chat_bubble_outline,
                onPressed: () {
                  if (response != null && otherUserId != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
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
                isPrimary: true,
              ),
              SizedBox(height: 12.h),
              _buildActionButton(
                context,
                label: AppLocalizations.of(context)!.goToHome,
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.bottomNavBar, (route) => false),
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required String label,
      IconData? icon,
      required VoidCallback onPressed,
      required bool isPrimary}) {
    final color = isPrimary ? context.onPrimaryColor : context.primaryColor;
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? context.primaryColor : context.surfaceColor,
          side: isPrimary
              ? null
              : BorderSide(color: context.primaryColor, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          elevation: 0,
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
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
            fontSize: 14.sp,
            color: context.subTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            color: context.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
