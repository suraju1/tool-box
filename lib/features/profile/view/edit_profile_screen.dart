import 'dart:io';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/features/location/view/map_address_picker_screen.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/core/widgets/app_cached_image.dart';
import 'package:tool_bocs/core/widgets/app_success_dialog.dart';
import 'package:tool_bocs/core/widgets/app_image_picker_bs.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/util/font_family.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _bioController;
  late final TextEditingController _dobController;

  String? _selectedGender;
  DateTime? _selectedDate;
  bool _profileVisibility = true;
  bool _showTradeHistory = false;
  File? _selectedImage;
  bool _isInitialized = false;
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    final profileCtrl = context.read<ProfileController>();
    if (profileCtrl.ownProfile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        profileCtrl.getUserProfile(null, isOwnProfile: true);
      });
    }
    final profile = profileCtrl.ownProfile?.userDetails;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _locationController = TextEditingController(text: profile?.location ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _mobileController = TextEditingController(text: profile?.phoneNumber ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _dobController = TextEditingController(text: profile?.dateOfBirth ?? '');
    _profileVisibility = profile?.profileVisibility == 1;
    _showTradeHistory = profile?.showTradeHistory == 1;
    _selectedGender = profile?.gender;
    _selectedLatitude = _parseCoordinate(profile?.latitude);
    _selectedLongitude = _parseCoordinate(profile?.longitude);
    if (profile?.dateOfBirth != null && profile!.dateOfBirth!.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(profile.dateOfBirth!);
        _dobController.text = "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";
      } catch (e) {
        debugPrint('Error parsing DOB: $e');
        _dobController.text = profile.dateOfBirth!;
      }
    }
    _isInitialized = profile != null;

    // Special handling for bio character count display
    _bioController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _pickImage() async {
    final List<XFile>? images = await AppImagePickerBS.show(context);
    if (images != null && images.isNotEmpty) {
      if (kIsWeb) {
        // TODO (Phase 4): Handle web image uploading using bytes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.webImageUploadComingIn)),
        );
        return;
      }
      setState(() {
        _selectedImage = File(images.first.path);
      });
    }
  }

  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  void _updateLocationFromController() {
    final locationController = context.read<LocationController>();
    if (mounted) {
      if (locationController.address != null) {
        setState(() {
          _locationController.text = locationController.address!;
          _selectedLatitude = locationController.latitude;
          _selectedLongitude = locationController.longitude;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final profile = controller.ownProfile?.userDetails;

    // Reactive pre-filling if data arrives after initState
    if (profile != null && !_isInitialized) {
      _nameController.text = profile.fullName;
      _locationController.text = profile.location ?? '';
      _emailController.text = profile.email ?? '';
      _mobileController.text = profile.phoneNumber ?? '';
      _bioController.text = profile.bio ?? '';
      _dobController.text = profile.dateOfBirth ?? '';
      _profileVisibility = profile.profileVisibility == 1;
      _showTradeHistory = profile.showTradeHistory == 1;
      _selectedGender = profile.gender;
      _selectedLatitude = _parseCoordinate(profile.latitude);
      _selectedLongitude = _parseCoordinate(profile.longitude);
      if (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty) {
        try {
          _selectedDate = DateTime.parse(profile.dateOfBirth!);
          _dobController.text = "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";
        } catch (e) {
          _dobController.text = profile.dateOfBirth!;
        }
      }
      _isInitialized = true;
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileImage(),
                SizedBox(height: 15.h),
                _buildSectionTitle(AppLocalizations.of(context)!.personalInformation),
                SizedBox(height: 10.h),
                _buildTextField(AppLocalizations.of(context)!.fullName, _nameController),
                _buildTextField(AppLocalizations.of(context)!.locationLabel, _locationController,
                    icon: Icons.location_on_outlined,
                    readOnly: true, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MapAddressPickerScreen(isPickOnly: true),
                    ),
                  ).then((_) => _updateLocationFromController());
                }),
                _buildTextField(AppLocalizations.of(context)!.emailAddress, _emailController,
                    icon: Icons.email_outlined,
                    helperText: AppLocalizations.of(context)!.usedForNotifications),
                _buildTextField(AppLocalizations.of(context)!.mobileNumber, _mobileController,
                    icon: Icons.phone_android_outlined,
                    helperText: AppLocalizations.of(context)!.verifiedMobileNumber,
                    readOnly: true),
                _buildTextField(
                  AppLocalizations.of(context)!.dateOfBirth,
                  _dobController,
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ??
                          DateTime.now().subtract(const Duration(days: 6570)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                        _dobController.text =
                            "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                      });
                    }
                  },
                ),
                SizedBox(height: 10.h),
                _buildSectionTitle(AppLocalizations.of(context)!.gender),
                Row(
                  children: [
                    _buildGenderRadio('Male', AppLocalizations.of(context)!.male),
                    _buildGenderRadio('Female', AppLocalizations.of(context)!.female),
                    _buildGenderRadio('Other', AppLocalizations.of(context)!.other),
                  ],
                ),
                SizedBox(height: 10.h),
                _buildSectionTitle(AppLocalizations.of(context)!.bio),
                SizedBox(height: 10.h),
                Text(
                  AppLocalizations.of(context)!.tellOthersAboutYourself,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textColor,
                    fontFamily: FontFamily.openSans,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10.h),
                _buildBioField(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.w, top: 8.h),
                      child: Text(
                        '${_bioController.text.length}/150',
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: greyColor,
                            fontFamily: FontFamily.openSans),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                _buildSectionTitle(AppLocalizations.of(context)!.profileVisibility),
                _buildSwitchTile(
                    AppLocalizations.of(context)!.profileVisibility,
                    AppLocalizations.of(context)!.publicAnyoneCanView,
                    _profileVisibility,
                    (val) => setState(() => _profileVisibility = val)),
                // _buildSwitchTile(
                //     'Show Ratings',
                //     'Your ratings are visible to others.',
                //     _showRatings,
                //     (val) => setState(() => _showRatings = val)),
                _buildSwitchTile(
                    AppLocalizations.of(context)!.showTradeHistory,
                    AppLocalizations.of(context)!.tradeHistoryHidden,
                    _showTradeHistory,
                    (val) => setState(() => _showTradeHistory = val)),

                SizedBox(height: 50.h),
              ],
            ),
          ),
          _buildSaveButton(controller),
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
        icon: Icon(Icons.arrow_back_ios, color: context.textColor),
      ),
      centerTitle: true,
      title: Text(
        'Edit Profile',
        style: TextStyle(
          color: context.textColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          fontFamily: FontFamily.openSans,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(10),
        child: Divider(height: 1, color: context.dividerColor),
      ),
    );
  }

  Widget _buildProfileImage() {
    final user = context.watch<ProfileController>().ownProfile?.userDetails;
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.onPrimaryColor, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60.r),
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          width: 120.r,
                          height: 120.r,
                          fit: BoxFit.cover,
                        )
                      : AppCachedImage(
                          imageUrl: user!.image ?? '',
                          userName: user.fullName,
                          width: 120.r,
                          height: 120.r,
                          fit: BoxFit.cover,
                          radius: 60.r,
                        ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: context.isDarkMode
                                ? Colors.black54
                                : Colors.black12,
                            blurRadius: 4)
                      ],
                    ),
                    child: Icon(Icons.camera_alt,
                        color: context.textColor, size: 24.sp),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            AppLocalizations.of(context)!.tapToChangePhoto,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade500,
              fontFamily: FontFamily.openSans,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        fontFamily: FontFamily.openSans,
        color: context.textColor,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {IconData? icon,
      String? helperText,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 14.sp,
                color: greyColor,
                fontFamily: FontFamily.openSans),
          ),
          SizedBox(height: 4.h),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly
                  ? (context.isDarkMode ? Colors.white10 : Colors.grey.shade100)
                  : context.surfaceColor,
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.grey.shade500, size: 20.sp)
                  : null,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: context.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: context.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: context.primaryColor),
              ),
            ),
          ),
          if (helperText != null) ...[
            SizedBox(height: 4.h),
            Text(
              helperText,
              style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey.shade500,
                  fontFamily: FontFamily.openSans),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBioField() {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _bioController,
            maxLines: 4,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textColor,
              fontFamily: FontFamily.openSans,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(8.w),
              border: InputBorder.none,
              hintText: AppLocalizations.of(context)!.enterYourBio,
              hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: context.textColor.withOpacity(0.5),
                  fontFamily: FontFamily.openSans),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.only(top: 15.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                      fontFamily: FontFamily.openSans),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                      fontFamily: FontFamily.openSans),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }


  Widget _buildSaveButton(ProfileController controller) {
    return Positioned(
      bottom: 20.h,
      left: 20.w,
      right: 20.w,
      child: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: () async {
                final fullName = _nameController.text.trim();
                if (fullName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.fullNameIsRequired)),
                  );
                  return;
                }

                final response = await controller.updateProfile(
                  fullName: fullName,
                  location: _locationController.text.trim(),
                  email: _emailController.text.trim(),
                  mobile: _mobileController.text.trim(),
                  bio: _bioController.text.trim(),
                  profileVisibility: _profileVisibility ? 1 : 0,
                  showTradeHistory: _showTradeHistory ? 1 : 0,
                  gender: _selectedGender,
                  dateOfBirth: _selectedDate != null
                      ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
                      : null,
                  latitude: _selectedLatitude,
                  longitude: _selectedLongitude,
                  termsAccepted: true,
                  profileImage: _selectedImage,
                );

                if (context.mounted) {
                  if (response.success) {
                    AppSuccessDialog.show(
                      context,
                      message: response.message,
                      onButtonPressed: () {
                        Navigator.pop(context);
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(controller.errorMessage ?? AppLocalizations.of(context)!.updateFailed)));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                minimumSize: Size(double.infinity, 55.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
                elevation: 0,
                shadowColor: context.primaryColor,
              ),
              child: Text(
                AppLocalizations.of(context)!.saveChanges,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: context.onPrimaryColor,
                  fontFamily: FontFamily.openSans,
                ),
              ),
            ),
    );
  }

  Widget _buildGenderRadio(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedGender,
          activeColor: context.primaryColor,
          onChanged: (v) => setState(() => _selectedGender = v),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 14.sp,
              color: context.textColor,
              fontFamily: FontFamily.openSans),
        ),
      ],
    );
  }
}
