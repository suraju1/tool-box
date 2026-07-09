import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/subscription/controller/subscription_controller.dart';
import 'package:tool_bocs/features/subscription/model/subscription_history_model.dart';
import 'package:tool_bocs/features/subscription/model/subscription_model.dart';
import 'package:tool_bocs/features/web_ui/widgets/web_screen_header.dart';

class WebMySubscriptionsListScreen extends StatefulWidget {
  const WebMySubscriptionsListScreen({super.key});

  @override
  State<WebMySubscriptionsListScreen> createState() =>
      _WebMySubscriptionsListScreenState();
}

class _WebMySubscriptionsListScreenState
    extends State<WebMySubscriptionsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<SubscriptionController>();
      controller.fetchSubscriptionHistory();
      if (controller.mySubscription == null) {
        controller.fetchMySubscription();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar:
          WebScreenHeader(title: AppLocalizations.of(context)!.paymentHistory),
      body: Consumer<SubscriptionController>(
        builder: (context, controller, child) {
          final subscription = controller.mySubscription;
          final history = controller.history;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    if (subscription != null) ...[
                      _buildActivePlanHeader(context, subscription),
                      const SizedBox(height: 32),
                    ],
                    _buildYearFilter(context),
                    const SizedBox(height: 24),
                    if (controller.isHistoryLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: _buildEmptyState(context, controller),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return _buildInvoiceCard(context, item: item);
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, SubscriptionController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80, color: context.subTextColor),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noSubscriptionHistory,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.textColor),
          ),
          const SizedBox(height: 12),
          Text(
            'You haven\'t made any subscription payments yet.',
            style: TextStyle(fontSize: 16, color: context.subTextColor),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => controller.fetchSubscriptionHistory(),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(AppLocalizations.of(context)!.refresh,
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanHeader(
      BuildContext context, MySubscriptionData subscription) {
    final expiryDate = subscription.endDate.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(subscription.endDate))
        : 'N/A';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: context.onPrimaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.currentPlan1,
                      style: TextStyle(
                        color: context.onPrimaryColor.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.onPrimaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        subscription.status.toUpperCase(),
                        style: TextStyle(
                          color: context.onPrimaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  subscription.name,
                  style: TextStyle(
                    color: context.onPrimaryColor,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Expires on $expiryDate',
                  style: TextStyle(
                    color: context.onPrimaryColor.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearFilter(BuildContext context) {
    final controller = context.watch<SubscriptionController>();
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    return Wrap(
      spacing: 16,
      children: years.map((year) {
        final isActive = controller.selectedYear == year;
        return _buildFilterChip(
          context,
          year.toString(),
          isActive: isActive,
          onTap: () => controller.setSelectedYear(year),
        );
      }).toList(),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label,
      {required bool isActive, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? context.primaryColor : context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isActive
                    ? context.primaryColor
                    : context.dividerColor.withOpacity(0.5)),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: context.primaryColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? context.onPrimaryColor : context.subTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context,
      {required SubscriptionHistoryItem item}) {
    final statusColor =
        item.status.toLowerCase() == 'active' ? Colors.green : Colors.grey;

    final startDate = item.startDate.isNotEmpty
        ? DateFormat('dd MMM').format(DateTime.parse(item.startDate))
        : '';
    final endDate = item.endDate.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(item.endDate))
        : '';
    final period = '$startDate - $endDate';

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID #${item.id}',
                          style: TextStyle(
                              fontSize: 14, color: context.subTextColor),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildInfoItem(context, 'PERIOD', period)),
                    Expanded(
                        child: _buildInfoItem(
                            context, 'AMOUNT', '₹${item.totalAmount}')),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars, color: context.primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      item.remainingCredit.split('.').first,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: context.textColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.creditsRemaining,
                      style: TextStyle(
                          fontSize: 14,
                          color: context.primaryColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.subTextColor,
              letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textColor),
        ),
      ],
    );
  }
}
