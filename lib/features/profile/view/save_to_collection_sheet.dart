import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';
import 'package:tool_bocs/core/services/toast_service.dart';

class SaveToCollectionBottomSheet extends StatefulWidget {
  final int userId;

  const SaveToCollectionBottomSheet({super.key, required this.userId});

  static Future<void> show(BuildContext context, int userId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SaveToCollectionBottomSheet(userId: userId),
    );
  }

  @override
  State<SaveToCollectionBottomSheet> createState() => _SaveToCollectionBottomSheetState();
}

class _SaveToCollectionBottomSheetState extends State<SaveToCollectionBottomSheet> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().getCollections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final collections = profileController.collections;
    final isLoading = profileController.isLoading && collections.isEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Save to Collection',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
              fontFamily: FontFamily.openSans,
            ),
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: context.primaryColor))
                : collections.isEmpty
                    ? Center(
                        child: Text(
                          'No collections found.',
                          style: TextStyle(color: context.subTextColor),
                        ),
                      )
                    : ListView.separated(
                        itemCount: collections.length,
                        separatorBuilder: (context, index) => SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final collection = collections[index];
                          return InkWell(
                            onTap: () async {
                              if (_isSaving) return;
                              if (mounted) setState(() => _isSaving = true);
                              final response = await context
                                  .read<ProfileController>()
                                  .addUserToCollection(collection.id, widget.userId);
                              if (context.mounted) {
                                Navigator.pop(context);
                                if (response.success) {
                                  ToastService.showSuccessToast(context, 'User saved to ${collection.name}');
                                } else {
                                  ToastService.showErrorToast(context, response.message ?? 'Failed to save');
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: context.dividerColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.folder, color: context.primaryColor),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Text(
                                      collection.name,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: context.textColor,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.add, color: context.textColor),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SizedBox(height: 20.h),
          InkWell(
            onTap: () {
              _showCreateFolderDialog(context);
            },
            borderRadius: BorderRadius.circular(50.r),
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                size: 32.sp,
                color: context.textColor,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            AppLocalizations.of(context)!.createNewFolder,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: context.textColor,
              fontFamily: FontFamily.openSans,
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          title: Text(
            AppLocalizations.of(context)!.createNewFolder,
            style: TextStyle(color: context.textColor, fontFamily: FontFamily.openSans),
          ),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: context.textColor),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.folderName,
              hintStyle: TextStyle(color: context.textColor.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.dividerColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.primaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: context.textColor)),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  final res = await context.read<ProfileController>().createCollection(nameController.text.trim());
                  if (res.success) {
                    if (context.mounted) ToastService.showSuccessToast(context, AppLocalizations.of(context)!.collectionCreatedSuccessfully);
                  } else {
                    if (context.mounted) ToastService.showErrorToast(context, res.message ?? AppLocalizations.of(context)!.failedToCreateCollection);
                  }
                }
              },
              child: Text(AppLocalizations.of(context)!.create, style: TextStyle(color: context.primaryColor)),
            ),
          ],
        );
      },
    );
  }
}
