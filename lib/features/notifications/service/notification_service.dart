import 'package:tool_bocs/core/api/api_client.dart';
import 'package:tool_bocs/core/api/api_constants.dart';
import 'package:tool_bocs/core/api/api_response.dart';
import 'package:tool_bocs/features/notifications/model/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<NotificationResponseModel>> fetchNotifications({
    int page = 1,
    int limit = 10,
    String type = 'general',
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: {
          'page': page,
          'limit': limit,
          'type': type,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Notifications fetched successfully',
            data: NotificationResponseModel.fromJson(data),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch notifications',
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<int>> fetchUnreadCount() async {
    try {
      final response = await _apiClient.get(ApiConstants.notificationUnread);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Unread count fetched successfully',
            data: data['unread_count'] ?? 0,
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch unread count',
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<dynamic>> markAllAsRead() async {
    try {
      final response = await _apiClient.put(ApiConstants.notificationsReadAll);

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'All notifications marked as read',
          data: data['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<dynamic>> markAsRead(int notificationId) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.notificationMarkRead
            .replaceFirst('{{id}}', notificationId.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Notification marked as read',
          data: data['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<dynamic>> deleteNotification(int notificationId) async {
    try {
      final response = await _apiClient.delete(
        ApiConstants.notificationDelete
            .replaceFirst('{{id}}', notificationId.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Notification deleted successfully',
          data: data['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
