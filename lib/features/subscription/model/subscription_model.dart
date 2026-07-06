class SubscriptionResponse {
  final bool success;
  final String message;
  final SubscriptionActivationData? data;

  SubscriptionResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? SubscriptionActivationData.fromJson(json['data'])
          : null,
    );
  }
}

class SubscriptionActivationData {
  final double totalBalance;
  final String startDate;
  final String endDate;
  final int remainingDays;
  final bool isExpired;

  SubscriptionActivationData({
    required this.totalBalance,
    required this.startDate,
    required this.endDate,
    required this.remainingDays,
    required this.isExpired,
  });

  factory SubscriptionActivationData.fromJson(Map<String, dynamic> json) {
    return SubscriptionActivationData(
      totalBalance: (json['total_balance'] ?? 0).toDouble(),
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      remainingDays: json['remaining_days'] ?? 0,
      isExpired: json['is_expired'] ?? false,
    );
  }
}

class MySubscriptionResponse {
  final bool success;
  final MySubscriptionData? data;
  final List<MySubscriptionData> activeSubscriptions;

  MySubscriptionResponse({
    required this.success,
    this.data,
    this.activeSubscriptions = const [],
  });

  factory MySubscriptionResponse.fromJson(Map<String, dynamic> json) {
    List<MySubscriptionData> activeSubscriptions = [];
    if (json['data'] != null) {
      if (json['data'] is List) {
        activeSubscriptions = (json['data'] as List)
            .map((e) => MySubscriptionData.fromJson(e))
            .toList();
      } else {
        activeSubscriptions = [MySubscriptionData.fromJson(json['data'])];
      }
    }
    return MySubscriptionResponse(
      success: json['success'] ?? false,
      data: activeSubscriptions.isNotEmpty ? activeSubscriptions.first : null, // Support legacy single object access
      activeSubscriptions: activeSubscriptions,
    );
  }
}

class MySubscriptionData {
  final int id;
  final int userId;
  final int subscriptionId;
  final String remainingCredit;
  final int usedPosts;
  final String postPrice;
  final String startDate;
  final String endDate;
  final String status;
  final String name;
  final int days;
  final int creditBalance;
  final bool isExpired;
  final String computedStatus;
  final int remainingDays;

  MySubscriptionData({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.remainingCredit,
    required this.usedPosts,
    required this.postPrice,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.name,
    required this.days,
    required this.creditBalance,
    required this.isExpired,
    required this.computedStatus,
    required this.remainingDays,
  });

  factory MySubscriptionData.fromJson(Map<String, dynamic> json) {
    return MySubscriptionData(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      subscriptionId: json['subscription_id'] ?? 0,
      remainingCredit: json['remaining_credit']?.toString() ?? '0.00',
      usedPosts: json['used_posts'] ?? 0,
      postPrice: json['post_price']?.toString() ?? '0.00',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? '',
      name: json['name'] ?? '',
      days: json['days'] ?? 0,
      creditBalance: json['credit_balance'] ?? 0,
      isExpired: json['is_expired'] ?? false,
      computedStatus: json['computed_status'] ?? '',
      remainingDays: json['remaining_days'] ?? 0,
    );
  }
}

class AvailableSubscriptionsResponse {
  final int user;
  final List<AvailablePlan> subscriptions;
  final bool success;

  AvailableSubscriptionsResponse({
    required this.user,
    required this.subscriptions,
    required this.success,
  });

  factory AvailableSubscriptionsResponse.fromJson(Map<String, dynamic> json) {
    return AvailableSubscriptionsResponse(
      user: json['user'] ?? 0,
      subscriptions: (json['subscriptions'] as List?)
              ?.map((e) => AvailablePlan.fromJson(e))
              .toList() ??
          [],
      success: json['success'] ?? false,
    );
  }
}

class AvailablePlan {
  final int id;
  final String name;
  final String price;
  final String status;
  final String description;
  final int days;
  final int creditBalance;
  final String createdAt;

  AvailablePlan({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    required this.description,
    required this.days,
    required this.creditBalance,
    required this.createdAt,
  });

  factory AvailablePlan.fromJson(Map<String, dynamic> json) {
    return AvailablePlan(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0.00',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      days: json['days'] ?? 0,
      creditBalance: json['credit_balance'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class CreateOrderResponse {
  final bool success;
  final String? orderId;
  final int amount;
  final String currency;
  final CreateOrderData? subscription;
  final String message;

  CreateOrderResponse({
    required this.success,
    this.orderId,
    this.amount = 0,
    this.currency = 'INR',
    this.subscription,
    this.message = '',
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      success: json['success'] ?? false,
      orderId: json['order_id']?.toString(),
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'INR',
      subscription: json['subscription'] != null
          ? CreateOrderData.fromJson(json['subscription'])
          : null,
      message: json['message'] ?? '',
    );
  }
}

class CreateOrderData {
  final int id;
  final String name;
  final String price;
  final int days;

  CreateOrderData({
    required this.id,
    required this.name,
    required this.price,
    required this.days,
  });

  factory CreateOrderData.fromJson(Map<String, dynamic> json) {
    return CreateOrderData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0.00',
      days: json['days'] ?? 0,
    );
  }
}
