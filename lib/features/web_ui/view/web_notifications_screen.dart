import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
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
import 'package:tool_bocs/features/notifications/model/notification_model.dart';
import 'package:intl/intl.dart';
import 'package:tool_bocs/util/date_util.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/view/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class WebNotificationsScreen extends StatefulWidget {
  final int? postId;
  const WebNotificationsScreen({super.key, this.postId});

  @override
  State<WebNotificationsScreen> createState() => _WebNotificationsScreenState();
}

class _WebNotificationsScreenState extends State<WebNotificationsScreen> {
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      tradeController.setSelectedResponse(response);
      try {
        await tradeController.fetchPostDetails(response.postId);
      } catch (_) {}

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

      if (mounted) Navigator.pop(context);

      if (mounted) {
        if (response.status == 'pending') {
          Navigator.pushNamed(context, AppRoutes.tradeStart);
        } else if (response.status == 'rejected') {
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
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: TabBarView(
              children: [
                _buildGeneralNotificationsView(context),
                _buildCombinedMatchesView(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePostResponsesView(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _buildResponsesListView(context, isIncoming: true),
        ),
      ),
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

    final activeResponses = allResponses.where((r) {
      return r.status == 'pending' || r.status == 'meeting_set';
    }).toList();

    final historyResponses = allResponses.where((r) {
      return r.status == 'completed' ||
          r.status == 'accepted' ||
          r.status == 'rejected' ||
          r.status == 'paid';
    }).toList();

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
      padding: const EdgeInsets.symmetric(vertical: 20),
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
                padding: const EdgeInsets.all(40),
                child: Text(
                  AppLocalizations.of(context)!.noActiveOffersYet,
                  style: TextStyle(color: context.subTextColor, fontSize: 16),
                ),
              ),
            )
          else
            ...activeResponses.map((response) =>
                _buildResponseCard(context, response, isIncoming)),
          if (historyResponses.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSuggestionsSection(context, historyResponses, isIncoming),
          ],
        ],
      ),
    );
  }

  Widget _buildCombinedMatchesView(BuildContext context) {
    final shimmer = context.watch<ShimmerController>();
    final tradeController = context.watch<TradeController>();

    final incomingResponses = tradeController.postResponses;
    final incomingLoading = tradeController.isIncomingLoading;

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
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 64, color: context.subTextColor),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noMatchesYet,
                style: TextStyle(
                  color: context.subTextColor,
                  fontSize: 16,
                  fontFamily: FontFamily.openSans,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: allMatches.length,
      itemBuilder: (context, index) {
        final matchData = allMatches[index];
        final response = matchData['response'] as TradeResponseModel;
        final isIncoming = matchData['isIncoming'] as bool;
        return _buildResponseCard(context, response, isIncoming);
      },
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

    final timeAgo = DateUtil.formatTimeAgo(response.createdAt);

    String distanceStr = '';
    if (response.distanceKm != null) {
      if (response.distanceKm! < 1.0) {
        distanceStr = '~ ${(response.distanceKm! * 1000).toInt()} mtrs away';
      } else {
        distanceStr = '~ ${response.distanceKm!.toStringAsFixed(1)} km away';
      }
    }

    print('--- Web _buildResponseCard: id = ${response.id}, responderName = ${response.responderName}, distanceKm = ${response.distanceKm}, distanceStr = "$distanceStr"');

    if (isIncoming) {
      final postItem = response.postItemName ?? 'item';
      messageSpans = [
        TextSpan(
            text: _firstName(response.responderName),
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
            text: _firstName(response.posterName),
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

    final responseImagePath =
        response.itemImages.isNotEmpty ? response.itemImages.first : '';
    final postImagePath =
        response.postItemImages.isNotEmpty ? response.postItemImages.first : '';
    final imageToUse =
        responseImagePath.isNotEmpty ? responseImagePath : postImagePath;

    Widget subMessageWidget = Text(
      subText,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: context.subTextColor,
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
          const SizedBox(width: 8),
          _buildActionButton(' Chat ', context.primaryColor,
              context.onPrimaryColor, () => _navigateToChat(response)),
        ],
        const Spacer(),
        Text(
          timeAgo,
          style: TextStyle(
            fontSize: 11,
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
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.history,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.history, size: 18, color: context.textColor),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.recent,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...history.map(
            (response) => _buildResponseCard(context, response, isIncoming)),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.appBarColor,
      elevation: 0,
      centerTitle: true,
      title: Text(
        AppLocalizations.of(context)!.matchOffers,
        style: GoogleFonts.inter(
          color: context.textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        PopupMenuButton<void>(
          offset: const Offset(-50, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.info_outline,
              size: 20,
              color: context.textColor,
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem<void>(
              enabled: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See what people want around you',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '• See existing posts by givers around you',
                      style: TextStyle(
                        color: context.subTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context)!.respondToPostsMentionWhat,
                      style: TextStyle(
                        color: context.subTextColor,
                        fontSize: 14,
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
                    size: 20,
                    color: context.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.helpSupport,
                    style: TextStyle(
                      color: context.primaryColor,
                      fontSize: 14,
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
              indicator: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              splashBorderRadius: BorderRadius.circular(30),
              labelColor: context.primaryColor,
              unselectedLabelColor: context.subTextColor,
              labelStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                context.watch<NotificationController>().unreadCount > 0
                    ? Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocalizations.of(context)!.general),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context
                                    .watch<NotificationController>()
                                    .unreadCount
                                    .toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Tab(text: 'General'),
                const Tab(text: 'Matches'),
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
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
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
    return _HoverCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppCachedImage(
                    imageUrl: imageUrl ?? imagePath ?? '',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorWidget: _buildImageErrorPlaceholder(context),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
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
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: context.textColor,
                            ),
                            children: message,
                          ),
                        ),
                      ),
                      if (distance.isNotEmpty && distance != 'Unknown') ...[
                        const SizedBox(width: 8),
                        Text(
                          distance,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: context.subTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (subMessageWidget != null) subMessageWidget,
                  const SizedBox(height: 12),
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
      width: 100,
      height: 100,
      color: context.surfaceColor,
      child: Icon(Icons.image,
          color: context.isDarkMode ? Colors.white10 : Colors.grey.shade400),
    );
  }

  Widget _buildActionButton(
      String label, Color bgColor, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
                size: 64, color: context.subTextColor),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noNotificationsFound,
              style: TextStyle(
                color: context.subTextColor,
                fontSize: 16,
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
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => notificationController.markAllAsRead(),
                    icon: Icon(Icons.done_all,
                        size: 20, color: context.primaryColor),
                    label: Text(
                      AppLocalizations.of(context)!.markAllAsRead,
                      style: TextStyle(
                        fontSize: 14,
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
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: notificationController.notifications.length +
                  (notificationController.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notificationController.notifications.length) {
                  notificationController.loadMore();
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator()));
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

    return _HoverCard(
      isUnread: isUnread,
      onTap: () {
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            break;
          case 'system':
            _showSystemNotificationDialog(context, notification);
            break;
          default:
            if (refId != null) {
              Navigator.pushNamed(
                context,
                AppRoutes.productDetails,
                arguments: refId,
              );
            }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isUnread)
                Container(
                  width: 5,
                  color: context.primaryColor,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Image.asset(
                                    'assets/logo_transperant.png',
                                    fit: BoxFit.contain,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification.notificationTitle,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: isUnread
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: context.textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isUnread)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: context.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)!
                                                .newText,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
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
                          GestureDetector(
                            onTap: () => notificationController
                                .deleteNotification(notification.id),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.close,
                                  size: 20,
                                  color: context.subTextColor.withOpacity(0.4)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        notification.notificationMessage,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: isUnread
                              ? context.textColor
                              : context.subTextColor.withOpacity(0.8),
                          fontWeight:
                              isUnread ? FontWeight.w500 : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: context.subTextColor),
                              const SizedBox(width: 6),
                              Text(
                                notification.createdAt != null
                                    ? _formatDate(notification.createdAt!)
                                    : '',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.subTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (isUnread)
                            Text(
                              AppLocalizations.of(context)!.tapToRead,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: context.primaryColor,
                                fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: ShimmerBox(height: 24, width: 100),
          ),
          const SizedBox(height: 12),
          _buildShimmerCard(context),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(height: 24, width: 120),
                ShimmerBox(height: 20, width: 80),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildShimmerCard(context),
          _buildShimmerCard(context),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 85, width: 85, radius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 18, width: 220),
                const SizedBox(height: 8),
                ShimmerBox(height: 16, width: 160),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ShimmerBox(height: 32, width: 80, radius: 6),
                    const SizedBox(width: 12),
                    ShimmerBox(height: 32, width: 80, radius: 6),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          notification.notificationTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: FontFamily.openSans,
          ),
        ),
        content: Text(
          notification.notificationMessage,
          style: TextStyle(
            fontSize: 16,
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

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isUnread;

  const _HoverCard(
      {super.key, required this.child, this.onTap, this.isUnread = false});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          transform: Matrix4.translationValues(0, isHovered ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: widget.isUnread
                ? context.primaryColor.withOpacity(0.04)
                : context.isDarkMode
                    ? const Color(0xFF1A1A1A)
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: widget.isUnread
                ? Border.all(
                    color: context.primaryColor.withOpacity(0.15), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
            boxShadow: context.isDarkMode
                ? []
                : [
                    BoxShadow(
                      color: widget.isUnread
                          ? context.primaryColor.withOpacity(0.08)
                          : Colors.black.withOpacity(isHovered ? 0.08 : 0.03),
                      blurRadius: isHovered ? 20 : 10,
                      offset: Offset(0, isHovered ? 8 : 4),
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
