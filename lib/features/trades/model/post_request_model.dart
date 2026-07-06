import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:tool_bocs/util/string_util.dart';

class PostRequestModel {
  final int userId;
  final String pickupArea;
  final double latitude;
  final double longitude;
  final double areaDiameter;
  final String tradeType;
  final String itemName;
  final String itemCategory;
  final int itemCategoryId;
  final String itemCondition;
  final String itemNote;
  final String itemSource; // "Homemade" or "Store bought"
  final String returnType; // "Price" or "Item"
  final double? priceMin;
  final double? priceMax;
  final bool isNegotiable;
  final int walletCredits;
  final bool notifyPartnersOnly;
  final List<int>? notifyCollectionIds;
  final String postType; // "give" or "take"
  final List<dynamic> itemImages; // Paths or XFiles to images
  final List<dynamic> returnItemImages; // Paths or XFiles to return item images (if any)
  final String? returnItemName;
  final String? returnItemCategory;
  final int? returnItemCategoryId;
  final String? returnItemCondition;
  final String? returnItemNote;
  final String? returnItemDescription;
  final String? returnItemSource;

  PostRequestModel({
    required this.userId,
    required this.pickupArea,
    required this.latitude,
    required this.longitude,
    required this.areaDiameter,
    required this.tradeType,
    required this.itemName,
    required this.itemCategory,
    required this.itemCategoryId,
    required this.itemCondition,
    required this.itemNote,
    required this.itemSource,
    required this.returnType,
    this.priceMin,
    this.priceMax,
    required this.isNegotiable,
    required this.walletCredits,
    required this.notifyPartnersOnly,
    this.notifyCollectionIds,
    required this.postType,
    required this.itemImages,
    this.returnItemImages = const [],
    this.returnItemName,
    this.returnItemCategory,
    this.returnItemCategoryId,
    this.returnItemCondition,
    this.returnItemNote,
    this.returnItemDescription,
    this.returnItemSource,
  });

  Future<FormData> toFormData() async {
    final Map<String, dynamic> data = {};

    // 1. Common Fields - Stringified to match Postman "Text" type behavior
    data['post_type'] = postType.toString();
    data['pickup_area'] = StringUtil.sanitizeForSql(pickupArea);
    data['latitude'] = latitude.toString();
    data['longitude'] = longitude.toString();
    data['area_diameter'] = areaDiameter.toString();
    data['trade_type'] = StringUtil.sanitizeForSql(tradeType);
    data['item_name'] = StringUtil.sanitizeForSql(itemName);
    data['item_category'] = StringUtil.sanitizeForSql(itemCategory);
    data['item_condition'] = StringUtil.sanitizeForSql(itemCondition);
    data['item_note'] = StringUtil.sanitizeForSql(itemNote);
    data['item_source'] = StringUtil.sanitizeForSql(itemSource);
    data['return_type'] = returnType.toString();
    data['notify_partners_only'] = notifyPartnersOnly.toString();
    if (notifyCollectionIds != null && notifyCollectionIds!.isNotEmpty) {
      data['notify_collection_ids'] = notifyCollectionIds!.join(',');
    }
    data['item_category_id'] = itemCategoryId.toString();
    data['is_negotiable'] = isNegotiable.toString();
    data['wallet_credits'] = walletCredits.toString();

    // 2. Conditional Return Item Fields
    if (returnType.toLowerCase() == 'item') {
      if (returnItemName != null) {
        data['return_item_name'] = StringUtil.sanitizeForSql(returnItemName);
      }
      if (returnItemCategory != null) {
        data['return_item_category'] =
            StringUtil.sanitizeForSql(returnItemCategory);
      }
      if (returnItemCondition != null) {
        data['return_item_condition'] =
            StringUtil.sanitizeForSql(returnItemCondition);
      }
      if (returnItemNote != null) {
        data['return_item_note'] = StringUtil.sanitizeForSql(returnItemNote);
      }
      if (returnItemDescription != null) {
        data['return_item_description'] =
            StringUtil.sanitizeForSql(returnItemDescription);
      }
      if (returnItemSource != null) {
        data['return_item_source'] =
            StringUtil.sanitizeForSql(returnItemSource);
      }
    } else {
      // Fields unique to Price return type
      if (priceMin != null) data['price_min'] = priceMin.toString();
      if (priceMax != null) data['price_max'] = priceMax.toString();
    }

    final formData = FormData.fromMap(data);

    // 3. Image Key Alignment (Crucial)
    // Removed brackets [] from both keys as Price flow worked without them.
    const String itemImagesKey = 'item_images';
    const String returnItemImagesKey = 'return_item_images';

    for (var image in itemImages) {
      String imagePath = image is String ? image : (image.path as String);
      if (imagePath.isNotEmpty) {
        if (kIsWeb) {
          final xFile = image is XFile ? image : XFile(imagePath);
          final bytes = await xFile.readAsBytes();
          formData.files.add(MapEntry(
            itemImagesKey,
            MultipartFile.fromBytes(bytes, filename: xFile.name),
          ));
        } else {
          formData.files.add(MapEntry(
            itemImagesKey,
            await MultipartFile.fromFile(imagePath),
          ));
        }
      }
    }

    if (returnType.toLowerCase() == 'item') {
      for (var image in returnItemImages) {
        String imagePath = image is String ? image : (image.path as String);
        if (imagePath.isNotEmpty) {
          if (kIsWeb) {
            final xFile = image is XFile ? image : XFile(imagePath);
            final bytes = await xFile.readAsBytes();
            formData.files.add(MapEntry(
              returnItemImagesKey,
              MultipartFile.fromBytes(bytes, filename: xFile.name),
            ));
          } else {
            formData.files.add(MapEntry(
              returnItemImagesKey,
              await MultipartFile.fromFile(imagePath),
            ));
          }
        }
      }
    }

    return formData;
  }
}
