import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/subscription/controller/subscription_controller.dart';
import 'package:tool_bocs/features/subscription/model/subscription_model.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class WebChoosePlanScreen extends StatefulWidget {
  const WebChoosePlanScreen({super.key});

  @override
  State<WebChoosePlanScreen> createState() => _WebChoosePlanScreenState();
}

class _WebChoosePlanScreenState extends State<WebChoosePlanScreen> {
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
          icon: Icon(Icons.arrow_back, color: context.textColor),
        ),
        title: Text(
          AppLocalizations.of(context)!.chooseYourPlan,
          style: TextStyle(
            color: context.textColor,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontFamily: FontFamily.openSans,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Divider(height: 1, color: context.dividerColor.withOpacity(0.5)),
        ),
      ),
      body: Consumer<SubscriptionController>(
        builder: (context, controller, child) {
          if (controller.isPlansLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = controller.availablePlans;

          if (plans.isEmpty && controller.errorMessage != null) {
            return _buildErrorState(context, controller);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .unlockPremiumFeaturesAndScale,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: context.subTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 64),
                    if (plans.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Text(
                          AppLocalizations.of(context)!
                              .noSubscriptionPlansAvailableAt,
                          style: TextStyle(
                              color: context.subTextColor, fontSize: 18),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 40,
                        runSpacing: 40,
                        alignment: WrapAlignment.center,
                        children: plans
                            .map((plan) => _HoverablePlanCard(
                                  plan: plan,
                                  isLoading: controller.isActivating,
                                  onSubscribe: () =>
                                      _onSubscribe(context, plan),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, SubscriptionController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.oopsSomethingWentWrong,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textColor),
            ),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage ?? 'Failed to load plans.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.subTextColor, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => controller.fetchAvailablePlans(),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(AppLocalizations.of(context)!.tryAgain,
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubscribe(BuildContext context, AvailablePlan plan) async {
    _activePlanId = plan.id;
    final controller = context.read<SubscriptionController>();
    final orderResponse = await controller.createOrder(plan.id);

    if (context.mounted) {
      if (orderResponse != null &&
          orderResponse.success &&
          orderResponse.orderId != null) {
        var options = {
          'key': 'rzp_test_T1ASSkvu0ktQw8',
          'amount': orderResponse.amount > 0
              ? orderResponse.amount
              : (double.tryParse(plan.price) ?? 0) * 100,
          'name': 'Toolucs',
          'description': plan.name,
          'order_id': orderResponse.orderId,
          'prefill': {
            'contact': '',
            'email': '',
          },
          'theme': {
            'color': '#45C0C7'
          }
        };

        try {
          _razorpay.open(options);
        } catch (e) {
          debugPrint('Error opening Razorpay checkout: $e');
          controller.cancelActivation();
        }
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
            content: Text(controller.successMessage ??
                'Payment successful & subscription activated'),
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
}

class _HoverablePlanCard extends StatefulWidget {
  final AvailablePlan plan;
  final bool isLoading;
  final VoidCallback onSubscribe;

  const _HoverablePlanCard({
    required this.plan,
    required this.isLoading,
    required this.onSubscribe,
  });

  @override
  State<_HoverablePlanCard> createState() => _HoverablePlanCardState();
}

class _HoverablePlanCardState extends State<_HoverablePlanCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SubscriptionController>();
    final isThisPlanLoading = controller.isActivating &&
        controller.activatingPlanId == widget.plan.id;
    final bool isPopular = widget.plan.name.toLowerCase().contains('pro');

    List<String> features = widget.plan.description
        .split(RegExp(r'[\n,]'))
        .where((e) => e.trim().isNotEmpty)
        .toList();

    if (features.isEmpty && widget.plan.description.isNotEmpty) {
      features = [widget.plan.description];
    }

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, isHovered ? -10.0 : 0.0),
        width: 380,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isPopular
                ? context.primaryColor
                : (isHovered
                    ? context.primaryColor.withOpacity(0.5)
                    : context.dividerColor.withOpacity(0.5)),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? context.primaryColor.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isHovered ? 40 : 20,
              offset: Offset(0, isHovered ? 15 : 10),
            )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isPopular)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.primaryColor,
                          context.primaryColor.withOpacity(0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(-2, 4),
                        )
                      ]),
                  child: Text(
                    AppLocalizations.of(context)!.mostPopular,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.plan.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: context.textColor,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${widget.plan.price.split('.').first}',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: context.primaryColor,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        ' /${widget.plan.days} days',
                        style: TextStyle(
                          fontSize: 16,
                          color: context.subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars_rounded,
                            color: context.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${widget.plan.creditBalance} Credits Included',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: context.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (features.isNotEmpty)
                    ...features.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.green, size: 16),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  f.trim(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: context.textColor,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Enjoy full access to ${widget.plan.name} features.',
                        style: TextStyle(
                            color: context.subTextColor, fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: widget.isLoading ? null : widget.onSubscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular || isHovered
                            ? context.primaryColor
                            : context.scaffoldBg,
                        foregroundColor: isPopular || isHovered
                            ? Colors.white
                            : context.primaryColor,
                        elevation: isHovered ? 8 : 0,
                        shadowColor: context.primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isPopular || isHovered
                              ? BorderSide.none
                              : BorderSide(
                                  color: context.primaryColor.withOpacity(0.3),
                                  width: 2),
                        ),
                      ),
                      child: isThisPlanLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isPopular || isHovered
                                      ? Colors.white
                                      : context.primaryColor,
                                ),
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)!.getStarted,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
