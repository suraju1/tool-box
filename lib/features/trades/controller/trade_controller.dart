import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:tool_bocs/features/trades/model/category_model.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/features/trades/model/post_request_model.dart';
import 'package:tool_bocs/features/trades/model/trade_response_request_model.dart';
import 'package:tool_bocs/features/trades/model/my_trade_model.dart';
import 'package:tool_bocs/features/trades/model/trade_response_model.dart';
import 'package:tool_bocs/features/trades/model/trade_completion_model.dart';
import 'package:tool_bocs/features/trades/service/trade_service.dart';
import 'package:tool_bocs/features/trades/model/report_reason_model.dart';
import 'package:tool_bocs/util/debouncer.dart';

class TradeController extends ChangeNotifier {
  final TradeService _tradeService = TradeService();
  List<int> _hiddenPostIds = [];
  int? _currentUserId;

  void setCurrentUserId(int? id) {
    _currentUserId = id;
  }

  TradeController() {
    _loadHiddenPosts();
  }

  Future<void> _loadHiddenPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('hidden_posts') ?? [];
    _hiddenPostIds = list.map((e) => int.parse(e)).toList();
    notifyListeners();
  }

  Future<void> hidePost(int postId) async {
    if (!_hiddenPostIds.contains(postId)) {
      _hiddenPostIds.add(postId);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList(
          'hidden_posts', _hiddenPostIds.map((id) => id.toString()).toList());
    }
  }

  Future<void> clearHiddenPosts() async {
    if (_hiddenPostIds.isNotEmpty) {
      _hiddenPostIds.clear();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('hidden_posts');
    }
  }

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isPostCreating = false;
  bool _isIncomingLoading = false;
  bool _isSentLoading = false;
  bool _isMyTradesLoading = false;
  bool _isMarkingUser = false;
  // Map to store user marks per trade response ID
  final Map<int, String> _userMarks = {};

  String? _errorMessage;
  String? _categoryErrorMessage;
  bool _noSubscriptionError = false;

  // --- My Trades State ---
  List<MyTradeModel> _myTrades = [];
  MyTradeStats? _myTradeStats;

  List<MyTradeModel> get myTrades => _myTrades;
  MyTradeStats? get myTradeStats => _myTradeStats;
  bool get isMyTradesLoading => _isMyTradesLoading;
  bool get isMarkingUser => _isMarkingUser;

  // Getter for a stored user mark
  String? getUserMark(int tradeResponseId) => _userMarks[tradeResponseId];

  // Setter to store a user mark and notify listeners
  void setUserMark(int tradeResponseId, String mark) {
    _userMarks[tradeResponseId] = mark;
    notifyListeners();
  }

  // --- Filter State ---
  List<String> _selectedCategories = [];
  String _selectedRating = 'All';
  String _selectedReturnType = 'All';
  // Dual sort: distance sort and date sort independently
  String _selectedDistanceSort = 'Nearest First'; // 'Nearest First' | 'Farthest First' | ''
  String _selectedDateSort = '';                  // 'Newest First' | 'Oldest First' | ''
  String _selectedPostType = 'all';

  List<String> get selectedCategories => _selectedCategories;
  String get selectedRating => _selectedRating;
  String get selectedReturnType => _selectedReturnType;
  String get selectedDistanceSort => _selectedDistanceSort;
  String get selectedDateSort => _selectedDateSort;
  // Kept for backward compat (SortButton active indicator)
  String get selectedSort => _selectedDistanceSort.isNotEmpty
      ? _selectedDistanceSort
      : _selectedDateSort;
  String get selectedPostType => _selectedPostType;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isPostCreating => _isPostCreating;
  bool get isIncomingLoading => _isIncomingLoading;
  bool get isSentLoading => _isSentLoading;
  String? get errorMessage => _errorMessage;
  String? get categoryErrorMessage => _categoryErrorMessage;
  bool get isNoSubscriptionError => _noSubscriptionError;
  void clearErrorMessage() {
    if (_errorMessage == null &&
        _categoryErrorMessage == null &&
        !_noSubscriptionError) {
      return;
    }
    _errorMessage = null;
    _categoryErrorMessage = null;
    _noSubscriptionError = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void reset() {
    _givePosts = [];
    _takePosts = [];
    _homePosts = [];
    _myTrades = [];
    _myTradeStats = null;
    _postResponses = [];
    _sentResponses = [];
    _selectedPost = null;
    _selectedResponse = null;
    _lastTradeCompletion = null;
    _hiddenPostIds = [];
    _categories = [];
    _errorMessage = null;
    _categoryErrorMessage = null;
    resetFilters();
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _categoryErrorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.fetchCategories();

      if (response.success) {
        _categories =
            (response.data ?? []).where((cat) => cat.status == 1).toList();
      } else {
        _categoryErrorMessage = response.message;
      }
    } catch (e) {
      _categoryErrorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPost(PostRequestModel request) async {
    _isPostCreating = true;
    _errorMessage = null;
    _noSubscriptionError = false;
    notifyListeners();

    try {
      final response = await _tradeService.createPost(request);

      if (response.success) {
        // Optimistic Update: Add to local list if valid data
        if (response.data != null) {
          try {
            final newPost = PostModel.fromJson(response.data);

            // Add to relevant lists
            if (newPost.postType == 'give') {
              _givePosts.insert(0, newPost);
            } else if (newPost.postType == 'take') {
              _takePosts.insert(0, newPost);
            }
            // Always add to home posts
            _homePosts.insert(0, newPost);
          } catch (e) {
            print("Error parsing created post for optimistic update: $e");
            // Fallback to fetch if parsing fails is not strictly necessary as the user will likely pull to refresh if they see nothing,
            // but the success return will trigger validation.
          }
        }

        _isPostCreating = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        final msg = _errorMessage?.toLowerCase() ?? '';
        _noSubscriptionError = msg.contains('active subscription') ||
            msg.contains('purchase subscription');
        _isPostCreating = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isPostCreating = false;
      notifyListeners();
      return false;
    }
  }

  // --- Give Posts State ---
  List<PostModel> _givePosts = [];
  bool _isGiveLoading = false;
  int _givePage = 1;
  bool _giveHasNext = true;
  bool _isGiveLoadMoreRunning = false;

  List<PostModel> get givePosts => _applyFilters(_givePosts);
  bool get isGiveLoading => _isGiveLoading;
  bool get giveHasNext => _giveHasNext;
  bool get isGiveLoadMoreRunning => _isGiveLoadMoreRunning;

  // --- Take Posts State ---
  List<PostModel> _takePosts = [];
  bool _isTakeLoading = false;
  int _takePage = 1;
  bool _takeHasNext = true;
  bool _isTakeLoadMoreRunning = false;

  List<PostModel> get takePosts => _applyFilters(_takePosts);
  bool get isTakeLoading => _isTakeLoading;
  bool get takeHasNext => _takeHasNext;
  bool get isTakeLoadMoreRunning => _isTakeLoadMoreRunning;

  // --- Home Posts State (All) ---
  List<PostModel> _homePosts = [];
  bool _isHomeLoading = false;
  int _homePage = 1;
  bool _homeHasNext = true;
  bool _isHomeLoadMoreRunning = false;

  List<PostModel> get homePosts => _applyFilters(_homePosts);
  bool get isHomeLoading => _isHomeLoading;
  bool get homeHasNext => _homeHasNext;
  bool get isHomeLoadMoreRunning => _isHomeLoadMoreRunning;

  final int _limit = 10;
  Timer? _debounceTimer;
  final _searchDebouncer = Debouncer(milliseconds: 500);

  String _giveSearchQuery = '';
  String _takeSearchQuery = '';
  String _homeSearchQuery = '';

  String get giveSearchQuery => _giveSearchQuery;
  String get takeSearchQuery => _takeSearchQuery;
  String get homeSearchQuery => _homeSearchQuery;

  double _distanceKm = 10.0; // Default distance
  double _maxDistanceKm = 10.0;
  double? _latitude;
  double? _longitude;

  double get distanceKm => _distanceKm;
  double get maxDistanceKm => _maxDistanceKm;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get hasLocation => _latitude != null && _longitude != null;
  bool get isDistanceFilterActive => hasLocation;

  void setDistance(double value,
      {bool triggerFetch = false, String fetchType = 'all'}) {
    double clamped = (_maxDistanceKm > 0.01 && value > _maxDistanceKm) ? _maxDistanceKm : value;
    if (_distanceKm == clamped) return;
    _distanceKm = clamped;
    notifyListeners();

    if (triggerFetch) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (fetchType == 'all') {
          fetchHomePosts(refresh: true);
        } else if (fetchType == 'give') {
          fetchGivePosts(refresh: true);
        } else if (fetchType == 'take') {
          fetchTakePosts(refresh: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchDebouncer.cancel();
    super.dispose();
  }

  int _lastLocationUpdateTimestamp = -1;

  void updateLocationAndFetchIfNeeded(double? lat, double? lng, int timestamp, {double? radius}) {
    if (lat == null || lng == null) {
      _latitude = lat;
      _longitude = lng;
      _lastLocationUpdateTimestamp = timestamp;
      if (radius != null && radius > 0) {
        _maxDistanceKm = radius;
        if (_distanceKm > _maxDistanceKm) {
          _distanceKm = _maxDistanceKm;
        }
      }
      return;
    }
    final bool isInitialSync = _lastLocationUpdateTimestamp == -1;
    final bool locationChanged = _latitude != lat || _longitude != lng;
    final bool timestampChanged = timestamp != _lastLocationUpdateTimestamp && !isInitialSync && timestamp != 0;
    bool radiusChanged = false;
    if (radius != null && radius > 0) {
      if (_maxDistanceKm != radius) {
        _maxDistanceKm = radius;
        radiusChanged = true;
      }
    }

    _latitude = lat;
    _longitude = lng;
    _lastLocationUpdateTimestamp = timestamp;

    if (locationChanged || radiusChanged || timestampChanged || _distanceKm > _maxDistanceKm) {
      if (locationChanged || radiusChanged || _distanceKm > _maxDistanceKm) {
        _distanceKm = _maxDistanceKm;
      }
      fetchHomePosts(refresh: true);
      fetchGivePosts(refresh: true);
      fetchTakePosts(refresh: true);
    }
  }

  void setLocation(double? lat, double? lng, {bool triggerFetch = false, double? radius}) {
    bool changed = _latitude != lat || _longitude != lng;
    if (radius != null && radius > 0) {
      if (_maxDistanceKm != radius || _distanceKm > radius || changed) {
        _maxDistanceKm = radius;
        _distanceKm = _maxDistanceKm;
        changed = true;
      }
    }
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
    if (triggerFetch && changed) {
      fetchHomePosts(refresh: true);
      fetchGivePosts(refresh: true);
      fetchTakePosts(refresh: true);
    }
  }

  void updateFilters({
    List<String>? categories,
    String? rating,
    String? returnType,
    String? sort,          // legacy — sets distanceSort
    String? distanceSort,
    String? dateSort,
    String? postType,
  }) {
    if (categories != null) _selectedCategories = categories;
    if (rating != null) _selectedRating = rating;
    if (returnType != null) _selectedReturnType = returnType;
    if (distanceSort != null) _selectedDistanceSort = distanceSort;
    if (dateSort != null) _selectedDateSort = dateSort;
    // legacy fallback
    if (sort != null && distanceSort == null && dateSort == null) {
      _selectedDistanceSort = sort;
    }
    if (postType != null) _selectedPostType = postType;
    notifyListeners();
  }

  void setSearchQuery(String query, {required String type}) {
    if (type == 'give') {
      if (_giveSearchQuery == query) return;
      _giveSearchQuery = query;
    } else if (type == 'take') {
      if (_takeSearchQuery == query) return;
      _takeSearchQuery = query;
    } else {
      if (_homeSearchQuery == query) return;
      _homeSearchQuery = query;
    }
    notifyListeners();

    _searchDebouncer.run(() {
      if (type == 'give') {
        fetchGivePosts(refresh: true);
      } else if (type == 'take') {
        fetchTakePosts(refresh: true);
      } else {
        fetchHomePosts(refresh: true);
      }
    });
  }

  void resetFilters() {
    _selectedCategories = [];
    _selectedRating = 'All';
    _selectedReturnType = 'All';
    _selectedDistanceSort = 'Nearest First';
    _selectedDateSort = '';
    _selectedPostType = 'all';
    _distanceKm = _maxDistanceKm > 0.01 ? _maxDistanceKm : 10.0;
    _giveSearchQuery = '';
    _takeSearchQuery = '';
    _homeSearchQuery = '';
    notifyListeners();
  }

  List<PostModel> _applyFilters(List<PostModel> posts) {
    List<PostModel> filtered = List.from(posts);

    // Filter out hidden posts locally
    filtered = filtered.where((p) => !_hiddenPostIds.contains(p.id)).toList();

    // Filter out current user's posts
    if (_currentUserId != null) {
      filtered = filtered.where((p) => p.userId != _currentUserId).toList();
    }

    // 0. Filter out completed trades (they shouldn't be publicly visible)
    filtered =
        filtered.where((p) => p.status.toLowerCase() != 'completed').toList();

    // 1. Filter by Post Type (only for Home posts usually, but safe here)
    if (_selectedPostType != 'all') {
      filtered = filtered.where((p) {
        final type = p.postType.toLowerCase();
        final selected = _selectedPostType.toLowerCase();
        if (selected == 'give') {
          return type == 'give' || type == 'giving' || type == 'give_away';
        } else if (selected == 'take') {
          return type == 'take' || type == 'taking';
        }
        return type == selected;
      }).toList();
    }

    // 2. Filter by Category
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered
          .where((p) => _selectedCategories.contains(p.itemCategory))
          .toList();
    }

    // 3. Filter by Rating
    if (_selectedRating != 'All') {
      double minRating =
          double.tryParse(_selectedRating.split(' ').first) ?? 0.0;
      filtered =
          filtered.where((p) => (p.userRating ?? 0.0) >= minRating).toList();
    }

    // 4. Filter by Return Type
    if (_selectedReturnType != 'All') {
      filtered = filtered.where((p) {
        final rt = p.returnType.toLowerCase();
        final rCat = (p.returnItemCategory ?? '').toLowerCase();
        final selected = _selectedReturnType.toLowerCase();

        if (selected == 'money') {
          return rt == 'price' || rt == 'money';
        } else if (selected == 'services') {
          return (rt == 'item' || rt == 'exchange') && rCat.contains('services');
        } else if (selected == 'goods') {
          return (rt == 'item' || rt == 'exchange') && rCat.contains('goods');
        }
        
        // Fallback for any exact matches
        return rt == selected;
      }).toList();
    }

    // 5. Sorting — distance (primary) + date (secondary) combined
    filtered.sort((a, b) {
      int distanceCmp = 0;
      int dateCmp = 0;

      if (_selectedDistanceSort == 'Nearest First') {
        distanceCmp = (a.distanceKm ?? 9999.0).compareTo(b.distanceKm ?? 9999.0);
      } else if (_selectedDistanceSort == 'Farthest First') {
        distanceCmp = (b.distanceKm ?? -1.0).compareTo(a.distanceKm ?? -1.0);
      }

      if (_selectedDateSort == 'Newest First') {
        dateCmp = b.createdAt.compareTo(a.createdAt);
      } else if (_selectedDateSort == 'Oldest First') {
        dateCmp = a.createdAt.compareTo(b.createdAt);
      }

      // Distance is primary sort; date breaks ties
      if (distanceCmp != 0) return distanceCmp;
      return dateCmp;
    });

    return filtered;
  }

  // --- Fetch Methods ---

  Future<void> fetchGivePosts({bool refresh = true}) async {
    await _fetchPostsGeneric(
      type: 'give',
      refresh: refresh,
      posts: _givePosts,
      page: _givePage,
      hasNext: _giveHasNext,
      isLoading: _isGiveLoading,
      isLoadMoreRunning: _isGiveLoadMoreRunning,
      latitude: _latitude,
      longitude: _longitude,
      distanceKm: _distanceKm,
      search: _giveSearchQuery,
      onStart: (loading, loadMore) {
        if (loading != null) _isGiveLoading = loading;
        if (loadMore != null) _isGiveLoadMoreRunning = loadMore;
        if (refresh) _errorMessage = null;
        notifyListeners();
      },
      onSuccess: (newPosts, next, page) {
        if (refresh) {
          _givePosts = newPosts;
        } else {
          _givePosts.addAll(newPosts);
        }
        _giveHasNext = next;
        _givePage = page;
        _isGiveLoading = false;
        _isGiveLoadMoreRunning = false;
        notifyListeners();
      },
      onError: (msg) {
        _errorMessage = msg;
        _isGiveLoading = false;
        _isGiveLoadMoreRunning = false;
        notifyListeners();
      },
    );
  }

  Future<void> fetchTakePosts({bool refresh = true}) async {
    await _fetchPostsGeneric(
      type: 'take',
      refresh: refresh,
      posts: _takePosts,
      page: _takePage,
      hasNext: _takeHasNext,
      isLoading: _isTakeLoading,
      isLoadMoreRunning: _isTakeLoadMoreRunning,
      latitude: _latitude,
      longitude: _longitude,
      distanceKm: _distanceKm,
      search: _takeSearchQuery,
      onStart: (loading, loadMore) {
        if (loading != null) _isTakeLoading = loading;
        if (loadMore != null) _isTakeLoadMoreRunning = loadMore;
        if (refresh) _errorMessage = null;
        notifyListeners();
      },
      onSuccess: (newPosts, next, page) {
        if (refresh) {
          _takePosts = newPosts;
        } else {
          _takePosts.addAll(newPosts);
        }
        _takeHasNext = next;
        _takePage = page;
        _isTakeLoading = false;
        _isTakeLoadMoreRunning = false;
        notifyListeners();
      },
      onError: (msg) {
        _errorMessage = msg;
        _isTakeLoading = false;
        _isTakeLoadMoreRunning = false;
        notifyListeners();
      },
    );
  }

  Future<void> fetchHomePosts({
    String type = 'all',
    bool refresh = true,
  }) async {
    await _fetchPostsGeneric(
      type: type,
      refresh: refresh,
      posts: _homePosts,
      page: _homePage,
      hasNext: _homeHasNext,
      isLoading: _isHomeLoading,
      isLoadMoreRunning: _isHomeLoadMoreRunning,
      latitude: _latitude,
      longitude: _longitude,
      distanceKm: _distanceKm,
      search: _homeSearchQuery,
      onStart: (loading, loadMore) {
        if (loading != null) _isHomeLoading = loading;
        if (loadMore != null) _isHomeLoadMoreRunning = loadMore;
        if (refresh) _errorMessage = null;
        notifyListeners();
      },
      onSuccess: (newPosts, next, page) {
        if (refresh) {
          _homePosts = newPosts;
        } else {
          _homePosts.addAll(newPosts);
        }
        _homeHasNext = next;
        _homePage = page;
        _isHomeLoading = false;
        _isHomeLoadMoreRunning = false;
        notifyListeners();
      },
      onError: (msg) {
        _errorMessage = msg;
        _isHomeLoading = false;
        _isHomeLoadMoreRunning = false;
        notifyListeners();
      },
    );
  }

  // Generic helper to reduce code duplication
  Future<void> _fetchPostsGeneric({
    required String type,
    required bool refresh,
    required List<PostModel> posts,
    required int page,
    required bool hasNext,
    required bool isLoading,
    required bool isLoadMoreRunning,
    double? latitude,
    double? longitude,
    double? distanceKm,
    String? search,
    required Function(bool? isLoading, bool? isLoadMoreRunning) onStart,
    required Function(List<PostModel> newPosts, bool hasNext, int page)
        onSuccess,
    required Function(String message) onError,
  }) async {
    int currentPage = page;

    if (refresh) {
      onStart(true, null);
      currentPage = 1;
    } else {
      if (!hasNext || isLoadMoreRunning) return;
      onStart(null, true);
    }

    try {
      // Only include distance if we have valid location data
      final bool includeDistance = latitude != null && longitude != null;

      final response = await _tradeService.getAllPosts(
        type: type,
        page: currentPage,
        limit: _limit,
        latitude: latitude,
        longitude: longitude,
        distanceKm: includeDistance ? _distanceKm : null,
        search: search,
      );

      if (response.success) {
        final List<PostModel> newPosts = response.data ?? [];
        bool next = true;
        int nextPage = currentPage;

        if (newPosts.length < _limit) {
          next = false;
        } else {
          nextPage++;
        }
        onSuccess(newPosts, next, nextPage);
      } else {
        onError(response.message);
      }
    } catch (e) {
      onError('An error occurred: $e');
    }
  }

  Future<void> loadMoreGivePosts() async =>
      await fetchGivePosts(refresh: false);
  Future<void> loadMoreTakePosts() async =>
      await fetchTakePosts(refresh: false);
  Future<void> loadMoreHomePosts() async =>
      await fetchHomePosts(refresh: false);

  PostModel? _selectedPost;
  TradeResponseModel? _selectedResponse;

  PostModel? get selectedPost => _selectedPost;
  TradeResponseModel? get selectedResponse => _selectedResponse;

  TradeCompletionModel? _lastTradeCompletion;
  TradeCompletionModel? get lastTradeCompletion => _lastTradeCompletion;

  void setSelectedPost(PostModel post) {
    _selectedPost = post;
    notifyListeners();
  }

  void setSelectedResponse(TradeResponseModel response) {
    _selectedResponse = response;
    notifyListeners();
  }

  Future<void> fetchPostDetails(int id) async {
    // Only clear if we are fetching a DIFFERENT post to prevent flickering/state loss
    if (_selectedPost?.id != id) {
      _selectedPost = null;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.getPostById(id);

      if (response.success) {
        _selectedPost = response.data;
        
        // Preserve distanceKm from existing lists if backend detail API doesn't provide it
        if (_selectedPost?.distanceKm == null) {
          final existingPosts = [..._homePosts, ..._givePosts, ..._takePosts];
          try {
            final existingPost = existingPosts.firstWhere((p) => p.id == id);
            if (existingPost.distanceKm != null) {
              _selectedPost = _selectedPost?.copyWith(distanceKm: existingPost.distanceKm);
            }
          } catch (_) {
            // Post not found in local lists, distanceKm remains null
          }
        }
      } else {
        // Post not found (e.g. 404) or access denied - explicitly clear selectedPost
        _selectedPost = null;
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.deletePost(id);
      if (response.success) {
        // Remove from local lists
        _homePosts.removeWhere((p) => p.id == id);
        _givePosts.removeWhere((p) => p.id == id);
        _takePosts.removeWhere((p) => p.id == id);
        if (_selectedPost?.id == id) {
          _selectedPost = null;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reactivatePost(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.reactivatePost(id);
      if (response.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivatePost(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.deactivatePost(id);
      if (response.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- 4-Step Trade Flow Controller Methods ---

  Future<bool> respondToPost(TradeResponseRequestModel request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.respondToPost(request);
      if (response.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<TradeResponseModel> _postResponses = [];
  List<TradeResponseModel> _sentResponses = [];

  List<TradeResponseModel> get postResponses => _postResponses;
  List<TradeResponseModel> get sentResponses => _sentResponses;

  PostModel? _responsesPost;
  PostModel? get responsesPost => _responsesPost;

  Future<void> fetchPostResponses(int postId) async {
    _isLoading = true;
    _errorMessage = null;
    _postResponses = [];
    notifyListeners();

    try {
      final response = await _tradeService.getPostResponses(postId);
      if (response.success) {
        final data = response.data;
        _postResponses =
            (data?['responses'] as List<TradeResponseModel>?) ?? [];
        _responsesPost = data?['giveaway'] as PostModel?;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPostResponses() async {
    _isIncomingLoading = true;
    _errorMessage = null;
    _postResponses = [];
    _responsesPost = null;
    notifyListeners();

    try {
      final response = await _tradeService.getMyPostResponses(
        latitude: _latitude,
        longitude: _longitude,
      );
      if (response.success) {
        _postResponses = response.data ?? [];
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isIncomingLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSentResponses() async {
    _isSentLoading = true;
    _errorMessage = null;
    _sentResponses = [];
    notifyListeners();

    try {
      final response = await _tradeService.getMySentResponses(
        latitude: _latitude,
        longitude: _longitude,
      );
      if (response.success) {
        _sentResponses = response.data ?? [];
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isSentLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateResponseStatus({
    required int responseId,
    required String status,
    String? meetingType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.updateResponseStatus(
        responseId: responseId,
        status: status,
        meetingType: meetingType,
      );
      if (response.success) {
        if (_selectedResponse != null && _selectedResponse!.id == responseId) {
          _selectedResponse = _selectedResponse!.copyWith(status: status);
        }
        // Update in lists
        final incomingIndex =
            _postResponses.indexWhere((e) => e.id == responseId);
        if (incomingIndex != -1) {
          _postResponses[incomingIndex] =
              _postResponses[incomingIndex].copyWith(status: status);
        }

        final sentIndex = _sentResponses.indexWhere((e) => e.id == responseId);
        if (sentIndex != -1) {
          _sentResponses[sentIndex] =
              _sentResponses[sentIndex].copyWith(status: status);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> processTradePayment(int responseId) async {
    _isLoading = true;
    _errorMessage = null;
    _lastTradeCompletion = null;
    notifyListeners();

    try {
      final response = await _tradeService.processTradePayment(responseId);
      if (response.success) {
        _lastTradeCompletion = response.data;
        if (_selectedResponse != null && _selectedResponse!.id == responseId) {
          _selectedResponse = _selectedResponse!.copyWith(
            paymentStatus: 'paid',
            status: 'paid',
          );
        }
        // Update in lists
        final incomingIndex =
            _postResponses.indexWhere((e) => e.id == responseId);
        if (incomingIndex != -1) {
          _postResponses[incomingIndex] =
              _postResponses[incomingIndex].copyWith(
            paymentStatus: 'paid',
            status: 'paid',
          );
        }

        final sentIndex = _sentResponses.indexWhere((e) => e.id == responseId);
        if (sentIndex != -1) {
          _sentResponses[sentIndex] = _sentResponses[sentIndex].copyWith(
            paymentStatus: 'paid',
            status: 'paid',
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyTrades({
    String postType = 'all',
    String role = 'all',
    String status = 'all',
    bool isRefresh = true,
  }) async {
    if (isRefresh) {
      _isMyTradesLoading = true;
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final response = await _tradeService.getMyTrades(
        postType: postType,
        role: role,
        status: status,
      );

      if (response.success) {
        _myTrades = response.data?.data ?? [];
        _myTradeStats = response.data?.tradeStats;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      if (isRefresh) {
        _isMyTradesLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchTradeHistoryDetails(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.getTradeHistoryDetails(id);

      if (response.success) {
        _selectedResponse = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelTrade(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.cancelTrade(id);
      if (response.success) {
        if (_selectedResponse != null && _selectedResponse!.id == id) {
          _selectedResponse = _selectedResponse!.copyWith(status: 'cancelled');
        }
        // Update in lists
        final incomingIndex = _postResponses.indexWhere((e) => e.id == id);
        if (incomingIndex != -1) {
          _postResponses[incomingIndex] =
              _postResponses[incomingIndex].copyWith(status: 'cancelled');
        }

        final sentIndex = _sentResponses.indexWhere((e) => e.id == id);
        if (sentIndex != -1) {
          _sentResponses[sentIndex] =
              _sentResponses[sentIndex].copyWith(status: 'cancelled');
        }

        final historyIndex = _myTrades.indexWhere((e) => e.id == id);
        if (historyIndex != -1) {
          _myTrades[historyIndex] =
              _myTrades[historyIndex].copyWith(status: 'cancelled');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitUserMark({
    required int tradeResponseId,
    required int userId,
    required String mark,
  }) async {
    _isMarkingUser = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.submitUserMark(
        tradeResponseId: tradeResponseId,
        userId: userId,
        mark: mark,
      );

      if (!response.success) {
        _errorMessage = response.message;
      }

      return response.success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isMarkingUser = false;
      notifyListeners();
    }
  }

  List<ReportReasonModel> _reportReasons = [];
  bool _isReportReasonsLoading = false;

  List<ReportReasonModel> get reportReasons => _reportReasons;
  bool get isReportReasonsLoading => _isReportReasonsLoading;

  Future<void> fetchReportReasons() async {
    if (_reportReasons.isNotEmpty) return; // Cache locally

    _isReportReasonsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.fetchReportReasons();

      if (response.success) {
        _reportReasons = response.data ?? [];
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isReportReasonsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reportPost({
    required int postId,
    required int reasonId,
    required String description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _tradeService.reportPost(
        postId: postId,
        reasonId: reasonId,
        description: description,
      );

      if (response.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
