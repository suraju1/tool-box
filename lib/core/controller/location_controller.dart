import 'package:flutter/material.dart';
import 'package:tool_bocs/core/services/location_service.dart';
import 'package:tool_bocs/core/services/local_location_service.dart';
import 'package:tool_bocs/features/address/model/address_model.dart';

/// Controller for managing location state
class LocationController extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  String? _address;
  String? _city;
  String? _label;
  bool _isLoading = false;
  String? _errorMessage;
  double _radius = 5.0; // Default 5km

  // Default location (Pune, India)
  static const double _defaultLatitude = 18.5204;
  static const double _defaultLongitude = 73.8567;
  static const String _defaultAddress = "Pune, Maharashtra, India";
  static const String _defaultCity = "Pune";
  static const String _defaultLabel = "LOCATION";

  LocationController() {
    _loadFromCache();
  }

  void _loadFromCache() {
    final cached = LocalLocationService.loadLastSelectedLocation();
    if (cached != null && cached['lat'] != null && cached['lng'] != null) {
      _latitude = double.tryParse(cached['lat']!);
      _longitude = double.tryParse(cached['lng']!);
      _address = cached['address'];
      _city = cached['city'];
      _label = cached['label'];
    }
  }

  // Getters
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get address => _address;
  String? get city => _city;
  String? get label => _label ?? "LOCATION";
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get radius => _radius;
  bool get hasLocation => _latitude != null && _longitude != null;

  /// Initialize with default location values
  void _initializeWithDefaults() {
    _latitude = _defaultLatitude;
    _longitude = _defaultLongitude;
    _address = _defaultAddress;
    _city = _defaultCity;
    _label = _defaultLabel;
    _persistCurrentLocation();
    notifyListeners();
  }

  /// Fetch current location with address
  Future<bool> fetchLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await LocationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled. Falling back to defaults.');
        _initializeWithDefaults();
        _isLoading = false;
        notifyListeners();
        return true; // Return true as we have a valid (default) location now
      }

      // 2. Check/Request permissions
      bool hasPermission = await LocationService.checkPermission();
      if (!hasPermission) {
        hasPermission = await LocationService.requestPermission();
        if (!hasPermission) {
          debugPrint(
              'Location permissions are denied. Falling back to defaults.');
          _initializeWithDefaults();
          _isLoading = false;
          notifyListeners();
          return true; // Return true as we have a valid (default) location now
        }
      }

      // 3. Fetch location
      final locationData = await LocationService.getLocationWithAddress();

      if (locationData != null) {
        _latitude = locationData['latitude'];
        _longitude = locationData['longitude'];
        _address = locationData['address'];

        // Extract city name
        if (_latitude != null && _longitude != null) {
          _city = await LocationService.getCityFromCoordinates(
            _latitude!,
            _longitude!,
          );

          // Save to Hive
          _persistCurrentLocation();
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Unable to get location. Falling back to defaults.');
        _initializeWithDefaults();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetching location: $e. Falling back to defaults.');
      _initializeWithDefaults();
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  /// Update location (refresh)
  Future<bool> updateLocation() async {
    return await fetchLocation();
  }

  /// Clear location data
  void clearLocation() {
    _latitude = null;
    _longitude = null;
    _address = null;
    _city = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set location manually
  void setLocation(double lat, double lng, String address, {double? radius, String? label}) {
    _latitude = lat;
    _longitude = lng;
    _address = address;
    _label = label;
    if (radius != null) {
      _radius = radius;
    }

    // Try to get city from manual address or coordinates
    LocationService.getCityFromCoordinates(lat, lng).then((cityName) {
      _city = cityName;
      _persistCurrentLocation();
      notifyListeners();
    });

    _persistCurrentLocation();
    notifyListeners();
  }

  /// Update radius
  void setRadius(double radius) {
    _radius = radius;
    notifyListeners();
  }

  void _persistCurrentLocation() {
    LocalLocationService.saveLastSelectedLocation({
      'lat': _latitude.toString(),
      'lng': _longitude.toString(),
      'address': _address ?? '',
      'city': _city ?? '',
      'label': _label ?? 'LOCATION',
    });
  }

  /// Update location from user data (API response)
  Future<void> updateFromUserData({
    required String? lat,
    required String? lng,
    required String? address,
  }) async {
    if (lat == null || lng == null) return;

    try {
      _latitude = double.tryParse(lat);
      _longitude = double.tryParse(lng);
      _address = address;
      _label = 'HOME';

      // Also try to get city if coordinates are valid
      if (_latitude != null && _longitude != null) {
        _city = await LocationService.getCityFromCoordinates(
          _latitude!,
          _longitude!,
        );
        _persistCurrentLocation();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating location from user data: $e');
    }
  }

  /// Update location from AddressModel (API response)
  Future<void> updateFromAddressModel(AddressModel addressModel) async {
    try {
      _latitude = addressModel.latitude;
      _longitude = addressModel.longitude;
      _address = addressModel.address;
      _label = addressModel.label;

      // Also try to get city if coordinates are valid
      if (_latitude != null && _longitude != null) {
        _city = await LocationService.getCityFromCoordinates(
          _latitude!,
          _longitude!,
        );
        _persistCurrentLocation();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating location from address model: $e');
    }
  }
}
