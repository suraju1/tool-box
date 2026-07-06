import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/core/services/share_service.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/trades/controller/trade_controller.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/trades/model/post_model.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/util/date_util.dart';
import 'package:tool_bocs/features/web_ui/widgets/web_product_card.dart';
import 'package:tool_bocs/features/web_ui/view/web_save_to_collection_dialog.dart';
import 'package:tool_bocs/features/web_ui/widgets/sticky_sidebar_wrapper.dart';
import 'package:tool_bocs/features/trades/widgets/report_post_sheet.dart';

class WebProductDetailsScreen extends StatefulWidget {
  final int postId;
  const WebProductDetailsScreen({super.key, required this.postId});

  @override
  State<WebProductDetailsScreen> createState() =>
      _WebProductDetailsScreenState();
}

class _WebProductDetailsScreenState extends State<WebProductDetailsScreen> {
  int _currentImageIndex = 0;
  bool _isHoveringImage = false;
  bool _isSharing = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _rowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradeController>().fetchPostDetails(widget.postId);
      context.read<ProfileController>().getSavedUsers();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      body: Consumer2<TradeController, LocationController>(
        builder: (context, controller, locationController, child) {
          if (controller.errorMessage != null) {
            return Center(child: Text(controller.errorMessage!));
          }

          if (widget.postId == 0) {
            return Center(
              child: Text(AppLocalizations.of(context)!.errorNoPostIdProvided),
            );
          }

          if (controller.isLoading ||
              controller.selectedPost?.id != widget.postId) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = controller.selectedPost;
          if (post == null) {
            return Center(
                child:
                    Text(AppLocalizations.of(context)!.postNotFoundOrAccess));
          }

          // Generate similar posts from already loaded frontend list
          final similarPosts = controller.homePosts
              .where(
                (p) => p.itemCategory == post.itemCategory && p.id != post.id,
              )
              .take(10)
              .toList();

          return SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreadcrumbs(post),
                      const SizedBox(height: 32),
                      Row(
                        key: _rowKey,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Media & Details (Now Sticky/Stable)
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildImageGallery(
                                  post.itemImages,
                                  post.itemCategory,
                                  post.tradeType,
                                ),
                                const SizedBox(height: 24),
                                _buildConditionAndSourceBox(post),
                              ],
                            ),
                          ),
                          const SizedBox(width: 64),
                          // Right Column: Seller Info, Actions, Specs (Now Scrollable)
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNewSellerCard(post),
                                const SizedBox(height: 24),
                                _buildProductInfoCard(post, locationController),
                                const SizedBox(height: 24),
                                _buildReturnItemCard(post),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                      // Bottom Section: Full Width Similar Products
                      if (similarPosts.isNotEmpty)
                        _buildRelatedProducts(similarPosts, post.itemCategory),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.surfaceColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: context.textColor,
          size: 20,
        ),
      ),
      centerTitle: true,
      title: Consumer<TradeController>(
        builder: (context, controller, child) {
          return Text(
            controller.selectedPost?.itemName ?? 'Product Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: FontFamily.openSans,
              color: context.textColor,
            ),
          );
        },
      ),
      actions: [
        Consumer<TradeController>(
          builder: (context, controller, child) {
            final post = controller.selectedPost;
            if (post == null) return const SizedBox.shrink();
            return Row(
              children: [
                  Consumer<AuthController>(
                    builder: (context, authController, _) {
                      final isOwner =
                          authController.currentUser?.id == post.userId;
                      return PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            color: context.textColor, size: 20),
                        onSelected: (value) async {
                          if (value == 'share') {
                            try {
                              await ShareService().sharePost(
                                context,
                                post: post,
                                includeImage: true,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ToastService.showErrorToast(
                                    context, 'Unable to share. Try again.');
                              }
                            }
                          } else if (value == 'report') {
                            ReportPostSheet.show(context, post.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share_outlined, color: context.textColor, size: 20),
                                const SizedBox(width: 10),
                                Text(AppLocalizations.of(context)!.sharePost, style: TextStyle(color: context.textColor)),
                              ],
                            ),
                          ),
                          if (!isOwner)
                            PopupMenuItem<String>(
                              value: 'report',
                              child: Row(
                                children: [
                                  const Icon(Icons.report_problem_outlined, color: Colors.red, size: 20),
                                  const SizedBox(width: 10),
                                  Text(AppLocalizations.of(context)!.reportPost, style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                const SizedBox(width: 16),
              ],
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: context.dividerColor),
      ),
    );
  }

  Widget _buildBreadcrumbs(PostModel post) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.bottomNavBar,
            (route) => false,
          ),
          child: Text(
            AppLocalizations.of(context)!.home,
            style: TextStyle(
              color: context.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Icon(Icons.chevron_right, size: 14, color: Colors.grey),
        ),
        Text(
          post.itemCategory,
          style: TextStyle(
            color: context.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Icon(Icons.chevron_right, size: 14, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            post.itemName,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(List<String> images, String category, String tradeType) {
    if (images.isEmpty) {
      return Container(
        height: 600,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dividerColor),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 64,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Hero Image
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringImage = true),
          onExit: (_) => setState(() => _isHoveringImage = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 600,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedScale(
                    scale: _isHoveringImage ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutQuart,
                    child: AppCachedImage(
                      imageUrl: images[_currentImageIndex],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      radius: 0,
                    ),
                  ),
                  Positioned(
                    top: 24,
                    left: 24,
                    child: _buildCategoryTag(category),
                  ),
                  Positioned(
                    top: 24,
                    right: 24,
                    child: _buildTradeTypeTag(tradeType),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Thumbnail Gallery
        if (images.length > 1)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final isSelected = _currentImageIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _currentImageIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? context.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: context.primaryColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AppCachedImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        radius: 0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: label.toLowerCase().contains('goods')
            ? Colors.blue.shade700
            : label.toLowerCase().contains('services')
                ? Colors.green.shade700
                : label.toLowerCase().contains('money')
                    ? Colors.orange.shade700
                    : context.isDarkMode
                        ? Colors.white
                        : Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: (label.toLowerCase().contains('goods') ||
                  label.toLowerCase().contains('services') ||
                  label.toLowerCase().contains('money'))
              ? Colors.white
              : context.isDarkMode
                  ? Colors.black
                  : Colors.white,
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTradeTypeTag(String tradeType) {
    if (tradeType.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tradeType.toUpperCase(),
        style: TextStyle(
          color: context.isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildConditionAndSourceBox(PostModel post) {
    if (post.itemCategory.toLowerCase() != 'goods')
      return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.itemCondition != null && post.itemCondition!.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                    child: Text('Condition',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14))),
                Expanded(
                    flex: 2,
                    child: Text(post.itemCondition!,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: context.textColor))),
              ],
            ),
            if (post.itemSource != null && post.itemSource!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: context.dividerColor.withOpacity(0.5)),
              const SizedBox(height: 16),
            ]
          ],
          if (post.itemSource != null && post.itemSource!.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                    child: Text('Source',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14))),
                Expanded(
                    flex: 2,
                    child: Text(post.itemSource!,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: context.textColor))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductInfoCard(
      PostModel post, LocationController locationController) {
    List<String> points =
        post.itemNote.split('\n').where((s) => s.trim().isNotEmpty).toList();

    if (points.length == 1 &&
        post.itemNote.contains('.') &&
        post.itemNote.length > 50) {
      points = post.itemNote
          .split('.')
          .where((s) => s.trim().isNotEmpty)
          .map((s) => '$s.')
          .toList();
    }

    final bool isCompleted = post.status.toLowerCase() == 'completed';
    final authController = context.read<AuthController>();
    final isOwner = authController.currentUser?.id == post.userId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.itemName,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: FontFamily.openSans,
              color: context.textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.descriptionPoints,
            style: TextStyle(
              fontSize: 16,
              color: context.textColor.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.textColor.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point.trim(),
                      style: TextStyle(
                        fontSize: 15,
                        color: context.textColor.withOpacity(0.75),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: context.dividerColor.withOpacity(0.5)),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 18, color: context.subTextColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  post.distanceKm != null
                      ? '${post.distanceKm!.toStringAsFixed(1)} km away from ${locationController.address ?? 'Current Location'}'
                      : post.pickupArea,
                  style: TextStyle(fontSize: 14, color: context.subTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time_outlined,
                  size: 18, color: context.subTextColor),
              const SizedBox(width: 12),
              Text(
                'Posted ${DateUtil.formatTimeAgo(post.createdAt)}.',
                style: TextStyle(fontSize: 14, color: context.subTextColor),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.thisItemIsNoLonger,
                  style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            )
          else if (isOwner)
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.notifications,
                arguments: post.id,
              ),
              icon: const Icon(Icons.inbox_rounded),
              label: Text(AppLocalizations.of(context)!.viewOffers),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    context.isDarkMode ? Colors.white : Colors.black,
                foregroundColor:
                    context.isDarkMode ? Colors.black : Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          else ...[
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.tradeOffer),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    context.isDarkMode ? Colors.white : Colors.black,
                foregroundColor:
                    context.isDarkMode ? Colors.black : Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: Text(
                  'Make Offer (${post.postType.toLowerCase() == 'take' || post.postType.toLowerCase() == 'taking' ? 'Give It' : 'Take It'})'),
            ),
            const SizedBox(height: 12),
            Consumer<ProfileController>(
              builder: (context, profileController, child) {
                final isSaved = profileController.savedUsers
                    .any((user) => user.id == post.userId);
                return OutlinedButton.icon(
                  onPressed: () async {
                    if (isSaved) {
                      final response =
                          await profileController.unsaveUser(post.userId);
                      if (context.mounted) {
                        if (response.success) {
                          ToastService.showSuccessToast(
                              context, 'Seller removed from saved');
                        } else {
                          ToastService.showErrorToast(
                              context, response.message ?? 'Failed to unsave');
                        }
                      }
                    } else {
                      WebSaveToCollectionDialog.show(context, post.userId);
                    }
                  },
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 20),
                  label: Text(isSaved ? 'Seller Saved' : 'Save Seller'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: isSaved
                            ? context.primaryColor
                            : (context.isDarkMode
                                ? Colors.white
                                : Colors.black87),
                        width: 1),
                    foregroundColor: isSaved
                        ? context.primaryColor
                        : (context.isDarkMode ? Colors.white : Colors.black87),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReturnItemCard(PostModel post) {
    final bool isPrice = _isPriceReturn(post);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(
                  bottom:
                      BorderSide(color: context.dividerColor.withOpacity(0.5))),
            ),
            child: Text(
              isPrice ? 'Price in return' : 'Item in return',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPrice) ...[
                  Text(
                    post.priceMax != null && post.priceMax! > post.priceMin!
                        ? '₹${post.priceMin} - ₹${post.priceMax}'
                        : '₹${post.priceMin}',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        fontFamily: FontFamily.openSans,
                        color: context.textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.priceInReturn,
                      style:
                          TextStyle(fontSize: 15, color: context.subTextColor)),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: post.returnItemImages.isNotEmpty
                            ? AppCachedImage(
                                imageUrl: post.returnItemImages.first,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                radius: 0)
                            : Container(
                                width: 64,
                                height: 64,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image,
                                    color: Colors.grey)),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Text(
                                        AppLocalizations.of(context)!.itemName,
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13))),
                                Expanded(
                                    flex: 2,
                                    child: Text(post.returnItemName ?? '-',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: context.textColor))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Text(
                                        AppLocalizations.of(context)!.condition,
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13))),
                                Expanded(
                                    flex: 2,
                                    child: Text(post.returnItemCondition ?? '-',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: context.textColor))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .itemSource,
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13))),
                                Expanded(
                                    flex: 2,
                                    child: Text(post.returnItemSource ?? '-',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: context.textColor))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (post.returnItemDescription != null &&
                      post.returnItemDescription!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(AppLocalizations.of(context)!.description,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    ...post.returnItemDescription!
                        .split('\n')
                        .where((l) => l.trim().isNotEmpty)
                        .map((l) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      margin: const EdgeInsets.only(
                                          top: 6, right: 10),
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade400,
                                          shape: BoxShape.circle)),
                                  Expanded(
                                      child: Text(l.trim(),
                                          style: TextStyle(
                                              color: context.subTextColor,
                                              fontSize: 14,
                                              height: 1.4))),
                                ],
                              ),
                            )),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewSellerCard(PostModel post) {
    final String postTypeStr = (post.postType.toLowerCase() == 'take' ||
            post.postType.toLowerCase() == 'taking')
        ? 'Taking'
        : 'Giving';
    return InkWell(
      onTap: () {
        ProfileController.navigateToUserProfile(context, post.userId);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: post.userImage != null
                  ? NetworkImage(
                          AppCachedImage.getFormattedUrl(post.userImage!))
                      as ImageProvider
                  : null,
              child: (post.userImage == null || post.userImage!.isEmpty)
                  ? Text(
                      post.userName.isNotEmpty
                          ? post.userName.substring(0, 1).toUpperCase()
                          : '?',
                      style:
                          TextStyle(fontSize: 22, color: Colors.grey.shade700),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.userName.isNotEmpty
                        ? post.userName
                        : 'User id-${post.userId}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.createdAt.isNotEmpty
                        ? DateUtil.formatTimeAgo(post.createdAt)
                        : 'Recently',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                    color: postTypeStr == 'Giving'
                        ? Colors.green.shade400
                        : context.primaryColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                postTypeStr,
                style: TextStyle(
                  color: postTypeStr == 'Giving'
                      ? Colors.green.shade600
                      : context.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(PostModel post) {
    final authController = context.read<AuthController>();
    final isOwner = authController.currentUser?.id == post.userId;

    if (isOwner) {
      return ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.notifications,
          arguments: post.id,
        ),
        icon: const Icon(Icons.inbox_rounded),
        label: Text(AppLocalizations.of(context)!.viewOffers),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      );
    }

    final String btnText = (post.postType.toLowerCase() == 'take' ||
            post.postType.toLowerCase() == 'taking')
        ? 'Give It'
        : 'Take It';

    return Column(
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.tradeOffer),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primaryColor,
            foregroundColor: context.onPrimaryColor,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            elevation: 8,
            shadowColor: context.primaryColor.withOpacity(0.4),
          ),
          child: Text('Make Offer ($btnText)'),
        ),
        const SizedBox(height: 16),
        Consumer<ProfileController>(
          builder: (context, profileController, child) {
            final isSaved = profileController.savedUsers.any(
              (user) => user.id == post.userId,
            );
            return OutlinedButton.icon(
              onPressed: () {
                WebSaveToCollectionDialog.show(context, post.userId);
              },
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
              label: Text(isSaved ? 'Seller Saved' : 'Save Seller'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                side: BorderSide(
                  color: isSaved ? context.primaryColor : context.dividerColor,
                  width: 1.5,
                ),
                foregroundColor:
                    isSaved ? context.primaryColor : context.textColor,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSellerCard(PostModel post) {
    final String postType = post.postType.toLowerCase();
    final bool isGiving = postType == 'give' || postType == 'giving';
    final Color badgeColor = isGiving ? Colors.green : Colors.blue;
    final String badgeText = isGiving ? 'Giving' : 'Asking';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () =>
            ProfileController.navigateToUserProfile(context, post.userId),
        hoverColor: Colors.transparent,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.dividerColor, width: 1),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: context.primaryColor.withOpacity(0.1),
                backgroundImage: post.userImage != null
                    ? NetworkImage(
                        AppCachedImage.getFormattedUrl(post.userImage!),
                      ) as ImageProvider
                    : null,
                child: (post.userImage == null || post.userImage!.isEmpty)
                    ? Text(
                        post.userName.isNotEmpty
                            ? post.userName.substring(0, 1).toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.userName.isNotEmpty
                        ? post.userName
                        : 'User id-${post.userId}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateUtil.formatTimeAgo(post.createdAt),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: badgeColor, width: 1.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isPriceReturn(PostModel post) {
    final type = post.returnType.trim().toLowerCase();
    return type == 'price' ||
        type == 'money' ||
        type == 'cash' ||
        type == 'amount';
  }

  bool _hasReturnItemDetails(PostModel post) {
    return post.returnItemImages.isNotEmpty ||
        (post.returnItemName?.trim().isNotEmpty ?? false) ||
        (post.returnItemCategory?.trim().isNotEmpty ?? false) ||
        (post.returnItemCondition?.trim().isNotEmpty ?? false) ||
        (post.returnItemSource?.trim().isNotEmpty ?? false) ||
        (post.returnItemDescription?.trim().isNotEmpty ?? false);
  }

  Widget _buildReturnDetailsSection(
    PostModel post,
    LocationController locationController,
  ) {
    final bool isCompleted = post.status.toLowerCase() == 'completed';
    final bool isPrice = _isPriceReturn(post);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPrice ? 'Price in return' : 'Item in return',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 16),
          if (isPrice) ...[
            Text(
              post.priceMax != null && post.priceMax! > post.priceMin!
                  ? '₹${post.priceMin} - ₹${post.priceMax}'
                  : '₹${post.priceMin}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontFamily: FontFamily.openSans,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.priceInReturn,
              style: TextStyle(
                fontSize: 16,
                color: context.textColor.withOpacity(0.8),
              ),
            ),
          ] else ...[
            if (_hasReturnItemDetails(post)) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.returnItemImages.isNotEmpty)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            _openReturnImagePreview(post.returnItemImages, 0),
                        borderRadius: BorderRadius.circular(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppCachedImage(
                            imageUrl: post.returnItemImages.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  if (post.returnItemImages.isNotEmpty)
                    const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.returnItemName != null &&
                            post.returnItemName!.isNotEmpty)
                          _buildReturnSpecItem(
                            'Item Name',
                            post.returnItemName!,
                          ),
                        if (post.returnItemCondition != null &&
                            post.returnItemCondition!.isNotEmpty)
                          _buildReturnSpecItem(
                            'Condition',
                            post.returnItemCondition!,
                          ),
                        if (post.returnItemSource != null &&
                            post.returnItemSource!.isNotEmpty)
                          _buildReturnSpecItem(
                            'Item Source',
                            post.returnItemSource!,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (post.returnItemDescription != null &&
                  post.returnItemDescription!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  post.returnItemDescription!,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.textColor,
                    height: 1.5,
                  ),
                ),
              ],
            ] else ...[
              Text(
                post.returnItemName ?? 'Exchange Item',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: FontFamily.openSans,
                  color: context.textColor,
                ),
              ),
            ],
          ],
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  post.distanceKm != null
                      ? '${post.distanceKm!.toStringAsFixed(1)} km away from ${locationController.address ?? 'Current Location'}'
                      : post.pickupArea,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Text(
                'Posted ${DateUtil.formatTimeAgo(post.createdAt)}.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!isCompleted) _buildActionButtons(post),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.thisItemIsNoLonger,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReturnSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _openReturnImagePreview(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReturnImagePreviewScreenWeb(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildRelatedProducts(List<PostModel> posts, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'More in $category',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                fontFamily: FontFamily.openSans,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.recommendedItemsFromVerifiedSellers,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 420,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 24),
            itemBuilder: (context, index) {
              final item = posts[index];
              return WebProductCard(post: item, width: 300);
            },
          ),
        ),
      ],
    );
  }
}

class _ReturnImagePreviewScreenWeb extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ReturnImagePreviewScreenWeb({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ReturnImagePreviewScreenWeb> createState() =>
      _ReturnImagePreviewScreenWebState();
}

class _ReturnImagePreviewScreenWebState
    extends State<_ReturnImagePreviewScreenWeb> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialIndex.clamp(0, widget.images.length - 1).toInt();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: SizedBox.expand(
                      child: AppCachedImage(
                        imageUrl: widget.images[index],
                        fit: BoxFit.contain,
                        radius: 0,
                        errorWidget: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white54,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 24,
              left: 24,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                top: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
