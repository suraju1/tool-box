import 'dart:async';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/core/services/location_service.dart';
import 'package:tool_bocs/core/services/local_location_service.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/address/controller/address_controller.dart';
import 'package:tool_bocs/features/address/model/address_model.dart';
import 'dart:math' as math;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

class MapAddressPickerScreen extends StatefulWidget {
  final bool isPickOnly;
  final AddressModel? editAddress;
  final double? initialRadius;
  const MapAddressPickerScreen(
      {super.key, this.isPickOnly = false, this.editAddress, this.initialRadius});

  @override
  State<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<MapAddressPickerScreen> with WidgetsBindingObserver {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng _lastMapPosition = const LatLng(18.5204, 73.8567); // Default Pune
  String _currentAddress = "Loading address...";
  bool _isReverseGeocoding = false;

  // Form controllers
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _mapSearchController = TextEditingController();
  final TextEditingController _customLabelController = TextEditingController();
  String _selectedLabel = 'Home';
  String _orderFor = 'Myself';
  double _radius = 5.0; // km
  String get formattedRadius {
    if (_radius < 1) {
      return '${(_radius * 1000).toStringAsFixed(1)} m';
    }

    return '${_radius.toStringAsFixed(1)} km';
  }

  double _currentZoom = 13.2; // default zoom for 5km

  // State management for multistep flow
  bool _showFullForm = false;
  bool _isMinimized = false;
  bool _isDefault = false;
  bool _isPanning = false;
  bool _isFetchingLocation = false;
  bool _isSaving = false;
  bool _isSystemLocationEnabled = true;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;

  // Autocomplete
  List<Map<String, String>> _autocompleteSuggestions = [];
  Timer? _debounce;
  String _sessionToken = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSystemLocation();
    
    // Listen for real-time location service status changes (e.g. from quick settings toggle)
    _serviceStatusStreamSubscription = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (mounted) {
        setState(() {
          _isSystemLocationEnabled = status == ServiceStatus.enabled;
        });
      }
    });

    if (widget.initialRadius != null) {
      _radius = widget.initialRadius!;
    }
    _currentZoom = _getZoomForRadius(_radius);
    _isDefault = widget.editAddress?.isDefault == 1;
    if (widget.editAddress != null) {
      _initEditAddress();
    } else {
      _initLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusStreamSubscription?.cancel();
    _debounce?.cancel();
    _houseController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _mapSearchController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSystemLocation();
    }
  }

  Future<void> _checkSystemLocation() async {
    bool serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (mounted) {
      setState(() {
        _isSystemLocationEnabled = serviceEnabled;
      });
    }
  }

  void _initEditAddress() {
    final addr = widget.editAddress!;
    _lastMapPosition = LatLng(addr.latitude, addr.longitude);
    
    String parsedAddress = addr.address;

    final validLabels = ['Home', 'Work', 'Office', 'Hotel', 'Other'];

    // Find matching label case-insensitively
    String? matchedLabel;
    for (var l in validLabels) {
      if (l.toLowerCase() == addr.label.toLowerCase()) {
        matchedLabel = l;
        break;
      }
    }

    if (matchedLabel != null && matchedLabel != 'Other') {
      _selectedLabel = matchedLabel;
    } else {
      _selectedLabel = 'Other';
      if (parsedAddress.contains(' - ')) {
        final idx = parsedAddress.indexOf(' - ');
        _customLabelController.text = parsedAddress.substring(0, idx).trim();
        parsedAddress = parsedAddress.substring(idx + 3).trim();
      }
    }

    _currentAddress = parsedAddress;
    _areaController.text = parsedAddress;

    double? savedRadius = addr.radius;
    if (addr.id != null) {
      savedRadius = savedRadius ?? LocalLocationService.getAddressRadius(addr.id!.toString());
    } else {
      savedRadius = savedRadius ?? LocalLocationService.getAddressRadius(addr.address.trim());
    }
    _radius = savedRadius ?? 10.0;
    _currentZoom = _getZoomForRadius(_radius);

    // Try to parse house/floor if they were saved in the address string
    // This is simple logic, might not be perfect depending on how it was saved
    final parts = parsedAddress.split(', ');
    if (parts.length >= 2) {
      _houseController.text = parts[0];
      if (parts.length >= 3) {
        _floorController.text = parts[1];
      }
    }

    _moveCamera(_lastMapPosition);
  }

  Future<void> _initLocation() async {
    final locationController = context.read<LocationController>();
    if (locationController.latitude != null &&
        locationController.longitude != null) {
      setState(() {
        _lastMapPosition =
            LatLng(locationController.latitude!, locationController.longitude!);
        _currentAddress = locationController.address ?? "";
        _areaController.text = _currentAddress;
        _radius = locationController.radius;
      });
      _updateCameraZoom(_radius);
    } else {
      setState(() {
        _radius = locationController.radius;
      });
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    bool serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
        bool? openSettings = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Enable Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text('Your system location services are disabled. Please enable them to fetch your current location.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.onPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Open Settings'),
                ),
              ],
            );
          },
        );
        if (openSettings == true) {
          await Geolocator.openLocationSettings();
        }
      }
      return;
    }
    bool hasPermission = await LocationService.checkPermission();
    if (!hasPermission) {
      hasPermission = await LocationService.requestPermission();
      if (!hasPermission) {
        if (mounted) {
          setState(() => _isFetchingLocation = false);
          bool? openSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  'Location Permission',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Text('Location permission is denied. Please enable it in app settings to fetch your current location.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: context.onPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Open Settings'),
                  ),
                ],
              );
            },
          );
          if (openSettings == true) {
            await Geolocator.openAppSettings();
          }
        }
        return;
      }
    }

    final success = await context.read<LocationController>().fetchLocation();
    if (success && mounted) {
      final loc = context.read<LocationController>();
      if (loc.latitude != null && loc.longitude != null) {
        _updateLocalLocation(LatLng(loc.latitude!, loc.longitude!), loc.address ?? "");
      }
    }
    if (mounted) setState(() => _isFetchingLocation = false);
  }

  void _updateLocalLocation(LatLng position, String address) {
    setState(() {
      _lastMapPosition = position;
      _currentAddress = address;
      _areaController.text = address;
    });
    _moveCamera(position);
  }

  Future<void> _moveCamera(LatLng position) async {
    _updateCameraZoom(_radius);
  }

  Future<void> _onCameraMove(CameraPosition position) async {
    _lastMapPosition = position.target;
    _currentZoom = position.zoom;
  }

  Future<void> _onCameraIdle() async {
    setState(() => _isPanning = false);
    if (_isReverseGeocoding) return;

    setState(() => _isReverseGeocoding = true);
    try {
      final address = await LocationService.getAddressFromCoordinates(
        _lastMapPosition.latitude,
        _lastMapPosition.longitude,
      );
      if (mounted) {
        setState(() {
          _currentAddress = address ?? "Unknown Address";
          _areaController.text = _currentAddress;
        });
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  String _getShortAddressName(String fullAddress) {
    if (fullAddress.isEmpty) return "Location";
    final parts = fullAddress.split(',');
    for (var part in parts) {
      final trimmed = part.trim();
      // Skip if it contains only numbers and special characters/spaces (like "1143")
      if (trimmed.isNotEmpty && !RegExp(r'^[\d\s\W]+$').hasMatch(trimmed)) {
        // Also skip short alphanumeric blocks that are likely house/flat numbers (e.g. "12A")
        if (trimmed.length <= 3 && RegExp(r'\d').hasMatch(trimmed)) {
          continue;
        }
        return trimmed;
      }
    }
    return parts.first.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 45.h,
        title: Text(AppLocalizations.of(context)!.addAddress,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _buildMap(),
          _buildMarkerOverlay(),
          _buildSearchOverlay(),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildUseCurrentLocationFloating(),
                  _buildRadiusSliderOverlay(),
                  _buildBottomForm(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSliderOverlay() {
    if (_showFullForm) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: context.onPrimaryColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode ? Colors.black45 : Colors.black12,
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Radius',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedRadius,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.h,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
              ),
              child: Slider(
                value: _radius,
                min: 0.01,
                max: 10.0,
                activeColor: context.primaryColor,
                inactiveColor: context.dividerColor,
                onChanged: (val) {
                  setState(() => _radius = val);
                  _updateCameraZoom(val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getZoomForRadius(double radius) {
    // Calculate zoom mathematically so the circle diameter is always around 220 pixels,
    // fitting perfectly without overlapping the bottom UI.
    double lat = _lastMapPosition.latitude;
    if (lat == 0.0) lat = 18.5204; // Fallback to Pune coordinates if 0
    
    double cosLat = math.cos(lat * math.pi / 180);
    double targetRadiusInPixels = 135.0; // Slightly larger diameter (270px)
    
    double term = (targetRadiusInPixels * 156543.03392 * cosLat) / (radius * 1000.0);
    double zoom = math.log(term) / math.ln2;
    
    return zoom.clamp(1.0, 20.0);
  }

  Future<void> _updateCameraZoom(double radius) async {
    final GoogleMapController controller = await _controller.future;

    final double zoom = _getZoomForRadius(radius);

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _lastMapPosition,
          zoom: zoom,
        ),
      ),
    );
  }

  Widget _buildMap() {
    // Calculate initial zoom based on radius
    double initialZoom = _getZoomForRadius(_radius);

    // Calculate center tick length in latitude degrees to maintain ~16px height
    final double metersPerPixel = 156543.03392 *
        math.cos(_lastMapPosition.latitude * math.pi / 180) /
        math.pow(2, _currentZoom);
    final double tickLatDelta = (16.0 * metersPerPixel) / 111132.0;

    return GoogleMap(
      initialCameraPosition:
          CameraPosition(target: _lastMapPosition, zoom: initialZoom),
      padding: EdgeInsets.only(
        top: 70.h,
        bottom: _showFullForm ? 0 : 350.h,
      ),
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
      onCameraMoveStarted: () {
        setState(() => _isPanning = true);
      },
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
      onTap: (LatLng location) async {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newLatLng(location),
        );
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      tiltGesturesEnabled: false,
    );
  }

  Widget _buildMarkerOverlay() {
    if (_showFullForm) return const SizedBox.shrink();

    // Smooth radius calculation
    final double metersPerPixel = 156543.03392 *
        math.cos(_lastMapPosition.latitude * math.pi / 180) /
        math.pow(2, _currentZoom);

    final double radiusInPixels =
        ((_radius * 1000) / metersPerPixel).clamp(0.0, 5000.0);

    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.only(top: 70.h, bottom: 350.h),
        child: Center(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Radius Circle
                Container(
                  width: radiusInPixels * 2,
                  height: radiusInPixels * 2,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                ),

                // Radius Line
                Transform.translate(
                  offset: Offset(radiusInPixels / 2, 0),
                  child: SizedBox(
                    width: radiusInPixels,
                    height: 16.h,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 3,
                          width: double.infinity,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),

                // Location Name Label (floating above the center)
                if (!_isPanning && _currentAddress.isNotEmpty)
                  Transform.translate(
                    offset: Offset(0, -35.h),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3))
                        ],
                      ),
                      child: Text(
                        _getShortAddressName(_currentAddress),
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                // Center Tick
                Container(
                  width: 4,
                  height: 16.h,
                  color: Colors.black,
                ),

                // Radius Text
                if (!_isPanning)
                  Transform.translate(
                    offset: Offset(radiusInPixels / 2, 18.h),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        formattedRadius,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        if (mounted) setState(() => _autocompleteSuggestions = []);
        return;
      }
      final suggestions = await LocationService.getAutocompleteSuggestions(query, sessionToken: _sessionToken);
      if (mounted) {
        setState(() {
          _autocompleteSuggestions = suggestions;
        });
      }
    });
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 10.h,
      left: 16.w,
      right: 16.w,
      child: Column(
        children: [
          Container(
            height: 50.h,
            decoration: BoxDecoration(
              color: context.onPrimaryColor,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                    color: context.isDarkMode ? Colors.black45 : Colors.black12,
                    blurRadius: 10)
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Icon(Icons.search, color: context.primaryColor),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: _mapSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search for area, locality...',
                      hintStyle:
                          TextStyle(color: context.subTextColor, fontSize: 14.sp),
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => _searchLocation(value),
                    onChanged: (val) {
                      setState(() {});
                      _onSearchChanged(val);
                    },
                  ),
                ),
                if (_mapSearchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _mapSearchController.clear();
                        _autocompleteSuggestions = [];
                      });
                    },
                  ),
              ],
            ),
          ),
          if (_autocompleteSuggestions.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 8.h),
              constraints: BoxConstraints(maxHeight: 250.h),
              decoration: BoxDecoration(
                color: context.onPrimaryColor,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                      color: context.isDarkMode ? Colors.black45 : Colors.black12,
                      blurRadius: 10)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _autocompleteSuggestions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = _autocompleteSuggestions[index];
                    return ListTile(
                      leading: Icon(Icons.location_on_outlined, color: context.primaryColor),
                      title: Text(
                        suggestion['description'] ?? '',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _mapSearchController.text = suggestion['description'] ?? '';
                          _autocompleteSuggestions = [];
                        });
                        _searchLocation(suggestion['description'] ?? '');
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isReverseGeocoding = true;
      _autocompleteSuggestions = []; // Hide suggestions when searching
    });
    // Reset session token for the next search
    _sessionToken = const Uuid().v4();
    try {
      List<geo.Location> locations = await geo.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final position = LatLng(loc.latitude, loc.longitude);

        // Get proper address from coordinates
        final address = await LocationService.getAddressFromCoordinates(
          loc.latitude,
          loc.longitude,
        );

        if (mounted) {
          _updateLocalLocation(position, address ?? query);
        }
      } else {
        if (mounted) ToastService.showErrorToast(context, 'Location not found');
      }
    } catch (e) {
      if (mounted) ToastService.showErrorToast(context, 'Location not found');
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  Widget _buildUseCurrentLocationFloating() {
    if (_showFullForm) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(right: 16.w, bottom: 15.h),
      child: InkWell(
        onTap: _getCurrentLocation,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: context.onPrimaryColor,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: context.primaryColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: context.isDarkMode ? Colors.black45 : Colors.black12,
                  blurRadius: 4)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isFetchingLocation
                  ? SizedBox(
                      width: 20.sp,
                      height: 20.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.primaryColor,
                      ),
                    )
                  : Icon(
                      _isSystemLocationEnabled ? Icons.my_location : Icons.location_disabled,
                      color: _isSystemLocationEnabled ? context.primaryColor : Colors.red, 
                      size: 20.sp,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomForm() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 5) {
          if (!_isMinimized && !_showFullForm)
            setState(() => _isMinimized = true);
        } else if (details.primaryDelta! < -5) {
          if (_isMinimized && !_showFullForm)
            setState(() => _isMinimized = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        decoration: BoxDecoration(
          color: context.onPrimaryColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode ? Colors.black45 : Colors.black12,
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab Handle
            Center(
              child: Container(
                width: 40.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            _showFullForm
                ? _buildDetailedAddressForm()
                : _buildConfirmationView(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.findingProductsIn,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: context.onPrimaryColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.dividerColor),
            boxShadow: [BoxShadow(color: context.dividerColor, blurRadius: 5)],
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: context.primaryColor, size: 28.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getShortAddressName(_currentAddress),
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _currentAddress,
                      style: TextStyle(
                          fontSize: 12.sp, color: context.subTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topCenter,
          child: _isMinimized
              ? const SizedBox.shrink()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12.h),
                    Text(AppLocalizations.of(context)!.saveAddressAs,
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8.h),
                    _buildLabelSelector(),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      height: 46.h,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : (widget.isPickOnly
                                ? _onConfirmLocation
                                : _onDirectSave),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isSaving
                                ? SizedBox(
                                    width: 20.sp,
                                    height: 20.sp,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.onPrimaryColor,
                                    ),
                                  )
                                : Text(
                                    widget.isPickOnly
                                        ? 'Confirm Location'
                                        : 'Save Location',
                                    style: TextStyle(
                                        color: context.onPrimaryColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
        ),
      ],
    );
  }

  void _onConfirmLocation() {
    context.read<LocationController>().setLocation(
          _lastMapPosition.latitude,
          _lastMapPosition.longitude,
          _currentAddress,
          radius: _radius,
        );
    Navigator.pop(context);
  }

  void _onDirectSave() {
    if (_selectedLabel == 'Other' &&
        _customLabelController.text.trim().isEmpty) {
      ToastService.showErrorToast(context, 'Please enter a custom label');
      return;
    }

    final addressController = context.read<AddressController>();
    String customLabelStr = _selectedLabel == 'Other' && _customLabelController.text.trim().isNotEmpty
        ? "${_customLabelController.text.trim()} - "
        : "";
    String finalLabel = _selectedLabel.toLowerCase();
    String finalAddress = "$customLabelStr$_currentAddress";

    if (widget.editAddress != null) {
      final updatedAddress = AddressModel(
        id: widget.editAddress!.id,
        label: finalLabel,
        address: finalAddress,
        latitude: _lastMapPosition.latitude,
        longitude: _lastMapPosition.longitude,
        isDefault: 1,
        radius: _radius,
      );

      setState(() => _isSaving = true);
      addressController
          .updateAddress(updatedAddress.id!, updatedAddress)
          .then((response) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        if (response.success) {
          context.read<LocationController>().setLocation(
                _lastMapPosition.latitude,
                _lastMapPosition.longitude,
                finalAddress,
                radius: _radius,
                label: finalLabel,
              );
          ToastService.showSuccessToast(
              context, 'Address updated successfully');
          Navigator.pop(context);
        } else {
          ToastService.showErrorToast(context, response.message);
        }
      });
    } else {
      final newAddress = AddressModel(
        label: finalLabel,
        address: finalAddress,
        latitude: _lastMapPosition.latitude,
        longitude: _lastMapPosition.longitude,
        isDefault: addressController.addresses.isEmpty ? 1 : 0,
        radius: _radius,
      );

      setState(() => _isSaving = true);
      addressController.saveAddress(newAddress).then((response) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        if (response.success) {
          context.read<LocationController>().setLocation(
                _lastMapPosition.latitude,
                _lastMapPosition.longitude,
                finalAddress,
                radius: _radius,
                label: finalLabel,
              );
          ToastService.showSuccessToast(context, 'Address saved successfully');
          Navigator.pop(context);
        } else {
          ToastService.showErrorToast(context, response.message);
        }
      });
    }
  }

  Widget _buildDetailedAddressForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.enterCompleteAddress,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => setState(() => _showFullForm = false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        SizedBox(height: 15.h),
        _buildSwitchOption(),
        SizedBox(height: 10.h),
        Text(AppLocalizations.of(context)!.saveAddressAs1,
            style: TextStyle(fontSize: 14.sp, color: context.subTextColor)),
        SizedBox(height: 10.h),
        _buildLabelSelector(),
        SizedBox(height: 20.h),
        _buildTextField('Flat / House no / Building name *', _houseController),
        _buildTextField('Floor (optional)', _floorController),
        _buildLocationDetails(),
        SizedBox(height: 10.h),
        _buildDefaultToggle(),
        SizedBox(height: 10.h),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildDefaultToggle() {
    return SwitchListTile(
      title: Text(AppLocalizations.of(context)!.setAsDefaultAddress, style: TextStyle(fontSize: 14.sp)),
      value: _isDefault,
      activeColor: context.primaryColor,
      onChanged: (val) => setState(() => _isDefault = val),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSwitchOption() {
    return SizedBox(
      height: 80.h,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context)!.whoYouAreSearchingFor,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          const Spacer(),
          Row(
            spacing: 10.w,
            children: [
              _buildRadio('Myself'),
              _buildRadio('Someone else'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadio(String label) {
    return InkWell(
      onTap: () => setState(() => _orderFor = label),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: label,
            groupValue: _orderFor,
            activeColor: context.primaryColor,
            onChanged: (v) => setState(() => _orderFor = v!),
          ),
          Text(label, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildLabelSelector() {
    final labels = ['Home', 'Work', 'Hotel', 'Other'];
    final icons = [
      Icons.home_outlined,
      Icons.work_outline,
      Icons.hotel_outlined,
      Icons.location_on_outlined
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(labels.length, (index) {
              final isSelected = _selectedLabel == labels[index];
              return Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedLabel = labels[index];
                      if (_selectedLabel != 'Other') {
                        _customLabelController.clear();
                      }
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primaryColor.withOpacity(0.1)
                          : context.surfaceColor,
                      border: Border.all(
                          color: isSelected
                              ? context.primaryColor
                              : context.dividerColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(icons[index],
                            color: isSelected ? context.primaryColor : Colors.grey,
                            size: 16.sp),
                        SizedBox(width: 4.w),
                        Text(labels[index],
                            style: TextStyle(
                                fontSize: 12.sp,
                                color: isSelected
                                    ? context.primaryColor
                                    : context.textColor)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (_selectedLabel == 'Other')
          Padding(
            padding: EdgeInsets.only(top: 15.h),
            child: _buildTextField('Custom label (e.g. Gym, Cafe)', _customLabelController),
          ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12.sp, color: context.subTextColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildLocationDetails() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white10
            : context.dividerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.areaSectorLocality,
                    style: TextStyle(
                        fontSize: 10.sp, color: context.subTextColor)),
                Text(
                  _currentAddress,
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {}, // Trigger search
            child:
                Text(AppLocalizations.of(context)!.change, style: TextStyle(color: context.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
        child: _isSaving
            ? SizedBox(
                width: 20.sp,
                height: 20.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.onPrimaryColor,
                ),
              )
            : Text(AppLocalizations.of(context)!.saveAddress,
                style: TextStyle(
                    color: context.onPrimaryColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _onSave() {
    if (_houseController.text.isEmpty) {
      ToastService.showErrorToast(context, 'Please enter house/building name');
      return;
    }
    if (_selectedLabel == 'Other' &&
        _customLabelController.text.trim().isEmpty) {
      ToastService.showErrorToast(context, 'Please enter a custom label');
      return;
    }

    String customLabelStr = _selectedLabel == 'Other' && _customLabelController.text.trim().isNotEmpty
        ? "${_customLabelController.text.trim()} - "
        : "";

    final fullAddress =
        "$customLabelStr${_houseController.text}, ${_floorController.text.isNotEmpty ? "${_floorController.text}, " : ""}$_currentAddress";

    String finalLabel = _selectedLabel.toLowerCase();

    // Create/Update address model
    final addressController = context.read<AddressController>();

    if (widget.editAddress != null) {
      // Update existing address
      final updatedAddress = AddressModel(
        id: widget.editAddress!.id,
        label: finalLabel,
        address: fullAddress,
        latitude: _lastMapPosition.latitude,
        longitude: _lastMapPosition.longitude,
        isDefault: _isDefault ? 1 : 0,
        radius: _radius,
      );

      setState(() => _isSaving = true);
      addressController
          .updateAddress(updatedAddress.id!, updatedAddress)
          .then((response) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        if (response.success) {
          context.read<LocationController>().setLocation(
                _lastMapPosition.latitude,
                _lastMapPosition.longitude,
                fullAddress,
                radius: _radius,
                label: finalLabel,
              );

          ToastService.showSuccessToast(
              context, 'Address updated successfully');
          Navigator.pop(context);
        } else {
          ToastService.showErrorToast(context, response.message);
        }
      });
    } else {
      // Save new address
      final newAddress = AddressModel(
        label: finalLabel,
        address: fullAddress,
        latitude: _lastMapPosition.latitude,
        longitude: _lastMapPosition.longitude,
        isDefault:
            _isDefault ? 1 : (addressController.addresses.isEmpty ? 1 : 0),
        radius: _radius,
      );

      setState(() => _isSaving = true);
      addressController.saveAddress(newAddress).then((response) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        if (response.success) {
          context.read<LocationController>().setLocation(
                _lastMapPosition.latitude,
                _lastMapPosition.longitude,
                fullAddress,
                radius: _radius,
                label: finalLabel,
              );

          ToastService.showSuccessToast(context, 'Address saved successfully');
          Navigator.pop(context);
        } else {
          ToastService.showErrorToast(context, response.message);
        }
      });
    }
  }
}
