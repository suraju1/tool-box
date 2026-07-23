import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/services/toast_service.dart';

class WebSaveToCollectionDialog extends StatefulWidget {
  final int userId;

  const WebSaveToCollectionDialog({super.key, required this.userId});

  static Future<void> show(BuildContext context, int userId) {
    return showDialog(
      context: context,
      builder: (context) => WebSaveToCollectionDialog(userId: userId),
    );
  }

  @override
  State<WebSaveToCollectionDialog> createState() =>
      _WebSaveToCollectionDialogState();
}

class _WebSaveToCollectionDialogState extends State<WebSaveToCollectionDialog> {
  bool _isCreating = false;
  bool _isSaving = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().getCollections();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateCollection() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ToastService.showErrorToast(context, 'Please enter a collection name');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final res = await context.read<ProfileController>().createCollection(name);

    if (context.mounted) {
      setState(() {
        _isSaving = false;
      });
      if (res.success) {
        ToastService.showSuccessToast(context, 'Collection created');
        setState(() {
          _isCreating = false;
          _nameController.clear();
        });
      } else {
        ToastService.showErrorToast(
            context, res.message ?? 'Failed to create collection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final collections = profileController.collections;
    final isLoading = profileController.isLoading && collections.isEmpty;

    return Dialog(
      backgroundColor: context.scaffoldBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Save to Collection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                      fontFamily: FontFamily.openSans,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: context.textColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isCreating) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.dividerColor),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Collection Name',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true,
                          fillColor: context.surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.dividerColor),
                          ),
                        ),
                        style: TextStyle(color: context.textColor),
                        autofocus: true,
                        onSubmitted: (_) => _handleCreateCollection(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isCreating = false;
                                _nameController.clear();
                              });
                            },
                            child: Text('Cancel',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed:
                                _isSaving ? null : _handleCreateCollection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: context.onPrimaryColor,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text('Create'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isCreating = true;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Collection'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: context.dividerColor),
                    foregroundColor: context.textColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: context.primaryColor))
                    : collections.isEmpty
                        ? Center(
                            child: Text(
                              'No collections found.',
                              style: TextStyle(
                                  color: context.subTextColor, fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            itemCount: collections.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final collection = collections[index];
                              return InkWell(
                                onTap: () async {
                                  final response = await context
                                      .read<ProfileController>()
                                      .addUserToCollection(
                                          collection.id, widget.userId);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    if (response.success) {
                                      ToastService.showSuccessToast(context,
                                          'User saved to ${collection.name}');
                                    } else {
                                      ToastService.showErrorToast(context,
                                          response.message ?? 'Failed to save');
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.surfaceColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: context.dividerColor
                                            .withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.folder,
                                          color: context.primaryColor,
                                          size: 24),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          collection.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: context.textColor,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.add,
                                          color: context.textColor, size: 20),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
