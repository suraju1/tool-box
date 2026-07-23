import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/subscription/controller/subscription_controller.dart';
import 'package:tool_bocs/features/subscription/model/subscription_model.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({super.key});

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  late Razorpay _razorpay;
  int? _activePlanId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionController>().fetchAvailablePlans();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              Icon(Icons.arrow_back_ios, color: context.textColor, size: 20.sp),
        ),
        centerTitle: true,
        title: Text(
          'Subscription',
          style: TextStyle(
            color: context.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            fontFamily: FontFamily.openSans,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: Consumer<SubscriptionController>(
        builder: (context, controller, child) {
          if (controller.isPlansLoading) {
            return _buildLoadingState(context);
          }

          final plans = controller.availablePlans;

          if (plans.isEmpty && controller.errorMessage != null) {
            return _buildErrorState(context, controller);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Text(
                  'Choose Your Plan',
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Unlock premium features and scale your productivity with TOOLUCS.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.subTextColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30.h),
                if (plans.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 50.h),
                    child: Text(
                      'No subscription plans available at the moment.',
                      style: TextStyle(color: context.subTextColor),
                    ),
                  )
                else
                  ...plans.map((plan) => Padding(
                        padding: EdgeInsets.only(bottom: 15.h),
                        child: _buildPlanCard(
                          context,
                          plan: plan,
                          isLoading: controller.isActivating,
                        ),
                      )),
                SizedBox(height: 40.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Column(
        children: [
          SizedBox(height: 50.h),
          ShimmerBox(height: 30.h, width: 200.w),
          SizedBox(height: 20.h),
          ShimmerBox(height: 40.h, width: double.infinity),
          SizedBox(height: 40.h),
          ...List.generate(3, (index) => Padding(
            padding: EdgeInsets.only(bottom: 20.h),
            child: ShimmerBox(height: 250.h, width: double.infinity, radius: 25.r),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SubscriptionController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              controller.errorMessage ?? 'Failed to load plans.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.subTextColor),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => controller.fetchAvailablePlans(),
              child: Text(AppLocalizations.of(context)!.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubscribe(BuildContext context, AvailablePlan plan) async {
    _activePlanId = plan.id;
    final controller = context.read<SubscriptionController>();
    
    // TEMPORARY BYPASS for testing: Skip createOrder and Razorpay, just activate directly
    // final orderResponse = await controller.createOrder(plan.id);
    final success = await controller.activateSubscription(plan.id);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.successMessage ?? 'Subscription activated successfully (Bypassed Payment)'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.mySubscription);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Failed to activate subscription'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_activePlanId == null) return;
    final controller = context.read<SubscriptionController>();
    final success = await controller.verifyPayment(
      orderId: response.orderId!,
      paymentId: response.paymentId!,
      signature: response.signature!,
      subscriptionId: _activePlanId!,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.successMessage ?? 'Payment successful & subscription activated'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.mySubscription);
      } else if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      context.read<SubscriptionController>().cancelActivation();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment Failed: ${response.message ?? 'Cancelled'}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet if needed
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required AvailablePlan plan,
    required bool isLoading,
  }) {
    final controller = context.read<SubscriptionController>();
    // Plan is activating if general loading is true AND this specific id matches
    final isThisPlanLoading = controller.isActivating && controller.activatingPlanId == plan.id;
    
    // Pro label logic (based on plan name)
    final bool isPopular = plan.name.toLowerCase().contains('pro');
    
    // Parse features from description: Split by newline OR comma
    List<String> features = plan.description
        .split(RegExp(r'[\n,]'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
        
    if (features.isEmpty && plan.description.isNotEmpty) {
      features = [plan.description];
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: isPopular ? context.primaryColor : context.dividerColor,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(23.r),
                    bottomLeft: Radius.circular(15.r),
                  ),
                ),
                child: Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: context.onPrimaryColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${plan.price.split('.').first}',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w800,
                        color: context.primaryColor,
                      ),
                    ),
                    Text(
                      ' /${plan.days} days',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15.h),
                Row(
                  children: [
                    Icon(Icons.stars, color: context.primaryColor, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '${plan.creditBalance} Credits Included',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: context.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                if (features.isNotEmpty)
                  ...features.map((f) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 18.sp),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                f.trim(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: context.textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                else
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      'Enjoy full access to ${plan.name} features.',
                      style: TextStyle(color: context.subTextColor),
                    ),
                  ),
                SizedBox(height: 15.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _onSubscribe(context, plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPopular ? context.primaryColor : const Color(0xFFE8F1FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: isThisPlanLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isPopular ? Colors.white : context.primaryColor,
                              ),
                            ),
                          )
                        : Text(
                            'Get Started',
                            style: TextStyle(
                              color: isPopular ? Colors.white : context.primaryColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
