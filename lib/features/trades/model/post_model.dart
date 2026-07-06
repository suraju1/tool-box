import 'package:tool_bocs/core/models/pagination_model.dart';

class PostResponseModel {
  final bool success;
  final String message;
  final Pagination? pagination;
  final List<PostModel> data;

  PostResponseModel({
    required this.success,
    required this.message,
    this.pagination,
    required this.data,
  });

  factory PostResponseModel.fromJson(Map<String, dynamic> json) =>
      PostResponseModel(
        success: json["success"] ?? false,
        message: json["message"] ?? "",
        pagination: json["pagination"] == null
            ? null
            : Pagination.fromJson(json["pagination"]),
        data: json["data"] == null
            ? []
            : List<PostModel>.from(
                json["data"].map((x) => PostModel.fromJson(x)),
              ),
      );
}

class PostModel {
  final int id;
  final int userId;
  final String pickupArea;
  final double latitude;
  final double longitude;
  final double areaDiameter;
  final String tradeType;
  final String itemName;
  final String itemCategory;
  final int? itemCategoryId;
  final String itemCondition;
  final String itemNote;
  final String itemSource;
  final List<String> itemImages;
  final String returnType;
  final double? priceMin;
  final double? priceMax;
  final bool isNegotiable;
  final String? returnItemName;
  final String? returnItemCategory;
  final String? returnItemCondition;
  final String? returnItemDescription;
  final String? returnItemSource;
  final List<String> returnItemImages;
  final int walletCredits;
  final bool notifyPartnersOnly;
  final String postType;
  final String status;
  final String createdAt;
  final String updatedAt;
  final int? flowId;
  final String userName;
  final String? userImage;
  final double? userRating;
  final double? distanceKm;
  final int? responseCount;
  final bool hasResponded;
  final String? userCreatedAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.pickupArea,
    required this.latitude,
    required this.longitude,
    required this.areaDiameter,
    required this.tradeType,
    required this.itemName,
    required this.itemCategory,
    this.itemCategoryId,
    required this.itemCondition,
    required this.itemNote,
    required this.itemSource,
    required this.itemImages,
    required this.returnType,
    this.priceMin,
    this.priceMax,
    required this.isNegotiable,
    this.returnItemName,
    this.returnItemCategory,
    this.returnItemCondition,
    this.returnItemDescription,
    this.returnItemSource,
    required this.returnItemImages,
    required this.walletCredits,
    required this.notifyPartnersOnly,
    required this.postType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.flowId,
    required this.userName,
    this.userImage,
    this.userRating,
    this.distanceKm,
    this.responseCount,
    this.hasResponded = false,
    this.userCreatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      pickupArea: json['pickup_area'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      areaDiameter:
          double.tryParse(json['area_diameter']?.toString() ?? '0') ?? 0.0,
      tradeType: json['trade_type'] ?? '',
      itemName: json['item_name'] ?? '',
      itemCategory: json['item_category'] ?? '',
      itemCategoryId: json['item_category_id'],
      itemCondition: json['item_condition'] ?? '',
      itemNote: json['item_note'] ?? '',
      itemSource: json['item_source'] ?? '',
      itemImages: (json['item_images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      returnType: json['return_type'] ?? '',
      priceMin: double.tryParse(json['price_min']?.toString() ?? ''),
      priceMax: double.tryParse(json['price_max']?.toString() ?? ''),
      isNegotiable:
          (json['is_negotiable'] == 1 || json['is_negotiable'] == true),
      returnItemName: json['return_item_name'],
      returnItemCategory: json['return_item_category'],
      returnItemCondition: json['return_item_condition'],
      returnItemDescription: json['return_item_description'],
      returnItemSource: json['return_item_source'],
      returnItemImages: (json['return_item_images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      walletCredits:
          int.tryParse(json['wallet_credits']?.toString() ?? '0') ?? 0,
      notifyPartnersOnly: (json['notify_partners_only'] == 1 ||
          json['notify_partners_only'] == true ||
          json['notify_partners_only']?.toString() == "1"),
      postType: json['post_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      flowId: json['flow_id'],
      userName: json['user_name']?.toString() ?? '',
      userImage: json['user_image']?.toString(),
      userRating: double.tryParse(json['user_rating']?.toString() ?? ''),
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '') ??
                  double.tryParse(json['distance']?.toString() ?? ''),
      responseCount: int.tryParse(json['response_count']?.toString() ?? ''),
      hasResponded: json['is_responded'] == 1 ||
          json['is_responded'] == true ||
          json['has_responded'] == 1 ||
          json['has_responded'] == true,
      userCreatedAt: json['user_created_at']?.toString(),
    );
  }

  PostModel copyWith({
    double? distanceKm,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      pickupArea: pickupArea,
      latitude: latitude,
      longitude: longitude,
      areaDiameter: areaDiameter,
      tradeType: tradeType,
      itemName: itemName,
      itemCategory: itemCategory,
      itemCategoryId: itemCategoryId,
      itemCondition: itemCondition,
      itemNote: itemNote,
      itemSource: itemSource,
      itemImages: itemImages,
      returnType: returnType,
      priceMin: priceMin,
      priceMax: priceMax,
      isNegotiable: isNegotiable,
      returnItemName: returnItemName,
      returnItemCategory: returnItemCategory,
      returnItemCondition: returnItemCondition,
      returnItemDescription: returnItemDescription,
      returnItemSource: returnItemSource,
      returnItemImages: returnItemImages,
      walletCredits: walletCredits,
      notifyPartnersOnly: notifyPartnersOnly,
      postType: postType,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      flowId: flowId,
      userName: userName,
      userImage: userImage,
      userRating: userRating,
      distanceKm: distanceKm ?? this.distanceKm,
      responseCount: responseCount,
      hasResponded: hasResponded,
      userCreatedAt: userCreatedAt,
    );
  }
}
