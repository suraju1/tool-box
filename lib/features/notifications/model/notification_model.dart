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
      referenceId: json["reference_id"] != null
          ? int.tryParse(json["reference_id"].toString())
          : null,
      createdBy: json["created_by"] != null
          ? int.tryParse(json["created_by"].toString())
          : null,
      readAt: json["read_at"] == null ? null : DateTime.parse(json["read_at"]),
      createdAt: json["created_at"] == null
          ? null
          : DateTime.parse(json["created_at"]),
    );
  }
}
