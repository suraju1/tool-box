// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tool_bocs/core/api/api_client.dart';
import 'package:tool_bocs/core/services/storage_service.dart';
import 'package:tool_bocs/features/login_and_signup/controller/auth_controller.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/features/address/controller/address_controller.dart';
import 'package:tool_bocs/features/profile/controller/profile_controller.dart';
import 'package:tool_bocs/features/bottom_navigation_bar/controller/bottom_navbar_controller.dart';

class SplashController extends ChangeNotifier {
  // Decide navigation based on authentication state
  Future<void> decideNavigation(
    BuildContext context,
    AuthController authController,
  ) async {
    // Start minimum splash delay of 2 seconds (skip on web)
    final delayFuture = kIsWeb ? Future.value() : Future.delayed(const Duration(seconds: 2));

    // Request location permission / fetch location on first launch only if not already cached
    final locationController = context.read<LocationController>();
    if (!locationController.hasLocation || locationController.address == null) {
      locationController.fetchLocation().catchError((e) {
        debugPrint('Error fetching location on startup: $e');
        return true;
      });
    }

    // Show splash for minimum 2 seconds
    await delayFuture;

    // Check if user is logged in
    final isLoggedIn = await StorageService.isLoggedIn();

    if (isLoggedIn) {
      // Load saved auth data
      await authController.loadAuthData();

      // Check if auth data was loaded successfully
      if (authController.isAuthenticated) {
        // Load cached profile data synchronously (or await it quickly)
        final profileController = context.read<ProfileController>();
        await profileController.loadCachedProfile();

        // Set token in API client for future requests
        final token = await StorageService.getAuthToken();
        if (token != null) {
          ApiClient().setAuthToken(token);
        }

        // Fetch addresses from API and set default
        final addressController = context.read<AddressController>();
        await addressController.fetchAddresses();
        final defaultAddress = addressController.defaultAddress;
        final user = authController.currentUser;

        if (defaultAddress != null) {
          context
              .read<LocationController>()
              .updateFromAddressModel(defaultAddress);
        } else {
          // Sync location data if available in user profile as fallback
          if (user != null) {
            final profileController = context.read<ProfileController>();
            // Fetch latest profile to get current location
            await profileController.getUserProfile(user.id, isOwnProfile: true);

            final profileLocation =
                profileController.ownProfile?.userDetails.location;

            if (profileLocation != null && profileLocation.isNotEmpty) {
              context.read<LocationController>().updateFromUserData(
                    lat: user.latitude,
                    lng: user.longitude,
                    address: profileLocation,
                  );
            } else {
              context.read<LocationController>().updateFromUserData(
                    lat: user.latitude,
                    lng: user.longitude,
                    address: user.location,
                  );
            }
          }
        }

        // Check if profile is complete
        if (user != null && user.isProfileComplete == 1) {
          // Reset Bottom Navigation Bar state to Home
          context.read<BottomNavBarController>().reset();

          // Profile complete → Navigate to home
          Navigator.pushReplacementNamed(context, AppRoutes.bottomNavBar);
        } else {
          // Reset Bottom Navigation Bar state to Home
          context.read<BottomNavBarController>().reset();

          // Profile incomplete → Navigate to complete profile (could be signup or profile edit)
          // For now, navigate to home anyway since profile is completed during signup
          Navigator.pushReplacementNamed(context, AppRoutes.bottomNavBar);
        }
      } else {
        // Auth data couldn't be loaded → Navigate to onboarding
        Navigator.pushReplacementNamed(context, AppRoutes.onBoarding);
      }
    } else {
      // User not logged in → Navigate to onboarding
      Navigator.pushReplacementNamed(context, AppRoutes.onBoarding);
    }
  }
}
