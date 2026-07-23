import 'dart:convert';

class MyTradeResponseModel {
  final bool success;
  final String message;
  final MyTradeStats? tradeStats;
  final List<MyTradeModel> data;

  MyTradeResponseModel({
    required this.success,
    required this.message,
    this.tradeStats,
    required this.data,
  });

  factory MyTradeResponseModel.fromJson(Map<String, dynamic> json) {
    return MyTradeResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      tradeStats: json['trade_stats'] != null
          ? MyTradeStats.fromJson(json['trade_stats'])
          : null,
      data: (json['data'] as List? ?? [])
          .map((e) => MyTradeModel.fromJson(e))
          .toList(),
    );
  }
}

class MyTradeStats {
  final int totalGives;
  final int totalTakes;
  final int totalTrades;

  MyTradeStats({
    required this.totalGives,
    required this.totalTakes,
    required this.totalTrades,
  });

  factory MyTradeStats.fromJson(Map<String, dynamic> json) {
    return MyTradeStats(
      totalGives: int.tryParse(json['total_gives']?.toString() ?? '0') ?? 0,
      totalTakes: int.tryParse(json['total_takes']?.toString() ?? '0') ?? 0,
      totalTrades: int.tryParse(json['total_trades']?.toString() ?? '0') ?? 0,
    );
  }
}

class MyTradeModel {
  final int id;
  final int giveawayId;
  final int posterUserId;
  final int responderUserId;
  final String itemName;
  final List<String> itemImages;
  final String postType; // 'give' or 'take'
  final String status; // 'pending', 'cancelled', 'completed', 'rejected'
  final String? posterName;
  final String? responderName;
  final String createdAt;
  final String updatedAt;
  final int flowId;
  final String? givingItemName;
  final String? givingItemCategory;
  final String? givingItemCondition;
  final String? returnItemName;
  final String? returnItemCondition;
  final double? distanceKm;

  MyTradeModel({
    required this.id,
    required this.giveawayId,
    required this.posterUserId,
    required this.responderUserId,
    required this.itemName,
    required this.itemImages,
    required this.postType,
    required this.status,
    this.posterName,
    this.responderName,
    required this.createdAt,
    required this.updatedAt,
    required this.flowId,
    this.givingItemName,
    this.givingItemCategory,
    this.givingItemCondition,
    this.returnItemName,
    this.returnItemCondition,
    this.distanceKm,
  });

  MyTradeModel copyWith({
    String? status,
    double? distanceKm,
  }) {
    return MyTradeModel(
      id: id,
      giveawayId: giveawayId,
      posterUserId: posterUserId,
      responderUserId: responderUserId,
      itemName: itemName,
      itemImages: itemImages,
      postType: postType,
      status: status ?? this.status,
      posterName: posterName,
      responderName: responderName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      flowId: flowId,
      givingItemName: givingItemName,
      givingItemCategory: givingItemCategory,
      givingItemCondition: givingItemCondition,
      returnItemName: returnItemName,
      returnItemCondition: returnItemCondition,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  factory MyTradeModel.fromJson(Map<String, dynamic> json) {
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

    return MyTradeModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      giveawayId: int.tryParse(json['giveaway_id']?.toString() ?? '0') ?? 0,
      posterUserId:
          int.tryParse(json['poster_user_id']?.toString() ?? '0') ?? 0,
      responderUserId:
          int.tryParse(json['responder_user_id']?.toString() ?? '0') ?? 0,
      itemName: json['item_name'] ?? json['giving_item_name'] ?? '',
      itemImages:
          parseImages(json['item_images'] ?? json['giving_item_images']),
      postType: json['post_type']?.toString().toLowerCase() ?? 'give',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      posterName: json['poster_name'],
      responderName: json['responder_name'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      flowId: int.tryParse(json['flow_id']?.toString() ?? '0') ?? 0,
      givingItemName: json['giving_item_name'],
      givingItemCategory: json['giving_item_category'],
      givingItemCondition: json['giving_item_condition'],
      returnItemName: json['return_item_name'],
      returnItemCondition: json['return_item_condition'],
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? json['distance']?.toString() ?? ''),
    );
  }
}
