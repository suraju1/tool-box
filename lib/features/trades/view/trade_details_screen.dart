import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:tool_bocs/features/chat/view/chat_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/features/trades/model/trade_response_model.dart';
import 'package:tool_bocs/core/api/api_constants.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';

class TradeDetailsScreen extends StatefulWidget {
  final int? tradeId;
  const TradeDetailsScreen({super.key, this.tradeId});

  @override
  State<TradeDetailsScreen> createState() => _TradeDetailsScreenState();
}

class _TradeDetailsScreenState extends State<TradeDetailsScreen> {
  String? _submittedMark;

  @override
  void initState() {
    super.initState();
    if (widget.tradeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<TradeController>()
            .fetchTradeHistoryDetails(widget.tradeId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tradeController = context.watch<TradeController>();
    final response = tradeController.selectedResponse;
    final isLoading = tradeController.isLoading;

    if (isLoading) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (response == null) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: _buildAppBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppLocalizations.of(context)!.noTradeSelected),
              if (tradeController.errorMessage != null)
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    tradeController.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          if (widget.tradeId != null) {
            await context
                .read<TradeController>()
                .fetchTradeHistoryDetails(widget.tradeId!);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainItemCard(response),
              SizedBox(height: 14.h),
              _buildSectionTitle(AppLocalizations.of(context)!.tradeWith),
              SizedBox(height: 8.h),
              _buildUserCard(response),
              _buildUserMarkActions(response),
              SizedBox(height: 14.h),
              _buildSectionTitle(AppLocalizations.of(context)!.exchangeDetails),
              SizedBox(height: 8.h),
              _buildExchangeCard(response),
              SizedBox(height: 14.h),
              _buildSectionTitle(AppLocalizations.of(context)!.tradeInfo),
              SizedBox(height: 8.h),
              _buildTradeInfoCard(response),
              SizedBox(height: 14.h),
              _buildSectionTitle(AppLocalizations.of(context)!.tradeNotes),
              SizedBox(height: 8.h),
              _buildNotesCard(response),
              SizedBox(height: 20.h),
              _buildChatButton(context, response),
              SizedBox(height: 10.h),
              _buildCompleteButton(context, response),
              SizedBox(height: 10.h),
              _buildCancelButton(context, response),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton(
      BuildContext context, TradeResponseModel response) {
    final authController = context.read<AuthController>();
    final currentUserId = authController.currentUser?.id;
    final isResponder = currentUserId == response.responderId;

    // Only responder needs to see 'Complete' button here to go to Step 4
    final canComplete = isResponder &&
        (response.status == 'accepted' || response.status == 'meeting_set');

    if (!canComplete) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Set the selected response in controller just in case
          context.read<TradeController>().setSelectedResponse(response);
          // Navigate to Step 4 Completion Screen
          Navigator.pushNamed(context, AppRoutes.tradeCompletion);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          elevation: 0,
        ),
        child: Text(
          AppLocalizations.of(context)!.completeTrade,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildChatButton(BuildContext context, TradeResponseModel response) {
    final authController = context.read<AuthController>();
    final currentUserId = authController.currentUser?.id;
    final isOwner = currentUserId == response.posterUserId;

    // Show chat button if trade is in active progress
    final showChat = response.status == 'accepted' ||
        response.status == 'meeting_set' ||
        response.status == 'paid' ||
        response.status == 'completed';

    if (!showChat) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final otherUserId = isOwner
              ? response.responderId.toString()
              : response.posterUserId.toString();
          final otherUserName = isOwner
              ? response.responderName
              : (response.posterName ?? 'User');
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
        },
        icon: Icon(Icons.chat_bubble_outline, color: context.onPrimaryColor),
        label: Text(
          AppLocalizations.of(context)!.chatWith(isOwner ? response.responderName : (response.posterName ?? 'User')),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: context.onPrimaryColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, TradeResponseModel response) {
    final authController = context.read<AuthController>();
    final currentUserId = authController.currentUser?.id;

    // Only offer sender can cancel
    final isOfferSender = currentUserId == response.responderId;
    final isCancellable = response.status == 'pending' ||
        response.status == 'accepted' ||
        response.status == 'waiting_for_payment';

    if (!isOfferSender || !isCancellable) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showCancelConfirmation(context, response.id),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          padding: EdgeInsets.symmetric(vertical: 14.h),
        ),
        child: Text(
          AppLocalizations.of(context)!.cancelTrade,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, int tradeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelTrade),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWant7),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await context.read<TradeController>().cancelTrade(tradeId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                        content: Text(success
                            ? AppLocalizations.of(context)!.tradeCancelledSuccessfully
                            : AppLocalizations.of(context)!.failedToCancelTrade),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child:
                Text(AppLocalizations.of(context)!.yesCancel, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.scaffoldBg,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: context.textColor, size: 20.sp),
      ),
      centerTitle: true,
      title: Text(
        AppLocalizations.of(context)!.tradeDetails,
        style: TextStyle(
          color: context.textColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(10.h),
        child: Divider(
          height: 1.h,
          color: context.dividerColor,
          thickness: 1.h,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        fontFamily: FontFamily.openSans,
        color: context.textColor,
      ),
    );
  }

  Widget _buildMainItemCard(TradeResponseModel response) {
    final itemName =
        response.postItemName ?? response.givingItemName ?? 'Trade Item';
    final images = response.postItemImages.isNotEmpty
        ? response.postItemImages
        : (response.givingItemImages ?? []);
    final imageUrl = images.isNotEmpty ? images.first : '';
    final isGive = response.postType == 'give' || response.postType == 'giving';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          imageUrl.isNotEmpty
              ? AppCachedImage(
                  imageUrl: imageUrl,
                  width: 80.w,
                  height: 80.w,
                  radius: 12.r,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: context.dividerColor.withOpacity(0.1),
                  ),
                  child: Icon(Icons.image, color: context.dividerColor),
                ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: FontFamily.openSans,
                    color: context.primaryColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _buildBadge(
                        isGive ? 'Give' : 'Take',
                        context.isDarkMode
                            ? Colors.blue.withOpacity(0.15)
                            : const Color(0xFFE8F1FF),
                        const Color(0xFF2F80ED)),
                    SizedBox(width: 8.w),
                    _buildBadge(
                        response.status.toUpperCase(),
                        response.status == 'completed'
                            ? (context.isDarkMode
                                ? Colors.green.withOpacity(0.15)
                                : const Color(0xFFE8F9EE))
                            : (context.isDarkMode
                                ? Colors.orange.withOpacity(0.15)
                                : const Color(0xFFFFF4E8)),
                        response.status == 'completed'
                            ? const Color(0xFF27AE60)
                            : const Color(0xFFF2994A)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildUserCard(TradeResponseModel response) {
    final authController = context.read<AuthController>();
    final currentUserId = authController.currentUser?.id;

    // Identify the partner
    final isPoster = currentUserId == response.posterUserId;
    final partnerName =
        isPoster ? (response.responderName) : (response.posterName ?? 'Poster');
    final partnerImage = isPoster
        ? (response.responderImage ?? '')
        : (response.posterImage ?? '');

    final imageUrl = partnerImage;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          AppCachedImage(
            imageUrl: imageUrl,
            userName: partnerName,
            width: 56.r,
            height: 56.r,
            radius: 28.r,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: FontFamily.openSans,
                    color: context.textColor,
                  ),
                ),
                Text(
                  (() {
                    final isGive = response.postType == 'give' || response.postType == 'giving';
                    final partnerIsGiving = (isPoster && !isGive) || (!isPoster && isGive);
                    final itemName = response.postItemName ?? response.givingItemName ?? 'Item';
                    return partnerIsGiving ? AppLocalizations.of(context)!.givingYouItem(itemName) : AppLocalizations.of(context)!.takingYourItem(itemName);
                  })(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: context.subTextColor,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              int partnerId =
                  isPoster ? response.responderId : response.posterUserId;
              ProfileController.navigateToUserProfile(context, partnerId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
            child: Text(
              AppLocalizations.of(context)!.viewProfile,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: context.onPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMarkActions(TradeResponseModel response) {
    final authController = context.read<AuthController>();
    final currentUserId = authController.currentUser?.id;
    final isCompleted = response.status.toLowerCase() == 'completed';
    final isPoster = currentUserId == response.posterUserId;
    final partnerId = isPoster ? response.responderId : response.posterUserId;
    // Retrieve previously submitted mark from controller (persisted across navigation)
    final tradeController = context.read<TradeController>();
    final existingMark = tradeController.getUserMark(response.id);
    // local variable for UI (will be overwritten by controller state if present)
    final markFromState = existingMark ?? _submittedMark;


    // Show like/dislike only after trade completed and valid partner
    if (!isCompleted || currentUserId == null || partnerId == 0) {
      return const SizedBox.shrink();
    }

    return Consumer<TradeController>(
      builder: (context, tradeController, _) {
        final currentMark = tradeController.getUserMark(response.id) ?? _submittedMark ?? response.userMark?.toLowerCase();
        
        return Container(
          margin: EdgeInsets.only(top: 10.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color:
                context.isDarkMode ? Colors.white10 : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.dividerColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMarkButton(
                  label: AppLocalizations.of(context)!.like,
                  icon: Icons.thumb_up_alt_outlined,
                  color: Colors.green,
                  isSelected: currentMark == 'like',
                  isLoading: tradeController.isMarkingUser,
                  onTap: () => _submitUserMark(response, partnerId, 'like'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildMarkButton(
                  label: AppLocalizations.of(context)!.dislike,
                  icon: Icons.thumb_down_alt_outlined,
                  color: Colors.red,
                  isSelected: currentMark == 'dislike',
                  isLoading: tradeController.isMarkingUser,
                  onTap: () => _submitUserMark(response, partnerId, 'dislike'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarkButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : context.surfaceColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: isSelected ? color : context.dividerColor),
        ),
        child: isLoading
            ? SizedBox(
                height: 18.r,
                width: 18.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.primaryColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      color: isSelected ? Colors.white : color, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : context.textColor,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitUserMark(
    TradeResponseModel response,
    int partnerId,
    String mark,
  ) async {
    final tc = context.read<TradeController>();
    final success = await tc.submitUserMark(
          tradeResponseId: response.id,
          userId: partnerId,
          mark: mark,
        );

    if (!mounted) return;

    if (success) {
      // Persist the mark in controller for later retrieval
      tc.setUserMark(response.id, mark);
      setState(() => _submittedMark = mark);
      ToastService.showSuccessToast(
        context,
        mark == 'like' ? AppLocalizations.of(context)!.likedSuccessfully : AppLocalizations.of(context)!.dislikedSuccessfully,
      );
      return;
    }

    final message =
        tc.errorMessage ?? AppLocalizations.of(context)!.failedToSubmitMark;
    ToastService.showErrorToast(context, message);
  }

  Widget _buildExchangeCard(TradeResponseModel response) {
    final authController = context.read<AuthController>();
    final currentUserId = authController.currentUser?.id;
    final isPoster = currentUserId == response.posterUserId;
    final isGive = response.postType == 'give' || response.postType == 'giving';
    final partnerIsGiving = (isPoster && !isGive) || (!isPoster && isGive);

    final isTicketTrade =
        response.responseType == 'price' || response.postReturnType == 'Price';

    String exchangeLabel = partnerIsGiving ? AppLocalizations.of(context)!.youGive : AppLocalizations.of(context)!.youReceive;
    String exchangeValue =
        response.itemName ?? response.givingItemName ?? 'Item';
    IconData exchangeIcon = Icons.inventory_2_outlined;

    if (isTicketTrade) {
      exchangeLabel = partnerIsGiving ? AppLocalizations.of(context)!.youPay : AppLocalizations.of(context)!.youReceive;
      if (response.offerPrice != null && response.offerPrice! > 0) {
        exchangeValue = '₹${response.offerPrice!.toStringAsFixed(0)}';
      } else if (response.priceRangeStart != null) {
        final startPrice = response.priceRangeStart!.toStringAsFixed(0);
        final endPrice = (response.priceRangeEnd ?? response.priceRangeStart!).toStringAsFixed(0);
        
        if (startPrice == endPrice) {
          exchangeValue = '₹$startPrice';
        } else {
          exchangeValue = '₹$startPrice - ₹$endPrice';
        }
      } else if (response.paymentAmount != null) {
        final parsedAmt = double.tryParse(response.paymentAmount!)?.toStringAsFixed(0) ?? response.paymentAmount;
        exchangeValue = '₹$parsedAmt';
      } else {
        exchangeValue = 'Price';
      }
      exchangeIcon = Icons.currency_rupee;
    }

    final images = response.itemImages.isNotEmpty
        ? response.itemImages
        : (response.givingItemImages ?? []);
    final imageUrl = images.isNotEmpty
        ? (images.first.startsWith('http')
            ? images.first.replaceFirst('http://88.222.245.145:4000', 'https://toolucs.com').replaceFirst('http://', 'https://')
            : '${ApiConstants.baseUrl2}${images.first}')
        : '';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color:
                  context.isDarkMode ? Colors.white10 : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: context.dividerColor),
            ),
            child: imageUrl.isNotEmpty && !isTicketTrade
                ? AppCachedImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    radius: 8.r,
                  )
                : Icon(exchangeIcon, color: context.primaryColor),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exchangeLabel,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: context.subTextColor,
                  ),
                ),
                Text(
                  exchangeValue,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: FontFamily.openSans,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeInfoCard(TradeResponseModel response) {
    String formattedDate = response.createdAt;
    if (formattedDate.contains('T')) {
      formattedDate = formattedDate.split('T').first;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today_outlined, AppLocalizations.of(context)!.dateLabel(formattedDate)),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.access_time_outlined,
              AppLocalizations.of(context)!.statusLabel(response.status.toUpperCase())),
          if (response.meetingType != null) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(Icons.handshake_outlined,
                AppLocalizations.of(context)!.meetingLabel(response.meetingType!.replaceAll('_', ' ').toUpperCase())),
          ],

          //dont show this
          // if (response.paymentAmount != null ||
          //     (response.offerPrice != null && response.offerPrice! > 0)) ...[
          //   SizedBox(height: 12.h),
          //   _buildInfoRow(Icons.payments_outlined,
          //       'Final Amount: ${response.paymentAmount ?? response.offerPrice} Tickets'),
          // ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: context.subTextColor, size: 20.sp),
        SizedBox(width: 12.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.subTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(TradeResponseModel response) {
    String notes = response.itemDescription ?? AppLocalizations.of(context)!.noAdditionalNotesProvided;
    if (response.rejectedReason != null) {
      notes = '${AppLocalizations.of(context)!.rejectedReasonLabel(response.rejectedReason!)}\n\n$notes';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description_outlined,
              color: context.subTextColor, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              notes,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: context.subTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
