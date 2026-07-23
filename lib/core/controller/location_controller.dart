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
  int _updateTimestamp = 0;

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
      if (cached['radius'] != null && cached['radius']!.isNotEmpty) {
        _radius = double.tryParse(cached['radius']!) ?? 10.0;
      } else if (_address != null && _address!.isNotEmpty) {
        final savedRad = LocalLocationService.getAddressRadius(_address!.trim());
        if (savedRad != null && savedRad > 0) {
          _radius = savedRad;
        } else {
          _radius = 10.0;
        }
      } else {
        _radius = 10.0;
      }
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
  int get updateTimestamp => _updateTimestamp;

  String get headerBoldPrefix {
    final lbl = (_label ?? "LOCATION").toUpperCase();
    if (lbl == 'OTHER' && _address != null && _address!.contains(' - ')) {
      final idx = _address!.indexOf(' - ');
      final customLabel = _address!.substring(0, idx).trim();
      if (customLabel.isNotEmpty) {
        return 'OTHER - $customLabel - ';
      }
    }
    return '$lbl - ';
  }

  String get headerBoldTitle {
    final lbl = (_label ?? "LOCATION").toUpperCase();
    if (lbl == 'OTHER' && _address != null && _address!.contains(' - ')) {
      final idx = _address!.indexOf(' - ');
      final customLabel = _address!.substring(0, idx).trim();
      if (customLabel.isNotEmpty) {
        return 'OTHER - $customLabel';
      }
    }
    return lbl;
  }

  String get headerAddressText {
    if (_address == null) return 'NA';
    final lbl = (_label ?? "LOCATION").toUpperCase();
    if (lbl == 'OTHER' && _address!.contains(' - ')) {
      final idx = _address!.indexOf(' - ');
      final customLabel = _address!.substring(0, idx).trim();
      if (customLabel.isNotEmpty) {
        return _address!.substring(idx + 3).trim();
      }
    }
    return _address!;
  }

  void _markUpdatedAndNotify() {
    _updateTimestamp = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  /// Initialize with default location values
  void _initializeWithDefaults() {
    _latitude = _defaultLatitude;
    _longitude = _defaultLongitude;
    _address = _defaultAddress;
    _city = _defaultCity;
    _label = _defaultLabel;
    _radius = 10.0;
    _persistCurrentLocation();
    _markUpdatedAndNotify();
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
        _radius = 10.0;
        _isLoading = false;
        _persistCurrentLocation();
        _markUpdatedAndNotify();

        // Extract city name
        if (_latitude != null && _longitude != null) {
          LocationService.getCityFromCoordinates(
            _latitude!,
            _longitude!,
          ).then((cityName) {
            if (cityName != null && cityName != _city) {
              _city = cityName;
              _persistCurrentLocation();
              notifyListeners();
            }
          });
        }

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
    _markUpdatedAndNotify();
  }

  /// Set location manually
  void setLocation(double lat, double lng, String address, {double? radius, String? label}) {
    _latitude = lat;
    _longitude = lng;
    _address = address;
    _label = label;
    if (radius != null && radius > 0) {
      _radius = radius;
      LocalLocationService.saveAddressRadius(address.trim(), radius);
    } else {
      final savedRad = LocalLocationService.getAddressRadius(address.trim());
      if (savedRad != null && savedRad > 0) {
        _radius = savedRad;
      } else {
        _radius = 10.0;
      }
    }
    _persistCurrentLocation();
    _markUpdatedAndNotify();

    // Try to get city from manual address or coordinates
    LocationService.getCityFromCoordinates(lat, lng).then((cityName) {
      if (cityName != null && cityName != _city) {
        _city = cityName;
        _persistCurrentLocation();
        notifyListeners();
      }
    });
  }

  /// Update radius
  void setRadius(double radius) {
    _radius = radius;
    if (_address != null && _address!.isNotEmpty) {
      LocalLocationService.saveAddressRadius(_address!.trim(), radius);
    }
    _persistCurrentLocation();
    _markUpdatedAndNotify();
  }

  void _persistCurrentLocation() {
    LocalLocationService.saveLastSelectedLocation({
      'lat': _latitude.toString(),
      'lng': _longitude.toString(),
      'address': _address ?? '',
      'city': _city ?? '',
      'label': _label ?? 'LOCATION',
      'radius': _radius.toString(),
    });
  }

  /// Update location from user data (API response)
  Future<void> updateFromUserData({
    required String? lat,
    required String? lng,
    required String? address,
  }) async {
    try {
      double? parsedLat = lat != null ? double.tryParse(lat) : null;
      double? parsedLng = lng != null ? double.tryParse(lng) : null;

      // If coordinates are missing, invalid, or 0.0, but we have a valid address, geocode it!
      if ((parsedLat == null || parsedLng == null || (parsedLat == 0.0 && parsedLng == 0.0)) &&
          address != null &&
          address.isNotEmpty &&
          address != 'Location unavailable') {
        final coords = await LocationService.getCoordinatesFromAddress(address);
        if (coords != null) {
          parsedLat = coords['latitude'];
          parsedLng = coords['longitude'];
          debugPrint('[LocationController] Geocoded address "$address" -> $parsedLat, $parsedLng');
        }
      }

      _latitude = parsedLat;
      _longitude = parsedLng;
      _address = address;
      _label = 'HOME';
      if (address != null && address.isNotEmpty) {
        final savedRad = LocalLocationService.getAddressRadius(address.trim());
        if (savedRad != null && savedRad > 0) {
          _radius = savedRad;
        } else {
          _radius = 10.0;
        }
      } else {
        _radius = 10.0;
      }
      _persistCurrentLocation();
      _markUpdatedAndNotify();

      // Also try to get city if coordinates are valid
      if (_latitude != null && _longitude != null) {
        LocationService.getCityFromCoordinates(
          _latitude!,
          _longitude!,
        ).then((cityName) {
          if (cityName != null && cityName != _city) {
            _city = cityName;
            _persistCurrentLocation();
            notifyListeners();
          }
        });
      }
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
      double? savedRadius = addressModel.radius;
      if (addressModel.id != null) {
        double? idRad = LocalLocationService.getAddressRadius(addressModel.id!.toString());
        if (savedRadius == null && idRad != null) {
          savedRadius = idRad;
        } else if (savedRadius == null && idRad == null) {
          LocalLocationService.removeAddressRadius(addressModel.address.trim());
        }
      } else {
        savedRadius = savedRadius ?? LocalLocationService.getAddressRadius(addressModel.address.trim());
      }
      if (savedRadius != null && savedRadius > 0) {
        _radius = savedRadius;
      } else {
        _radius = 10.0;
      }
      _persistCurrentLocation();
      _markUpdatedAndNotify();

      // Also try to get city if coordinates are valid
      if (_latitude != null && _longitude != null) {
        LocationService.getCityFromCoordinates(
          _latitude!,
          _longitude!,
        ).then((cityName) {
          if (cityName != null && cityName != _city) {
            _city = cityName;
            _persistCurrentLocation();
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating location from address model: $e');
    }
  }

  /// Handle deletion of an address model; if it was currently active, switch to a fallback
  Future<void> handleAddressDeleted({
    required AddressModel deletedAddr,
    required List<AddressModel> remainingAddresses,
    required dynamic userProfile,
  }) async {
    final bool wasSelected = (_address != null && _address!.trim().toLowerCase() == deletedAddr.address.trim().toLowerCase()) ||
        (_address != null && (_address!.trim().toLowerCase().contains(deletedAddr.address.trim().toLowerCase()) || deletedAddr.address.trim().toLowerCase().contains(_address!.trim().toLowerCase()))) ||
        (_latitude != null && _longitude != null && (_latitude! - deletedAddr.latitude).abs() < 0.0001 && (_longitude! - deletedAddr.longitude).abs() < 0.0001);
    if (!wasSelected) {
      return;
    }
    debugPrint('[LocationController] Active address "${deletedAddr.address}" deleted. Switching to fallback...');
    if (remainingAddresses.isNotEmpty) {
      final fallback = remainingAddresses.firstWhere(
        (a) => a.isDefault == 1,
        orElse: () => remainingAddresses.first,
      );
      await updateFromAddressModel(fallback);
    } else if (userProfile != null && userProfile.location != null && userProfile.location!.toString().isNotEmpty && userProfile.location != deletedAddr.address) {
      await updateFromUserData(
        lat: userProfile.latitude?.toString(),
        lng: userProfile.longitude?.toString(),
        address: userProfile.location,
      );
    } else {
      await fetchLocation();
    }
  }
}
