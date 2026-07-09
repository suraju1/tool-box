import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:tool_bocs/core/controller/shimmer_controller.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/features/web_ui/widgets/web_screen_header.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';

class WebTradeHistoryScreen extends StatefulWidget {
  const WebTradeHistoryScreen({super.key});

  @override
  State<WebTradeHistoryScreen> createState() => _WebTradeHistoryScreenState();
}

class _WebTradeHistoryScreenState extends State<WebTradeHistoryScreen> {
  String selectedFilter = ' All ';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTradeHistory();
    });
  }

  Future<void> _loadTradeHistory() async {
    final tradeController = context.read<TradeController>();
    final locationController = context.read<LocationController>();

    if (locationController.hasLocation) {
      tradeController.setLocation(
        locationController.latitude,
        locationController.longitude,
      );
    }

    await Future.wait([
      tradeController.fetchMyTrades(),
      tradeController.fetchSentResponses(),
      tradeController.fetchAllPostResponses(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final shimmer = context.watch<ShimmerController>();
    final tradeController = context.watch<TradeController>();

    bool isLoading = shimmer.isLoading ||
        tradeController.isMyTradesLoading ||
        tradeController.isSentLoading ||
        tradeController.isIncomingLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebScreenHeader(
                  title: AppLocalizations.of(context)!.tradeHistory),
              Expanded(
                child: isLoading
                    ? _buildShimmer(context)
                    : RefreshIndicator(
                        onRefresh: _loadTradeHistory,
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            _buildTradeSummary(),
                            const SizedBox(height: 32),
                            _buildFilters(),
                            const SizedBox(height: 24),
                            _buildHistoryList(),
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

  Widget _buildTradeSummary() {
    final tradeController = context.watch<TradeController>();
    final stats = tradeController.myTradeStats;
    final sentOffers = tradeController.sentResponses.length;
    final receivedOffers = tradeController.postResponses.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.tradeSummary,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSummaryCard(
                '${stats?.totalTrades ?? 0}',
                AppLocalizations.of(context)!.totalTrades,
                Icons.handshake,
                Colors.blue),
            const SizedBox(width: 24),
            _buildSummaryCard(
                '$sentOffers',
                AppLocalizations.of(context)!.sentOffers,
                Icons.outbox_outlined,
                Colors.red),
            const SizedBox(width: 24),
            _buildSummaryCard(
                '$receivedOffers',
                AppLocalizations.of(context)!.receivedOffers,
                Icons.move_to_inbox_outlined,
                Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String count, String label, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: greyColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        _buildFilterChip('all', ' ${AppLocalizations.of(context)!.all} '),
        const SizedBox(width: 12),
        _buildFilterChip('sent', ' ${AppLocalizations.of(context)!.sentTab} '),
        const SizedBox(width: 12),
        _buildFilterChip(
            'received', ' ${AppLocalizations.of(context)!.receivedTab} '),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? context.primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isSelected
                  ? context.primaryColor
                  : greyColor.withOpacity(0.3)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final trades = context.watch<TradeController>().myTrades;

    if (trades.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 100),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noTradeHistoryFound,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 600,
        mainAxisExtent: 140,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: greyColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AppCachedImage(
              imageUrl: imagePath,
              width: 100,
              height: 100,
              radius: 12,
              fit: BoxFit.cover,
              errorWidget: Icon(Icons.image_outlined,
                  color: Colors.grey.shade400, size: 40),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isGive
                              ? Colors.blue.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isGive
                                  ? Colors.blue.shade200
                                  : Colors.orange.shade200),
                        ),
                        child: Text(
                          isGive ? 'Give' : 'Take',
                          style: TextStyle(
                            fontSize: 12,
                            color: isGive
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        user,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(date,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade600)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle_outline
                                : Icons.hourglass_top,
                            size: 16,
                            color: isCompleted ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const ShimmerBox(height: 28, width: 200),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 2 ? 24.0 : 0),
                child: const ShimmerBox(
                    height: 120, width: double.infinity, radius: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: const [
            ShimmerBox(height: 48, width: 80, radius: 30),
            SizedBox(width: 12),
            ShimmerBox(height: 48, width: 100, radius: 30),
            SizedBox(width: 12),
            ShimmerBox(height: 48, width: 100, radius: 30),
          ],
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 600,
            mainAxisExtent: 140,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: 6,
          itemBuilder: (context, index) =>
              const ShimmerBox(height: 140, width: double.infinity, radius: 16),
        ),
      ],
    );
  }
}
