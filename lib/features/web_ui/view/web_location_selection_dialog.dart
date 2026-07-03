import 'package:flutter/material.dart';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/core/services/toast_service.dart';

import 'package:tool_bocs/features/web_ui/view/web_map_address_picker_dialog.dart';
import 'package:tool_bocs/features/address/controller/address_controller.dart';
import 'package:tool_bocs/features/address/model/address_model.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/features/login_and_signup/model/user_model.dart';

class WebLocationSelectionDialog extends StatefulWidget {
  const WebLocationSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const WebLocationSelectionDialog(),
    );
  }

  @override
  State<WebLocationSelectionDialog> createState() =>
      _WebLocationSelectionDialogState();
}

class _WebLocationSelectionDialogState
    extends State<WebLocationSelectionDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressController>().fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: context.onPrimaryColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  _buildUseCurrentLocation(context),
                  _buildDivider(),
                  _buildOptionItem(
                    icon: Icons.add,
                    title: AppLocalizations.of(context)!.addNewAddress,
                    onTap: () {
                      Navigator.pop(context);
                      WebMapAddressPickerDialog.show(context);
                    },
                  ),
                  const SizedBox(height: 24),
                  if (context
                      .watch<AddressController>()
                      .addresses
                      .isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.savedAddresses,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...context
                        .watch<AddressController>()
                        .addresses
                        .map((addr) => _buildSavedAddressItem(addr)),
                  ] else if (context
                              .watch<AuthController>()
                              .currentUser
                              ?.location !=
                          null &&
                      context
                          .watch<AuthController>()
                          .currentUser!
                          .location
                          .isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.profileAddress,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildProfileAddressItem(
                        context.watch<AuthController>().currentUser!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 16, top: 20, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.selectDeliveryLocation,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 28),
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
        if (!context.mounted) return;
        if (success) {
          ToastService.showSuccessToast(
              context, 'Location updated successfully');
          Navigator.pop(context);
        } else {
          ToastService.showErrorToast(context,
              locationController.errorMessage ?? 'Failed to fetch location');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(Icons.my_location, color: context.primaryColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.useCurrentLocation,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locationController.address ??
                        'Enable GPS for accurate location',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                if (icon != null)
                  Icon(icon, color: iconColor ?? context.primaryColor, size: 28)
                else if (image != null)
                  Image.asset(image,
                      width: 28,
                      height: 28,
                      errorBuilder: (c, e, s) => const Icon(Icons.location_city,
                          color: Colors.red, size: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
                addr.label.toLowerCase() == 'home'
                    ? Icons.home_outlined
                    : addr.label.toLowerCase() == 'work'
                        ? Icons.work_outline
                        : Icons.location_on_outlined,
                color: Colors.grey,
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getDisplayLabel(addr),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (addr.isDefault == 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.defaultLabel,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    addr.address,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon:
                  const Icon(Icons.edit_outlined, size: 24, color: Colors.blue),
              onPressed: () {
                Navigator.pop(context);
                WebMapAddressPickerDialog.show(context, editAddress: addr);
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, size: 24, color: Colors.red),
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
            onPressed: () async {
              Navigator.pop(context);
              final response = await context
                  .read<AddressController>()
                  .deleteAddress(addr.id!);
              if (!context.mounted) return;
              if (response.success) {
                ToastService.showSuccessToast(context, 'Address deleted');
              } else {
                ToastService.showErrorToast(context, response.message);
              }
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.person_pin_circle_outlined,
                color: Colors.grey, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.homeFromProfile,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.location,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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
