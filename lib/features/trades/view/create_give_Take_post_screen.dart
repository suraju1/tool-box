import 'dart:convert';
import 'dart:io';
import 'package:tool_bocs/core/services/storage_service.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/features/location/view/location_selection_sheet.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/trades/model/category_model.dart';
import 'package:tool_bocs/features/trades/model/post_request_model.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/subscription/controller/subscription_controller.dart';
import 'package:tool_bocs/core/widgets/app_image_picker_bs.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/widgets/app_price_range_selector.dart';
import 'package:tool_bocs/core/widgets/popup_menu_arrow_shape.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';

class CreateGivePostScreen extends StatefulWidget {
  const CreateGivePostScreen({super.key});

  @override
  State<CreateGivePostScreen> createState() => _CreateGivePostScreenState();
}

class _CreateGivePostScreenState extends State<CreateGivePostScreen> {
  double _diameter = 5;
  bool _isTemporary = true;
  String _selectedCondition = 'New';
  bool _isPriceSelected = true;
  RangeValues _priceRange = const RangeValues(10, 50000);
  bool _isNegotiable = false;
  bool _notifyPartnersOnly = false;
  List<int> _selectedCollectionIds = [];
  bool _isHomemade = false;
  bool _isStoreBought = false;
  String _returnSelectedCondition = 'New';
  bool _isReturnHomemade = false;
  bool _isReturnStoreBought = false;
  CategoryModel? _selectedCategory = CategoryModel(
    id: 12,
    name: 'Goods',
    subId: 0,
    imageUrl: '',
    status: 1,
  );
  CategoryModel? _selectedReturnCategory = CategoryModel(
    id: 12,
    name: 'Goods',
    subId: 0,
    imageUrl: '',
    status: 1,
  );

  // Form Controllers
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemNoteController = TextEditingController();
  final TextEditingController _returnItemNameController =
      TextEditingController();
  final TextEditingController _returnItemDescriptionController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Validation State
  bool _showImageError = false;
  bool _showSourceError = false;
  bool _showReturnImageError = false;

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Images
  final List<XFile> _itemImages = [];
  final List<XFile> _returnItemImages = [];

