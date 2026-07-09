import 'dart:convert';

class TradeResponseModel {
  final int id;
  final int postId;
  final int responderId;
  final int posterUserId;
  final String responderName;
  final String? responderImage;
  final String responseType; // 'price' or 'item'
  final double? priceRangeStart;
  final double? priceRangeEnd;
  final bool isNegotiable;
  final String? itemName;
  final String? itemCategory;
  final String? itemCondition;
  final String? itemDescription;
  final bool isHomemade;
  final bool isStoreBought;
  final List<String> itemImages;
  final String status; // 'pending', 'accepted', 'rejected'
  final String createdAt;
  final String paymentStatus; // 'unpaid', 'paid'
  final String? postItemName;
  final String? returnItemName;
  final List<String> postItemImages;
  final String? postType;
  final String? rejectedBy;
  final String? rejectedReason;
  final String? posterName;
  final String? posterImage;
  final int? itemCategoryId;
  final String? posterMobile;
  final String? responderMobile;

  // New fields from Trade History Details API
  final String? meetingType;
  final String? meetingLocation;
  final String? meetingLatitude;
  final String? meetingLongitude;
  final String? meetingScheduledAt;
  final double? offerPrice;
  final String? givingItemName;
  final String? givingItemCategory;
  final String? givingItemCondition;
  final List<String>? givingItemImages;
  final String? returnItemCategory;
  final String? returnItemCondition;
  final String? postReturnType;
  final String? paymentAmount;
  final double? distanceKm;

  TradeResponseModel({
    required this.id,
    required this.postId,
    required this.responderId,
    required this.posterUserId,
    required this.responderName,
    this.responderImage,
    required this.responseType,
    this.priceRangeStart,
    this.priceRangeEnd,
    this.isNegotiable = false,
    this.itemName,
    this.itemCategory,
    this.itemCondition,
    this.itemDescription,
    this.isHomemade = false,
    this.isStoreBought = false,
    this.itemImages = const [],
    required this.status,
    this.paymentStatus = 'unpaid',
    required this.createdAt,
    this.postItemName,
    this.returnItemName,
    this.postItemImages = const [],
    this.postType,
    this.rejectedBy,
    this.rejectedReason,
    this.posterName,
    this.posterImage,
    this.itemCategoryId,
    this.posterMobile,
    this.responderMobile,
    this.meetingType,
    this.meetingLocation,
    this.meetingLatitude,
    this.meetingLongitude,
    this.meetingScheduledAt,
    this.offerPrice,
    this.givingItemName,
    this.givingItemCategory,
    this.givingItemCondition,
    this.givingItemImages,
    this.returnItemCategory,
    this.returnItemCondition,
    this.postReturnType,
    this.paymentAmount,
    this.distanceKm,
  });

