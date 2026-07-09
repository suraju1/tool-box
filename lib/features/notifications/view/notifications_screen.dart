import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/shimmer_controller.dart';
import 'package:tool_bocs/core/widgets/shimmer_box.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/trades/model/trade_response_model.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/chat/view/chat_screen.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/notifications/controller/notification_controller.dart';
import 'package:tool_bocs/features/notifications/model/notification_model.dart';
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

      // Always fetch full post details to ensure all fields (like userId) are present
      await tradeController.fetchPostDetails(response.postId);

      // Final check if post details were actually loaded
      if (tradeController.selectedPost == null) {
        throw 'Failed to load post details. Please try again.';
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
          final authController = context.read<AuthController>();
          final isOwner =
              authController.currentUser?.id == response.posterUserId;

          if (isOwner) {
            if (response.status == 'completed' ||
                response.status == 'accepted' ||
                response.status == 'meeting_set') {
              Navigator.pushNamed(context, AppRoutes.tradeDetails,
                  arguments: response.id);
            } else if (response.paymentStatus == 'paid' ||
                response.status == 'paid') {
              _navigateToChat(response);
            } else {
              ToastService.showErrorToast(
                context,
                'Waiting for partner response',
              );
            }
          } else {
            if (response.status == 'completed') {
              Navigator.pushNamed(context, AppRoutes.tradeDetails,
                  arguments: response.id);
            } else {
              Navigator.pushNamed(context, AppRoutes.tradeCompletion);
            }
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
      allMatches.add({'response': r, 'isIncoming': true});
    }
    for (var r in outgoingResponses) {
      allMatches.add({'response': r, 'isIncoming': false});
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
      return Center(
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
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      itemCount: allMatches.length,
      itemBuilder: (context, index) {
        final matchData = allMatches[index];
        final response = matchData['response'] as TradeResponseModel;
        final isIncoming = matchData['isIncoming'] as bool;
        return _buildResponseCard(context, response, isIncoming);
      },
    );
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

    print('--- Mobile _buildResponseCard: id = ${response.id}, responderName = ${response.responderName}, distanceKm = ${response.distanceKm}, distanceStr = "$distanceStr"');

    if (isIncoming) {
      final postItem = response.postItemName ?? 'item';
      messageSpans = [
        TextSpan(
            text: response.responderName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: ' is\nTaking your '),
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
        subText =
            '(Category: ${response.itemCategory ?? 'Unknown'} | Condition: ${response.itemCondition ?? 'Unknown'})';
      }
    } else {
      final postItem = response.postItemName ?? 'item';
      messageSpans = [
        TextSpan(
            text: response.posterName ?? 'User',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: ' is\nGiving you '),
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

    if (response.status == 'pending') {
      actionLabel = isIncoming ? 'Review' : 'Waiting';
      actionColor = context.primaryColor;
    } else if (response.status == 'accepted') {
      actionLabel = 'Continue';
      actionColor = Colors.green;
    } else if (response.status == 'rejected') {
      actionLabel = 'Rejected';
      actionColor = Colors.red;
    } else {
      actionLabel = 'Details';
      actionColor = Colors.blue;
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
      actions: [
        _buildActionButton(actionLabel, actionColor, context.onPrimaryColor,
            () => _onResponseTap(response)),
        if (response.status == 'completed') ...[
          SizedBox(width: 8.w),
          _buildActionButton(' Chat ', context.primaryColor,
              context.onPrimaryColor, () => _navigateToChat(response)),
        ],
        const Spacer(),
        Text(
          timeAgo,
          style: TextStyle(
            fontSize: 10.sp,
            color: context.subTextColor,
            fontFamily: FontFamily.openSans,
          ),
        ),
      ],
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
        ...history.map(
            (response) => _buildResponseCard(context, response, isIncoming)),
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
          color: Colors.white,
          surfaceTintColor: Colors.transparent,

          // ✅ Updated Detail / Info Icon
          icon: Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: Colors.white,
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
              color: Colors.black87,
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
                        color: const Color(0xFF111311),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      AppLocalizations.of(context)!.seeExistingPostsByGivers,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      AppLocalizations.of(context)!.respondToPostsMentionWhat2,
                      style: TextStyle(
                        color: Colors.grey.shade700,
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
                    color: context.primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    AppLocalizations.of(context)!.helpSupport,
                    style: TextStyle(
                      color: context.primaryColor,
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
            color: textColor,
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

    if (notificationController.isLoading) {
      return _buildShimmer(context);
    }

    if (notificationController.notifications.isEmpty) {
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
          if (notificationController.notifications.isNotEmpty)
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
              itemCount: notificationController.notifications.length +
                  (notificationController.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notificationController.notifications.length) {
                  notificationController.loadMore();
                  return const Center(child: CircularProgressIndicator());
                }

                final notification =
                    notificationController.notifications[index];
                return _buildGeneralNotificationCard(context, notification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralNotificationCard(
      BuildContext context, NotificationModel notification) {
    final notificationController = context.read<NotificationController>();
    final isUnread = notification.isRead == 0;

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
            // just open notification detail / show message
            _showSystemNotificationDialog(context, notification);
            break;
          default:
            // Fallback for types not explicitly handled
            if (refId != null) {
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
