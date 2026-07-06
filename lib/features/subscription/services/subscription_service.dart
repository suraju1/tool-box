import 'package:tool_bocs/core/api/api_client.dart';
import 'package:tool_bocs/core/api/api_constants.dart';
import 'package:tool_bocs/features/subscription/model/subscription_model.dart';
import 'package:tool_bocs/features/subscription/model/subscription_history_model.dart';

class SubscriptionService {
  final ApiClient _apiClient = ApiClient();

  /// Activate a subscription plan
  Future<SubscriptionResponse> activateSubscription(int subscriptionId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.subscribe,
        data: {'subscription_id': subscriptionId},
      );
      return SubscriptionResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user subscription info
  Future<MySubscriptionResponse> getMySubscription() async {
    try {
      final response = await _apiClient.get(ApiConstants.mySubscription);
      return MySubscriptionResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get subscription history
  Future<SubscriptionHistoryResponse> getSubscriptionHistory({int? year}) async {
    try {
      String url = ApiConstants.mySubscriptionHistory;
      if (year != null) {
        url = '$url?year=$year';
      }
      final response = await _apiClient.get(url);
      return SubscriptionHistoryResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all available subscription plans
  Future<AvailableSubscriptionsResponse> getAvailableSubscriptions() async {
    try {
      final response = await _apiClient.get(ApiConstants.viewSubscriptions);
      return AvailableSubscriptionsResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Create Razorpay order for a subscription plan
  Future<CreateOrderResponse> createOrder(int subscriptionId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.createOrder,
        data: {'subscription_id': subscriptionId},
      );
      return CreateOrderResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify Razorpay payment and activate subscription
  Future<SubscriptionResponse> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required int subscriptionId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.verifyPayment,
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'subscription_id': subscriptionId,
        },
      );
      return SubscriptionResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
