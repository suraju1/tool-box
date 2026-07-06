import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/features/web_ui/view/web_location_selection_dialog.dart';
import 'package:tool_bocs/features/web_ui/widgets/web_product_card.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationController = context.read<LocationController>();
      final tradeController = context.read<TradeController>();
      final authController = context.read<AuthController>();

      tradeController.setCurrentUserId(authController.currentUser?.id);

      // Sync user-selected location
      if (locationController.hasLocation) {
        tradeController.setLocation(
          locationController.latitude,
          locationController.longitude,
        );
      }

      tradeController.fetchHomePosts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TradeController>();
    final locationController = context.watch<LocationController>();

    // Proactively sync location from LocationController if it exists but is missing in TradeController
    if (locationController.hasLocation && !controller.hasLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TradeController>().setLocation(
              locationController.latitude,
              locationController.longitude,
            );
        context.read<TradeController>().fetchHomePosts(refresh: true);
      });
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildLocationHeader(context)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDistanceSection(context)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // CATEGORY OR SECTION TITLE
            Text(
              controller.selectedCategories.isNotEmpty
                  ? "Catalog: ${controller.selectedCategories.first}"
                  : "Recommended for You",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // PRODUCTS GRID
            if (controller.isHomeLoading && controller.homePosts.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (controller.homePosts.isEmpty)
              Center(
                  child:
                      Text(AppLocalizations.of(context)!.noPostsFoundNearYou))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 420,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: controller.homePosts.length,
                itemBuilder: (context, index) {
                  return WebProductCard(post: controller.homePosts[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationHeader(BuildContext context) {
    return Consumer<LocationController>(
      builder: (context, locationController, child) {
        return InkWell(
          onTap: () async {
            await WebLocationSelectionDialog.show(context);
            if (!context.mounted) return;
            context.read<TradeController>().setLocation(
                  locationController.latitude,
                  locationController.longitude,
                );
            context.read<TradeController>().fetchHomePosts();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (locationController.label ?? 'LOCATION').toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        locationController.address ?? 'Set your location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).iconTheme.color,
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDistanceSection(BuildContext context) {
    return Consumer<TradeController>(
      builder: (context, controller, child) {
        String displayDistance;
        if (controller.distanceKm < 1) {
          displayDistance = '${(controller.distanceKm * 1000).round()} m';
        } else {
          displayDistance = '${controller.distanceKm.toStringAsFixed(1)} km';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.distanceLabel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    controller.hasLocation
                        ? 'Show items near you'
                        : 'Set your location',
                    style: TextStyle(
                      fontSize: 12,
                      color: controller.hasLocation
                          ? Colors.grey.shade600
                          : Colors.orange,
                      fontWeight: controller.hasLocation
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                      width: 61), // 16px gap + 45px width for the distance text
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: controller.distanceKm.clamp(0.01, 10.0),
                        min: 0.01,
                        max: 10.0,
                        activeColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                        inactiveColor: Colors.grey.shade300,
                        thumbColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                        onChanged: (val) {
                          controller.setDistance(
                            val,
                            triggerFetch: true,
                            fetchType: 'all',
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 55,
                    child: Text(
                      displayDistance,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
