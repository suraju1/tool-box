import 'dart:developer';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/trades/model/category_model.dart';
import 'package:tool_bocs/features/trades/model/trade_response_request_model.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/web_ui/widgets/web_price_range_selector.dart';
import 'package:tool_bocs/features/trade_steps_flow/view/trade_offer_screen2.dart'
    show ReturnType;
import 'dart:io';

class WebTradeOfferScreen extends StatefulWidget {
  const WebTradeOfferScreen({super.key});

  @override
  State<WebTradeOfferScreen> createState() => _WebTradeOfferScreenState();
}

class _WebTradeOfferScreenState extends State<WebTradeOfferScreen> {
  late TradeController _tradeController;
  ReturnType _selectedReturnType = ReturnType.existing;
  String _customItemCondition = 'New';
  bool _isHomemade = false;
  bool _isStoreBought = false;
  RangeValues _priceRange = const RangeValues(10, 50000);
  bool _isNegotiable = false;

  // Controllers for Custom Item
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int? _selectedCategoryId;
  CategoryModel? _selectedCategory;

  // Images logic
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _itemImages = [];

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        if (_itemImages.length + images.length > 5) {
          ToastService.showErrorToast(context, 'Max 5 images allowed');
        } else {
          _itemImages.addAll(images);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _itemImages.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _tradeController = context.read<TradeController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tradeController.fetchCategories();
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _tradeController.clearErrorMessage();
    super.dispose();
  }

