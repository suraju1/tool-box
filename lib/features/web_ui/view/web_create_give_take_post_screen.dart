import 'dart:convert';
import 'dart:io';
import 'package:tool_bocs/core/services/storage_service.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:tool_bocs/features/web_ui/view/web_image_picker_dialog.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/web_ui/view/web_price_range_selector.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';

class WebCreateGivePostScreen extends StatefulWidget {
  const WebCreateGivePostScreen({super.key});

  @override
  State<WebCreateGivePostScreen> createState() =>
      _WebCreateGivePostScreenState();
}

class _WebCreateGivePostScreenState extends State<WebCreateGivePostScreen> {
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

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemNoteController = TextEditingController();
  final TextEditingController _returnItemNameController =
      TextEditingController();
  final TextEditingController _returnItemDescriptionController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _showImageError = false;
  bool _showSourceError = false;
  bool _showReturnImageError = false;

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  final List<XFile> _itemImages = [];
  final List<XFile> _returnItemImages = [];

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

    final List<XFile>? images = await WebImagePickerDialog.show(context,
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
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Restore Unsaved Draft?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: const Text(
              'We found an unsaved draft from your previous session. Would you like to restore your filled form or start fresh?',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await StorageService.clearPostDraft(postType);
                  if (context.mounted) Navigator.of(context).pop(false);
                },
                child: const Text(
                  'Start New Form',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Restore Draft',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDecoration(),
                    child: _buildLocationSection(),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDecoration(),
                    child: _buildItemDetailsSection(),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          width: 1.5),
                    ),
                    child: _buildReturnSection(),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _buildTradeDetailsSection(),
                        const SizedBox(height: 24),
                        Divider(
                            color: Theme.of(context).dividerColor,
                            thickness: 1),
                        const SizedBox(height: 24),
                        _buildWalletAndNotificationSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPostButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      border:
          Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.tradingPoint,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: FontFamily.openSans),
        ),
        const SizedBox(height: 20),
        Text(AppLocalizations.of(context)!.selectArea, style: _labelStyle()),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            LocationSelectionSheet.show(context,
                    isPickOnly: true, initialRadius: _diameter)
                .then((_) => _updateLocationFromController());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Colors.grey, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${(context.watch<LocationController>().label ?? "LOCATION").toUpperCase()} - ',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: context.watch<LocationController>().address ?? _pickupAddress,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.change,
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.selectRadius,
                style: _labelStyle()),
            Text(
                _diameter < 1
                    ? '${(_diameter * 1000).round()} m'
                    : '${_diameter.toStringAsFixed(1)} km',
                style: _labelStyle()),
          ],
        ),
        const SizedBox(height: 16),
        Slider(
          value: _diameter.clamp(0.01, 10.0),
          min: 0.01,
          max: 10.0,
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Theme.of(context).dividerColor,
          onChanged: (val) {
            setState(() => _diameter = val);
            context.read<LocationController>().setRadius(val);
          },
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.partnersWithinRadius,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTradeDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.tradeDetails,
            style: _labelStyle(size: 18)),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context)!.tradeType,
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        const Text(
          'Temporary: Stays for 48 hours (make it active for free)',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Text(
          'Permanent: Permanently stays on account until you remove it',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
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
            style: _labelStyle(size: 16)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _itemImages.length >= 5 ? null : () => _pickImage(false),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _showImageError
                      ? Colors.red
                      : (_itemImages.length >= 5
                          ? Colors.grey.withOpacity(0.3)
                          : Theme.of(context).dividerColor),
                  style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined,
                    color: _showImageError ? Colors.red : Colors.grey,
                    size: 40),
                const SizedBox(height: 12),
                Text(
                  _showImageError
                      ? 'Photo required'
                      : (_itemImages.length >= 5
                          ? 'Max 5 photos reached'
                          : 'Add up to 5 photos'),
                  style: TextStyle(
                      color: _showImageError ? Colors.red : Colors.grey,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_itemImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _itemImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
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
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: () => _removeImage(index, false),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child:
                              Icon(Icons.close, size: 14, color: Colors.white),
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
            style: _labelStyle(size: 20)),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.itemName, style: _labelStyle()),
        const SizedBox(height: 12),
        _buildTextField('Enter item name',
            controller: _itemNameController,
            validator: (val) => _validateRequired(val, 'Item Name')),
        const SizedBox(height: 24),
        _buildAddPhotosSection(),
        const SizedBox(height: 32),
        Text(AppLocalizations.of(context)!.category, style: _labelStyle()),
        const SizedBox(height: 12),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(AppLocalizations.of(context)!.condition,
                        style: _labelStyle()),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      items: ['New', 'Like New', 'Used'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
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
                    const SizedBox(height: 24),
                    Text(AppLocalizations.of(context)!.itemSources,
                        style: _labelStyle()),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _isHomemade
                          ? 'Homemade'
                          : (_isStoreBought ? 'Store bought' : null),
                      hint: Text(AppLocalizations.of(context)!.selectSource,
                          style: const TextStyle(fontSize: 14)),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      items: ['Homemade', 'Store bought'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
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
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            AppLocalizations.of(context)!
                                .pleaseSelectAtLeastOne,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 14)),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.writeANote, style: _labelStyle()),
        const SizedBox(height: 12),
        _buildTextField('Describe your product here...',
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
            style: _labelStyle(size: 20)),
        const SizedBox(height: 24),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildToggleButton('Price', _isPriceSelected, () {
                setState(() => _isPriceSelected = true);
              }),
              _buildToggleButton('Item', !_isPriceSelected, () {
                setState(() => _isPriceSelected = false);
              }),
            ],
          ),
        ),
        if (_isPriceSelected) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WebPriceRangeSelector(
                  initialValues: _priceRange,
                  onChanged: (val) => setState(() => _priceRange = val),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Switch(
                      value: _isNegotiable,
                      activeColor: Colors.green,
                      onChanged: (val) => setState(() => _isNegotiable = val),
                    ),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.negotiable,
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
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
        const SizedBox(height: 32),
        Text(AppLocalizations.of(context)!.itemName, style: _labelStyle()),
        const SizedBox(height: 12),
        _buildTextField('Enter item name',
            controller: _returnItemNameController,
            validator: (val) => _validateRequired(val, 'Return Item Name')),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.addPhotos,
                style: _labelStyle(size: 16)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap:
                  _returnItemImages.length >= 5 ? null : () => _pickImage(true),
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _showReturnImageError
                          ? Colors.red
                          : (_returnItemImages.length >= 5
                              ? Colors.grey.withOpacity(0.3)
                              : Theme.of(context).dividerColor),
                      style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        color: _showReturnImageError ? Colors.red : Colors.grey,
                        size: 40),
                    const SizedBox(height: 12),
                    Text(
                      _showReturnImageError
                          ? 'Photo required'
                          : (_returnItemImages.length >= 5
                              ? 'Max 5 photos reached'
                              : 'Add up to 5 photos'),
                      style: TextStyle(
                          color:
                              _showReturnImageError ? Colors.red : Colors.grey,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_returnItemImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _returnItemImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
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
                          top: -8,
                          right: -8,
                          child: GestureDetector(
                            onTap: () => _removeImage(index, true),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close,
                                  size: 14, color: Colors.white),
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
        const SizedBox(height: 32),
        Text(AppLocalizations.of(context)!.category, style: _labelStyle()),
        const SizedBox(height: 12),
        _buildCategoryToggleSelection(
          _selectedReturnCategory,
          (val) => setState(() => _selectedReturnCategory = val),
        ),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.condition, style: _labelStyle()),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildReturnConditionChip('New'),
            const SizedBox(width: 16),
            _buildReturnConditionChip('Like New'),
            const SizedBox(width: 16),
            _buildReturnConditionChip('Used'),
          ],
        ),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.description, style: _labelStyle()),
        const SizedBox(height: 12),
        _buildTextField('Describe your product here...',
            maxLines: 4,
            controller: _returnItemDescriptionController,
            validator: (val) =>
                _validateRequired(val, 'Return Item Description')),
        const SizedBox(height: 24),
        Row(
          children: [
            Row(
              children: [
                Checkbox(
                  value: _isReturnHomemade,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    setState(() {
                      _isReturnHomemade = val ?? false;
                      if (_isReturnHomemade) _isReturnStoreBought = false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.homemade,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(width: 32),
            Row(
              children: [
                Checkbox(
                  value: _isReturnStoreBought,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    setState(() {
                      _isReturnStoreBought = val ?? false;
                      if (_isReturnStoreBought) _isReturnHomemade = false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.storeBought,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReturnConditionChip(String label) {
    bool isSelected = _returnSelectedCondition == label;
    return GestureDetector(
      onTap: () => setState(() => _returnSelectedCondition = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.wallet,
                  style: _labelStyle(size: 18)),
              const SizedBox(height: 16),
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
                              color: Theme.of(context).primaryColor, size: 24),
                          const SizedBox(width: 12),
                          Text('$postPrice Credits per trade',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('Credits: $remainingCredit',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).primaryColor)),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.notificationSettings,
                  style: _labelStyle(size: 18)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.notifySavedUsersOnly,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          'Only partners you\'ve traded with before will receive notifications.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _notifyPartnersOnly,
                    activeColor: Colors.green,
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
                const SizedBox(height: 12),
                Consumer<ProfileController>(
                  builder: (context, profileCtrl, child) {
                    if (profileCtrl.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (profileCtrl.collections.isEmpty) {
                      return Text(
                        "No saved collections found.",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Select Collections",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
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
          height: 56,
          child: ElevatedButton(
            onPressed: tradeController.isPostCreating ? null : _onPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: tradeController.isPostCreating
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context)!.postItem,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
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
    if (!_formKey.currentState!.validate()) {
      isValid = false;
    }

    if (_selectedCategory == null) {
      ToastService.showErrorToast(
          context, 'Please select a category for the item');
      isValid = false;
    }

    if (_itemImages.isEmpty) {
      setState(() => _showImageError = true);
      isValid = false;
    }

    if (!_isHomemade && !_isStoreBought) {
      setState(() => _showSourceError = true);
      isValid = false;
    }

    if (!_isPriceSelected) {
      if (_selectedReturnCategory == null) {
        ToastService.showErrorToast(
            context, 'Please select a category for the return item');
        isValid = false;
      }
      if (_returnItemImages.isEmpty) {
        setState(() => _showReturnImageError = true);
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

    String title = "Create Post";
    if (ModalRoute.of(context)!.settings.arguments != null) {
      title = ModalRoute.of(context)!.settings.arguments as String;
    }
    final String postType =
        title.toLowerCase().contains('take') ? 'take' : 'give';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            Icon(Icons.stars, color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.activeSubscriptionRequired,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: FontFamily.openSans),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.noActiveSubscriptionMessage,
          style: TextStyle(fontSize: 16, fontFamily: FontFamily.openSans),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.choosePlan).then((_) {
                if (mounted) {
                  context.read<SubscriptionController>().fetchMySubscription();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(AppLocalizations.of(context)!.buySubscription,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
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
        fillColor: Theme.of(context).cardColor,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey, size: 24)
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).dividerColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).primaryColor)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                CategoryModel cat = tradeController.categories.firstWhere(
                  (c) => c.name.toLowerCase() == label.toLowerCase(),
                  orElse: () => CategoryModel(
                      id: label == 'Goods'
                          ? 12
                          : (label == 'Services' ? 13 : 14),
                      name: label,
                      subId: 0,
                      imageUrl: '',
                      status: 1),
                );
                onSelected(cat);
              },
              child: Container(
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).dividerColor),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
          );
        }

        return Row(
          children: [
            buildBtn('Goods'),
            const SizedBox(width: 16),
            buildBtn('Services'),
            const SizedBox(width: 16),
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
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10)),
          child: Text(
            label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 16),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle({double size = 16}) {
    return TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: size,
        fontFamily: FontFamily.openSans);
  }

  Widget _buildAppBar() {
    String title = "Create Post";
    if (ModalRoute.of(context)?.settings.arguments != null) {
      title = ModalRoute.of(context)!.settings.arguments as String;
    }
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 24),
          onPressed: _handleBackPress,
        ),
        const SizedBox(width: 24),
        Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              fontFamily: FontFamily.openSans),
        ),
      ],
    );
  }
}
