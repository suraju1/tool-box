class ApiConstants {
  // Base URL
  // //old
  // static const String baseUrl = 'https://toolbocs.apluscrm.in/api/';
  // static const String baseUrl2 = 'https://toolbocs.apluscrm.in/';

  // // // new
  // static const String baseUrl = 'http://88.222.245.145:4000/api/';
  // static const String baseUrl2 = 'http://88.222.245.145:4000/';
  static const String baseUrl = 'https://toolucsdemo.apluscrm.in/api/';
  static const String baseUrl2 = 'https://toolucsdemo.apluscrm.in';
//   static const String baseUrl = 'https://toolucs.com/api/';
//   static const String baseUrl2 = 'https://toolucs.com/';
  static const String termsConditionsUrl = '${baseUrl2}terms-conditions';
  static const String privacyPolicyUrl = '${baseUrl2}privacy-policy';

  //-------------------------------- API Endpoints -----------------------------------//

  //1. Auth/login/complete-profile/verify-otp/logout
  static const String completeProfile = 'complete-profile'; //post
  static const String login = 'login'; //post
  static const String verifyOtp = 'verify-otp'; //post

  static const String logout = 'logout'; //post
  //2. Categories types
  static const String getCategoryTypes = 'get_categories'; //get

  // 3. give post - getAll/getbyid/create/update/delete
  static const String createGiveTakePost = 'create_post'; // post
  static const String getAllGiveTakePost = 'get_posts'; // get
  static const String getGiveTakePostById = 'get_post_by_id/{{postid}}'; //get
  static const String updateGiveTakePost = 'update_post/{{postid}}'; // put
  static const String deleteGiveTakePost = 'delete_post/{{postid}}'; // put
  static const String getMyPosts = 'get_my_posts'; //get

  // New endpoint for reactivating a post
  static const String reactivatePost = 'reactivate_post/{{postId}}'; //put
  static const String deactivatePost = 'inactive_post/{{postId}}'; //put

  // 4-Step Trade Flow
  static const String respondToPost = 'respond/{{postid}}'; //post
  static const String getPostResponses = 'responses/{{postid}}'; //get
  static const String getMyPostResponses = 'my-post-responses'; //get
  static const String getMyResponses = 'my-responses'; //get
  static const String updateResponseStatus = 'update_response_status'; //post
  static const String processTradePayment = 'process_trade_payment'; //post
  static const String completeTrade = 'complete/{{id}}'; //post
  static const String tradeHistoryEndpoint = 'my-trades'; //get
  static const String getTradeDetailsById =
      'my-post-responses-by-id/{{id}}'; //get
  static const String cancelTrade = 'cancel/{{id}}'; //put
  static const String getUserProfile = 'get_user_profile'; //get
  static const String getOtherProfile = 'get_other_profile/{{id}}'; //get

  static const String submitUserReview = 'submit_user_review'; //post
  static const String toggleReviewReaction = 'toggle_review_reaction'; //post
  static const String submitUserMark = 'submit_user_mark'; //post
  static const String updateProfile = 'update_profile'; //post
  static const String getAchievements = 'user/achievements'; //get
  static const String getReportReasons = 'report-reasons'; //get
  static const String reportPost = 'report-post'; //post

  // 5. Address Management
  static const String saveAddress = 'save_address'; //post
  static const String myAddresses = 'my_addresses'; //get
  static const String editAddress = 'edit_address/{{id}}'; //put
  static const String deleteAddress = 'del_address/{{id}}'; //delete
  static const String getAddress = 'address/{{id}}'; //get

  // Block/Unblock
  static const String blockUser = 'user_blocked/{{id}}'; //post
  static const String unblockUser = 'unblocked_user/{{id}}'; //delete
  static const String listBlockedUser = 'list_blocked_user'; //get

  // Saved Users
  // static const String userSave = 'user_save/{{id}}'; //post
  static const String unsaveUser = 'unsave_user/{{id}}'; //delete
  static const String listSaveUser = 'list_save_user'; //get
  static const String collections = 'collections'; //get, post
  static const String fetchCollectionItems = 'collections/{{id}}'; //get
  static const String collectionItems = 'collections/{{id}}/items'; //post
  static const String removeCollectionItem =
      'collections/{{id}}/items/{{itemId}}'; //delete
  static const String deleteCollection = 'collections/{{id}}'; //delete

  // static const String reactivatePost = 'reactivate_post/{{postid}}'; //put
  static const String subscribe = 'subscribe'; //post
  static const String createOrder = 'create_order'; //post
  static const String verifyPayment = 'verify_payment'; //post
  static const String mySubscription = 'my_subscription'; //get
  static const String mySubscriptionHistory = 'my_subscription_history'; //get
  static const String viewSubscriptions = 'view_subscriptions'; //get

  //settings
  static const String faqs = 'faqs'; //get
  static const String feedback = 'feedback'; //post

  // Notifications
  static const String notifications = 'notifications'; //get
  static const String notificationUnread = 'notification_unread'; //get
  static const String notificationsReadAll = 'notifications_read_all'; //put
  static const String notificationMarkRead =
      'notification_mark_read/{{id}}'; //put
  static const String notificationDelete = 'notifications_del/{{id}}'; //delete
  static const String walletTransactions = 'wallet_transactions'; //get

  //-----------------------------------------------------------------------------//
  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Storage keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
}
