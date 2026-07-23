import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? initialPostType;
  const FilterBottomSheet({super.key, this.initialPostType});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<TradeController>();
      controller.fetchCategories();
      setState(() {
        double maxLim = controller.maxDistanceKm > 0.01 ? controller.maxDistanceKm : 10.0;
        distance = controller.distanceKm.clamp(0.01, maxLim);
        selectedCategories = List.from(controller.selectedCategories);
        selectedRating = controller.selectedRating;
        returnType = controller.selectedReturnType;
        selectedSort = controller.selectedSort;

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
  String selectedSort = 'Newest First';

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(35.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              child: _buildHeader(),
            ),
            Divider(color: context.dividerColor, thickness: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySection(),
                    SizedBox(height: 12.h),
                    _buildReturnTypeSection(),
                    SizedBox(height: 12.h),
                    _buildDistanceSection(),
                    SizedBox(height: 25.h),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
              decoration: BoxDecoration(
                color: context.surfaceColor,
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
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: context.textColor),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Expanded(
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.filter,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: context.textColor,
                fontFamily: FontFamily.openSans,
              ),
            ),
          ),
        ),
        SizedBox(width: 40.w), // To balance the close icon
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What are you taking", style: _sectionTitleStyle()),
        SizedBox(height: 12.h),
        Consumer<TradeController>(
          builder: (context, tradeController, child) {
            if (tradeController.isLoading &&
                tradeController.categories.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (tradeController.categories.isEmpty) {
              return Text(
                'No categories available',
                style: TextStyle(color: context.subTextColor),
              );
            }

            return Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
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
                    padding: EdgeInsets.symmetric(
                        horizontal: 22.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primaryColor
                          : context.surfaceColor,
                      borderRadius: BorderRadius.circular(10.r),
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
                        fontSize: 14.sp,
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
    final controller = context.read<TradeController>();
    double maxLim = controller.maxDistanceKm > 0.01 ? controller.maxDistanceKm : 10.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.distance, style: _sectionTitleStyle()),
        SizedBox(height: 5.h),
        Row(
          children: [
            SizedBox(width: 10.w),
            Expanded(
              child: Slider(
                padding: EdgeInsets.zero,
                value: distance.clamp(0.01, maxLim),
                min: 0.01,
                max: maxLim,
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
            SizedBox(width: 15.w),
            SizedBox(
              width: 60.w,
              child: Text(
                distance < 1.0 
                    ? '${(distance * 1000).round()} m' 
                    : '${distance == distance.toInt() ? distance.toInt() : distance.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Show items near you',
          style: TextStyle(fontSize: 12.sp, color: context.subTextColor),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    final ratings = ['4 & above', '3 & above', '2 & above', '1 & above', 'All'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.personRating, style: _sectionTitleStyle()),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: ratings.map((rating) {
            bool isSelected = selectedRating == rating;
            bool isAll = rating == 'All';
            return GestureDetector(
              onTap: () => setState(() => selectedRating = rating),
              child: Container(
                padding: isAll
                    ? EdgeInsets.symmetric(horizontal: 25.w, vertical: 8.h)
                    : EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color:
                      isSelected ? context.primaryColor : context.surfaceColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                      color: isSelected
                          ? context.primaryColor
                          : context.dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isAll) ...[
                      Icon(Icons.star,
                          color: isSelected
                              ? Colors.yellow
                              : Colors.yellow.shade700,
                          size: 16.sp),
                      SizedBox(width: 5.w),
                    ],
                    Text(
                      rating,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isSelected
                            ? context.onPrimaryColor
                            : context.subTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReturnTypeSection() {
    final returnTypes = ['Money', 'Services', 'Goods'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("What are you giving in return", style: _sectionTitleStyle()),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: returnTypes.map((type) {
            final isSelected = returnType == type;
            return GestureDetector(
              onTap: () => setState(() => returnType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                    horizontal: 22.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.primaryColor
                      : context.surfaceColor,
                  borderRadius: BorderRadius.circular(10.r),
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
                    fontSize: 14.sp,
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

              // 1. Update distance in controller
              controller.setDistance(distance);

              // 2. Update other filters
              controller.updateFilters(
                categories: selectedCategories,
                rating: selectedRating,
                returnType: returnType,
                postType: selectedPostType,
                sort: selectedSort,
              );

              // 3. Trigger fetch based on current screen context
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
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 8.h),
            ),
            child: Text(
              AppLocalizations.of(context)!.apply,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: context.onPrimaryColor,
              ),
            ),
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              context.read<TradeController>().resetFilters();
              setState(() {
                selectedCategories.clear();
                distance = 10.0;
                selectedRating = 'All';
                returnType = 'All';
                selectedSort = 'Nearest First';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  context.isDarkMode ? Colors.white10 : const Color(0xFFF0F2F5),
              foregroundColor: context.textColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 8.h),
            ),
            child: Text(
              AppLocalizations.of(context)!.reset,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostTypeSection() {
    final types = [
      {'label': AppLocalizations.of(context)!.all, 'value': 'all'},
      {'label': AppLocalizations.of(context)!.give, 'value': 'give'},
      {'label': AppLocalizations.of(context)!.take, 'value': 'take'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.postType, style: _sectionTitleStyle()),
        SizedBox(height: 10.h),
        Row(
          children: types.map((type) {
            bool isSelected =
                selectedPostType.toLowerCase() == type['value']!.toLowerCase();
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => selectedPostType = type['value']!.toLowerCase()),
                child: Container(
                  margin: EdgeInsets.only(right: type['label'] == AppLocalizations.of(context)!.take ? 0 : 10.w),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.primaryColor
                        : context.surfaceColor,
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: isSelected
                          ? context.primaryColor
                          : context.dividerColor,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    type['label']!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isSelected
                          ? context.onPrimaryColor
                          : context.subTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  TextStyle _sectionTitleStyle() {
    return TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w700,
      color: context.textColor,
      fontFamily: FontFamily.openSans,
    );
  }
}
