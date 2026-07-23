import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/profile/model/collection_model.dart';
import 'package:tool_bocs/features/profile/model/collection_item_model.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/web_ui/widgets/web_screen_header.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';

class WebCollectionItemsScreen extends StatefulWidget {
  final CollectionModel collection;

  const WebCollectionItemsScreen({super.key, required this.collection});

  @override
  State<WebCollectionItemsScreen> createState() =>
      _WebCollectionItemsScreenState();
}

class _WebCollectionItemsScreenState extends State<WebCollectionItemsScreen> {
  List<CollectionItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchItems();
    });
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    final response = await context
        .read<ProfileController>()
        .fetchCollectionItems(widget.collection.id);
    if (mounted) {
      setState(() {
        _items = response.success
            ? (response.data as List<CollectionItemModel>)
            : [];
        _isLoading = false;
      });
      if (!response.success) {
        ToastService.showErrorToast(
            context, response.message ?? 'Failed to load items');
      }
    }
  }

  Future<void> _deleteCollection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.deleteCollection,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWant3,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final response = await context
          .read<ProfileController>()
          .deleteCollection(widget.collection.id);
      if (response.success && mounted) {
        ToastService.showSuccessToast(context, 'Collection deleted');
        Navigator.pop(context); // Go back
      } else if (mounted) {
        ToastService.showErrorToast(
            context, response.message ?? 'Failed to delete');
      }
    }
  }

  Future<void> _removeItem(int itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.removeItem,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWant4,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.remove,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final response = await context
          .read<ProfileController>()
          .removeUserFromCollection(widget.collection.id, itemId);
      if (response.success && mounted) {
        ToastService.showSuccessToast(context, 'Item removed');
        _fetchItems();
      } else if (mounted) {
        ToastService.showErrorToast(
            context, response.message ?? 'Failed to remove');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              WebScreenHeader(
                title: widget.collection.name,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: AppLocalizations.of(context)!.deleteCollection,
                    onPressed: _deleteCollection,
                  ),
                ],
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open,
                                    size: 64,
                                    color: Theme.of(context).dividerColor),
                                const SizedBox(height: 16),
                                Text(
                                  'This collection is empty',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(32),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                            ),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _buildItemCard(context, item);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, CollectionItemModel item) {
    final dividerColor = Theme.of(context).dividerColor.withOpacity(0.3);
    return InkWell(
      onTap: () {
        if (item.itemType == 'profile') {
          ProfileController.navigateToUserProfile(context, item.itemId);
        } else {
          // It's a post. Not explicitly supported in this flow, but could be added.
          ToastService.showSuccessToast(
              context, 'Navigating to \${item.itemType} \${item.itemId}');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: AppCachedImage(
                imageUrl: item.profileImage ?? '',
                userName: item.fullName,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                radius: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.fullName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontFamily: FontFamily.openSans,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.location != null &&
                      item.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.location!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: () => _removeItem(item.itemId),
              tooltip: AppLocalizations.of(context)!.remove,
            ),
          ],
        ),
      ),
    );
  }
}
