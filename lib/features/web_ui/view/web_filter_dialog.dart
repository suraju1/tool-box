import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';

class WebFilterDialog extends StatefulWidget {
  final String? initialPostType;
  const WebFilterDialog({super.key, this.initialPostType});

  static Future<void> show(BuildContext context, {String? initialPostType}) {
    return showDialog(
      context: context,
      builder: (context) => WebFilterDialog(initialPostType: initialPostType),
    );
  }

  @override
  State<WebFilterDialog> createState() => _WebFilterDialogState();
}

class _WebFilterDialogState extends State<WebFilterDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<TradeController>();
      controller.fetchCategories();
      setState(() {
        distance = controller.distanceKm.clamp(0.01, 10.0);
        selectedCategories = List.from(controller.selectedCategories);
        selectedRating = controller.selectedRating;
        returnType = controller.selectedReturnType;

        if (widget.initialPostType != null) {
          selectedPostType = widget.initialPostType!;
        } else {
          selectedPostType = controller.selectedPostType;
        }
      });
    });
  }

  List<String> selectedCategories = [];
  double distance = 10.0;
  String selectedRating = 'All';
  String returnType = 'All';
  String selectedPostType = 'all';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: context.surfaceColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildHeader(),
            ),
            Divider(color: context.dividerColor, thickness: 1),
            Flexible(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySection(),
                    const SizedBox(height: 20),
                    _buildDistanceSection(),
                    const SizedBox(height: 20),
                    _buildReturnTypeSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: context.isDarkMode
                        ? Colors.black54
                        : context.dividerColor.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.filter,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.textColor,
                fontFamily: FontFamily.openSans,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: context.textColor, size: 28),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What are you taking",
            style: _sectionTitleStyle()),
        const SizedBox(height: 12),
        Consumer<TradeController>(
          builder: (context, tradeController, child) {
            if (tradeController.isLoading &&
                tradeController.categories.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (tradeController.categories.isEmpty) {
              return Text(
                AppLocalizations.of(context)!.noCategoriesAvailable,
                style: TextStyle(color: context.subTextColor, fontSize: 14),
              );
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: tradeController.categories.map((category) {
                final isSelected = selectedCategories.contains(category.name);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedCategories.remove(category.name);
                      } else {
                        selectedCategories.add(category.name);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primaryColor
                          : context.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? context.primaryColor
                            : context.isDarkMode
                                ? Colors.white24
                                : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? context.onPrimaryColor
                            : context.textColor,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.distance,
            style: _sectionTitleStyle()),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Slider(
                padding: EdgeInsets.zero,
                value: distance,
                min: 0.01,
                max: 10.0,
                activeColor: context.primaryColor,
                inactiveColor:
                    context.isDarkMode ? Colors.white12 : Colors.grey.shade200,
                thumbColor: context.primaryColor,
                onChanged: (val) {
                  setState(() => distance = val);
                  context.read<TradeController>().setDistance(
                        val,
                        triggerFetch: true,
                        fetchType: selectedPostType,
                      );
                },
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 70,
              child: Text(
                distance < 1.0
                    ? '${(distance * 1000).round()} m'
                    : '${distance == distance.toInt() ? distance.toInt() : distance.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
              ),
            ),
          ],
        ),
        Text(
          AppLocalizations.of(context)!.showItemsNearYou,
          style: TextStyle(fontSize: 14, color: context.subTextColor),
        ),
      ],
    );
  }

  Widget _buildReturnTypeSection() {
    final returnTypes = ['Money', 'Services', 'Goods'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What are you giving in return",
            style: _sectionTitleStyle()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: returnTypes.map((type) {
            final isSelected = returnType == type;
            return GestureDetector(
              onTap: () => setState(() => returnType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? context.primaryColor : context.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? context.primaryColor
                        : context.isDarkMode
                            ? Colors.white24
                            : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? context.onPrimaryColor : context.textColor,
                    fontFamily: FontFamily.openSans,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              final controller = context.read<TradeController>();

              controller.setDistance(distance);
              controller.updateFilters(
                categories: selectedCategories,
                rating: selectedRating,
                returnType: returnType,
                postType: selectedPostType,
              );

              if (widget.initialPostType == 'give') {
                controller.fetchGivePosts(refresh: true);
              } else if (widget.initialPostType == 'take') {
                controller.fetchTakePosts(refresh: true);
              } else {
                controller.fetchHomePosts(refresh: true);
              }

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              AppLocalizations.of(context)!.apply,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.onPrimaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              context.read<TradeController>().resetFilters();
              setState(() {
                selectedCategories.clear();
                distance = 10.0;
                selectedRating = 'All';
                returnType = 'All';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  context.isDarkMode ? Colors.white10 : const Color(0xFFF0F2F5),
              foregroundColor: context.textColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              AppLocalizations.of(context)!.reset,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _sectionTitleStyle() {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: context.textColor,
      fontFamily: FontFamily.openSans,
    );
  }
}
