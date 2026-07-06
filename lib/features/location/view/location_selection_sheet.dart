import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/core/services/toast_service.dart';

import 'package:tool_bocs/features/location/view/map_address_picker_screen.dart';
import 'package:tool_bocs/features/address/controller/address_controller.dart';
import 'package:tool_bocs/features/address/model/address_model.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/login_and_signup/model/user_model.dart';

class LocationSelectionSheet extends StatefulWidget {
  final bool isPickOnly;
  final double? initialRadius;
  const LocationSelectionSheet({super.key, this.isPickOnly = false, this.initialRadius});

  static Future<void> show(BuildContext context, {bool isPickOnly = false, double? initialRadius}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectionSheet(isPickOnly: isPickOnly, initialRadius: initialRadius),
    );
  }

  @override
  State<LocationSelectionSheet> createState() => _LocationSelectionSheetState();
}

class _LocationSelectionSheetState extends State<LocationSelectionSheet> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressController>().fetchAddresses();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.onPrimaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: [
                _buildUseCurrentLocation(context),
                _buildDivider(),
                _buildOptionItem(
                  icon: Icons.add,
                  title: AppLocalizations.of(context)!.addNewAddress,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapAddressPickerScreen(
                          isPickOnly: false, // Always allow saving new address
                          initialRadius: widget.initialRadius,
                        ),
                      ),
                    );
                  },
                ),

                // _buildOptionItem(
                //   image:
                //       'assets/icons/zomato.png', // Fallback to icon if image missing
                //   title: 'Import your addresses from Zomato',
                //   onTap: () {},
                // ),
                SizedBox(height: 20.h),
                if (context.watch<AddressController>().addresses.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!.savedAddresses,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  ...context
                      .watch<AddressController>()
                      .addresses
                      .map((addr) => _buildSavedAddressItem(addr)),
                ] else if (context.watch<AuthController>().currentUser?.location != null &&
                    context.watch<AuthController>().currentUser!.location.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!.profileAddress,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildProfileAddressItem(
                      context.watch<AuthController>().currentUser!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: 10.h, bottom: 20.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.selectDeliveryLocation,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, size: 24.sp),
          ),
        ],
      ),
    );
  }



  Widget _buildUseCurrentLocation(BuildContext context) {
    final locationController = context.watch<LocationController>();
    return InkWell(
      onTap: () async {
        final success =
            await context.read<LocationController>().fetchLocation();
        if (success && mounted) {
          ToastService.showSuccessToast(
              context, 'Location updated successfully');
          Navigator.pop(context);
        } else if (mounted) {
          ToastService.showErrorToast(context,
              locationController.errorMessage ?? 'Failed to fetch location');
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(Icons.my_location, color: context.primaryColor, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.useCurrentLocation,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                  Text(
                    locationController.address ??
                        AppLocalizations.of(context)!.enableGpsForAccurateLocation,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    IconData? icon,
    String? image,
    required String title,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 15.h),
            child: Row(
              children: [
                if (icon != null)
                  Icon(icon, color: iconColor ?? context.primaryColor, size: 24.sp)
                else if (image != null)
                  Image.asset(image,
                      width: 24.w,
                      height: 24.h,
                      errorBuilder: (c, e, s) => Icon(Icons.location_city,
                          color: Colors.red, size: 24.sp)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey, size: 20.sp),
              ],
            ),
          ),
          _buildDivider(),
        ],
      ),
    );
  }

  String _getDisplayLabel(AddressModel addr) {
    if (addr.label.toLowerCase() == 'other') {
      if (addr.address.contains(' - ')) {
        final customLabel = addr.address.split(' - ').first.trim();
        if (customLabel.isNotEmpty) {
          // Capitalize first letter
          return customLabel[0].toUpperCase() + customLabel.substring(1);
        }
      }
      return 'Other';
    }
    if (addr.label.isEmpty) return 'Location';
    return addr.label[0].toUpperCase() + addr.label.substring(1).toLowerCase();
  }

  Widget _buildSavedAddressItem(AddressModel addr) {
    final locationController = context.watch<LocationController>();
    final isSelected = locationController.address == addr.address;

    return InkWell(
      onTap: () {
        context.read<LocationController>().updateFromAddressModel(addr);
        Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Icon(
                addr.label.toLowerCase() == 'home'
                    ? Icons.home_outlined
                    : addr.label.toLowerCase() == 'work'
                        ? Icons.work_outline
                        : Icons.location_on_outlined,
                color: Colors.grey,
                size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getDisplayLabel(addr),
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                      if (addr.isDefault == 1) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.defaultLabel,
                            style: TextStyle(
                                fontSize: 10.sp,
                                color: context.primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      if (isSelected) ...[
                        SizedBox(width: 8.w),
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    addr.address,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 20.sp, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MapAddressPickerScreen(editAddress: addr),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20.sp, color: Colors.red),
              onPressed: () => _handleDeleteAddress(addr),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeleteAddress(AddressModel addr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAddress),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWant1),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AddressController>().deleteAddress(addr.id!).then((response) {
                if (response.success) {
                  ToastService.showSuccessToast(context, 'Address deleted');
                } else {
                  ToastService.showErrorToast(context, response.message);
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAddressItem(UserModel user) {
    final locationController = context.watch<LocationController>();
    final isSelected = locationController.address == user.location;

    return InkWell(
      onTap: () {
        context.read<LocationController>().updateFromUserData(
              lat: user.latitude,
              lng: user.longitude,
              address: user.location,
            );
        Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Icon(Icons.person_pin_circle_outlined, color: Colors.grey, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Home (from Profile)',
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                      if (isSelected) ...[
                        SizedBox(width: 8.w),
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    user.location,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[200]);
  }
}
