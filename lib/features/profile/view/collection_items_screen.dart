import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/model/collection_model.dart';
import 'package:tool_bocs/features/profile/model/collection_item_model.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/services/toast_service.dart';

class CollectionItemsScreen extends StatefulWidget {
  final CollectionModel collection;

  const CollectionItemsScreen({super.key, required this.collection});

  @override
  State<CollectionItemsScreen> createState() => _CollectionItemsScreenState();
}

class _CollectionItemsScreenState extends State<CollectionItemsScreen> {
  List<CollectionItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    final response = await context.read<ProfileController>().fetchCollectionItems(widget.collection.id);
    if (mounted) {
      setState(() {
        _items = response.success ? (response.data as List<CollectionItemModel>) : [];
        _isLoading = false;
      });
      if (!response.success) {
        ToastService.showErrorToast(context, response.message ?? 'Failed to load items');
      }
    }
  }

  Future<void> _deleteCollection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: Text(AppLocalizations.of(context)!.deleteCollection, style: TextStyle(color: context.textColor)),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWant3, style: TextStyle(color: context.textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: context.subTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final response = await context.read<ProfileController>().deleteCollection(widget.collection.id);
      if (response.success && mounted) {
        ToastService.showSuccessToast(context, 'Collection deleted');
        Navigator.pop(context); // Go back
      } else if (mounted) {
        ToastService.showErrorToast(context, response.message ?? 'Failed to delete');
      }
    }
  }

  Future<void> _removeItem(int itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: Text(AppLocalizations.of(context)!.removeItem, style: TextStyle(color: context.textColor)),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWant4, style: TextStyle(color: context.textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: context.subTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.remove, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final response = await context.read<ProfileController>().removeUserFromCollection(widget.collection.id, itemId);
      if (response.success && mounted) {
        ToastService.showSuccessToast(context, 'Item removed');
        _fetchItems(); // Refresh
      } else if (mounted) {
        ToastService.showErrorToast(context, response.message ?? 'Failed to remove item');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.collection.name,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            fontFamily: FontFamily.openSans,
            color: context.textColor,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, size: 20.sp, color: context.textColor),
        ),
        actions: [
          IconButton(
            onPressed: _deleteCollection,
            icon: Icon(Icons.delete_outline, color: Colors.red, size: 24.sp),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchItems,
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        'No items in this collection.',
                        style: TextStyle(color: context.textColor, fontSize: 16.sp),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(20.w),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => SizedBox(height: 16.h),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _buildItemCard(item);
                      },
                    ),
            ),
    );
  }

  Widget _buildItemCard(CollectionItemModel item) {
    final dividerColor = context.dividerColor.withOpacity(0.3);
    return InkWell(
      onTap: () {
        if (item.itemType == 'profile') {
          ProfileController.navigateToUserProfile(context, item.itemId);
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: dividerColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: AppCachedImage(
                imageUrl: item.profileImage ?? '',
                userName: item.fullName,
                width: 48.w,
                height: 48.w,
                fit: BoxFit.cover,
                radius: 24.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fullName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.openSans,
                      color: context.textColor,
                    ),
                  ),
                  if (item.location != null)
                    Text(
                      item.location!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.subTextColor,
                        fontFamily: FontFamily.openSans,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeItem(item.itemId),
            ),
          ],
        ),
      ),
    );
  }
}
