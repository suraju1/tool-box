import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tool_bocs/core/api/api_client.dart';
import 'package:tool_bocs/core/api/api_constants.dart';
import 'package:tool_bocs/core/api/api_response.dart';
import 'package:tool_bocs/features/profile/model/user_profile_model.dart';
import 'package:tool_bocs/features/profile/model/user_review_request_model.dart';
import '../model/blocked_user_model.dart';

import 'package:tool_bocs/features/profile/model/saved_user_model.dart';
import 'package:tool_bocs/features/profile/model/faq_model.dart';
import 'package:tool_bocs/features/profile/model/collection_model.dart';
import 'package:tool_bocs/features/profile/model/collection_item_model.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<UserProfileModel>> fetchOwnProfile() async {
    try {
      final response = await _apiClient.get(ApiConstants.getUserProfile);
      _logProfileApiResponse('OWN PROFILE', response.data);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Profile fetched successfully',
            data: UserProfileModel.fromJson(data['data']),
          );
        } else {
          return ApiResponse(
            success: false,
            message:
                data['error'] ?? data['message'] ?? 'Failed to fetch profile',
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

  Future<ApiResponse<UserProfileModel>> fetchOtherProfile(int userId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getOtherProfile.replaceFirst('{{id}}', userId.toString()),
      );
      _logProfileApiResponse('OTHER PROFILE $userId', response.data);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Profile fetched successfully',
            data: UserProfileModel.fromJson(data['data']),
          );
        } else {
          return ApiResponse(
            success: false,
            message:
                data['error'] ?? data['message'] ?? 'Failed to fetch profile',
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


  Future<ApiResponse<dynamic>> toggleReviewReaction(
      int reviewId, String reactionType) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.toggleReviewReaction,
        data: {
          'review_id': reviewId,
          'reaction_type': reactionType,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Review reaction updated successfully',
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

  Future<ApiResponse<dynamic>> deleteUserReview(int reviewId) async {
    try {
      final response = await _apiClient.delete(
        ApiConstants.deleteUserReview.replaceFirst('{{id}}', reviewId.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Review deleted successfully',
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

  Future<ApiResponse<dynamic>> clearReviewComment(int reviewId) async {
    try {
      final response = await _apiClient.patch(
        ApiConstants.clearReviewComment.replaceFirst('{{id}}', reviewId.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Comment cleared successfully',
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

  Future<ApiResponse<dynamic>> submitUserReview(
      UserReviewRequestModel request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.submitUserReview,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ??
              data['msg'] ??
              data['error'] ??
              'Review submitted successfully',
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

  Future<ApiResponse<dynamic>> updateGeneralProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.completeProfile,
        data: data,
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        return ApiResponse(
          success: resData['success'] ?? false,
          message: resData['message'] ?? 'Profile updated successfully',
          data: resData['data'],
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

  Future<ApiResponse<dynamic>> updateProfileImage(dynamic imageFile) async {
    try {
      final formData = FormData();
      final String path = imageFile.path;
      String fileName = '';
      try {
        fileName = imageFile.name;
      } catch (_) {
        fileName = path.split(RegExp(r'[\\/]')).last;
      }

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        formData.files.add(MapEntry(
            'profile_image',
            MultipartFile.fromBytes(bytes, filename: fileName)));
      } else {
        formData.files.add(MapEntry(
            'profile_image',
            await MultipartFile.fromFile(path, filename: fileName)));
      }

      final response = await _apiClient.post(
        ApiConstants.updateProfile,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data; boundary=${formData.boundary}',
        ),
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        return ApiResponse(
          success: resData['success'] ?? false,
          message: resData['message'] ?? 'Profile image updated successfully',
          data: resData['data'],
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

  Future<ApiResponse<dynamic>> blockUser(int userId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.blockUser.replaceFirst('{{id}}', userId.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'User blocked successfully',
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

  Future<ApiResponse<dynamic>> unblockUser(int userId) async {
    try {
      final response = await _apiClient.delete(
        ApiConstants.unblockUser.replaceFirst('{{id}}', userId.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'User unblocked successfully',
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

  Future<ApiResponse<List<BlockedUserModel>>> fetchBlockedUsers() async {
    try {
      final response = await _apiClient.get(ApiConstants.listBlockedUser);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> blockedData = data['data'];
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Blocked users fetched successfully',
            data: blockedData.map((e) => BlockedUserModel.fromJson(e)).toList(),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch blocked users',
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

  Future<ApiResponse<dynamic>> addUserToCollection(int collectionId, int targetUserId) async {
    try {
      final endpoint = ApiConstants.addUserToCollection
          .replaceFirst('{{collectionId}}', collectionId.toString())
          .replaceFirst('{{targetUserId}}', targetUserId.toString());
      final response = await _apiClient.post(endpoint);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'User added to collection successfully',
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

  Future<ApiResponse<dynamic>> addCollectionItem(int collectionId, String itemType, int itemId) async {
    if (itemType == 'profile' || itemType == 'user') {
      return addUserToCollection(collectionId, itemId);
    }
    try {
      final response = await _apiClient.post(
        ApiConstants.collectionItems.replaceFirst('{{id}}', collectionId.toString()),
        data: {'item_type': itemType, 'item_id': itemId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Item added to collection successfully',
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

  Future<ApiResponse<List<CollectionItemModel>>> fetchCollectionMembers(int collectionId) async {
    return fetchCollectionItems(collectionId);
  }

  Future<ApiResponse<List<CollectionItemModel>>> fetchCollectionItems(int collectionId) async {
    try {
      final endpoint = ApiConstants.fetchCollectionMembers
          .replaceFirst('{{collectionId}}', collectionId.toString())
          .replaceFirst('{{id}}', collectionId.toString());
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> itemsData;
          if (data['data'] is List) {
            itemsData = data['data'];
          } else if (data['data'] is Map && data['data']['members'] != null) {
            itemsData = data['data']['members'];
          } else if (data['data'] is Map && data['data']['items'] != null) {
            itemsData = data['data']['items'];
          } else {
            itemsData = [];
          }
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Collection members fetched successfully',
            data: itemsData.map((e) => CollectionItemModel.fromJson(e)).toList(),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch collection members',
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

  Future<ApiResponse<dynamic>> removeUserFromCollection(int collectionId, int targetUserId) async {
    try {
      final endpoint = ApiConstants.removeUserFromCollection
          .replaceFirst('{{collectionId}}', collectionId.toString())
          .replaceFirst('{{targetUserId}}', targetUserId.toString())
          .replaceFirst('{{id}}', collectionId.toString())
          .replaceFirst('{{itemId}}', targetUserId.toString());
      final response = await _apiClient.delete(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'User removed from collection successfully',
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

  Future<ApiResponse<dynamic>> removeCollectionItem(int collectionId, int itemId) async {
    return removeUserFromCollection(collectionId, itemId);
  }

  Future<ApiResponse<dynamic>> deleteCollection(int collectionId) async {
    try {
      final endpoint = ApiConstants.deleteCollection
          .replaceFirst('{{collectionId}}', collectionId.toString())
          .replaceFirst('{{id}}', collectionId.toString());
      final response = await _apiClient.delete(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Collection deleted successfully',
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

  Future<ApiResponse<dynamic>> saveUser(int userId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.userSave.replaceFirst('{{id}}', userId.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'User saved successfully',
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

  Future<ApiResponse<dynamic>> unsaveUser(int userId) async {
    try {
      final response = await _apiClient.delete(
        ApiConstants.unsaveUser.replaceFirst('{{id}}', userId.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'User unsaved successfully',
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

  Future<ApiResponse<List<SavedUserModel>>> fetchSavedUsers() async {
    try {
      final response = await _apiClient.get(ApiConstants.listSaveUser);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> savedData = data['data'];
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Saved users fetched successfully',
            data: savedData.map((e) => SavedUserModel.fromJson(e)).toList(),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch saved users',
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

  Future<ApiResponse<List<CollectionModel>>> fetchCollections() async {
    try {
      final response = await _apiClient.get(ApiConstants.listCollections);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> collectionsData = data['data'];
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Collections fetched successfully',
            data: collectionsData.map((e) => CollectionModel.fromJson(e)).toList(),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch collections',
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

  Future<ApiResponse<CollectionModel>> createCollection(String name) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.createCollection,
        data: {'name': name},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Collection created successfully',
          data: data['data'] != null
              ? CollectionModel.fromJson(data['data'])
              : null,
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

  Future<ApiResponse<List<FaqModel>>> fetchFaqs() async {
    try {
      final response = await _apiClient.get(ApiConstants.faqs);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> faqData = data['data'];
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'FAQs fetched successfully',
            data: faqData.map((e) => FaqModel.fromJson(e)).toList(),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch FAQs',
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

  Future<ApiResponse<dynamic>> submitFeedback(String message) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.feedback,
        data: {'message': message},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Feedback submitted successfully',
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

  Future<ApiResponse<PostResponseModel>> fetchMyPosts(
      {String postType = 'all', int page = 1, int limit = 10}) async {
    try {
      final Map<String, dynamic> queryParameters = {};

      if (postType != 'all') {
        queryParameters['type'] = postType;
      }
      queryParameters['page'] = page;
      queryParameters['limit'] = limit;

      final response = await _apiClient.get(
        ApiConstants.getMyPosts,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'My posts fetched successfully',
            data: PostResponseModel.fromJson(data),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch my posts',
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

  void _logProfileApiResponse(String title, dynamic data) {
    if (!kDebugMode) return;

    String output;
    try {
      output = const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      output = data.toString();
    }

    const chunkSize = 800;
    debugPrint('================ $title API RESPONSE START ================');
    for (var i = 0; i < output.length; i += chunkSize) {
      final end =
          i + chunkSize < output.length ? i + chunkSize : output.length;
      debugPrint(output.substring(i, end));
    }
    debugPrint('================ $title API RESPONSE END ==================');
  }
}
