import 'package:flutter/material.dart';
import 'package:tool_bocs/core/api/api_exception.dart';
import 'package:tool_bocs/features/subscription/model/subscription_model.dart';
import 'package:tool_bocs/features/subscription/model/subscription_history_model.dart';
import 'package:tool_bocs/features/subscription/services/subscription_service.dart';

class SubscriptionController extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Loading states
  bool _isLoading = false;
  bool _isHistoryLoading = false;
  bool _isPlansLoading = false;
  bool _isActivating = false;
  int? _activatingPlanId;

  // Data
  List<MySubscriptionData> _activeSubscriptions = [];
  MySubscriptionData? _mySubscription;
  List<SubscriptionHistoryItem> _history = [];
  List<AvailablePlan> _availablePlans = [];
  
  // Error/Success messages
  String? _errorMessage;
  String? _successMessage;

  // Filter
  int _selectedYear = DateTime.now().year;

  // Getters
  bool get isLoading => _isLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  bool get isPlansLoading => _isPlansLoading;
  bool get isActivating => _isActivating;
  int? get activatingPlanId => _activatingPlanId;
  List<MySubscriptionData> get activeSubscriptions => _activeSubscriptions;
  MySubscriptionData? get mySubscription => _mySubscription;
  List<SubscriptionHistoryItem> get history => _history;
  List<AvailablePlan> get availablePlans => _availablePlans;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get selectedYear => _selectedYear;

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
    fetchSubscriptionHistory();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Fetch current user subscription
  Future<void> fetchMySubscription() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _subscriptionService.getMySubscription();
      if (response.success) {
        _activeSubscriptions = response.activeSubscriptions;
        _mySubscription = response.data;
      } else {
        _errorMessage = "Failed to fetch subscription info";
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = "An unexpected error occurred";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch subscription history
  Future<void> fetchSubscriptionHistory() async {
    _isHistoryLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _subscriptionService.getSubscriptionHistory(year: _selectedYear);
      if (response.success) {
        _history = response.data;
      } else {
        _errorMessage = "Failed to fetch subscription history";
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = "An unexpected error occurred";
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  /// Activate a subscription
  Future<bool> activateSubscription(int subscriptionId) async {
    _isActivating = true;
    _activatingPlanId = subscriptionId;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _subscriptionService.activateSubscription(subscriptionId);
      if (response.success) {
        _successMessage = response.message;
        // Refresh subscription info after activation
        await fetchMySubscription();
        return true;
      } else {
        _errorMessage = response.message;
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred";
      return false;
    } finally {
      _isActivating = false;
      _activatingPlanId = null;
      notifyListeners();
    }
  }

  /// Cancel activation loading state (e.g. when payment popup is closed or fails)
  void cancelActivation() {
    if (_isActivating) {
      _isActivating = false;
      _activatingPlanId = null;
      notifyListeners();
    }
  }

  /// Create Razorpay order for subscription plan
  Future<CreateOrderResponse?> createOrder(int subscriptionId) async {
    _isActivating = true;
    _activatingPlanId = subscriptionId;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _subscriptionService.createOrder(subscriptionId);
      if (response.success && response.orderId != null) {
        return response;
      } else {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : "Failed to create order";
        _isActivating = false;
        _activatingPlanId = null;
        notifyListeners();
        return null;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isActivating = false;
      _activatingPlanId = null;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = "An unexpected error occurred while creating order";
      _isActivating = false;
      _activatingPlanId = null;
      notifyListeners();
      return null;
    }
  }

  /// Verify Razorpay payment and activate subscription
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required int subscriptionId,
  }) async {
    _isActivating = true;
    _activatingPlanId = subscriptionId;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _subscriptionService.verifyPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        subscriptionId: subscriptionId,
      );
      if (response.success) {
        _successMessage = response.message;
        await fetchMySubscription();
        return true;
      } else {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : "Payment verification failed";
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred during payment verification";
      return false;
    } finally {
      _isActivating = false;
      _activatingPlanId = null;
      notifyListeners();
    }
  }

  /// Fetch all available subscription plans
  Future<void> fetchAvailablePlans() async {
    _isPlansLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _subscriptionService.getAvailableSubscriptions();
      if (response.success) {
        _availablePlans = response.subscriptions;
      } else {
        _errorMessage = "Failed to fetch available plans";
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = "An unexpected error occurred";
    } finally {
      _isPlansLoading = false;
      notifyListeners();
    }
  }
}
