import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/api/api_response.dart';
import 'package:tool_bocs/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/profile/model/user_profile_model.dart';
import 'package:tool_bocs/features/profile/model/user_review_request_model.dart';
import '../model/blocked_user_model.dart';
import 'package:tool_bocs/features/profile/service/profile_service.dart';
import 'package:tool_bocs/features/profile/view/user_profile_screen.dart';
import 'package:tool_bocs/features/profile/view/profile_screen.dart';
import 'package:tool_bocs/core/services/firebase_notification_service.dart';
import 'package:tool_bocs/features/profile/model/saved_user_model.dart';
import 'package:tool_bocs/features/profile/model/faq_model.dart';
import 'package:tool_bocs/features/profile/model/collection_model.dart';
import 'package:tool_bocs/features/profile/model/collection_item_model.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/core/models/pagination_model.dart';
import 'package:tool_bocs/core/services/storage_service.dart';
import 'package:tool_bocs/core/widgets/responsive_layout.dart';
import 'package:tool_bocs/features/web_ui/view/web_user_profile_screen.dart';
class ProfileController extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  UserProfileModel? _ownProfile;
  UserProfileModel? _viewedProfile;
  List<BlockedUserModel> _blockedUsers = [];
  List<SavedUserModel> _savedUsers = [];
  List<CollectionModel> _collections = [];
  List<FaqModel> _faqs = [];
  List<PostModel> _myPosts = [];

  int _totalMyPostsCount = 0;
  int _totalMyGivesCount = 0;
  int _totalMyTakesCount = 0;
  String _selectedMyPostsFilter = 'All';
  bool _isLoading = false;
  bool _isPaginationLoading = false;
  String? _errorMessage;
  Pagination? _myPostsPagination;
  int _currentMyPostsPage = 1;

  UserProfileModel? get ownProfile => _ownProfile;
  UserProfileModel? get viewedProfile => _viewedProfile;
  List<BlockedUserModel> get blockedUsers => _blockedUsers;
  List<SavedUserModel> get savedUsers => _savedUsers;
  List<CollectionModel> get collections => _collections;
  List<FaqModel> get faqs => _faqs;
  List<PostModel> get myPosts => _myPosts;
  int get totalMyPostsCount => _totalMyPostsCount;
  int get totalMyGivesCount => _totalMyGivesCount;
  int get totalMyTakesCount => _totalMyTakesCount;
  String get selectedMyPostsFilter => _selectedMyPostsFilter;
  UserProfileModel? get userProfile =>
      _viewedProfile ??
      _ownProfile; // Keep for backward compatibility if needed, but preferably use specific ones
  bool get isLoading => _isLoading;
  bool get isPaginationLoading => _isPaginationLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreMyPosts => _myPostsPagination?.hasNext ?? false;

  Future<void> getBlockedUsers() async {
    _isLoading = true;
    notifyListeners();

    final response = await _profileService.fetchBlockedUsers();

    if (response.success) {
      _blockedUsers = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> getSavedUsers() async {
    _isLoading = true;
    notifyListeners();

    final response = await _profileService.fetchSavedUsers();

    if (response.success) {
      _savedUsers = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> getCollections() async {
    _isLoading = true;
    notifyListeners();

    final response = await _profileService.fetchCollections();

    if (response.success) {
      _collections = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ApiResponse<dynamic>> createCollection(String name) async {
    _isLoading = true;
    notifyListeners();

    final response = await _profileService.createCollection(name);

    if (response.success) {
      await getCollections();
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }

  Future<ApiResponse<dynamic>> deleteCollection(int collectionId) async {
    _isLoading = true;
    notifyListeners();

    final response = await _profileService.deleteCollection(collectionId);

    if (response.success) {
      await getCollections();
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }

  Future<ApiResponse<List<CollectionItemModel>>> fetchCollectionItems(int collectionId) async {
    final response = await _profileService.fetchCollectionItems(collectionId);
    if (!response.success) {
      _errorMessage = response.message;
    }
    return response;
  }

  Future<ApiResponse<dynamic>> addCollectionItem(int collectionId, String itemType, int itemId) async {
    final response = await _profileService.addCollectionItem(collectionId, itemType, itemId);
    if (response.success) {
      await getCollections(); // Update the count in the collections list
      await getSavedUsers(); // Update the "All Saved" list
    } else {
      _errorMessage = response.message;
    }
    return response;
  }

  Future<ApiResponse<dynamic>> removeCollectionItem(int collectionId, int itemId) async {
    final response = await _profileService.removeCollectionItem(collectionId, itemId);
    if (response.success) {
      // User requested that removing from a collection should also remove from All Saved
      await unsaveUser(itemId, removeFromCollections: false);
      
      await getCollections(); // Update the count in the collections list
      await getSavedUsers(); // Update the "All Saved" list
    } else {
      _errorMessage = response.message;
    }
    return response;
  }

  Future<ApiResponse<dynamic>> unsaveUser(int userId, {bool removeFromCollections = true}) async {
    final response = await _profileService.unsaveUser(userId);

    if (response.success) {
      if (removeFromCollections) {
        // Also remove the user from all custom collections
        for (var collection in _collections) {
          await _profileService.removeCollectionItem(collection.id, userId);
        }
        await getCollections(); // Refresh the collection list count
      }
      await getSavedUsers();
    } else {
      _errorMessage = response.message;
    }
    return response;
  }

  Future<ApiResponse<dynamic>> blockUser(int userId) async {
    _isLoading = true;
    notifyListeners();

    final response = await _profileService.blockUser(userId);

    if (response.success) {
      // Refresh blocked list
      await getBlockedUsers();
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }

  Future<ApiResponse<dynamic>> unblockUser(int userId) async {
    _isLoading = true;
    notifyListeners();

    final response = await _profileService.unblockUser(userId);

    if (response.success) {
      // Refresh blocked list
      await getBlockedUsers();
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }

  Future<void> loadCachedProfile() async {
    final profileJsonStr = await StorageService.getUserProfile();
    if (profileJsonStr != null && _ownProfile == null) {
      try {
        final Map<String, dynamic> json = jsonDecode(profileJsonStr);
        _ownProfile = UserProfileModel.fromJson(json);
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading cached user profile: $e");
      }
    }
  }

  Future<bool> getUserProfile(int? userId, {bool isOwnProfile = true}) async {
    _isLoading = true;
    _errorMessage = null;
    if (!isOwnProfile) {
      _viewedProfile = null; // Clear previous viewed profile
    }
    notifyListeners();

    final response = isOwnProfile
        ? await _profileService.fetchOwnProfile()
        : await _profileService.fetchOtherProfile(userId ?? 0);

    bool success = false;
    if (response.success) {
      if (isOwnProfile) {
        _ownProfile = response.data;
        if (response.data != null) {
           StorageService.saveUserProfile(jsonEncode(response.data!.toJson()));
        }
      } else {
        _viewedProfile = response.data;
      }
      success = true;
    } else {
      _errorMessage = response.message;
      success = false;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }


  Future<ApiResponse<dynamic>> toggleReviewReaction(int reviewId, String reactionType) async {
    final response = await _profileService.toggleReviewReaction(reviewId, reactionType);

    if (response.success && response.data != null) {
      final updatedData = response.data;
      final int rId = updatedData['review_id'] ?? reviewId;
      final int newLikesCount = int.tryParse(updatedData['likes_count']?.toString() ?? '') ?? 0;
      final int newDislikesCount = int.tryParse(updatedData['dislikes_count']?.toString() ?? '') ?? 0;
      final String? newUserReaction = updatedData['user_reaction'];

      List<Review> updateReviewsList(List<Review> list) {
        return list.map((r) {
          if (r.id == rId) {
            return Review(
              id: r.id,
              userId: r.userId,
              reviewerId: r.reviewerId,
              reviewerName: r.reviewerName,
              reviewerImage: r.reviewerImage,
              rating: r.rating,
              feedbackLabel: r.feedbackLabel,
              comment: r.comment,
              createdAt: r.createdAt,
              likesCount: newLikesCount,
              dislikesCount: newDislikesCount,
              userReaction: newUserReaction,
            );
          }
          return r;
        }).toList();
      }

      if (_ownProfile != null) {
        _ownProfile = UserProfileModel(
          userDetails: _ownProfile!.userDetails,
          tradeStats: _ownProfile!.tradeStats,
          reviews: updateReviewsList(_ownProfile!.reviews),
          isSaved: _ownProfile!.isSaved,
          isRated: _ownProfile!.isRated,
          showTradeHistory: _ownProfile!.showTradeHistory,
        );
      }
      
      if (_viewedProfile != null) {
        _viewedProfile = UserProfileModel(
          userDetails: _viewedProfile!.userDetails,
          tradeStats: _viewedProfile!.tradeStats,
          reviews: updateReviewsList(_viewedProfile!.reviews),
          isSaved: _viewedProfile!.isSaved,
          isRated: _viewedProfile!.isRated,
          showTradeHistory: _viewedProfile!.showTradeHistory,
        );
      }
      notifyListeners();
    } else {
      _errorMessage = response.message;
      notifyListeners();
    }

    return response;
  }

  Future<ApiResponse<dynamic>> submitReview({
    required int userId,
    required String label,
    required String comment,
  }) async {
    // Dynamic mapping from label to rating
    int rating = 0;
    switch (label) {
      case 'Friendly':
        rating = 5;
        break;
      case 'Professional':
        rating = 4;
        break;
      case 'Smooth':
        rating = 3;
        break;
      case 'Average':
        rating = 2;
        break;
      case 'Unpleasant':
        rating = 1;
        break;
      default:
        rating = 5; // Default safe value
    }

    final request = UserReviewRequestModel(
      userId: userId,
      rating: rating,
      feedbackLabel: label,
      comment: comment,
    );

    _isLoading = true;
    notifyListeners();

    final response = await _profileService.submitUserReview(request);

    _isLoading = false;
    notifyListeners();

    if (response.success) {
      // Reload profile to show new review/rating if it's being viewed or is own
      if (_viewedProfile?.userDetails.id == userId) {
        getUserProfile(userId, isOwnProfile: false);
      } else if (_ownProfile?.userDetails.id == userId) {
        getUserProfile(userId, isOwnProfile: true);
      }
    } else {
      _errorMessage = response.message;
    }
    return response;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _ownProfile = null;
    _viewedProfile = null;
    _blockedUsers = [];
    _savedUsers = [];
    _faqs = [];
    _myPosts = [];
    _totalMyPostsCount = 0;
    _totalMyGivesCount = 0;
    _totalMyTakesCount = 0;
    _selectedMyPostsFilter = 'All';
    _myPostsPagination = null;
    _currentMyPostsPage = 1;
    _errorMessage = null;
    notifyListeners();
  }

  Future<ApiResponse<dynamic>> updateProfile({
    String? fullName,
    String? location,
    String? email,
    String? mobile,
    String? bio,
    dynamic profileVisibility,
    int? showTradeHistory,
    String? gender,
    String? dateOfBirth,
    double? latitude,
    double? longitude,
    bool? termsAccepted,
    dynamic profileImage,
    int? age,
    String? occupation,
    String? educationalQualification,
    String? country,
    String? state,
    String? city,
    String? pinCode,
    String? address,
    String? churchName,
    String? fatherOrPastorName,
    String? churchCity,
    String? churchPinCode,
    String? churchAddress,
    String? churchPhoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    final Map<String, dynamic> requestData = {
      'user_id': _ownProfile?.userDetails.id,
      'full_name': fullName ?? _ownProfile?.userDetails.fullName,
      'email': email ?? _ownProfile?.userDetails.email,
      'phone_number': mobile ?? _ownProfile?.userDetails.phoneNumber,
      'location': location ?? _ownProfile?.userDetails.location,
      'latitude': latitude ?? _ownProfile?.userDetails.latitude,
      'longitude': longitude ?? _ownProfile?.userDetails.longitude,
      'date_of_birth': dateOfBirth ?? _ownProfile?.userDetails.dateOfBirth,
      'gender': gender ?? _ownProfile?.userDetails.gender,
      'bio': bio ?? _ownProfile?.userDetails.bio,
      'profile_visibility': profileVisibility ?? _ownProfile?.userDetails.profileVisibility,
      'show_trade_history': showTradeHistory ?? _ownProfile?.userDetails.showTradeHistory,
      'terms_accepted': termsAccepted ?? _ownProfile?.userDetails.termsAccepted,
      'age': age ?? _ownProfile?.userDetails.age,
      'occupation': occupation ?? _ownProfile?.userDetails.occupation,
      'educational_qualification': educationalQualification ?? _ownProfile?.userDetails.educationalQualification,
      'country': country ?? _ownProfile?.userDetails.country,
      'state': state ?? _ownProfile?.userDetails.state,
      'city': city ?? _ownProfile?.userDetails.city,
      'pin_code': pinCode ?? _ownProfile?.userDetails.pinCode,
      'address': address ?? _ownProfile?.userDetails.address,
      'church_name': churchName ?? _ownProfile?.userDetails.churchName,
      'father_or_pastor_name': fatherOrPastorName ?? _ownProfile?.userDetails.fatherOrPastorName,
      'church_city': churchCity ?? _ownProfile?.userDetails.churchCity,
      'church_pin_code': churchPinCode ?? _ownProfile?.userDetails.churchPinCode,
      'church_address': churchAddress ?? _ownProfile?.userDetails.churchAddress,
      'church_phone_number': churchPhoneNumber ?? _ownProfile?.userDetails.churchPhoneNumber,
    };

    // 1. Update Profile Image if provided
    if (profileImage != null) {
      final imageResponse = await _profileService.updateProfileImage(profileImage);
      if (!imageResponse.success) {
        _isLoading = false;
        _errorMessage = imageResponse.message;
        notifyListeners();
        return imageResponse;
      }
    }

    // 2. Update General Profile Data
    ApiResponse<dynamic> response = await _profileService.updateGeneralProfile(requestData);

    // WORKAROUND for backend bug where completeProfile crashes on createNotification
    // The database is successfully updated, but the backend throws this error
    // because it tries to send a notification and fails. We can safely ignore it.
    if (!response.success && response.message?.contains("createNotification") == true) {
      response = ApiResponse(
        success: true,
        message: "Profile updated successfully",
        data: response.data,
      );
    }

    _isLoading = false;
    notifyListeners();

    if (response.success) {
      // Reload own profile after update
      if (_ownProfile != null) {
        final reloadSuccess = await getUserProfile(_ownProfile!.userDetails.id,
            isOwnProfile: true);
        // Sync both name and profile image to Firestore so chat screens stay up to date
        if (reloadSuccess) {
           FirebaseNotificationService.syncProfileData(
            fullName: _ownProfile?.userDetails.fullName,
            profileImageUrl: _ownProfile?.userDetails.image,
          );
        }
      }
    } else {
      _errorMessage = response.message;
    }
    return response;
  }

  /// Global helper to navigate to user profile with privacy guard
  static void navigateToUserProfile(BuildContext context, int userId) {
    final authController = context.read<AuthController>();
    final isWeb = ResponsiveLayout.isWeb(context);

    // If it's own profile, push ProfileScreen
    if (authController.currentUser?.id == userId) {
      if (isWeb) {
        // Typically on web, own profile is accessed via nav bar or WebProfileScreen,
        // but if navigated directly here, we can fallback to the web user profile screen for consistency 
        // or just let it load own profile in it.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebUserProfileScreen(userId: userId.toString()),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(isTab: false, isDrawer: false),
          ),
        );
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => isWeb
            ? WebUserProfileScreen(userId: userId.toString())
            : UserProfileScreen(userId: userId.toString()),
      ),
    );
  }
  Future<void> getFaqs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _profileService.fetchFaqs();

    if (response.success) {
      _faqs = response.data ?? [];
      // Sort by sequence number
      _faqs.sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ApiResponse<dynamic>> submitFeedback(String message) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _profileService.submitFeedback(message);

    if (!response.success) {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }

  Future<void> getMyPosts(
      {String postType = 'all',
      String label = 'All',
      bool isRefresh = true}) async {
    if (isRefresh) {
      _myPosts = [];
      _currentMyPostsPage = 1;
      _isLoading = true;
    } else {
      _isPaginationLoading = true;
    }

    _errorMessage = null;
    _selectedMyPostsFilter = label;
    notifyListeners();

    final response = await _profileService.fetchMyPosts(
      postType: postType,
      page: _currentMyPostsPage,
      limit: 10,
    );

    if (response.success && response.data != null) {
      final newPosts = response.data!.data;
      if (isRefresh) {
        _myPosts = newPosts;
      } else {
        _myPosts.addAll(newPosts);
      }

      _myPostsPagination = response.data!.pagination;
      if (_myPostsPagination != null) {
        _currentMyPostsPage = _myPostsPagination!.page + 1;
      }

      // Update counts based on pagination total if available
      final totalFromApi = _myPostsPagination?.total ?? _myPosts.length;
      if (postType == 'all') {
        _totalMyPostsCount = totalFromApi;
        // fallback calculation for gives/takes if we have the full list
        if (_myPostsPagination?.totalPages == 1) {
           _totalMyGivesCount = _myPosts.where((p) => p.postType.toLowerCase() == 'give').length;
           _totalMyTakesCount = _myPosts.where((p) => p.postType.toLowerCase() == 'take').length;
        }
      } else if (postType == 'give') {
        _totalMyGivesCount = totalFromApi;
      } else if (postType == 'take') {
        _totalMyTakesCount = totalFromApi;
      }
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    _isPaginationLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreMyPosts() async {
    if (!hasMoreMyPosts || _isPaginationLoading) return;

    String postType = 'all';
    if (_selectedMyPostsFilter.trim() == 'Gives') postType = 'give';
    if (_selectedMyPostsFilter.trim() == 'Takes') postType = 'take';

    await getMyPosts(
        postType: postType, label: _selectedMyPostsFilter, isRefresh: false);
  }

}
