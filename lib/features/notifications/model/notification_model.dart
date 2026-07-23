import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tool_bocs/core/models/pagination_model.dart';

class NotificationResponseModel {
  final bool success;
  final String message;
  final Pagination? pagination;
  final List<NotificationModel> data;

  NotificationResponseModel({
    required this.success,
    required this.message,
    this.pagination,
    required this.data,
  });

  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) =>
      NotificationResponseModel(
        success: json["success"] ?? false,
        message: json["message"] ?? "",
        pagination: json["pagination"] == null
            ? null
            : Pagination.fromJson(json["pagination"]),
        data: json["data"] == null
            ? []
            : List<NotificationModel>.from(
                json["data"].map((x) => NotificationModel.fromJson(x)),
              ),
      );
}

class NotificationModel {
  final int id;
  final int userId;
  final String notificationTitle;
  final String notificationMessage;
  final int isRead;
  final String? type;
  final int? referenceId;
  final int? createdBy;
  final DateTime? readAt;
  final DateTime? createdAt;
  
  // New Post Nearby specific fields
  final List<String> itemImages;
  final String? itemName;
  final String? postType;
  final String? returnType;
  final String? returnItemName;
  final String? priceMin;
  final String? priceMax;
  final String? distanceKm;
  final String? creatorName;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.notificationTitle,
    required this.notificationMessage,
    required this.isRead,
    this.type,
    this.referenceId,
    this.createdBy,
    this.readAt,
    this.createdAt,
    this.itemImages = const [],
    this.itemName,
    this.postType,
    this.returnType,
    this.returnItemName,
    this.priceMin,
    this.priceMax,
    this.distanceKm,
    this.creatorName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    debugPrint("Notification JSON mapping: $json");
    // Use the explicit ID field from the API.
    final dynamic rawId = json["id"] ?? json["notification_id"];

    // Use hashing as a last resort fallback only.
    final int parsedId = (rawId != null)
        ? (rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0)
        : (json["notification_title"].toString() +
                json["notification_message"].toString() +
                json["created_at"].toString())
            .hashCode;

    return NotificationModel(
      id: parsedId,
      userId: json["user_id"] ?? 0,
      notificationTitle: json["notification_title"] ?? "",
      notificationMessage: json["notification_message"] ?? "",
      isRead: json["is_read"] ?? 0,
      type: json["type"],
      referenceId: () {
        int? refId;
        if (json["reference_id"] != null) {
          refId = int.tryParse(json["reference_id"].toString());
          if (refId == 0) refId = null;
        }
        if (refId == null && json["post_id"] != null) {
          refId = int.tryParse(json["post_id"].toString());
          if (refId == 0) refId = null;
        }
        return refId;
      }(),
      createdBy: json["created_by"] != null
          ? int.tryParse(json["created_by"].toString())
          : null,
      readAt: json["read_at"] == null ? null : DateTime.parse(json["read_at"]),
      createdAt: json["created_at"] == null
          ? null
          : DateTime.parse(json["created_at"]),
      itemImages: _parseImages(json["item_images"]),
      itemName: json["item_name"],
      postType: json["post_type"],
      returnType: json["return_type"],
      returnItemName: json["return_item_name"],
      priceMin: json["price_min"]?.toString(),
      priceMax: json["price_max"]?.toString(),
      distanceKm: json["distance_km"]?.toString(),
      creatorName: json["creator_name"] ?? json["user_name"] ?? json["poster_name"],
    );
  }

  static List<String> _parseImages(dynamic imagesData) {
    if (imagesData == null) return [];
    if (imagesData is List) {
      return imagesData.map((e) => e.toString()).toList();
    }
    if (imagesData is String) {
      if (imagesData.isEmpty || imagesData == "[]") return [];
      try {
        final decoded = jsonDecode(imagesData);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return [];
  }
}