  Future<void> _handleOfferSubmission() async {
    final tradeController = context.read<TradeController>();
    final post = tradeController.selectedPost;
    if (post == null) return;

    String responseType = 'item';
    double? priceStart;
    double? priceEnd;
    bool? isNegotiable;
    String? itemName;
    String? condition;
    String? description;
    bool? isHomemade;
    bool? isStoreBought;
    int? categoryId = _selectedCategoryId;

    if (_selectedReturnType == ReturnType.money) {
      responseType = 'price';
      priceStart = _priceRange.start;
      priceEnd = _priceRange.end;
      isNegotiable = _isNegotiable;
    } else if (_selectedReturnType == ReturnType.customItem) {
      responseType = 'item';
      itemName = _itemNameController.text.trim();
      description = _descriptionController.text.trim();
      condition = _customItemCondition;
      isHomemade = _isHomemade;
      isStoreBought = _isStoreBought;

      if (itemName.isEmpty) {
        ToastService.showErrorToast(context, 'Please enter item name');
        return;
      }
    } else if (_selectedReturnType == ReturnType.existing) {
      responseType = 'existing';
      if (post.returnType.toLowerCase() == 'price') {
        priceStart = post.priceMin;
        priceEnd = post.priceMax;
        isNegotiable = post.isNegotiable;
      } else {
        itemName = post.returnItemName;
        description = post.returnItemDescription;
        condition = post.returnItemCondition;
      }
    } else if (_selectedReturnType == ReturnType.free) {
      responseType = 'free';
    }

    final request = TradeResponseRequestModel(
      giveawayId: post.id,
      returnType: responseType,
      itemName: itemName,
      categoryId: categoryId,
      condition: condition,
      description: description,
      isHomemade: isHomemade,
      isStoreBought: isStoreBought,
      notifyPoster: true,
      priceRangeStart: priceStart,
      priceRangeEnd: priceEnd,
      isNegotiable: isNegotiable,
      images: _itemImages,
    );

    log(request.toJson().toString());
    final success = await tradeController.respondToPost(request);

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      ToastService.showErrorToast(
          context, tradeController.errorMessage ?? 'Submission failed');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.surfaceColor,
        content: Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.offerSentTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.offerSentMsg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.subTextColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to details or home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.done,
                    style: TextStyle(
                        color: context.onPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonName(bool isGivePost) {
    if (_selectedReturnType == ReturnType.existing) {
      return isGivePost ? 'Make Offer (Take It)' : 'Make Offer (Give It)';
    } else if (_selectedReturnType == ReturnType.customItem) {
      return isGivePost
          ? 'Make Custom Offer (Take)'
          : 'Make Custom Offer (Give)';
    } else if (_selectedReturnType == ReturnType.money) {
      return isGivePost ? 'Offer Money' : 'Ask for Money';
    } else {
      return isGivePost ? 'Ask for Free' : 'Give for Free';
    }
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
          icon: Icon(Icons.arrow_back, color: context.textColor, size: 24),
        ),
        title: Consumer<TradeController>(
          builder: (context, controller, child) {
            final post = controller.selectedPost;
            if (post == null) return const SizedBox.shrink();
            final isGivePost = post.postType.toLowerCase() == 'give';
            return Text(
              isGivePost
                  ? 'Take ${post.itemName} from ${post.userName}'
                  : 'Give ${post.itemName} to ${post.userName}',
              style: TextStyle(
                color: context.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: FontFamily.openSans,
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: Consumer<TradeController>(
        builder: (context, controller, child) {
          final post = controller.selectedPost;
          if (post == null) {
            return Center(
                child: Text(AppLocalizations.of(context)!.postNotFound));
          }

          final isGivePost = post.postType.toLowerCase() == 'give';

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 48.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Recipient Context Card
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.offerSummary,
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor),
                            ),
                            const SizedBox(height: 24),
                            _buildRecipientCard(post, isGivePost),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                      // Right Column: Forms
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: context.isDarkMode
                                    ? []
                                    : [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 20,
                                            offset: const Offset(0, 4))
                                      ],
                                border: Border.all(color: context.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .selectYourOffer,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: context.textColor),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildReturnOption(
                                    type: ReturnType.existing,
                                    title: isGivePost
                                        ? "Give what ${(post.userName ?? 'User').split(' ').first}'s asking for"
                                        : "Take what ${(post.userName ?? 'User').split(' ').first}'s giving",
                                    child: _buildItemPreviewCard(post),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildReturnOption(
                                    type: ReturnType.customItem,
                                    title: isGivePost
                                        ? "Item You Offer in Return"
                                        : "Item You Want in Return",
                                    subtitle: isGivePost
                                        ? "Fill details of the item you're offering"
                                        : "Fill item details you want in return",
                                    child: _buildCustomItemForm(),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildReturnOption(
                                    type: ReturnType.money,
                                    title: isGivePost
                                        ? "Money ( Ask for Money )"
                                        : "Ask for Money",
                                    subtitle: isGivePost
                                        ? "Offer a price for the item"
                                        : "Set a custom price for the item",
                                    child: _buildMoneyForm(isGivePost),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildReturnOption(
                                    type: ReturnType.free,
                                    title: isGivePost
                                        ? "Ask for Free"
                                        : "Give For Free",
                                    subtitle: AppLocalizations.of(context)!
                                        .spreadSomeJoy,
                                    child: const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildBottomAction(isGivePost, controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipientCard(dynamic post, bool isGivePost) {
    Widget buildImageBox(String? url, bool isMoney) {
      if (isMoney) {
        return Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: context.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.primaryColor),
          ),
          child: Icon(Icons.payments_outlined,
              color: context.primaryColor, size: 60),
        );
      }
      return Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.dividerColor),
          image: DecorationImage(
            image: url != null
                ? NetworkImage(AppCachedImage.getFormattedUrl(url))
                    as ImageProvider
                : const AssetImage('assets/iphone.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.dividerColor),
        boxShadow: context.isDarkMode
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: context.primaryColor.withOpacity(0.1),
                child: Text(
                  post?.userName?.isNotEmpty == true
                      ? post.userName![0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: context.primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGivePost ? 'GIVER' : 'TAKER',
                    style: TextStyle(
                        color: context.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post?.userName ?? '-',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.textColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "${(post?.userName ?? 'User').split(' ').first}'s ${isGivePost ? 'Giving' : 'Taking'}",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.subTextColor),
          ),
          const SizedBox(height: 8),
          Text(
            post?.itemName ?? '-',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textColor),
          ),
          const SizedBox(height: 24),
          Center(
            child: buildImageBox(
              (post?.itemImages != null && post!.itemImages.isNotEmpty)
                  ? post.itemImages.first
                  : null,
              false,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildDetailRow('Offer Type', post?.tradeType ?? '-'),
          const SizedBox(height: 12),
          _buildDetailRow('Category', post?.itemCategory ?? '-'),
          const SizedBox(height: 12),
          _buildDetailRow('Distance',
              '${post?.distanceKm?.toStringAsFixed(1) ?? '0.4'} km away'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: context.subTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                color: context.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReturnOption({
    required ReturnType type,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    bool isSelected = _selectedReturnType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedReturnType = type),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFF))
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? context.primaryColor : context.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isSelected
                            ? context.primaryColor
                            : context.dividerColor,
                        width: 2),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.primaryColor),
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textColor),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 14,
                                color: context.subTextColor,
                                fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected && child is! SizedBox) ...[
              const SizedBox(height: 24),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemPreviewCard(dynamic post) {
    final bool isMoney = post?.returnType?.toLowerCase() == 'price';
    final String? returnImageUrl =
        (post?.returnItemImages != null && post!.returnItemImages.isNotEmpty)
            ? post.returnItemImages.first
            : null;
    final String returnName = isMoney ? 'Money' : (post?.returnItemName ?? '-');
    final String returnCategory = isMoney
        ? '₹${post?.priceMin?.toStringAsFixed(0) ?? '0'} - ₹${post?.priceMax?.toStringAsFixed(0) ?? '0'}'
        : (post?.returnItemCategory ?? '-');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          if (isMoney)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: context.primaryColor.withOpacity(0.1),
                border: Border.all(color: context.primaryColor),
              ),
              child: Icon(Icons.payments_outlined,
                  color: context.primaryColor, size: 32),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: context.surfaceColor,
                border: Border.all(color: context.dividerColor),
                image: returnImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(
                            AppCachedImage.getFormattedUrl(returnImageUrl)),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: returnImageUrl == null
                  ? Icon(Icons.image_outlined,
                      color: context.subTextColor, size: 24)
                  : null,
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(returnName,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textColor)),
                const SizedBox(height: 4),
                Text(returnCategory,
                    style:
                        TextStyle(fontSize: 14, color: context.subTextColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showReturnDetailsSheet(context, post),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.seeDetails,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.subTextColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    color: context.subTextColor, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReturnDetailsSheet(BuildContext context, dynamic post) {
    if (post == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.requestedReturnDetails,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 24),
            if (post.returnType.toLowerCase() == 'price') ...[
              _buildInfoRow('Price Range',
                  '₹${post.priceMin?.toStringAsFixed(2) ?? '0'} - ₹${post.priceMax?.toStringAsFixed(2) ?? '0'}'),
              const SizedBox(height: 16),
              _buildInfoRow(
                  'Negotiable', post.isNegotiable == true ? 'Yes' : 'No'),
            ] else ...[
              if (post.returnItemImages != null &&
                  post.returnItemImages.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AppCachedImage(
                      imageUrl: post.returnItemImages.first,
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _buildInfoRow('Item Name', post.returnItemName ?? 'NA'),
              const SizedBox(height: 16),
              _buildInfoRow('Category', post.returnItemCategory ?? 'NA'),
              const SizedBox(height: 16),
              _buildInfoRow('Condition', post.returnItemCondition ?? 'NA'),
              const SizedBox(height: 16),
              _buildInfoRow('Trade Type', post.tradeType ?? 'NA'),
              if (post.returnItemDescription != null &&
                  post.returnItemDescription.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.subTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.returnItemDescription,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.textColor,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(AppLocalizations.of(context)!.close,
                    style: TextStyle(
                        color: context.onPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.subTextColor.withOpacity(0.8),
            fontFamily: FontFamily.openSans,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textColor,
              fontFamily: FontFamily.openSans,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomItemForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Item Name', 'Enter item name',
            controller: _itemNameController),
        const SizedBox(height: 20),
        _buildAddPhotosSection(),
        const SizedBox(height: 20),
        Text(AppLocalizations.of(context)!.category,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: context.textColor)),
        const SizedBox(height: 8),
        _buildDropdown('Select Category'),
        const SizedBox(height: 20),
        Text(AppLocalizations.of(context)!.condition,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: context.textColor)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildConditionChip('New'),
            const SizedBox(width: 12),
            _buildConditionChip('Like New'),
            const SizedBox(width: 12),
            _buildConditionChip('Used'),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField('Description', 'Describe your product here...',
            maxLines: 4, controller: _descriptionController),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildCheckbox(
                'Homemade',
                _isHomemade,
                (val) => setState(() {
                      _isHomemade = val ?? false;
                      if (_isHomemade) _isStoreBought = false;
                    })),
            const SizedBox(width: 32),
            _buildCheckbox(
                'Store bought',
                _isStoreBought,
                (val) => setState(() {
                      _isStoreBought = val ?? false;
                      if (_isStoreBought) _isHomemade = false;
                    })),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String hint,
      {int maxLines = 1, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: context.textColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.surfaceColor,
            hintText: hint,
            hintStyle: TextStyle(
                color: context.subTextColor.withOpacity(0.5), fontSize: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.dividerColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.dividerColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.primaryColor)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String hint) {
    return Consumer<TradeController>(
      builder: (context, tradeController, child) {
        if (tradeController.isLoading) {
          return Center(
              child: CircularProgressIndicator(color: context.primaryColor));
        }
        return DropdownButtonFormField<CategoryModel>(
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: context.surfaceColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.dividerColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.dividerColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.primaryColor)),
          ),
          hint: Text(hint,
              style: TextStyle(color: context.subTextColor, fontSize: 14)),
          isExpanded: true,
          value: _selectedCategory,
          items: tradeController.categories
              .where((category) =>
                  category.name.toLowerCase() != 'money' && category.id != 14)
              .map((category) =>
                  DropdownMenuItem(value: category, child: Text(category.name)))
              .toList(),
          onChanged: (val) => setState(() {
            _selectedCategory = val;
            _selectedCategoryId = val?.id;
          }),
        );
      },
    );
  }

  Widget _buildAddPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.addPhotos,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: context.textColor)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color:
                  context.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.dividerColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined,
                    color: context.primaryColor, size: 40),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.addUpTo5Photos,
                    style:
                        TextStyle(color: context.subTextColor, fontSize: 14)),
              ],
            ),
          ),
        ),
        if (_itemImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _itemImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
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
                        onTap: () => _removeImage(index),
                        child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildConditionChip(String label) {
    bool isSelected = _customItemCondition == label;
    return GestureDetector(
      onTap: () => setState(() => _customItemCondition = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor : context.surfaceColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isSelected ? context.primaryColor : context.dividerColor),
        ),
        child: Text(label,
            style: TextStyle(
                color:
                    isSelected ? context.onPrimaryColor : context.subTextColor,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCheckbox(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
            value: value,
            activeColor: context.primaryColor,
            onChanged: onChanged),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.textColor)),
      ],
    );
  }

  Widget _buildMoneyForm(bool isGivePost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WebPriceRangeSelector(
          initialValues: _priceRange,
          label: isGivePost ? 'Your Price Offer' : 'Desired Price Range',
          onChanged: (val) => setState(() => _priceRange = val),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Switch(
                value: _isNegotiable,
                activeColor: context.primaryColor,
                onChanged: (val) => setState(() => _isNegotiable = val)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.negotiable,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.subTextColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomAction(bool isGivePost, TradeController controller) {
    final post = controller.selectedPost;
    if (post != null && post.hasResponded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.youHaveAlreadyMadeAn,
              style: TextStyle(
                color: context.isDarkMode
                    ? Colors.green.shade400
                    : Colors.green.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isLoading ? null : _handleOfferSubmission,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: controller.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : Text(_getButtonName(isGivePost),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
      ),
    );
  }
}