  // Location
  String _pickupAddress = "Detecting location...";
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradeController>().fetchCategories();
      context.read<SubscriptionController>().fetchMySubscription();
      context.read<ProfileController>().getCollections();
      _initLocation();
      _checkAndOfferDraftRestore();
    });
  }

  Future<void> _initLocation() async {
    final locationController = context.read<LocationController>();
    await locationController.fetchLocation();
    _updateLocationFromController();
  }

  void _updateLocationFromController() {
    final locationController = context.read<LocationController>();
    if (mounted) {
      if (locationController.address != null) {
        setState(() {
          _pickupAddress = locationController.address!;
          _latitude = locationController.latitude;
          _longitude = locationController.longitude;
          _diameter = locationController.radius;
        });
      } else {
        setState(() {
          _pickupAddress = "Location not found";
        });
      }
    }
  }

  Future<void> _pickImage(bool isReturnItem) async {
    final int currentCount =
        isReturnItem ? _returnItemImages.length : _itemImages.length;
    final int remaining = 5 - currentCount;

    if (remaining <= 0) {
      ToastService.showErrorToast(context, 'Max 5 images allowed');
      return;
    }

    final List<XFile>? images = await AppImagePickerBS.show(context,
        allowMultiple: true, limit: remaining);

    if (images != null && images.isNotEmpty) {
      setState(() {
        if (isReturnItem) {
          if (_returnItemImages.length + images.length > 5) {
            final int toTake = 5 - _returnItemImages.length;
            _returnItemImages.addAll(images.take(toTake));
            ToastService.showErrorToast(
                context, 'Only first $toTake images added (Max 5 allowed)');
          } else {
            _returnItemImages.addAll(images);
          }
        } else {
          if (_itemImages.length + images.length > 5) {
            final int toTake = 5 - _itemImages.length;
            _itemImages.addAll(images.take(toTake));
            ToastService.showErrorToast(
                context, 'Only first $toTake images added (Max 5 allowed)');
          } else {
            _itemImages.addAll(images);
          }
        }
      });
    }
  }

  void _removeImage(int index, bool isReturnItem) {
    setState(() {
      if (isReturnItem) {
        _returnItemImages.removeAt(index);
      } else {
        _itemImages.removeAt(index);
      }
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemNoteController.dispose();
    _returnItemNameController.dispose();
    _returnItemDescriptionController.dispose();
    super.dispose();
  }

  bool _hasUnsavedChanges() {
    return _itemNameController.text.trim().isNotEmpty ||
        _itemNoteController.text.trim().isNotEmpty ||
        _returnItemNameController.text.trim().isNotEmpty ||
        _returnItemDescriptionController.text.trim().isNotEmpty ||
        _itemImages.isNotEmpty ||
        _returnItemImages.isNotEmpty;
  }

  Future<void> _saveDraft() async {
    if (!_hasUnsavedChanges()) return;
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final String postType = (args == 'Create Take Post') ? 'take' : 'give';

    final draftData = {
      'itemName': _itemNameController.text,
      'itemNote': _itemNoteController.text,
      'returnItemName': _returnItemNameController.text,
      'returnItemDescription': _returnItemDescriptionController.text,
      'selectedCondition': _selectedCondition,
      'returnSelectedCondition': _returnSelectedCondition,
      'isPriceSelected': _isPriceSelected,
      'priceStart': _priceRange.start,
      'priceEnd': _priceRange.end,
      'isNegotiable': _isNegotiable,
      'notifyPartnersOnly': _notifyPartnersOnly,
      'diameter': _diameter,
    };

    await StorageService.savePostDraft(postType, jsonEncode(draftData));
  }

  Future<void> _checkAndOfferDraftRestore() async {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final String postType = (args == 'Create Take Post') ? 'take' : 'give';
    final draftJson = await StorageService.getPostDraft(postType);

    if (draftJson != null && draftJson.isNotEmpty && mounted) {
      final shouldRestore = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: context.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Restore Unsaved Draft?',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                fontFamily: FontFamily.openSans,
              ),
            ),
            content: Text(
              'We found an unsaved draft from your previous session. Would you like to restore your filled form or start fresh?',
              style: TextStyle(
                color: context.subTextColor,
                fontSize: 14.sp,
                fontFamily: FontFamily.openSans,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await StorageService.clearPostDraft(postType);
                  if (context.mounted) Navigator.of(context).pop(false);
                },
                child: Text(
                  'Start New Form',
                  style: TextStyle(
                    color: context.subTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Restore Draft',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldRestore == true && mounted) {
        try {
          final Map<String, dynamic> data = jsonDecode(draftJson);
          setState(() {
            _itemNameController.text = data['itemName'] ?? '';
            _itemNoteController.text = data['itemNote'] ?? '';
            _returnItemNameController.text = data['returnItemName'] ?? '';
            _returnItemDescriptionController.text =
                data['returnItemDescription'] ?? '';
            if (data['selectedCondition'] != null) {
              _selectedCondition = data['selectedCondition'];
            }
            if (data['returnSelectedCondition'] != null) {
              _returnSelectedCondition = data['returnSelectedCondition'];
            }
            if (data['isPriceSelected'] != null) {
              _isPriceSelected = data['isPriceSelected'];
            }
            if (data['priceStart'] != null && data['priceEnd'] != null) {
              _priceRange = RangeValues(
                (data['priceStart'] as num).toDouble(),
                (data['priceEnd'] as num).toDouble(),
              );
            }
            if (data['isNegotiable'] != null) {
              _isNegotiable = data['isNegotiable'];
            }
            if (data['notifyPartnersOnly'] != null) {
              _notifyPartnersOnly = data['notifyPartnersOnly'];
            }
            if (data['diameter'] != null) {
              _diameter = (data['diameter'] as num).toDouble();
            }
          });
        } catch (_) {}
      }
    }
  }

  Future<bool> _onBackPress() async {
    await _saveDraft();
    return true;
  }

  Future<void> _handleBackPress() async {
    await _saveDraft();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await _saveDraft();
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //app bar here
              SizedBox(height: 6.h),
              _buildAppBar(),
              Divider(
                color: context.dividerColor,
                thickness: 1,
                height: 10.h,
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: context.dividerColor),
                  boxShadow: context.isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: greyColorWithOpacity0_4,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    _buildLocationSection(),
                    SizedBox(height: 20.h),
                    // _buildTradeDetailsSection(),
                    // SizedBox(height: 20.h),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              //add item details section
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: context.dividerColor),
                  boxShadow: context.isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: greyColorWithOpacity0_4,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: _buildItemDetailsSection(),
              ),
              SizedBox(height: 8.h),
              SizedBox(height: 8.h),
              //note section
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: context.dividerColor),
                  boxShadow: context.isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: greyColorWithOpacity0_4,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: _buildNoteSection(),
              ),
              SizedBox(height: 8.h),
              //return section
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: context.primaryColor.withOpacity(0.2), width: 1.5),
                  boxShadow: context.isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: context.primaryColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    _buildReturnSection(),
                    // SizedBox(height: 20.h),
                    // _buildWalletAndNotificationSection(),
                    // SizedBox(height: 30.h),
                    // _buildPostButton(),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              // Trade Details & Wallet Section
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                padding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 12.w,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: context.dividerColor),
                  boxShadow: context.isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: greyColorWithOpacity0_4,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    _buildTradeDetailsSection(),
                    SizedBox(height: 12.h),
                    Divider(color: context.dividerColor, thickness: 1),
                    SizedBox(height: 12.h),
                    _buildWalletAndNotificationSection(),
                  ],
                ),
              ),

              //build post button
              SizedBox(height: 20.h),
              _buildPostButton(),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.tradingPoint,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: FontFamily.openSans,
            color: context.textColor,
          ),
        ),
        SizedBox(height: 12.h),
        Text(AppLocalizations.of(context)!.selectArea, style: _labelStyle()),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () {
            LocationSelectionSheet.show(context,
                    isPickOnly: true, initialRadius: _diameter)
                .then((_) => _updateLocationFromController());
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: context.dividerColor),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: context.subTextColor, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${(context.watch<LocationController>().label ?? "LOCATION").toUpperCase()} - ',
                          style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                        TextSpan(
                          text: context.watch<LocationController>().address ?? _pickupAddress,
                          style: TextStyle(fontSize: 13.sp, color: context.textColor),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.change,
                  style: TextStyle(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.selectRadius,
                style: _labelStyle()),
            Text(
                _diameter < 1
                    ? '${(_diameter * 1000).toStringAsFixed(1)} m'
                    : '${_diameter.toStringAsFixed(1)} km',
                style: _labelStyle()),
          ],
        ),
        SizedBox(height: 15.h),
        Slider(
          value: _diameter,
          min: 0.01,
          max: 10.0,
          padding: EdgeInsets.zero,
          activeColor: context.primaryColor,
          inactiveColor: context.dividerColor,
          onChanged: (val) {
            setState(() => _diameter = val);
            context.read<LocationController>().setRadius(val);
          },
        ),
        SizedBox(height: 15.h),
        Text(
          AppLocalizations.of(context)!.partnersWithinRadius,
          style: TextStyle(color: context.subTextColor, fontSize: 10.sp),
        ),
      ],
    );
  }

  Widget _buildTradeDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.tradeDetails,
            style: _labelStyle(size: 14)),
        SizedBox(height: 8.h),
        Text(AppLocalizations.of(context)!.tradeType,
            style: TextStyle(color: context.subTextColor, fontSize: 12.sp)),
        SizedBox(height: 12.h),
        Container(
          height: 45.h,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Colors.white10
                : context.dividerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              _buildToggleButton('Temporary Exchange', _isTemporary, () {
                setState(() => _isTemporary = true);
              }),
              _buildToggleButton('Permanent Exchange', !_isTemporary, () {
                setState(() => _isTemporary = false);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.addPhotos,
            style: _labelStyle(size: 14)),
        SizedBox(height: 15.h),
        GestureDetector(
          onTap: _itemImages.length >= 5 ? null : () => _pickImage(false),
          child: Container(
            width: double.infinity,
            height: 150.h,
            decoration: BoxDecoration(
              color:
                  context.isDarkMode ? Colors.white10 : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                  color: _showImageError
                      ? Colors.red
                      : (_itemImages.length >= 5
                          ? Colors.grey.withOpacity(0.3)
                          : context.dividerColor),
                  style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined,
                    color: _showImageError
                        ? Colors.red
                        : (_itemImages.length >= 5 ? Colors.grey : Colors.grey),
                    size: 30.sp),
                SizedBox(height: 8.h),
                Text(
                  _showImageError
                      ? AppLocalizations.of(context)!.photoRequired
                      : (_itemImages.length >= 5
                          ? AppLocalizations.of(context)!.max5PhotosReached
                          : AppLocalizations.of(context)!.addUpTo5Photos),
                  style: TextStyle(
                      color: _showImageError
                          ? Colors.red
                          : (_itemImages.length >= 5
                              ? Colors.grey
                              : context.subTextColor),
                      fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        if (_itemImages.isNotEmpty)
          SizedBox(
            height: 80.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _itemImages.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 70.w,
                      height: 70.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        image: DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(_itemImages[index].path)
                                  as ImageProvider
                              : FileImage(File(_itemImages[index].path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -5,
                      right: -5,
                      child: GestureDetector(
                        onTap: () => _removeImage(index, false),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close,
                              size: 12, color: context.onPrimaryColor),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildItemDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.itemDetails,
            style: _labelStyle(size: 16)),
        SizedBox(height: 12.h),
        Text(AppLocalizations.of(context)!.itemName, style: _labelStyle()),
        SizedBox(height: 8.h),
        _buildTextField(AppLocalizations.of(context)!.enterItemName,
            controller: _itemNameController,
            validator: (val) => _validateRequired(val, 'Item Name')),
        SizedBox(height: 12.h),
        _buildAddPhotosSection(),
        SizedBox(height: 20.h),
        Text(AppLocalizations.of(context)!.category, style: _labelStyle()),
        SizedBox(height: 8.h),
        _buildCategoryToggleSelection(
          _selectedCategory,
          (val) => setState(() => _selectedCategory = val),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _selectedCategory?.name == 'Goods'
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20.h),
                    _buildConditionSection(),
                    SizedBox(height: 16.h),
                    _buildItemSourcesSection(),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.condition, style: _labelStyle()),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: _selectedCondition,
          icon: Icon(Icons.keyboard_arrow_down, color: context.subTextColor),
          decoration: InputDecoration(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: context.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: context.dividerColor),
            ),
            filled: true,
            fillColor: context.surfaceColor,
          ),
          items: ['New', 'Like New', 'Used'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: context.textColor,
                      fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCondition = newValue;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildItemSourcesSection() {
    String? currentSource;
    if (_isHomemade) currentSource = 'Homemade';
    if (_isStoreBought) currentSource = 'Store bought';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.itemSources, style: _labelStyle()),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: currentSource,
          hint: Text(AppLocalizations.of(context)!.selectSource,
              style: TextStyle(fontSize: 13.sp, color: context.subTextColor)),
          icon: Icon(Icons.keyboard_arrow_down, color: context.subTextColor),
          decoration: InputDecoration(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: context.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: context.dividerColor),
            ),
            filled: true,
            fillColor: context.surfaceColor,
          ),
          items: ['Homemade', 'Store bought'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: context.textColor,
                      fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _isHomemade = newValue == 'Homemade';
                _isStoreBought = newValue == 'Store bought';
              });
            }
          },
        ),
        if (_showSourceError)
          Padding(
            padding: EdgeInsets.only(top: 8.h, left: 4.w),
            child: Text(
              AppLocalizations.of(context)!.pleaseSelectAtLeastOneOption,
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.writeANote, style: _labelStyle()),
        SizedBox(height: 8.h),
        _buildTextField(AppLocalizations.of(context)!.describeYourProduct,
            maxLines: 4,
            controller: _itemNoteController,
            validator: (val) => _validateRequired(val, 'Note')),
      ],
    );
  }

  Widget _buildReturnSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.whatDoYouWantIn,
            style: _labelStyle(size: 16)),
        SizedBox(height: 16.h),
        Container(
          height: 45.h,
          decoration: BoxDecoration(
            color:
                context.isDarkMode ? Colors.white10 : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              _buildToggleButton(
                  AppLocalizations.of(context)!.priceLabel, _isPriceSelected,
                  () {
                setState(() => _isPriceSelected = true);
              }),
              _buildToggleButton(
                  AppLocalizations.of(context)!.itemLabel, !_isPriceSelected,
                  () {
                setState(() => _isPriceSelected = false);
              }),
            ],
          ),
        ),
        if (_isPriceSelected) ...[
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border.all(color: context.dividerColor),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPriceRangeSelector(
                  initialValues: _priceRange,
                  onChanged: (val) => setState(() => _priceRange = val),
                ),
                SizedBox(height: 25.h),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: _isNegotiable,
                        activeColor: Colors.green,
                        onChanged: (val) => setState(() => _isNegotiable = val),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(AppLocalizations.of(context)!.negotiable,
                        style: TextStyle(
                            color: context.subTextColor, fontSize: 13.sp)),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          _buildReturnItemDetailsSection(),
        ]
      ],
    );
  }

  Widget _buildReturnItemDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Text(AppLocalizations.of(context)!.itemName, style: _labelStyle()),
        SizedBox(height: 8.h),
        _buildTextField(AppLocalizations.of(context)!.enterItemName,
            controller: _returnItemNameController,
            validator: (val) => _validateRequired(val, 'Return Item Name')),
        SizedBox(height: 20.h),
        // Return Item Images
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.addPhotos,
                style: _labelStyle(size: 14)),
            SizedBox(height: 15.h),
            GestureDetector(
              onTap:
                  _returnItemImages.length >= 5 ? null : () => _pickImage(true),
              child: Container(
                width: double.infinity,
                height: 150.h,
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: _showReturnImageError
                          ? Colors.red
                          : (_returnItemImages.length >= 5
                              ? Colors.grey.withOpacity(0.3)
                              : context.dividerColor),
                      style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        color: _showReturnImageError
                            ? Colors.red
                            : (_returnItemImages.length >= 5
                                ? Colors.grey
                                : Colors.grey),
                        size: 30.sp),
                    SizedBox(height: 8.h),
                    Text(
                      _showReturnImageError
                          ? AppLocalizations.of(context)!.photoRequired
                          : (_returnItemImages.length >= 5
                              ? AppLocalizations.of(context)!.max5PhotosReached
                              : AppLocalizations.of(context)!.addUpTo5Photos),
                      style: TextStyle(
                          color: _showReturnImageError
                              ? Colors.red
                              : (_returnItemImages.length >= 5
                                  ? Colors.grey
                                  : context.subTextColor),
                          fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            if (_returnItemImages.isNotEmpty)
              SizedBox(
                height: 80.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _returnItemImages.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 70.w,
                          height: 70.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            image: DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(_returnItemImages[index].path)
                                      as ImageProvider
                                  : FileImage(
                                      File(_returnItemImages[index].path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -5,
                          right: -5,
                          child: GestureDetector(
                            onTap: () => _removeImage(index, true),
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close,
                                  size: 12, color: context.onPrimaryColor),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
        SizedBox(height: 20.h),
        Text(AppLocalizations.of(context)!.category, style: _labelStyle()),
        SizedBox(height: 8.h),
        _buildCategoryToggleSelection(
          _selectedReturnCategory,
          (val) => setState(() => _selectedReturnCategory = val),
        ),
        SizedBox(height: 16.h),
        Text(AppLocalizations.of(context)!.condition, style: _labelStyle()),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildReturnConditionChip('New'),
            _buildReturnConditionChip('Like New'),
            _buildReturnConditionChip('Used'),
          ],
        ),
        SizedBox(height: 16.h),
        Text(AppLocalizations.of(context)!.description, style: _labelStyle()),
        SizedBox(height: 8.h),
        _buildTextField(AppLocalizations.of(context)!.describeYourProduct,
            maxLines: 4,
            controller: _returnItemDescriptionController,
            validator: (val) =>
                _validateRequired(val, 'Return Item Description')),
        SizedBox(height: 12.h),
        Row(
          children: [
            Row(
              children: [
                SizedBox(
                  height: 24.w,
                  width: 24.w,
                  child: Checkbox(
                    value: _isReturnHomemade,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setState(() {
                        _isReturnHomemade = val ?? false;
                        if (_isReturnHomemade) _isReturnStoreBought = false;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Homemade',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: FontFamily.openSans,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(width: 20.w),
            Row(
              children: [
                SizedBox(
                  height: 24.w,
                  width: 24.w,
                  child: Checkbox(
                    value: _isReturnStoreBought,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setState(() {
                        _isReturnStoreBought = val ?? false;
                        if (_isReturnStoreBought) _isReturnHomemade = false;
                      });
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Store bought',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: FontFamily.openSans,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildReturnConditionChip(String label) {
    bool isSelected = _returnSelectedCondition == label;
    return GestureDetector(
      onTap: () => setState(() => _returnSelectedCondition = label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor : context.surfaceColor,
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
              color: isSelected ? context.primaryColor : context.dividerColor),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: context.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? context.onPrimaryColor : context.subTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildWalletAndNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: greyColorWithOpacity0_4,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.wallet,
                  style: _labelStyle(size: 14)),
              SizedBox(height: 8.h),
              Consumer<SubscriptionController>(
                builder: (context, subscriptionController, child) {
                  final subscription = subscriptionController.mySubscription;
                  final remainingCredit =
                      subscription?.remainingCredit.split('.').first ?? '0';
                  final postPrice = subscription?.postPrice ?? '0';

                  return Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              color: context.primaryColor, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text(
                              AppLocalizations.of(context)!
                                  .creditsPerTrade(postPrice.toString()),
                              style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(
                              AppLocalizations.of(context)!
                                  .creditsLeft(remainingCredit.toString()),
                              style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: context.primaryColor)),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 6.h),
              Divider(color: context.dividerColor),
              SizedBox(height: 6.h),
              Text(AppLocalizations.of(context)!.notificationSettings,
                  style: _labelStyle(size: 14)),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.notifySavedUsersOnly,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13.sp)),
                        SizedBox(height: 4.h),
                        Text(
                          AppLocalizations.of(context)!.onlyPartnersYou,
                          style: TextStyle(
                              color: context.subTextColor, fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _notifyPartnersOnly,
                    activeColor: Colors.green,
                    padding: EdgeInsets.all(8.w),
                    onChanged: (val) {
                      setState(() {
                        _notifyPartnersOnly = val;
                        if (!val) {
                          _selectedCollectionIds.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
              if (_notifyPartnersOnly) ...[
                SizedBox(height: 12.h),
                Consumer<ProfileController>(
                  builder: (context, profileCtrl, child) {
                    if (profileCtrl.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (profileCtrl.collections.isEmpty) {
                      return Text(
                        "No saved collections found.",
                        style: TextStyle(color: Colors.red, fontSize: 12.sp),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Select Collections",
                            style: TextStyle(
                                fontSize: 13.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 4.h,
                          children: profileCtrl.collections.map((collection) {
                            final isSelected =
                                _selectedCollectionIds.contains(collection.id);
                            return FilterChip(
                              label: Text(collection.name ?? 'Unknown'),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCollectionIds.add(collection.id);
                                  } else {
                                    _selectedCollectionIds
                                        .remove(collection.id);
                                  }
                                });
                              },
                              selectedColor: Colors.green.withOpacity(0.2),
                              checkmarkColor: Colors.green,
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostButton() {
    return Consumer<TradeController>(
      builder: (context, tradeController, child) {
        return SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: tradeController.isPostCreating ? null : _onPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleManager.roundedRadius(10.r),
              elevation: 0,
            ),
            child: tradeController.isPostCreating
                ? SizedBox(
                    height: 20.h,
                    width: 20.h,
                    child: CircularProgressIndicator(
                      color: context.onPrimaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.postItem,
                    style: TextStyle(
                      color: context.onPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _onPost() async {
    setState(() {
      _showImageError = false;
      _showSourceError = false;
      _showReturnImageError = false;
    });

    bool isValid = true;

    // Validate Form Fields (Name, Note, Category, Return Name/Description)
    if (!_formKey.currentState!.validate()) {
      isValid = false;
    }

    // Validate Category
    if (_selectedCategory == null) {
      ToastService.showErrorToast(
          context, 'Please select a category for the item');
      isValid = false;
    }

    // Validate Images
    if (_itemImages.isEmpty) {
      setState(() => _showImageError = true);
      // ToastService.showErrorToast(context, 'Please add at least 1 photo of the item');
      isValid = false;
    }

    // Validate Source (Homemade/Store Bought)
    if (!_isHomemade && !_isStoreBought) {
      setState(() => _showSourceError = true);
      isValid = false;
    }

    // Validate Return Item Details (if applicable)
    if (!_isPriceSelected) {
      if (_selectedReturnCategory == null) {
        ToastService.showErrorToast(
            context, 'Please select a category for the return item');
        isValid = false;
      }
      if (_returnItemImages.isEmpty) {
        setState(() => _showReturnImageError = true);
        // ToastService.showErrorToast(context, 'Please add at least 1 photo of the return item');
        isValid = false;
      }
    }

    if (_latitude == null || _longitude == null) {
      ToastService.showErrorToast(context, 'Location not detected');
      isValid = false;
    }

    if (!isValid) {
      if (_showImageError || _showReturnImageError || _showSourceError) {
        ToastService.showErrorToast(context, 'Please fill all required fields');
      }
      return;
    }

    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) {
      ToastService.showErrorToast(
          context, 'User not found. Please login again.');
      return;
    }

    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final String title = args == 'Create Take Post'
        ? AppLocalizations.of(context)!.createTakePost
        : AppLocalizations.of(context)!.createGivePost;
    final String postType =
        title.toLowerCase().contains('take') ? 'take' : 'give';

    // Create Request
    final request = PostRequestModel(
      userId: userId,
      pickupArea: _pickupAddress,
      latitude: _latitude!,
      longitude: _longitude!,
      areaDiameter: _diameter,
      tradeType: _isTemporary ? "Temporary" : "Permanent",
      itemName: _itemNameController.text,
      itemCategory: _selectedCategory!.name,
      itemCategoryId: _selectedCategory!.id,
      itemCondition: _selectedCondition,
      itemNote: _itemNoteController.text,
      itemSource: _isHomemade ? "Homemade" : "Store bought",
      returnType: _isPriceSelected ? "Price" : "Item",
      priceMin: _isPriceSelected ? _priceRange.start : null,
      priceMax: _isPriceSelected ? _priceRange.end : null,
      isNegotiable: _isNegotiable,
      walletCredits: (double.tryParse(context
                      .read<SubscriptionController>()
                      .mySubscription
                      ?.postPrice ??
                  '0') ??
              0)
          .toInt(),
      notifyPartnersOnly: _notifyPartnersOnly,
      notifyCollectionIds: _notifyPartnersOnly ? _selectedCollectionIds : null,
      postType: postType,
      itemImages: _itemImages,
      returnItemImages: _isPriceSelected ? [] : _returnItemImages,
      returnItemName:
          (!_isPriceSelected && _returnItemNameController.text.isNotEmpty)
              ? _returnItemNameController.text
              : null,
      returnItemCategory:
          _isPriceSelected ? null : _selectedReturnCategory?.name,
      returnItemCategoryId:
          _isPriceSelected ? null : _selectedReturnCategory?.id,
      returnItemCondition: _isPriceSelected ? null : _returnSelectedCondition,
      returnItemNote: (!_isPriceSelected &&
              _returnItemDescriptionController.text.isNotEmpty)
          ? _returnItemDescriptionController.text
          : null,
      returnItemDescription: (!_isPriceSelected &&
              _returnItemDescriptionController.text.isNotEmpty)
          ? _returnItemDescriptionController.text
          : null,
      returnItemSource: _isPriceSelected
          ? null
          : (_isReturnHomemade
              ? 'Homemade'
              : (_isReturnStoreBought ? 'Store bought' : null)),
    );

    final success = await context.read<TradeController>().createPost(request);

    if (success && mounted) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      final String postType = (args == 'Create Take Post') ? 'take' : 'give';
      await StorageService.clearPostDraft(postType);
      ToastService.showSuccessToast(context, 'Giveaway created successfully!');
      Navigator.pop(context);
    } else if (mounted) {
      if (context.read<TradeController>().isNoSubscriptionError) {
        _showNoSubscriptionDialog();
      } else {
        ToastService.showErrorToast(
            context,
            context.read<TradeController>().errorMessage ??
                "Failed to create post");
      }
    }
  }

  void _showNoSubscriptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: context.surfaceColor,
        title: Row(
          children: [
            Icon(Icons.stars, color: context.primaryColor, size: 22.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.activeSubscriptionRequired,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                  fontFamily: FontFamily.openSans,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.noActiveSubscriptionMessage,
          style: TextStyle(
            fontSize: 14.sp,
            color: context.subTextColor,
            fontFamily: FontFamily.openSans,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: context.subTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.choosePlan).then((_) {
                // Refresh subscription status when returning
                if (mounted) {
                  context.read<SubscriptionController>().fetchMySubscription();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              AppLocalizations.of(context)!.buySubscription,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint,
      {IconData? prefixIcon,
      int maxLines = 1,
      TextEditingController? controller,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: context.surfaceColor,
        hintText: hint,
        hintStyle: TextStyle(color: context.subTextColor, fontSize: 13.sp),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: context.subTextColor, size: 20.sp)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: context.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: context.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: context.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
    );
  }

  Widget _buildCategoryToggleSelection(
      CategoryModel? currentValue, Function(CategoryModel) onSelected) {
    return Consumer<TradeController>(
      builder: (context, tradeController, child) {
        Widget buildBtn(String label) {
          bool isSelected = currentValue?.name == label;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                // Find category from API or fallback to default
                CategoryModel cat = tradeController.categories.firstWhere(
                  (c) => c.name.toLowerCase() == label.toLowerCase(),
                  orElse: () => CategoryModel(
                    id: label == 'Goods' ? 12 : (label == 'Services' ? 13 : 14),
                    name: label,
                    subId: 0,
                    imageUrl: '',
                    status: 1,
                  ),
                );
                onSelected(cat);
              },
              child: Container(
                height: 45.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isSelected ? context.primaryColor : context.surfaceColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected
                        ? context.primaryColor
                        : context.dividerColor,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? context.onPrimaryColor
                        : context.subTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          );
        }

        return Row(
          children: [
            buildBtn('Goods'),
            SizedBox(width: 10.w),
            buildBtn('Services'),
            SizedBox(width: 10.w),
            buildBtn('Money'),
          ],
        );
      },
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? context.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? context.onPrimaryColor : context.subTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionChip(String label) {
    bool isSelected = _selectedCondition == label;

    return Flexible(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCondition = label),
        child: Container(
          height: 45.h,
          width: 90.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? context.primaryColor : context.surfaceColor,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? context.primaryColor : context.dividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? context.onPrimaryColor : context.subTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle({double size = 12}) {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: size.sp,
      fontFamily: FontFamily.openSans,
      color: context.textColor,
    );
  }

  Widget _buildAppBar() {
    // take teh argument data
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final String title = args == 'Create Take Post'
        ? AppLocalizations.of(context)!.createTakePost
        : AppLocalizations.of(context)!.createGivePost;
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(top: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon:
                Icon(Icons.arrow_back_ios, color: context.textColor, size: 22),
            onPressed: _handleBackPress,
          ),
          SizedBox(width: 45.w),
          Center(
            child: Text(
              title,
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                fontFamily: FontFamily.openSans,
              ),
            ),
          ),
          const Spacer(),
          PopupMenuButton<void>(
            offset: const Offset(-200, 45),
            shape: PopupMenuArrowShape(borderRadius: 12.r),
            color: Colors.white,
            elevation: 4,
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                enabled: false,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppLocalizations.of(context)!.askSomeoneToTake,
                      AppLocalizations.of(context)!.postVisibleToTakers,
                      AppLocalizations.of(context)!.inYourSelectedArea,
                    ]
                        .map((text) => Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: const Color(0xFF111311),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: FontFamily.openSans,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              height: 40.h,
              width: 40.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF5F7F9),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: context.isDarkMode
                      ? Colors.white24
                      : Colors.grey.shade300,
                ),
              ),
              child: Icon(
                Icons.info_outline,
                color: context.primaryColor,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoundedRectangleManager {
  static RoundedRectangleBorder roundedRadius(double radius) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}
