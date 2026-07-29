import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/api/api_response.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';

class UserReviewDialog extends StatefulWidget {
  final int userId;
  final String userName;

  const UserReviewDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserReviewDialog> createState() => _UserReviewDialogState();
}

class _UserReviewDialogState extends State<UserReviewDialog> {
  int? _selectedFeedbackIndex;
  final TextEditingController _reviewController = TextEditingController();

  final List<Map<String, dynamic>> _feedbackOptions = [
    {'icon': Icons.check_circle, 'color': Colors.green, 'label': 'Friendly'},
    {'icon': Icons.check_circle, 'color': Colors.green, 'label': 'Professional'},
    {'icon': Icons.cancel, 'color': Colors.red, 'label': 'Smooth'},
    {'icon': Icons.cancel, 'color': Colors.red, 'label': 'Unpleasant'},
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      elevation: 0,
      backgroundColor: context.surfaceColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 24.0, color: context.textColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'Mark This Person?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                    fontFamily: FontFamily.openSans,
                  ),
                ),
                const SizedBox(height: 24.0),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: context.dividerColor),
                    color: context.surfaceColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.userName} was',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: context.textColor,
                          fontFamily: FontFamily.openSans,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: List.generate(_feedbackOptions.length, (index) {
                          final option = _feedbackOptions[index];
                          final isSelected = _selectedFeedbackIndex == index;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFeedbackIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(30.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.primaryColor.withOpacity(0.08)
                                    : context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.blue.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(30.0),
                                border: Border.all(
                                  color: isSelected
                                      ? context.primaryColor
                                      : context.dividerColor,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    option['icon'] as IconData,
                                    color: option['color'] as Color,
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    option['label']!,
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? context.primaryColor
                                          : context.textColor,
                                      fontFamily: FontFamily.openSans,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        'Review',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: context.textColor,
                          fontFamily: FontFamily.openSans,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          'required*',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: context.isDarkMode ? Colors.black : Colors.white,
                            fontFamily: FontFamily.openSans,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Share details about your\nexperience',
                    hintStyle: TextStyle(
                      fontSize: 14.0,
                      color: context.subTextColor,
                      fontFamily: FontFamily.openSans,
                    ),
                    filled: true,
                    fillColor: context.isDarkMode ? Colors.white10 : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: context.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
                SizedBox(
                  width: double.infinity,
                  height: 52.0,
                  child: Consumer<ProfileController>(
                    builder: (context, controller, child) {
                      return ElevatedButton(
                        onPressed: controller.isLoading
                            ? null
                            : () async {
                                if (_selectedFeedbackIndex == null) {
                                  ToastService.showErrorToast(
                                      context, 'Please select a label');
                                  return;
                                }

                                if (_reviewController.text.trim().isEmpty) {
                                  ToastService.showErrorToast(
                                      context, 'Please enter a review');
                                  return;
                                }

                                final ApiResponse<dynamic> response =
                                    await controller.submitReview(
                                  userId: widget.userId,
                                  label: _feedbackOptions[_selectedFeedbackIndex!]
                                      ['label']!,
                                  comment: _reviewController.text,
                                );

                                if (response.success) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ToastService.showSuccessToast(
                                        context, response.message);
                                  }
                                } else {
                                  if (context.mounted) {
                                    ToastService.showErrorToast(
                                        context, response.message);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isLoading
                            ? SizedBox(
                                height: 24.0,
                                width: 24.0,
                                child: CircularProgressIndicator(
                                  color: context.onPrimaryColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: FontFamily.openSans,
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
      ),
    );
  }
}