  factory TradeResponseModel.fromJson(Map<String, dynamic> json) {
    // Helper function to handle mixed type image fields
    List<String> parseImages(dynamic images) {
      if (images == null) return [];
      if (images is List) return images.map((e) => e.toString()).toList();
      if (images is String) {
        if (images.isEmpty || images == "[]") return [];
        try {
          final decoded = jsonDecode(images);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    return TradeResponseModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      postId: int.tryParse(
              (json['giveaway_id'] ?? json['post_id'])?.toString() ?? '') ??
          0,
      responderId: int.tryParse(
              (json['responder_user_id'] ?? json['user_id'])?.toString() ??
                  '') ??
          0,
      posterUserId: int.tryParse(json['poster_user_id']?.toString() ?? '') ?? 0,
      responderName: json['responder_name'] ?? json['user_name'] ?? 'User',
      responderImage: json['responder_image'] ?? json['user_image'],
      responseType: json['post_return_type'] ??
          json['return_type'] ??
          json['response_type'] ??
          'item',
      priceRangeStart:
          double.tryParse(json['price_range_start']?.toString() ?? ''),
      priceRangeEnd: double.tryParse(json['price_range_end']?.toString() ?? ''),
      isNegotiable: (json['offer_is_negotiable'] == 1 ||
          json['offer_is_negotiable'] == true ||
          json['is_negotiable'] == 1 ||
          json['is_negotiable'] == true),
      itemName: (json['post_type'] == 'give' || json['post_type'] == 'giving')
          ? (json['return_item_name'] ??
              json['giving_item_name'] ??
              json['item_name'])
          : (json['giving_item_name'] ??
              json['return_item_name'] ??
              json['item_name']),
      itemCategory: json['giving_item_category'] ?? json['category_name'],
      itemCondition: json['giving_item_condition'] ?? json['condition'],
      itemDescription: json['giving_item_note'] ?? json['description'],
      isHomemade: (json['giving_is_homemade'] == 1 ||
          json['giving_is_homemade'] == true ||
          json['is_homemade'] == 1 ||
          json['is_homemade'] == true),
      isStoreBought: (json['giving_is_store_bought'] == 1 ||
          json['giving_is_store_bought'] == true ||
          json['is_store_bought'] == 1 ||
          json['is_store_bought'] == true),
      itemImages: parseImages(json['giving_item_images'] ?? json['images']),
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      createdAt: json['created_at'] ?? '',
      postItemName: json['post_item_name'] ??
          json['item_name'] ??
          ((json['post_type'] == 'give' || json['post_type'] == 'giving')
              ? json['giving_item_name']
              : json['return_item_name']),
      returnItemName: json['return_item_name'],
      postItemImages:
          parseImages(json['post_item_images'] ?? json['post_images']),
      postType: json['post_type'],
      rejectedBy: json['rejected_by']?.toString(),
      rejectedReason: json['rejected_reason'],
      posterName: json['poster_name'],
      posterImage: json['poster_image'],
      itemCategoryId: int.tryParse(
              (json['giving_item_category_id'] ?? json['item_category_id'])
                      ?.toString() ??
                  '') ??
          0,
      posterMobile: json['poster_mobile'] ?? json['poster_phone_number'],
      responderMobile:
          json['responder_mobile'] ?? json['responder_phone_number'],
      meetingType: json['meeting_type'],
      meetingLocation: json['meeting_location'],
      meetingLatitude: json['meeting_latitude']?.toString(),
      meetingLongitude: json['meeting_longitude']?.toString(),
      meetingScheduledAt: json['meeting_scheduled_at'],
      offerPrice: double.tryParse(json['offer_price']?.toString() ?? ''),
      givingItemName: json['giving_item_name'],
      givingItemCategory: json['giving_item_category'],
      givingItemCondition: json['giving_item_condition'],
      givingItemImages: parseImages(json['giving_item_images']),
      returnItemCategory: json['return_item_category'],
      returnItemCondition: json['return_item_condition'],
      postReturnType: json['post_return_type'],
      paymentAmount: json['payment_amount']?.toString(),
      distanceKm: () {
        final val = double.tryParse(json['distance_km']?.toString() ?? json['distance']?.toString() ?? '');
        print('--- TradeResponseModel Parsing: id = ${json['id']}, distance_km = ${json['distance_km']}, distance = ${json['distance']}, parsed = $val');
        return val;
      }(),
    );
  }

  TradeResponseModel copyWith({
    String? status,
    String? paymentStatus,
  }) {
    return TradeResponseModel(
      id: id,
      postId: postId,
      responderId: responderId,
      posterUserId: posterUserId,
      responderName: responderName,
      responderImage: responderImage,
      responseType: responseType,
      priceRangeStart: priceRangeStart,
      priceRangeEnd: priceRangeEnd,
      isNegotiable: isNegotiable,
      itemName: itemName,
      itemCategory: itemCategory,
      itemCondition: itemCondition,
      itemDescription: itemDescription,
      isHomemade: isHomemade,
      isStoreBought: isStoreBought,
      itemImages: itemImages,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
      postItemName: postItemName,
      returnItemName: returnItemName,
      postItemImages: postItemImages,
      postType: postType,
      rejectedBy: rejectedBy,
      rejectedReason: rejectedReason,
      posterName: posterName,
      posterImage: posterImage,
      itemCategoryId: itemCategoryId,
      posterMobile: posterMobile,
      responderMobile: responderMobile,
      meetingType: meetingType,
      meetingLocation: meetingLocation,
      meetingLatitude: meetingLatitude,
      meetingLongitude: meetingLongitude,
      meetingScheduledAt: meetingScheduledAt,
      offerPrice: offerPrice,
      givingItemName: givingItemName,
      givingItemCategory: givingItemCategory,
      givingItemCondition: givingItemCondition,
      givingItemImages: givingItemImages,
      returnItemCategory: returnItemCategory,
      returnItemCondition: returnItemCondition,
      postReturnType: postReturnType,
      paymentAmount: paymentAmount,
      distanceKm: distanceKm,
    );
  }
}
