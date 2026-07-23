import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:tool_bocs/util/string_util.dart';

class TradeResponseRequestModel {
  final int giveawayId;
  final String returnType; // 'existing', 'price', 'item', 'free'
  final String? itemName;
  final int? categoryId;
  final String? condition; // 'New', 'Like New', 'Used'
  final String? description;
  final bool? isHomemade;
  final bool? isStoreBought;
  final bool? notifyPoster;
  final double? priceRangeStart;
  final double? priceRangeEnd;
  final bool? isNegotiable;
  final List<dynamic>? images; // List of file paths or XFiles

  TradeResponseRequestModel({
    required this.giveawayId,
    required this.returnType,
    this.itemName,
    this.categoryId,
    this.condition,
    this.description,
    this.isHomemade,
    this.isStoreBought,
    this.notifyPoster,
    this.priceRangeStart,
    this.priceRangeEnd,
    this.isNegotiable,
    this.images,
  });

  Future<FormData> toFormData() async {
    final sanitizedName = StringUtil.sanitizeForSql(itemName);
    final sanitizedDescription = StringUtil.sanitizeForSql(description);
    final sanitizedCondition = StringUtil.sanitizeForSql(condition);

    final processedReturnType = returnType.toLowerCase();

    final formData = FormData();

    // 1. Mandatory Fields at the beginning
    formData.fields.add(MapEntry('return_type', processedReturnType));

    // 2. Conditional return item fields
    if (itemName != null || returnType.toLowerCase() == 'item') {
      formData.fields.add(MapEntry('item_name', sanitizedName));
    }

    if (categoryId != null) {
      formData.fields.add(MapEntry('category_id', categoryId.toString()));
    }

    if (condition != null) {
      formData.fields.add(MapEntry('condition', sanitizedCondition));
    }

    if (description != null) {
      formData.fields.add(MapEntry('description', sanitizedDescription));
    }

    // 3. Other boolean/numeric fields
    if (isHomemade != null) {
      formData.fields.add(MapEntry('is_homemade', isHomemade!.toString()));
    }
    if (isStoreBought != null) {
      formData.fields.add(MapEntry('is_store_bought', isStoreBought!.toString()));
    }
    if (notifyPoster != null) {
      formData.fields.add(MapEntry('notify_poster', notifyPoster!.toString()));
    }

    if (priceRangeStart != null) {
      formData.fields.add(MapEntry('price_range_start', priceRangeStart.toString()));
    }
    if (priceRangeEnd != null) {
      formData.fields.add(MapEntry('price_range_end', priceRangeEnd.toString()));
    }
    if (isNegotiable != null) {
      formData.fields.add(MapEntry('is_negotiable', isNegotiable!.toString()));
    }

    if (images != null && images!.isNotEmpty) {
      for (var image in images!) {
        String path = image is String ? image : (image.path as String);
        if (path.isNotEmpty) {
          if (kIsWeb) {
            final xFile = image is XFile ? image : XFile(path);
            final bytes = await xFile.readAsBytes();
            for (final key in ['images', 'item_images', 'giving_item_images', 'return_item_images']) {
              formData.files.add(MapEntry(
                key,
                MultipartFile.fromBytes(bytes, filename: xFile.name),
              ));
            }
          } else {
            for (final key in ['images', 'item_images', 'giving_item_images', 'return_item_images']) {
              formData.files.add(MapEntry(
                key,
                await MultipartFile.fromFile(path),
              ));
            }
          }
        }
      }
    }

    return formData;
  }

  Map<String, dynamic> toJson() {
    return {
      'giveaway_id': giveawayId,
      'return_type': returnType,
      'item_name': itemName,
      'category_id': categoryId,
      'condition': condition,
      'description': description,
      'is_homemade': isHomemade,
      'is_store_bought': isStoreBought,
      'notify_poster': notifyPoster,
      'price_range_start': priceRangeStart,
      'price_range_end': priceRangeEnd,
      'is_negotiable': isNegotiable,
    };
  }
}
