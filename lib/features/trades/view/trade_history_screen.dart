import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:tool_bocs/core/controller/shimmer_controller.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';

class TradeHistoryScreen extends StatefulWidget {
  const TradeHistoryScreen({super.key});

  @override
  State<TradeHistoryScreen> createState() => _TradeHistoryScreenState();
}

class _TradeHistoryScreenState extends State<TradeHistoryScreen> {
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTradeHistory();
    });
  }

  Future<void> _loadTradeHistory() async {
    final tradeController = context.read<TradeController>();
    await Future.wait([
      tradeController.fetchMyTrades(),
      tradeController.fetchSentResponses(),
      tradeController.fetchAllPostResponses(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tradeController = context.watch<TradeController>();

    bool isLoadingList = tradeController.isMyTradesLoading ||
        tradeController.isSentLoading ||
        tradeController.isIncomingLoading;

    bool isInitialLoad = isLoadingList && tradeController.myTradeStats == null;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      body: isInitialLoad
          ? _buildShimmer(context)
          : RefreshIndicator(
              onRefresh: _loadTradeHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTradeSummary(),
                    _buildFilters(),
                    SizedBox(height: 10.h),
                    isLoadingList ? _buildListShimmer() : _buildHistoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.scaffoldBg,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: context.textColor),
      ),
      centerTitle: true,
      title: Text(
        'Trade History',
        style: TextStyle(
          color: context.textColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
        ),
      ),
    );
  }

  Widget _buildTradeSummary() {
    final tradeController = context.watch<TradeController>();
    final stats = tradeController.myTradeStats;
    final sentOffers = tradeController.sentResponses.length;
    final receivedOffers = tradeController.postResponses.length;
    return Padding(
      padding: EdgeInsets.all(10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.tradeSummary,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: context.textColor,
              fontFamily: FontFamily.openSans,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard('${stats?.totalTrades ?? 0}', AppLocalizations.of(context)!.totalTrades,
                  Icons.handshake, Colors.blue),
              _buildSummaryCard('$sentOffers', AppLocalizations.of(context)!.sentOffers,
                  Icons.outbox_outlined, Colors.red),
              _buildSummaryCard('$receivedOffers', AppLocalizations.of(context)!.receivedOffers,
                  Icons.move_to_inbox_outlined, Colors.orange),
            ],
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String count, String label, IconData icon, Color iconColor) {
    return Container(
      width: 115.w,
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: context.dividerColor),
        boxShadow: context.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: greyColorWithOpacity0_4,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24.sp),
              SizedBox(width: 5.w),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: context.primaryColor,
                  fontFamily: FontFamily.openSans,
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.subTextColor,
              fontWeight: FontWeight.w600,
              fontFamily: FontFamily.openSans,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFilterChip('all', AppLocalizations.of(context)!.all),
          _buildFilterChip('sent', AppLocalizations.of(context)!.sentTab),
          _buildFilterChip('received', AppLocalizations.of(context)!.receivedTab),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    bool isSelected = selectedFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = filterKey);
        String postType = 'all';
        if (filterKey == 'sent') postType = 'give';
        if (filterKey == 'received') postType = 'take';
        context.read<TradeController>().fetchMyTrades(postType: postType);
      },
      child: Container(
        width: 115.w,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor : context.surfaceColor,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
              color: isSelected ? context.primaryColor : context.dividerColor),
          boxShadow: context.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: greyColorWithOpacity0_4,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: isSelected ? context.onPrimaryColor : context.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 100.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 50.sp, color: Colors.grey),
            SizedBox(height: 10.h),
            Text(
              AppLocalizations.of(context)!.noTradeHistoryFound,
              style: TextStyle(
                fontSize: 16.sp,
                color: context.subTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final tradeController = context.watch<TradeController>();

    if (selectedFilter.trim() == 'sent') {
      final responses = tradeController.sentResponses;
      if (responses.isEmpty) return _buildEmptyState();

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(10.w),
        itemCount: responses.length,
        itemBuilder: (context, index) {
          final response = responses[index];
          String title = response.postItemName ?? response.itemName ?? 'Item';
          String otherUser = response.posterName ?? 'Unknown User';
          String roleLabel = 'Poster';
          String dateStr = response.createdAt;
          try {
            final date = DateTime.parse(response.createdAt);
            dateStr = "${date.day} ${_getMonth(date.month)} ${date.year}";
          } catch (_) {}
          String imagePath = response.postItemImages.isNotEmpty 
              ? response.postItemImages[0] 
              : (response.itemImages.isNotEmpty ? response.itemImages[0] : '');

          return _buildHistoryItem(
            response.id,
            title,
            'With $otherUser ($roleLabel)',
            dateStr,
            response.status[0].toUpperCase() + response.status.substring(1),
            false,
            imagePath,
          );
        },
      );
    } else if (selectedFilter.trim() == 'received') {
      final responses = tradeController.postResponses;
      if (responses.isEmpty) return _buildEmptyState();

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(10.w),
        itemCount: responses.length,
        itemBuilder: (context, index) {
          final response = responses[index];
          String title = response.itemName ?? response.postItemName ?? 'Item';
          String otherUser = response.responderName;
          String roleLabel = 'Responder';
          String dateStr = response.createdAt;
          try {
            final date = DateTime.parse(response.createdAt);
            dateStr = "${date.day} ${_getMonth(date.month)} ${date.year}";
          } catch (_) {}
          String imagePath = response.itemImages.isNotEmpty 
              ? response.itemImages[0] 
              : (response.postItemImages.isNotEmpty ? response.postItemImages[0] : '');

          return _buildHistoryItem(
            response.id,
            title,
            'With $otherUser ($roleLabel)',
            dateStr,
            response.status[0].toUpperCase() + response.status.substring(1),
            true,
            imagePath,
          );
        },
      );
    } else {
      final trades = tradeController.myTrades;

      if (trades.isEmpty) return _buildEmptyState();

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(10.w),
        itemCount: trades.length,
        itemBuilder: (context, index) {
          final trade = trades[index];
          bool isGive = trade.postType == 'give';

          String otherUser = isGive
              ? (trade.responderName ?? 'No responder yet')
              : (trade.posterName ?? 'Unknown Giver');
          String roleLabel = isGive ? 'Taker' : 'Giver';

          String dateStr = trade.createdAt;
          try {
            final date = DateTime.parse(trade.createdAt);
            dateStr = "${date.day} ${_getMonth(date.month)} ${date.year}";
          } catch (_) {}

          return _buildHistoryItem(
            trade.id,
            trade.itemName,
            'With $otherUser ($roleLabel)',
            dateStr,
            trade.status[0].toUpperCase() + trade.status.substring(1),
            isGive,
            trade.itemImages.isNotEmpty ? trade.itemImages[0] : '',
          );
        },
      );
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildHistoryItem(int tradeId, String title, String user, String date,
      String status, bool isGive, String imagePath) {
    bool isCompleted = status == 'Completed';
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.tradeDetails,
            arguments: tradeId);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: context.dividerColor),
          boxShadow: context.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: greyColorWithOpacity0_4,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          children: [
            AppCachedImage(
              imageUrl: imagePath,
              width: 90.w,
              height: 100.w,
              radius: 10.r,
              fit: BoxFit.cover,
              errorWidget: const Icon(Icons.image_outlined),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: isGive
                              ? Colors.blue.shade400
                              : Colors.orange.shade400,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          isGive ? 'Give' : 'Take',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: context.onPrimaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14.sp, color: Colors.grey),
                      SizedBox(width: 5.w),
                      Text(user,
                          style: TextStyle(
                              fontSize: 12.sp, color: context.subTextColor)),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14.sp, color: Colors.grey),
                      SizedBox(width: 5.w),
                      Text(date,
                          style: TextStyle(
                              fontSize: 12.sp, color: context.subTextColor)),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Spacer(),
                      Icon(
                        isCompleted
                            ? Icons.check_circle_outline
                            : Icons.hourglass_top,
                        size: 14.sp,
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: isCompleted ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trade Summary Shimmer
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 24.h, width: 150.w),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    3,
                    (index) =>
                        ShimmerBox(height: 100.h, width: 115.w, radius: 15.r),
                  ),
                ),
              ],
            ),
          ),
          // Filters Shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                ShimmerBox(height: 35.h, width: 60.w, radius: 20.r),
                SizedBox(width: 8.w),
                ShimmerBox(height: 35.h, width: 80.w, radius: 20.r),
                SizedBox(width: 8.w),
                ShimmerBox(height: 35.h, width: 70.w, radius: 20.r),
                const Spacer(),
                ShimmerBox(height: 35.h, width: 80.w, radius: 20.r),
              ],
            ),
          ),
          // History List Shimmer
          _buildListShimmer(),
        ],
      ),
    );
  }

  Widget _buildListShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(10.w),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 15.h),
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Row(
            children: [
              ShimmerBox(height: 100.w, width: 90.w, radius: 10.r),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(height: 20.h, width: 120.w),
                        ShimmerBox(
                            height: 18.h, width: 50.w, radius: 8.r),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ShimmerBox(height: 14.h, width: 100.w),
                    SizedBox(height: 8.h),
                    ShimmerBox(height: 14.h, width: 130.w),
                    SizedBox(height: 8.h),
                    ShimmerBox(height: 14.h, width: 80.w),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
