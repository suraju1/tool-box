import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

class TradeCompletionScreen extends StatefulWidget {
  const TradeCompletionScreen({super.key});

  @override
  State<TradeCompletionScreen> createState() => _TradeCompletionScreenState();
}

class _TradeCompletionScreenState extends State<TradeCompletionScreen> {
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
        body: Center(child: Text(AppLocalizations.of(context)!.noTradeSelected)),
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
              const Text(
                  'As the post owner, you don\'t need to complete this step.'),
              SizedBox(height: 20.h),
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
                child: Text(AppLocalizations.of(context)!.goToChat),
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
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_clock, size: 64.sp, color: Colors.orange),
                SizedBox(height: 24.h),
                Text(
                  response.status == 'rejected'
                      ? 'Trade Rejected'
                      : 'Waiting for Owner',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  response.status == 'rejected'
                      ? 'This trade offer was rejected by the owner.'
                      : 'You can only complete the trade once the owner has accepted your offer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.subTextColor,
                  ),
                ),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.goBack),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                _buildStepper(context),
                SizedBox(height: 10.h),
                _buildHandshakeBanner(),
                SizedBox(height: 24.h),
                _buildTradeSummary(response),
                SizedBox(height: 16.h),
                _buildChatTicketCard(response, isPaid, tradeController),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomAction(tradeController, isPaid),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.scaffoldBg,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: context.textColor, size: 20.sp),
      ),
      centerTitle: true,
      title: Text(
        'Complete the Trade',
        style: TextStyle(
          color: context.textColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
        ),
      ),
    );
  }

  Widget _buildStepper(BuildContext context) {
    return Container(
      color: context.scaffoldBg,
      padding: EdgeInsets.only(bottom: 10.h, left: 10.w, right: 10.w),
      child: Row(
        children: [
          _buildStepSegment(isActive: true),
          _buildStepSegment(isActive: true),
          _buildStepSegment(isActive: true),
          _buildStepSegment(isActive: true),
        ],
      ),
    );
  }

  Widget _buildStepSegment({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 5.h,
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: isActive ? context.primaryColor : greyColorWithOpacity0_4,
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  Widget _buildHandshakeBanner() {
    return Container(
      width: double.infinity,
      height: 220.h,
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Image.asset(
        'assets/TradeAccepted.png', // Fallback for now
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.fill,

        colorBlendMode: BlendMode.dstIn,
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: context.subTextColor,
            fontSize: 16.sp,
            fontFamily: FontFamily.openSans,
            height: 1.5,
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
                text: ' You will receive the product once completed.'),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTicketCard(TradeResponseModel response, bool isPaid,
      TradeController tradeController) {
    // In Step 4, the user is the PARTNER (responder). So the OTHER user is the POST OWNER.
    final post = tradeController.selectedPost;
    final otherUserName = post?.userName ?? 'Owner';

    return InkWell(
      onTap: () {
        if (!isPaid) {
          final creditFee = '20';
          _showClosureConfirmation(context, tradeController, creditFee);
        } else {
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
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: context.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: greyColorWithOpacity0_4,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white10
                    : const Color(0xFFE6F0FF),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.chat_bubble_outline,
                  color: const Color(0xFF1E61CC), size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat with $otherUserName',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: context.textColor, size: 18.sp),
          ],
        ),
      ),
    );
  }

  void _showPaymentRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: context.primaryColor, size: 24.sp),
            SizedBox(width: 10.w),
            Text(
              'Chat Locked',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFamily: FontFamily.openSans,
                  fontSize: 18.sp),
            ),
          ],
        ),
        content: Text(
          'Kindly close the trade first; only then will the chat be enabled.',
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: context.textColor,
              fontFamily: FontFamily.openSans),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
              minimumSize: Size(100.w, 40.h),
            ),
            child: Text(AppLocalizations.of(context)!.ok,
                style: TextStyle(
                    color: context.onPrimaryColor,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(TradeController controller, bool isPaid) {
    final creditFee = '20';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: context.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: greyColorWithOpacity0_4,
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
      ),
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
          minimumSize: Size(double.infinity, 54.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          elevation: 0,
        ),
        child: controller.isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: CircularProgressIndicator(
                    color: context.onPrimaryColor, strokeWidth: 2))
            : Text(
                isPaid ? 'View Trade Details' : 'Close Trade',
                style: TextStyle(
                  color: context.onPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Close Trade',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontFamily: FontFamily.openSans),
        ),
        content: Text(
          'A fee of $creditFee credits is required to close this trade. Do you wish to proceed?',
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              fontFamily: FontFamily.openSans),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'No, Cancel',
              style: TextStyle(
                  color: context.subTextColor, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handlePayment(context, controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text(AppLocalizations.of(context)!.yesProceed,
                style: TextStyle(
                    color: context.onPrimaryColor,
                    fontWeight: FontWeight.w700)),
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
