import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/shimmer_controller.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/features/trades/model/trade_response_model.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/chat/view/chat_screen.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/notifications/controller/notification_controller.dart';
import 'package:tool_bocs/core/api/api_constants.dart';
import 'package:tool_bocs/features/notifications/model/notification_model.dart';
import 'package:tool_bocs/features/profile/service/profile_service.dart';
import 'package:intl/intl.dart';
import 'package:tool_bocs/util/date_util.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/view/profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final int? postId;
  const NotificationsScreen({super.key, this.postId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tradeController = context.read<TradeController>();
      final notificationController = context.read<NotificationController>();
      final locationController = context.read<LocationController>();

      if (locationController.hasLocation) {
        tradeController.setLocation(
          locationController.latitude,
          locationController.longitude,
        );
      }

      if (widget.postId != null) {
        tradeController.fetchPostResponses(widget.postId!);
      } else {
        tradeController.fetchAllPostResponses();
        tradeController.fetchSentResponses();
        notificationController.fetchNotifications(isRefresh: true);
      }
    });
  }

  Future<void> _refreshMatches() async {
    final tradeController = context.read<TradeController>();
    if (widget.postId != null) {
      await tradeController.fetchPostResponses(widget.postId!);
    } else {
      await tradeController.fetchAllPostResponses();
      await tradeController.fetchSentResponses();
    }
  }

  void _navigateToChat(TradeResponseModel response) {
    final authController = context.read<AuthController>();
    final isOwner = authController.currentUser?.id == response.posterUserId;

    final otherUserId = isOwner
        ? response.responderId.toString()
        : response.posterUserId.toString();
    final otherUserName =
        isOwner ? response.responderName : (response.posterName ?? 'User');
    final otherUserImage =
        isOwner ? response.responderImage : response.posterImage;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserImage: otherUserImage,
          tradeResponse: response,
        ),
      ),
    );
  }

  void _onResponseTap(TradeResponseModel response) async {
    final tradeController = context.read<TradeController>();

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Set selected response
      tradeController.setSelectedResponse(response);

      // Try fetching full post details from backend
      try {
        await tradeController.fetchPostDetails(response.postId);
      } catch (_) {}

      // If backend returns 404 (post deleted/expired), fallback to constructing a PostModel from response data
      if (tradeController.selectedPost == null) {
        final fallbackPost = PostModel(
          id: response.postId,
          userId: response.posterUserId,
          pickupArea: response.meetingLocation ?? '',
          latitude: 0.0,
          longitude: 0.0,
          areaDiameter: 5.0,
          tradeType: 'Temporary',
          itemName: response.postItemName ?? response.itemName ?? 'Item',
          itemCategory: response.itemCategory ?? 'General',
          itemCondition: response.itemCondition ?? 'Good',
          itemNote: response.itemDescription ?? '',
          itemSource: response.isHomemade ? 'Homemade' : 'Store bought',
          itemImages: response.postItemImages.isNotEmpty
              ? response.postItemImages
              : response.itemImages,
          returnType: response.responseType,
          priceMin: response.priceRangeStart,
          priceMax: response.priceRangeEnd,
          isNegotiable: response.isNegotiable,
          returnItemName: response.returnItemName ?? response.itemName,
          returnItemCategory: response.itemCategory,
          returnItemCondition: response.itemCondition,
          returnItemDescription: response.itemDescription,
          returnItemImages: response.itemImages,
          walletCredits: 0,
          notifyPartnersOnly: false,
          postType: response.postType ?? 'give',
          status: response.status,
          createdAt: response.createdAt,
          updatedAt: response.createdAt,
          userName: response.posterName ?? 'User',
          userImage: response.posterImage,
        );
        tradeController.setSelectedPost(fallbackPost);
      }

      if (mounted) Navigator.pop(context); // Close loading overlay

      // Navigation logic based on status and role
      if (mounted) {
        if (response.status == 'pending') {
          Navigator.pushNamed(context, AppRoutes.tradeStart);
        } else if (response.status == 'rejected') {
          // You can show a specific rejection details screen or just show the offer details
          // For now, let's keep it on tradeStart or a dedicated details view if available
          Navigator.pushNamed(context, AppRoutes.tradeStart);
        } else if (response.status == 'accepted' ||
            response.status == 'meeting_set' ||
            response.status == 'paid' ||
            response.status == 'completed') {
          bool isPaid = response.paymentStatus == 'paid' ||
              response.status == 'paid' ||
              response.status == 'completed';

          if (isPaid) {
            _navigateToChat(response);
            return;
          }

          final authController = context.read<AuthController>();
          final isOwner =
              authController.currentUser?.id == response.posterUserId;

          if (isOwner) {
            Navigator.pushNamed(context, AppRoutes.tradeDetails,
                arguments: response.id);
          } else {
            Navigator.pushNamed(context, AppRoutes.tradeCompletion);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading overlay
        ToastService.showErrorToast(context, e.toString());
      }
    }
  }

  Future<void> _rejectTrade(
      BuildContext context, TradeResponseModel response) async {
    final controller = context.read<TradeController>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await controller.updateResponseStatus(
        responseId: response.id,
        status: 'rejected',
      );
      if (mounted) {
        Navigator.pop(context);
        if (success) {
          ToastService.showSuccessToast(context, 'Offer Rejected');
          if (widget.postId != null) {
            controller.fetchPostResponses(widget.postId!);
          } else {
            context.read<NotificationController>().fetchNotifications();
          }
        } else {
          ToastService.showErrorToast(
            context,
            controller.errorMessage ?? 'Action failed',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ToastService.showErrorToast(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.postId != null) {
      return _buildSinglePostResponsesView(context);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: _buildAppBar(context),
        body: TabBarView(
          children: [
            _buildGeneralNotificationsView(context),
            _buildCombinedMatchesView(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePostResponsesView(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      body: _buildResponsesListView(context, isIncoming: true),
    );
  }

  Widget _buildResponsesListView(BuildContext context,
      {required bool isIncoming}) {
    final shimmer = context.watch<ShimmerController>();
    final tradeController = context.watch<TradeController>();
    final allResponses = isIncoming
        ? tradeController.postResponses
        : tradeController.sentResponses;

    final isLoading = isIncoming
        ? tradeController.isIncomingLoading
        : tradeController.isSentLoading;

    if (shimmer.isLoading || isLoading) {
      return _buildShimmer(context);
    }

    // Filter into Active and History
    final activeResponses = allResponses.where((r) {
      return r.status == 'pending' || r.status == 'meeting_set';
    }).toList();

    final historyResponses = allResponses.where((r) {
      return r.status == 'completed' ||
          r.status == 'accepted' ||
          r.status == 'rejected' ||
          r.status == 'paid';
    }).toList();

    // Sort History by date (newest first)
    historyResponses.sort((a, b) {
      try {
        DateTime dateA = DateTime.parse(a.createdAt);
        DateTime dateB = DateTime.parse(b.createdAt);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            widget.postId != null
                ? 'Responses for ${tradeController.responsesPost?.itemName ?? 'Post'} (${activeResponses.length})'
                : isIncoming
                    ? 'Incoming Offers (${activeResponses.length})'
                    : 'Sent Offers (${activeResponses.length})',
          ),
          if (activeResponses.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(40.w),
                child: Text(
                  'No active offers yet',
                  style: TextStyle(color: context.subTextColor),
                ),
              ),
            )
          else
            ...activeResponses.map((response) =>
                _buildResponseCard(context, response, isIncoming)),
          if (historyResponses.isNotEmpty) ...[
            SizedBox(height: 20.h),
            _buildSuggestionsSection(context, historyResponses, isIncoming),
          ],
        ],
      ),
    );
  }

  Widget _buildCombinedMatchesView(BuildContext context) {
    final shimmer = context.watch<ShimmerController>();
    final tradeController = context.watch<TradeController>();

    // Get incoming responses (My Items - responses on your posts)
    final incomingResponses = tradeController.postResponses;
    final incomingLoading = tradeController.isIncomingLoading;

    // Get outgoing responses (My Offers - your responses to others' posts)
    final outgoingResponses = tradeController.sentResponses;
    final outgoingLoading = tradeController.isSentLoading;

    if (shimmer.isLoading || incomingLoading || outgoingLoading) {
      return _buildShimmer(context);
    }

    final List<Map<String, dynamic>> allMatches = [];

    for (var r in incomingResponses) {
      if (r.status?.toLowerCase() != 'rejected' && r.status?.toLowerCase() != 'deleted') {
        allMatches.add({'response': r, 'isIncoming': true});
      }
    }
    for (var r in outgoingResponses) {
      if (r.status?.toLowerCase() != 'rejected' && r.status?.toLowerCase() != 'deleted') {
        allMatches.add({'response': r, 'isIncoming': false});
      }
    }

    // Sort all matches by date (newest first)
    allMatches.sort((a, b) {
      try {
        DateTime dateA =
            DateTime.parse((a['response'] as TradeResponseModel).createdAt);
        DateTime dateB =
            DateTime.parse((b['response'] as TradeResponseModel).createdAt);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    if (allMatches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshMatches,
        color: context.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(40.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64.sp, color: context.subTextColor),
                  SizedBox(height: 16.h),
                  Text(
                    'No matches yet',
                    style: TextStyle(
                      color: context.subTextColor,
                      fontSize: 16.sp,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMatches,
      color: context.primaryColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 20.h),
        itemCount: allMatches.length,
        itemBuilder: (context, index) {
          final matchData = allMatches[index];
          final response = matchData['response'] as TradeResponseModel;
          final isIncoming = matchData['isIncoming'] as bool;
          return _buildResponseCard(context, response, isIncoming);
        },
      ),
    );
  }

  /// Returns only the first word of a full name
  String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'User';
    return fullName.trim().split(' ').first;
  }

  Widget _buildResponseCard(
      BuildContext context, TradeResponseModel response, bool isIncoming) {
    List<TextSpan> messageSpans = [];
    String subText = '';
    String actionLabel = '';
    Color actionColor = context.primaryColor;

    // Format time ago
    final timeAgo = DateUtil.formatTimeAgo(response.createdAt);

    String distanceStr = '';
    if (response.distanceKm != null) {
      if (response.distanceKm! < 1.0) {
        distanceStr = '~ ${(response.distanceKm! * 1000).toInt()} mtrs away';
      } else {
        distanceStr = '~ ${response.distanceKm!.toStringAsFixed(1)} km away';
      }
    }

    print(
        '--- Mobile _buildResponseCard: id = ${response.id}, responderName = ${response.responderName}, distanceKm = ${response.distanceKm}, distanceStr = "$distanceStr"');

    if (isIncoming) {
      final postItem = response.postItemName ?? 'item';
      messageSpans = [
        TextSpan(
            text: '${_firstName(response.responderName)} is\nTaking your '),
        TextSpan(
            text: postItem,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ];

      if (response.returnItemName != null &&
          response.returnItemName!.isNotEmpty &&
          response.returnItemName != postItem) {
        subText = 'Giving you ${response.returnItemName} in return';
      } else if (response.itemName != null &&
          response.itemName!.isNotEmpty &&
          (response.responseType == 'item' ||
              response.responseType == 'Item') &&
          response.itemName != postItem) {
        subText = 'Giving you ${response.itemName} in return';
      } else if ((response.priceRangeStart ?? 0) > 0 ||
          (response.priceRangeEnd ?? 0) > 0) {
        final startPrice = (response.priceRangeStart ?? 0).toStringAsFixed(0);
        final endPrice = (response.priceRangeEnd ?? 0).toStringAsFixed(0);
        subText = startPrice == endPrice
            ? 'Giving you ₹$startPrice in return'
            : 'Giving you ₹$startPrice - ₹$endPrice in return';
      } else {
        subText = 'Giving nothing in return';
      }
    } else {
      final postItem = response.postItemName ?? 'item';
      final currentUserName = context.read<AuthController>().currentUser?.fullName;
      String otherUserName = response.posterName ?? 'User';
      if (currentUserName != null && 
          _firstName(response.posterName).toLowerCase() == _firstName(currentUserName).toLowerCase()) {
        otherUserName = response.responderName;
      }

      messageSpans = [
        TextSpan(text: '${_firstName(otherUserName)} is\nGiving you '),
        TextSpan(
            text: postItem,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ];

      if (response.itemName != null &&
          response.itemName!.isNotEmpty &&
          response.itemName != postItem) {
        subText = 'Taking ${response.itemName} in return';
      } else if ((response.priceRangeStart ?? 0) > 0 ||
          (response.priceRangeEnd ?? 0) > 0) {
        final startPrice = (response.priceRangeStart ?? 0).toStringAsFixed(0);
        final endPrice = (response.priceRangeEnd ?? 0).toStringAsFixed(0);
        subText = startPrice == endPrice
            ? 'Taking ₹$startPrice in return'
            : 'Taking ₹$startPrice - ₹$endPrice in return';
      } else {
        subText = 'Taking an offer in return';
      }
    }

    // Use response item image if available, else post image
    final responseImagePath =
        response.itemImages.isNotEmpty ? response.itemImages.first : '';
    final postImagePath =
        response.postItemImages.isNotEmpty ? response.postItemImages.first : '';
    final imageToUse =
        responseImagePath.isNotEmpty ? responseImagePath : postImagePath;

    Widget subMessageWidget = Text(
      subText,
      style: TextStyle(
        fontSize: 12.sp,
        color: context.subTextColor,
        fontFamily: FontFamily.openSans,
      ),
    );

    return _buildNotificationCard(
      context,
      imageUrl: imageToUse,
      distance: distanceStr,
      message: messageSpans,
      subMessageWidget: subMessageWidget,
      actions: response.status == 'pending'
          ? (isIncoming
              ? [
                  _buildActionButton(
                      'Accept',
                      context.isDarkMode ? Colors.grey.shade800 : Colors.black,
                      Colors.white,
                      () => _onResponseTap(response)),
                  SizedBox(width: 8.w),
                  _buildActionButton(
                      'Reject',
                      Colors.grey,
                      Colors.white,
                      () => _rejectTrade(context, response)),
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: context.subTextColor,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                ]
              : [
                  _buildActionButton(
                      'Waiting',
                      context.primaryColor,
                      context.onPrimaryColor,
                      () => _onResponseTap(response)),
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: context.subTextColor,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                ])
          : (response.status == 'rejected' || response.status == 'cancelled'
              ? [
                  Text(
                    response.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: context.subTextColor,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                ]
              : ((response.paymentStatus == 'paid' || response.status == 'paid' || response.status == 'completed')
                  ? [
                      _buildActionButton(
                          'Chat',
                          context.isDarkMode ? Colors.grey.shade800 : Colors.black,
                          Colors.white,
                          () => _navigateToChat(response)),
                      const Spacer(),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: context.subTextColor,
                          fontFamily: FontFamily.openSans,
                        ),
                      ),
                    ]
                  : [
                      _buildActionButton(
                          isIncoming ? 'Waiting' : 'Complete Trade',
                          context.primaryColor,
                          context.onPrimaryColor,
                          () => _onResponseTap(response)),
                      const Spacer(),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: context.subTextColor,
                          fontFamily: FontFamily.openSans,
                        ),
                      ),
                    ])),
      onTap: () => _onResponseTap(response),
    );
  }

  Widget _buildSuggestionsSection(
      BuildContext context, List<TradeResponseModel> history, bool isIncoming) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'History',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: FontFamily.openSans,
                  color: context.textColor,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.history, size: 18.sp, color: context.textColor),
                  SizedBox(width: 4.w),
                  Text(
                    'Recent',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        ...history
            .where((response) =>
                response.status != 'pending' &&
                response.status != 'accepted' &&
                response.status != 'rejected')
            .map((response) =>
                _buildResponseCard(context, response, isIncoming)),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.appBarColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: context.textColor, size: 20.sp),
      ),
      centerTitle: true,
      title: Text(
        AppLocalizations.of(context)!.matchOffers,
        style: TextStyle(
          color: context.textColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
        ),
      ),
      actions: [
        PopupMenuButton<void>(
          offset: const Offset(-200, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          color: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,

          // ✅ Updated Detail / Info Icon
          icon: Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.white10 : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4.r,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.info_outline,
              size: 18.sp,
              color: context.textColor,
            ),
          ),

          itemBuilder: (context) => [
            PopupMenuItem<void>(
              enabled: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.seeWhatPeopleWantAround,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      AppLocalizations.of(context)!.seeExistingPostsByGivers,
                      style: TextStyle(
                        color: context.subTextColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      AppLocalizations.of(context)!.respondToPostsMentionWhat2,
                      style: TextStyle(
                        color: context.subTextColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<void>(
              onTap: () {
                Future.delayed(Duration.zero, () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.helpSupport,
                  );
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 18.sp,
                    color: context.textColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    AppLocalizations.of(context)!.helpSupport,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: widget.postId == null
          ? TabBar(
              dividerColor: Colors.transparent,
              indicatorColor: context.primaryColor,
              labelColor: context.primaryColor,
              unselectedLabelColor: context.subTextColor,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                fontFamily: FontFamily.openSans,
              ),
              tabs: [
                context.watch<NotificationController>().unreadCount > 0
                    ? Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocalizations.of(context)!.general),
                            SizedBox(width: 4.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                context
                                    .watch<NotificationController>()
                                    .unreadCount
                                    .toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Tab(text: AppLocalizations.of(context)!.general),
                Tab(text: AppLocalizations.of(context)!.matches),
              ],
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(10),
              child: Divider(height: 1, color: context.dividerColor),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
          color: context.textColor,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    String? imagePath,
    String? imageUrl,
    required String distance,
    required List<TextSpan> message,
    Widget? subMessageWidget,
    required List<Widget> actions,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: context.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: context.dividerColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: AppCachedImage(
                    imageUrl: imageUrl ?? imagePath ?? '',
                    width: 85.w,
                    height: 75.w,
                    fit: BoxFit.cover,
                    errorWidget: _buildImageErrorPlaceholder(context),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: context.textColor,
                              fontFamily: FontFamily.openSans,
                            ),
                            children: message,
                          ),
                        ),
                      ),
                      if (distance.isNotEmpty && distance != 'Unknown') ...[
                        SizedBox(width: 8.w),
                        Text(
                          distance,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: context.subTextColor,
                            fontFamily: FontFamily.openSans,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  if (subMessageWidget != null) subMessageWidget,
                  SizedBox(height: 8.h),
                  Row(children: actions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder(BuildContext context) {
    return Container(
      width: 85.w,
      height: 75.w,
      color: context.surfaceColor,
      child: Icon(Icons.image,
          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade400),
    );
  }

  Widget _buildActionButton(
      String label, Color bgColor, Color textColor, VoidCallback onTap) {
    final effectiveTextColor =
        (bgColor == context.primaryColor && textColor == Colors.white)
            ? context.onPrimaryColor
            : textColor;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            fontFamily: FontFamily.openSans,
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralNotificationsView(BuildContext context) {
    final notificationController = context.watch<NotificationController>();
    final tradeController = context.watch<TradeController>();
    final activePostIds = <int>{
      ...tradeController.sentResponses
          .where((r) =>
              r.status?.toLowerCase() != 'rejected' &&
              r.status?.toLowerCase() != 'deleted')
          .map((r) => r.postId),
      ...tradeController.postResponses
          .where((r) =>
              r.status?.toLowerCase() != 'rejected' &&
              r.status?.toLowerCase() != 'deleted')
          .map((r) => r.postId),
    };

    final filteredNotifications = notificationController.notifications.where((n) {
      if (n.notificationTitle.toLowerCase().contains("new post nearby") &&
          n.referenceId != null) {
        if (activePostIds.contains(n.referenceId)) {
          return false;
        }
      }
      return true;
    }).toList();

    if (notificationController.isLoading) {
      return _buildShimmer(context);
    }

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                size: 64.sp, color: context.subTextColor),
            SizedBox(height: 16.h),
            Text(
              'No notifications found',
              style: TextStyle(
                color: context.subTextColor,
                fontSize: 16.sp,
                fontFamily: FontFamily.openSans,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          notificationController.fetchNotifications(isRefresh: true),
      child: Column(
        children: [
          if (filteredNotifications.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => notificationController.markAllAsRead(),
                    icon: Icon(Icons.done_all,
                        size: 18.sp, color: context.primaryColor),
                    label: Text(
                      AppLocalizations.of(context)!.markAllAsRead,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.primaryColor,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 20.h),
              itemCount: filteredNotifications.length +
                  (notificationController.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredNotifications.length) {
                  notificationController.loadMore();
                  return const Center(child: CircularProgressIndicator());
                }

                final notification = filteredNotifications[index];
                return _AnimatedNotificationItem(
                  key: ValueKey(notification.id),
                  notification: notification,
                  builder: (context, triggerRemove) {
                    return _buildGeneralNotificationCard(
                      context,
                      notification,
                      onIgnore: triggerRemove,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPostNearbyCard(
      BuildContext context, NotificationModel notification, bool isUnread,
      {VoidCallback? onIgnore}) {
    final notificationController = context.read<NotificationController>();

    // Formatting the distance
    String distanceStr = '';
    if (notification.distanceKm != null &&
        notification.distanceKm!.isNotEmpty) {
      final double? dist = double.tryParse(notification.distanceKm!);
      if (dist != null) {
        if (dist < 1.0) {
          distanceStr = '~ ${(dist * 1000).toInt()} mtrs away';
        } else {
          distanceStr = '~ ${dist.toStringAsFixed(1)} km away';
        }
      }
    }

    final postType =
        notification.postType?.toLowerCase() == 'give' ? 'Giving' : 'Taking';
    final itemName = notification.itemName ?? 'Unknown Item';

    final imageUrl =
        notification.itemImages.isNotEmpty ? notification.itemImages.first : '';
    final timeAgo =
        DateUtil.formatTimeAgo(notification.createdAt?.toIso8601String() ?? '');
    final actionButtonText = postType == 'Giving' ? 'Take' : 'Give';

    return _buildNewPostNotificationCard(
      context,
      imageUrl: imageUrl,
      distance: distanceStr,
      message: [
        TextSpan(
          text: notification.notificationTitle,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w800 : FontWeight.bold,
            color: context.textColor,
            fontSize: 14.sp,
          ),
        ),
      ],
      subMessageWidget: _PosterNameSubtext(
        notification: notification,
        postType: postType,
        itemName: itemName,
        priceMin: notification.priceMin,
        priceMax: notification.priceMax,
        returnType: notification.returnType,
        returnItemName: notification.returnItemName,
        timeAgo: timeAgo,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  _buildActionBtn(actionButtonText, () {
                    if (isUnread)
                      notificationController.markAsRead(notification.id);
                    if (notification.referenceId != null) {
                      Navigator.pushNamed(context, AppRoutes.productDetails,
                          arguments: notification.referenceId);
                    }
                  }),
                  SizedBox(width: 8.w),
                  _buildActionBtn('Ignore', () {
                    if (onIgnore != null) {
                      onIgnore();
                    } else {
                      notificationController.deleteNotification(notification.id);
                      notificationController.notifications
                          .removeWhere((n) => n.id == notification.id);
                    }
                  }),
                ],
              ),
              Text(
                timeAgo,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: context.subTextColor,
                  fontFamily: FontFamily.openSans,
                ),
              ),
            ],
          ),
        ),
      ],
      isUnread: isUnread,
      onTap: () {
        if (isUnread) notificationController.markAsRead(notification.id);
        if (notification.referenceId != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.productDetails,
            arguments: notification.referenceId,
          );
        }
      },
    );
  }

  Widget _buildActionBtn(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNewPostNotificationCard(
    BuildContext context, {
    required String imageUrl,
    required String distance,
    required List<TextSpan> message,
    required Widget subMessageWidget,
    required bool isUnread,
    required VoidCallback onTap,
    List<Widget>? actions,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isUnread
              ? context.primaryColor.withOpacity(0.06)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(12.r),
          border: isUnread
              ? Border.all(
                  color: context.primaryColor.withOpacity(0.1), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
          boxShadow: context.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: isUnread
                        ? context.primaryColor.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isUnread)
                  Container(
                    width: 5.w,
                    color: context.primaryColor,
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 70.w,
                          height: 70.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: context.surfaceColor,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: AppCachedImage(
                              imageUrl: imageUrl,
                              width: 70.w,
                              height: 70.w,
                              fit: BoxFit.cover,
                              errorWidget: _buildImageErrorPlaceholder(context),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(children: message),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (distance.isNotEmpty) ...[
                                    SizedBox(width: 8.w),
                                    Text(
                                      distance,
                                      style: TextStyle(
                                        color: context.subTextColor,
                                        fontSize: 10.sp,
                                        fontFamily: FontFamily.openSans,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subMessageWidget,
                              if (actions != null && actions.isNotEmpty) ...[
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: actions,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralNotificationCard(
      BuildContext context, NotificationModel notification,
      {VoidCallback? onIgnore}) {
    final notificationController = context.read<NotificationController>();
    final isUnread = notification.isRead == 0;

    if (notification.notificationTitle
        .toLowerCase()
        .contains("new post nearby")) {
      return _buildNewPostNearbyCard(context, notification, isUnread,
          onIgnore: onIgnore);
    }

    return InkWell(
      onTap: () {
        // Mark as read when clicked
        if (isUnread) {
          notificationController.markAsRead(notification.id);
        }

        final type = notification.type?.toLowerCase() ?? '';
        final refId = notification.referenceId;
        final createdBy = notification.createdBy;

        debugPrint(
            "Notification Tapped: Type=$type, RefId=$refId, CreatedBy=$createdBy");

        switch (type) {
          case 'giveaway':
            if (refId != null) {
              Navigator.pushNamed(
                context,
                AppRoutes.productDetails,
                arguments: refId,
              );
            }
            break;
          case 'response':
            if (refId != null) {
              Navigator.pushNamed(
                context,
                AppRoutes.tradeDetails,
                arguments: refId,
              );
            }
            break;
          case 'review':
          case 'new_user':
            // user says : createdBy = other user's id
            final userId = createdBy ?? refId;
            if (userId != null) {
              ProfileController.navigateToUserProfile(context, userId);
            }
            break;
          case 'subscription':
            Navigator.pushNamed(context, AppRoutes.subscriptionHistory);
            break;
          case 'wallet_giveaway':
          case 'wallet_trade':
            Navigator.pushNamed(context, AppRoutes.transactionHistory);
            break;
          case 'profile':
            // open my profile screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            break;
          case 'system':
          case 'warning':
          case 'admin':
            // just open notification detail / show message
            _showSystemNotificationDialog(context, notification);
            break;
          default:
            // Fallback for types not explicitly handled
            if (notification.notificationTitle
                    .toLowerCase()
                    .contains('warning') ||
                notification.notificationTitle
                    .toLowerCase()
                    .contains('admin')) {
              _showSystemNotificationDialog(context, notification);
            } else if (refId != null) {
              Navigator.pushNamed(
                context,
                AppRoutes.productDetails,
                arguments: refId,
              );
            }
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isUnread
              ? context.primaryColor.withOpacity(0.06)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(12.r),
          border: isUnread
              ? Border.all(
                  color: context.primaryColor.withOpacity(0.1), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
          boxShadow: context.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: isUnread
                        ? context.primaryColor.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unread indicator line
                if (isUnread)
                  Container(
                    width: 5.w,
                    color: context.primaryColor,
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 42.r,
                                    height: 42.r,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: EdgeInsets.all(5.r),
                                    child: Image.asset(
                                      'assets/logo_transperant.png',
                                      fit: BoxFit.contain,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification.notificationTitle,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: isUnread
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: context.textColor,
                                            fontFamily: FontFamily.openSans,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isUnread)
                                          Container(
                                            margin: EdgeInsets.only(top: 2.h),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6.w, vertical: 1.h),
                                            decoration: BoxDecoration(
                                              color: context.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                            ),
                                            child: Text(
                                              'NEW',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Delete icon
                            GestureDetector(
                              onTap: () => notificationController
                                  .deleteNotification(notification.id),
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                child: Icon(Icons.close,
                                    size: 16.sp,
                                    color:
                                        context.subTextColor.withOpacity(0.4)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          notification.notificationMessage,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isUnread
                                ? context.textColor
                                : context.subTextColor.withOpacity(0.8),
                            fontFamily: FontFamily.openSans,
                            fontWeight:
                                isUnread ? FontWeight.w500 : FontWeight.normal,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 10.sp, color: context.subTextColor),
                                SizedBox(width: 4.w),
                                Text(
                                  notification.createdAt != null
                                      ? _formatDate(notification.createdAt!)
                                      : '',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: context.subTextColor,
                                    fontFamily: FontFamily.openSans,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isUnread)
                              Text(
                                'Tap to read',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: context.primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: FontFamily.openSans,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(date);
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  Widget _buildShimmer(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: ShimmerBox(height: 20.h, width: 80.w),
          ),
          SizedBox(height: 12.h),
          _buildShimmerCard(context),
          SizedBox(height: 30.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(height: 20.h, width: 100.w),
                ShimmerBox(height: 15.h, width: 60.w),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          _buildShimmerCard(context),
          _buildShimmerCard(context),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 70.w, width: 70.w, radius: 12.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14.h, width: 180.w),
                SizedBox(height: 6.h),
                ShimmerBox(height: 12.h, width: 140.w),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    ShimmerBox(height: 25.h, width: 60.w, radius: 6.r),
                    SizedBox(width: 8.w),
                    ShimmerBox(height: 25.h, width: 60.w, radius: 6.r),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSystemNotificationDialog(
      BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          notification.notificationTitle,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            fontFamily: FontFamily.openSans,
          ),
        ),
        content: Text(
          notification.notificationMessage,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            fontFamily: FontFamily.openSans,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }
}

class _PosterNameSubtext extends StatefulWidget {
  final NotificationModel notification;
  final String postType;
  final String itemName;
  final String? priceMin;
  final String? priceMax;
  final String? returnType;
  final String? returnItemName;
  final String timeAgo;

  const _PosterNameSubtext({
    required this.notification,
    required this.postType,
    required this.itemName,
    this.priceMin,
    this.priceMax,
    this.returnType,
    this.returnItemName,
    required this.timeAgo,
  });

  @override
  State<_PosterNameSubtext> createState() => _PosterNameSubtextState();
}

class _PosterNameSubtextState extends State<_PosterNameSubtext> {
  String? _fetchedName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchName();
  }

  Future<void> _fetchName() async {
    if (widget.notification.creatorName != null &&
        widget.notification.creatorName!.isNotEmpty) {
      if (mounted)
        setState(() => _fetchedName = widget.notification.creatorName);
      return;
    }
    if (widget.notification.createdBy != null) {
      if (mounted) setState(() => _isLoading = true);

      final response = await ProfileService()
          .fetchOtherProfile(widget.notification.createdBy!);

      if (!mounted) return;
      if (response.success && response.data != null) {
        final profile = response.data!;
        setState(() {
          _fetchedName = profile.userDetails.fullName.isNotEmpty
              ? profile.userDetails.fullName
              : 'User #${widget.notification.createdBy}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _fetchedName = 'User #${widget.notification.createdBy}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? displayFirstName = _fetchedName?.trim().split(' ').first;
    String prefix = displayFirstName != null && displayFirstName.isNotEmpty
        ? '$displayFirstName is '
        : (widget.notification.createdBy != null && _isLoading
            ? 'Loading... '
            : '');

    if (prefix.isEmpty && widget.notification.createdBy != null) {
      prefix = 'User #${widget.notification.createdBy} is ';
    }

    String subText = '$prefix${widget.postType} ${widget.itemName}';

    if (widget.returnType?.toLowerCase() == 'price' &&
        widget.priceMin != null) {
      final pMin = widget.priceMin!;
      final pMax = widget.priceMax ?? pMin;
      final priceStr = pMin == pMax ? '₹$pMin' : '₹$pMin - ₹$pMax';
      subText += '\nTaking $priceStr in return';
    } else if (widget.returnItemName != null &&
        widget.returnItemName!.isNotEmpty) {
      subText += '\nTaking ${widget.returnItemName} in return';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        Text(
          subText,
          style: TextStyle(
            fontSize: 12.sp,
            color: context.subTextColor,
            fontFamily: FontFamily.openSans,
          ),
        ),
      ],
    );
  }
}

class _AnimatedNotificationItem extends StatefulWidget {
  final NotificationModel notification;
  final Widget Function(BuildContext context, VoidCallback triggerRemove)
      builder;

  const _AnimatedNotificationItem({
    super.key,
    required this.notification,
    required this.builder,
  });

  @override
  State<_AnimatedNotificationItem> createState() =>
      _AnimatedNotificationItemState();
}

class _AnimatedNotificationItemState extends State<_AnimatedNotificationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.2, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeInOutCubic),
    ));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    ));
    _sizeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeInOutCubic),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerRemove() async {
    if (_isRemoving) return;
    setState(() {
      _isRemoving = true;
    });
    await _controller.forward();
    if (!mounted) return;
    final notificationController = context.read<NotificationController>();
    notificationController.deleteNotification(widget.notification.id);
    notificationController.notifications
        .removeWhere((n) => n.id == widget.notification.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_isRemoving && _controller.isCompleted) {
      return const SizedBox.shrink();
    }
    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Dismissible(
            key: ValueKey('dismiss_notification_${widget.notification.id}'),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              final notificationController =
                  context.read<NotificationController>();
              notificationController
                  .deleteNotification(widget.notification.id);
              notificationController.notifications
                  .removeWhere((n) => n.id == widget.notification.id);
            },
            background: Container(
              margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.delete_outline, color: Colors.red, size: 24.sp),
            ),
            child: widget.builder(context, _triggerRemove),
          ),
        ),
      ),
    );
  }
}
