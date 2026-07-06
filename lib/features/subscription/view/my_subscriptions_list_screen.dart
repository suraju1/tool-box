import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/subscription/controller/subscription_controller.dart';
import 'package:tool_bocs/features/subscription/model/subscription_history_model.dart';
import 'package:tool_bocs/features/subscription/model/subscription_model.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';

class MySubscriptionsListScreen extends StatefulWidget {
  const MySubscriptionsListScreen({super.key});

  @override
  State<MySubscriptionsListScreen> createState() => _MySubscriptionsListScreenState();
}

class _MySubscriptionsListScreenState extends State<MySubscriptionsListScreen> {
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
          AppLocalizations.of(context)!.mySubscriptions,
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
          final subscription = controller.mySubscription;
          final history = controller.history;

          return Column(
            children: [
              if (subscription != null) _buildActivePlanHeader(context, subscription),
              SizedBox(height: 12.h),
              _buildYearFilter(context),
              Expanded(
                child: controller.isHistoryLoading
                    ? _buildLoadingList()
                    : history.isEmpty
                        ? _buildEmptyState(context, controller)
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                            itemCount: history.length,
                            separatorBuilder: (context, index) => SizedBox(height: 20.h),
                            itemBuilder: (context, index) {
                              final item = history[index];
                              return _buildInvoiceCard(
                                context,
                                item: item,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      padding: EdgeInsets.all(10.w),
      itemCount: 4,
      separatorBuilder: (context, index) => SizedBox(height: 20.h),
      itemBuilder: (context, index) => ShimmerBox(height: 180.h, width: double.infinity, radius: 20.r),
    );
  }

  Widget _buildEmptyState(BuildContext context, SubscriptionController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64.sp, color: context.subTextColor),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context)!.noSubscriptionHistory,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)!.noSubscriptionPaymentsYet,
            style: TextStyle(color: context.subTextColor),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => controller.fetchSubscriptionHistory(),
            child: Text(AppLocalizations.of(context)!.retry, style: TextStyle(color: context.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanHeader(BuildContext context, MySubscriptionData subscription) {
    final expiryDate = subscription.endDate.isNotEmpty 
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(subscription.endDate))
        : 'N/A';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              height: 150.r,
              width: 150.r,
              decoration: BoxDecoration(
                color: context.onPrimaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(15.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.currentPlan,
                      style: TextStyle(
                        color: context.onPrimaryColor.withOpacity(0.7),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: context.onPrimaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        subscription.status.toLowerCase() == 'active'
                            ? AppLocalizations.of(context)!.activeStatus
                            : (subscription.status.toLowerCase() == 'expired'
                                ? AppLocalizations.of(context)!.expiredStatus
                                : subscription.status.toUpperCase()),
                        style: TextStyle(
                          color: context.onPrimaryColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  subscription.name,
                  style: TextStyle(
                    color: context.onPrimaryColor,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  AppLocalizations.of(context)!.expiresOn(expiryDate),
                  style: TextStyle(
                    color: context.onPrimaryColor.withOpacity(0.7),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
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

    return Container(
      height: 45.h,
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        itemCount: years.length,
        separatorBuilder: (context, index) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final year = years[index];
          final isActive = controller.selectedYear == year;
          return _buildFilterChip(
            context,
            year.toString(),
            isActive: isActive,
            onTap: () => controller.setSelectedYear(year),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label,
      {required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? context.primaryColor : context.surfaceColor,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
              color:
                  isActive ? context.primaryColor : context.dividerColor),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: context.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? context.onPrimaryColor : context.subTextColor,
            fontSize: 14.sp,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context, {
    required SubscriptionHistoryItem item,
  }) {
    final statusColor = item.status.toLowerCase() == 'active' ? Colors.green : Colors.grey;
    
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
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
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
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.idHash(item.id.toString()),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: context.subTextColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        item.status.toLowerCase() == 'active'
                            ? AppLocalizations.of(context)!.activeStatus
                            : (item.status.toLowerCase() == 'expired'
                                ? AppLocalizations.of(context)!.expiredStatus
                                : item.status.toUpperCase()),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(context, AppLocalizations.of(context)!.periodLabel, period),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                          context, AppLocalizations.of(context)!.amountLabel, '₹${item.totalAmount}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars, color: context.primaryColor, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      item.remainingCredit.split('.').first,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      AppLocalizations.of(context)!.creditsRemaining,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, color: context.subTextColor),
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
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: context.subTextColor,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
      ],
    );
  }
}
