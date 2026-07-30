import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/chat/controller/chat_service.dart';

import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/widgets/user_review_dialog.dart';
import 'package:tool_bocs/features/trades/model/trade_response_model.dart';

import 'package:tool_bocs/core/services/chat_listener.dart';

import 'package:tool_bocs/core/widgets/app_cached_image.dart';

class WebChatScreen extends StatefulWidget {
  final String? chatRoomId;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserImage;
  final TradeResponseModel? tradeResponse;
  final bool showBackButton;

  const WebChatScreen({
    super.key,
    this.chatRoomId,
    this.otherUserId,
    this.otherUserName,
    this.otherUserImage,
    this.tradeResponse,
    this.showBackButton = true,
  });

  @override
  State<WebChatScreen> createState() => _WebChatScreenState();
}

class _WebChatScreenState extends State<WebChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserId;
  String _chatRoomId = '';
  Stream<QuerySnapshot>? _messagesStream;

  late String otherUserName;

  @override
  void initState() {
    super.initState();
    otherUserName = widget.otherUserName ?? "Chat";
    _initializeChat();
  }

  @override
  void dispose() {
    ChatListener.currentChatRoomId = null;
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final user = await _chatService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.id.toString();
        if (widget.chatRoomId != null) {
          _chatRoomId = widget.chatRoomId!;
        } else if (widget.otherUserId != null) {
          _chatRoomId = _chatService.getChatRoomId(
            _currentUserId!,
            widget.otherUserId!,
            tradeId: widget.tradeResponse?.id,
          );
        }

        if (_chatRoomId.isNotEmpty) {
          _messagesStream = _chatService.getMessages(_chatRoomId);
        }
      });

      if (_chatRoomId.isNotEmpty) {
        ChatListener.currentChatRoomId = _chatRoomId;
        _chatService.markMessagesAsRead(_chatRoomId, _currentUserId!);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _currentUserId == null ||
        widget.otherUserId == null) {
      return;
    }

    if (_chatRoomId.isEmpty) {
      _chatRoomId = _chatService.getChatRoomId(
        _currentUserId!,
        widget.otherUserId!,
        tradeId: widget.tradeResponse?.id,
      );
    }

    await _chatService.sendMessage(
        _chatRoomId, _messageController.text.trim(), widget.otherUserId!,
        tradeResponse: widget.tradeResponse);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTradeStatusBanner(),
          Expanded(
            child: _chatRoomId.isEmpty || _currentUserId == null
                ? Column(
                    children: [
                      Expanded(
                        child: Center(
                            child: Text(
                                AppLocalizations.of(context)!
                                    .startAConversation,
                                style: TextStyle(fontSize: 16))),
                      ),
                      _buildInput(false),
                    ],
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error}',
                                style: const TextStyle(fontSize: 16)));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      bool isChatDisabled = false;
                      if (docs.isNotEmpty) {
                        try {
                          final firstMsgData =
                              docs.last.data() as Map<String, dynamic>;
                          final Timestamp? firstMsgTimestamp =
                              firstMsgData['timestamp'];
                          if (firstMsgTimestamp != null) {
                            final firstMsgTime = firstMsgTimestamp.toDate();
                            final now = DateTime.now();
                            final difference = now.difference(firstMsgTime);
                            if (difference.inHours >= 72) {
                              isChatDisabled = true;
                            }
                          }
                        } catch (e) {
                          debugPrint("Error calculating chat lockout: $e");
                        }
                      }

                      if (docs.isNotEmpty &&
                          _currentUserId != null &&
                          _chatRoomId.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _chatService.markMessagesAsRead(
                              _chatRoomId, _currentUserId!);
                        });
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 20),
                              itemCount: docs.length,
                              itemBuilder: (_, i) {
                                final data =
                                    docs[i].data() as Map<String, dynamic>;
                                return _buildMessageBubble(data);
                              },
                            ),
                          ),
                          _buildInput(isChatDisabled),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.surfaceColor,
      elevation: 0,
      automaticallyImplyLeading: widget.showBackButton,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child:
            Container(color: context.dividerColor.withOpacity(0.5), height: 1),
      ),
      leading: widget.showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: context.textColor, size: 24),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildAvatar(40),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                otherUserName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: FontFamily.openSans,
                  color: context.textColor,
                ),
              ),
              _buildPartnerMobile(),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          padding: const EdgeInsets.only(right: 16),
          icon: const Icon(Icons.info_outline),
          color: context.textColor,
          onPressed: _showInfoDialog,
        ),
        IconButton(
          padding: const EdgeInsets.only(right: 16),
          icon: const Icon(Icons.more_vert),
          color: context.textColor,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => UserReviewDialog(
                userId: int.tryParse(widget.otherUserId ?? '0') ?? 0,
                userName: otherUserName,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvatar(double size) {
    if (widget.tradeResponse != null) {
      final isOwner = context.read<AuthController>().currentUser?.id ==
          widget.tradeResponse!.posterUserId;
      final imageUrl = isOwner
          ? (widget.tradeResponse!.responderImage ??
              widget.otherUserImage ??
              '')
          : (widget.tradeResponse!.posterImage ?? widget.otherUserImage ?? '');

      return AppCachedImage(
        imageUrl: imageUrl,
        userName: otherUserName,
        width: size,
        height: size,
        fit: BoxFit.cover,
        radius: size / 2,
      );
    } else if (widget.otherUserImage != null &&
        widget.otherUserImage!.isNotEmpty) {
      return AppCachedImage(
        imageUrl: widget.otherUserImage!,
        userName: otherUserName,
        width: size,
        height: size,
        fit: BoxFit.cover,
        radius: size / 2,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        otherUserName.trim().isNotEmpty
            ? otherUserName.trim().substring(0, 1).toUpperCase()
            : '?',
        style: TextStyle(
          color: context.primaryColor,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPartnerMobile() {
    if (widget.tradeResponse == null || _currentUserId == null)
      return const SizedBox.shrink();

    return Builder(builder: (context) {
      final trade = widget.tradeResponse!;
      final isOwner =
          context.read<AuthController>().currentUser?.id == trade.posterUserId;
      final partnerMobile =
          isOwner ? trade.responderMobile : trade.posterMobile;

      if (partnerMobile == null || partnerMobile.isEmpty)
        return const SizedBox.shrink();

      return Text(
        partnerMobile,
        style: TextStyle(
          color: context.subTextColor,
          fontSize: 12,
          fontFamily: FontFamily.openSans,
        ),
      );
    });
  }

  void _showInfoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.chatInfoTitle,
                style: TextStyle(
                  color: context.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: FontFamily.openSans,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: Icon(Icons.circle,
                        size: 6, color: context.textColor.withOpacity(0.5)),
                  ),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.chatInfo1,
                      style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          fontFamily: FontFamily.openSans),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: Icon(Icons.circle,
                        size: 6, color: context.textColor.withOpacity(0.5)),
                  ),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.chatInfo2,
                      style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          fontFamily: FontFamily.openSans),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: Icon(Icons.circle,
                        size: 6, color: context.textColor.withOpacity(0.5)),
                  ),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.chatInfo3,
                      style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          fontFamily: FontFamily.openSans),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context)!.done,
                    style: TextStyle(
                      color: context.onPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTradeStatusBanner() {
    if (widget.tradeResponse == null || _currentUserId == null) {
      return const SizedBox.shrink();
    }

    final trade = widget.tradeResponse!;
    final isOwner =
        context.read<AuthController>().currentUser?.id == trade.posterUserId;

    String givingItem = '';
    String takingItem = '';

    final isGivePost = trade.postType?.toLowerCase() == 'give' ||
        trade.postType?.toLowerCase() == 'giving';

    if (isOwner) {
      if (isGivePost) {
        givingItem = trade.postItemName ?? 'Item';
        takingItem = trade.responseType.toLowerCase() == 'price'
            ? '₹${trade.priceRangeStart} - ₹${trade.priceRangeEnd}'
            : (trade.itemName ?? 'Item');
      } else {
        givingItem = trade.responseType.toLowerCase() == 'price'
            ? '₹${trade.priceRangeStart} - ₹${trade.priceRangeEnd}'
            : (trade.itemName ?? 'Item');
        takingItem = trade.postItemName ?? 'Item';
      }
    } else {
      if (isGivePost) {
        givingItem = trade.responseType.toLowerCase() == 'price'
            ? '₹${trade.priceRangeStart} - ₹${trade.priceRangeEnd}'
            : (trade.itemName ?? 'Item');
        takingItem = trade.postItemName ?? 'Item';
      } else {
        givingItem = trade.postItemName ?? 'Item';
        takingItem = trade.responseType.toLowerCase() == 'price'
            ? '₹${trade.priceRangeStart} - ₹${trade.priceRangeEnd}'
            : (trade.itemName ?? 'Item');
      }
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => UserReviewDialog(
            userId: int.tryParse(widget.otherUserId ?? '0') ?? 0,
            userName: otherUserName,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: context.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFC),
          border: Border(
              bottom: BorderSide(
                  color: context.dividerColor.withOpacity(0.5), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle),
              child:
                  Icon(Icons.swap_horiz, color: context.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 15,
                      color: context.textColor,
                      fontFamily: FontFamily.openSans,
                      height: 1.5),
                  children: [
                    TextSpan(text: AppLocalizations.of(context)!.youChose),
                    TextSpan(
                        text: AppLocalizations.of(context)!
                            .givingTo(givingItem, otherUserName),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.primaryColor)),
                    TextSpan(text: AppLocalizations.of(context)!.andWord),
                    TextSpan(
                        text: AppLocalizations.of(context)!.taking(takingItem),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.primaryColor)),
                    TextSpan(text: AppLocalizations.of(context)!.inReturn),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final String senderId = msg['senderId'].toString();
    final bool isMe = senderId == _currentUserId;
    final Timestamp? timestamp = msg['timestamp'];
    final String time =
        timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';
    String text = msg['text'] ?? '';
    bool isImage = false;

    if (text.startsWith("[IMAGE] ")) {
      isImage = true;
      text = text.substring(8);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? context.primaryColor : context.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
          border: isMe
              ? null
              : Border.all(color: context.dividerColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      text,
                      height: 200,
                      width: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image,
                          color: isMe ? Colors.white : context.subTextColor,
                          size: 40),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                        color: isMe ? Colors.white : context.textColor,
                        fontSize: 15,
                        height: 1.4),
                  ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.8)
                          : context.subTextColor,
                      fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: (msg['isRead'] ?? false)
                        ? const Color(0xFF4ADE80)
                        : Colors.white.withOpacity(0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(bool isDisabled) {
    if (isDisabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.isDarkMode ? Colors.white10 : const Color(0xFFF8FAFC),
          border: Border(
              top: BorderSide(color: context.dividerColor.withOpacity(0.5))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chat with ${otherUserName.toLowerCase()} is over',
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'You cannot send or receive messages from ${otherUserName.toLowerCase()}',
              style: TextStyle(color: context.subTextColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
            top: BorderSide(color: context.dividerColor.withOpacity(0.5))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? Colors.white10
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: context.dividerColor.withOpacity(0.5)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.typeAMessage,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      hintStyle:
                          const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: context.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 24),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
