import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:tool_bocs/core/api/api_client.dart';
import 'package:tool_bocs/core/api/api_constants.dart';
import 'package:tool_bocs/features/trades/model/category_model.dart';
import 'package:tool_bocs/features/trades/model/my_trade_model.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/features/trades/model/post_request_model.dart';
import 'package:tool_bocs/features/trades/model/trade_response_model.dart';
import 'package:tool_bocs/features/trades/model/trade_response_request_model.dart';
import 'package:tool_bocs/core/api/api_response.dart';
import 'package:tool_bocs/features/trades/model/trade_completion_model.dart';
import 'package:tool_bocs/features/trades/model/report_reason_model.dart';

class TradeService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<CategoryModel>>> fetchCategories() async {
    try {
      final response = await _apiClient.get(ApiConstants.getCategoryTypes);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> &&
            data['success'] == true &&
            data['data'] != null) {
          final List<dynamic> categoriesJson = data['data'];
          final categories = categoriesJson
              .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse(
              success: true, message: 'Categories fetched', data: categories);
        } else if (data is List) {
          final categories = data
              .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse(
              success: true, message: 'Categories fetched', data: categories);
        } else {
          return ApiResponse(
              success: false,
              message: data is Map
                  ? (data['message'] ?? 'Failed to fetch categories')
                  : 'Unexpected response format');
        }
      } else {
        return ApiResponse(
            success: false, message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<dynamic>> createPost(PostRequestModel request) async {
    try {
      final formData = await request.toFormData();
      final response = await _apiClient.post(
        ApiConstants.createGiveTakePost,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data; boundary=${formData.boundary}',
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResponse(
              success: true,
              message: data['message'] ?? 'Post created successfully',
              data: data['data']);
        } else {
          return ApiResponse(
              success: false,
              message: data['message'] ?? 'Failed to create post');
        }
      } else {
        return ApiResponse(
            success: false, message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<List<PostModel>>> getAllPosts({
    String type = 'all',
    int page = 1,
    int limit = 10,
    double? latitude,
    double? longitude,
    double? distanceKm,
    String? search,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getAllGiveTakePost,
        queryParameters: {
          "type": type,
          "page": page,
          "limit": limit,
          if (latitude != null) "latitude": latitude,
          if (longitude != null) "longitude": longitude,
          if (distanceKm != null)
            "distance_km": double.parse(distanceKm.toStringAsFixed(2)),
          if (search != null && search.isNotEmpty) "search": search,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print("API Response (getAllPosts): $data");
        if (data is Map<String, dynamic> && data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          final posts = list
              .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse(
              success: true,
              message: 'Posts fetched successfully',
              data: posts);
        } else if (data is List) {
          final posts = data
              .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse(
              success: true,
              message: 'Posts fetched successfully',
              data: posts);
        } else {
          return ApiResponse(
              success: false,
              message: data is Map
                  ? (data['message'] ?? 'Failed to fetch posts')
                  : 'Unexpected response format');
        }
      } else {
        return ApiResponse(
            success: false, message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<PostModel>> getPostById(int id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getGiveTakePostById
            .replaceAll('{{postid}}', id.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Post fetched successfully',
            data: PostModel.fromJson(data['data']),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch post details',
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

  Future<ApiResponse<dynamic>> deletePost(int id) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.deleteGiveTakePost.replaceAll('{{postid}}', id.toString()),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Post deleted successfully',
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

  Future<ApiResponse<dynamic>> reactivatePost(int id) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.reactivatePost.replaceAll('{{postId}}', id.toString()),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Post reactivated successfully',
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

  Future<ApiResponse<dynamic>> deactivatePost(int id) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.deactivatePost.replaceAll('{{postId}}', id.toString()),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Post deactivated successfully',
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

  // --- 4-Step Trade Flow Methods ---

  Future<ApiResponse<dynamic>> respondToPost(
      TradeResponseRequestModel request) async {
    try {
      final formData = await request.toFormData();
      final response = await _apiClient.post(
        ApiConstants.respondToPost
            .replaceAll('{{postid}}', request.giveawayId.toString()),
        data: formData,
        queryParameters: {'return_type': request.returnType.toLowerCase()},
        options: Options(
          contentType: 'multipart/form-data; boundary=${formData.boundary}',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Response submitted',
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

  Future<ApiResponse<Map<String, dynamic>>> getPostResponses(int postId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getPostResponses
            .replaceAll('{{postid}}', postId.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('--- getPostResponses API RAW Response: ${jsonEncode(data)}');
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          final responses =
              list.map((e) => TradeResponseModel.fromJson(e)).toList();

          PostModel? giveaway;
          if (data['giveaway'] != null) {
            try {
              giveaway = PostModel.fromJson(data['giveaway']);
            } catch (e) {
              print('Error parsing giveaway metadata: $e');
            }
          }

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Responses fetched',
            data: {
              'responses': responses,
              'giveaway': giveaway,
            },
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch responses',
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

  Future<ApiResponse<List<TradeResponseModel>>> getMyPostResponses({double? latitude, double? longitude}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getMyPostResponses,
        queryParameters: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('--- getMyPostResponses API RAW Response: ${jsonEncode(data)}');
        if (data['success'] == true) {
          final List<TradeResponseModel> responses = [];
          for (var e in (data['data'] as List)) {
            try {
              responses.add(TradeResponseModel.fromJson(e));
            } catch (err) {
              print('Error parsing incoming response: $err for data: $e');
            }
          }
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'All responses fetched',
            data: responses,
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch responses',
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

  Future<ApiResponse<List<TradeResponseModel>>> getMySentResponses({double? latitude, double? longitude}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getMyResponses,
        queryParameters: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('--- getMySentResponses API RAW Response: ${jsonEncode(data)}');
        if (data['success'] == true) {
          final List<TradeResponseModel> responses = [];
          for (var e in (data['data'] as List)) {
            try {
              responses.add(TradeResponseModel.fromJson(e));
            } catch (err) {
              print('Error parsing sent response: $err for data: $e');
            }
          }
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Sent offers fetched successfully',
            data: responses,
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch sent offers',
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

  Future<ApiResponse<dynamic>> updateResponseStatus({
    required int responseId,
    required String status,
    String? meetingType,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.updateResponseStatus,
        data: {
          'response_id': responseId,
          'status': status,
          if (meetingType != null) 'meeting_type': meetingType,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Status updated',
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

  Future<ApiResponse<TradeCompletionModel>> processTradePayment(
      int responseId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.completeTrade.replaceAll('{{id}}', responseId.toString()),
        data: {'amount': 5},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Payment processed',
            data: TradeCompletionModel.fromJson(data['data']),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to process payment',
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

  Future<ApiResponse<MyTradeResponseModel>> getMyTrades({
    String postType = 'all',
    String role = 'all',
    String status = 'all',
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.tradeHistoryEndpoint,
        queryParameters: {
          if (postType != 'all') 'post_type': postType,
          // if (role != 'all') 'role': role,
          // if (status != 'all') 'status': status,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'My trades fetched',
            data: MyTradeResponseModel.fromJson(data),
          );
        } else if (data is List) {
          return ApiResponse(
            success: true,
            message: 'My trades fetched',
            data: MyTradeResponseModel.fromJson(<String, dynamic>{
              'success': true,
              'message': 'Success',
              'data': data,
            }),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data is Map
                ? (data['message'] ?? 'Failed to fetch my trades')
                : 'Unexpected response format',
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

  Future<ApiResponse<TradeResponseModel>> getTradeHistoryDetails(int id) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getTradeDetailsById.replaceAll('{{id}}', id.toString()),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Trade details fetched',
            data: TradeResponseModel.fromJson(data['data']),
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Failed to fetch trade details',
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

  Future<ApiResponse<dynamic>> cancelTrade(int id) async {
    try {
      final response = await _apiClient.put(
        ApiConstants.cancelTrade.replaceAll('{{id}}', id.toString()),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Trade cancelled',
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

  Future<ApiResponse<dynamic>> submitUserMark({
    required int tradeResponseId,
    required int userId,
    required String mark,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.submitUserMark,
        data: {
          'trade_response_id': tradeResponseId,
          'user_id': userId,
          'mark': mark,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'User marked successfully',
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

  Future<ApiResponse<List<ReportReasonModel>>> fetchReportReasons() async {
    try {
      final response = await _apiClient.get(ApiConstants.getReportReasons);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true && data['data'] != null) {
          final List<dynamic> reasonsJson = data['data'];
          final reasons = reasonsJson
              .map((e) => ReportReasonModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse(
              success: true, message: 'Reasons fetched', data: reasons);
        } else if (data is List) {
          final reasons = data
              .map((e) => ReportReasonModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResponse(
              success: true, message: 'Reasons fetched', data: reasons);
        } else {
          return ApiResponse(
              success: false,
              message: data is Map
                  ? (data['message'] ?? 'Failed to fetch report reasons')
                  : 'Unexpected response format');
        }
      } else {
        return ApiResponse(
            success: false, message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<dynamic>> reportPost({
    required int postId,
    required int reasonId,
    required String description,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.reportPost,
        data: {
          'post_id': postId,
          'reason_id': reasonId,
          'description': description,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Post reported successfully',
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
