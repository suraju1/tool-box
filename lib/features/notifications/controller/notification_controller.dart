import 'package:flutter/material.dart';
import 'package:tool_bocs/features/notifications/model/notification_model.dart';
import 'package:tool_bocs/features/notifications/service/notification_service.dart';
import 'package:tool_bocs/core/models/pagination_model.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPaginationLoading = false;
  bool get isPaginationLoading => _isPaginationLoading;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  String? _error;
  String? get error => _error;

  Pagination? _pagination;
  Pagination? get pagination => _pagination;

  int _currentPage = 1;

  Future<void> fetchNotifications({bool isRefresh = false, String type = 'general'}) async {
    if (isRefresh) {
      _currentPage = 1;
      _notifications = [];
      _currentType = type;
    }

    if (_currentPage == 1) {
      _isLoading = true;
    } else {
      _isPaginationLoading = true;
    }
    _error = null;
    notifyListeners();

    final response = await _service.fetchNotifications(
      page: _currentPage,
      limit: 10,
      type: type,
    );

    if (response.success && response.data != null) {
      if (isRefresh) {
        _notifications = response.data!.data;
      } else {
        _notifications.addAll(response.data!.data);
      }
      _pagination = response.data!.pagination;
      if (_pagination != null) {
        _currentPage = _pagination!.page + 1;
      }
    } else {
      _error = response.message;
    }

    _isLoading = false;
    _isPaginationLoading = false;
    notifyListeners();
    // Also fetch unread count when notifications are fetched
    if (isRefresh) {
      fetchUnreadCount();
    }
  }

  Future<void> fetchUnreadCount() async {
    final response = await _service.fetchUnreadCount();
    if (response.success && response.data != null) {
      _unreadCount = response.data!;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final response = await _service.markAllAsRead();
    if (response.success) {
      fetchNotifications(isRefresh: true, type: _currentType);
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    debugPrint("Marking notification as read, ID: $notificationId");
    final response = await _service.markAsRead(notificationId);
    if (response.success) {
      fetchNotifications(isRefresh: true, type: _currentType);
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    debugPrint("Deleting notification, ID: $notificationId");
    final response = await _service.deleteNotification(notificationId);
    if (response.success) {
      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
      notifyListeners();
      fetchNotifications(isRefresh: true, type: _currentType);
    }
  }

  String _currentType = 'general';

  bool get hasMore => _pagination?.hasNext ?? false;

  Future<void> loadMore({String type = 'general'}) async {
    if (!hasMore || _isPaginationLoading) return;
    await fetchNotifications(type: _currentType);
  }
}
