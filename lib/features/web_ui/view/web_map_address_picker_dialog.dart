import 'dart:async';
import 'package:tool_bocs/l10n/generated/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tool_bocs/core/controller/location_controller.dart';
import 'package:tool_bocs/core/services/location_service.dart';
import 'package:tool_bocs/util/colors.dart';
import 'package:tool_bocs/core/services/toast_service.dart';
import 'package:tool_bocs/features/address/controller/address_controller.dart';
import 'package:tool_bocs/features/address/model/address_model.dart';
import 'dart:math' as math;
import 'package:geocoding/geocoding.dart' as geo;

class WebMapAddressPickerDialog extends StatefulWidget {
  final bool isPickOnly;
  final AddressModel? editAddress;
  const WebMapAddressPickerDialog({
    super.key,
    this.isPickOnly = false,
    this.editAddress,
  });

  static Future<void> show(BuildContext context,
      {bool isPickOnly = false, AddressModel? editAddress}) {
    return showDialog(
      context: context,
      builder: (context) => WebMapAddressPickerDialog(
        isPickOnly: isPickOnly,
        editAddress: editAddress,
      ),
    );
  }

  @override
  State<WebMapAddressPickerDialog> createState() =>
      _WebMapAddressPickerDialogState();
}

class _WebMapAddressPickerDialogState extends State<WebMapAddressPickerDialog> {
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
      return '${(_radius * 1000).toInt()} meters';
    }
    return '${_radius.toStringAsFixed(1)} km';
  }

  double _currentZoom = 13.2;

  bool _showFullForm = false;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
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
    _houseController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _mapSearchController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  void _initEditAddress() {
    final addr = widget.editAddress!;
    _lastMapPosition = LatLng(addr.latitude, addr.longitude);
    _currentAddress = addr.address;
    _areaController.text = addr.address;
    _selectedLabel = addr.label;

    final parts = addr.address.split(', ');
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
    bool serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.locationDisabled,
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
                AppLocalizations.of(context)!.yourSystemLocationServicesAre),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.ok,
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }
      return;
    }

    final success = await context.read<LocationController>().fetchLocation();
    if (!mounted) return;
    if (success) {
      final loc = context.read<LocationController>();
      if (loc.latitude != null && loc.longitude != null) {
        _updateLocalLocation(LatLng(loc.latitude!, loc.longitude!),
            loc.address ?? "Unknown Address");
      }
    }
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
    setState(() {
      _lastMapPosition = position.target;
      _currentZoom = position.zoom;
    });
  }

  Future<void> _onCameraIdle() async {
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

  double _getZoomForRadius(double radius) {
    if (radius <= 0.05) return 19.0;
    if (radius <= 0.1) return 18.0;
    if (radius <= 0.2) return 17.5;
    if (radius <= 0.5) return 16.5;
    if (radius <= 1) return 15.5;
    if (radius <= 2) return 14.5;
    if (radius <= 5) return 13.2;
    if (radius <= 10) return 12.2;
    if (radius <= 20) return 11.2;
    if (radius <= 35) return 10.2;
    return 9.5;
  }

  Future<void> _updateCameraZoom(double radius) async {
    final GoogleMapController controller = await _controller.future;
    final double zoom = _getZoomForRadius(radius);
    final double adjustedZoom = zoom - 0.6;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _lastMapPosition, zoom: adjustedZoom),
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() => _isReverseGeocoding = true);

    try {
      // 1. Try standard geocoding first (works best on mobile)
      List<geo.Location> locations = await geo.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final position = LatLng(loc.latitude, loc.longitude);
        final address = await LocationService.getAddressFromCoordinates(
            loc.latitude, loc.longitude);
        if (mounted) {
          _updateLocalLocation(position, address ?? query);
          setState(() => _isReverseGeocoding = false);
        }
        return;
      }
    } catch (e) {
      debugPrint('Standard geocoding failed, trying fallback: $e');
    }

    // 2. Fallback for Web (Geocoding API direct call)
    try {
      const apiKey = 'AIzaSyDcGPon7dpfONgGUw8lBMOXveihNhaepVo';
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];
          final formattedAddress = result['formatted_address'];

          final position = LatLng(lat, lng);
          if (mounted) {
            _updateLocalLocation(position, formattedAddress ?? query);
          }
        } else {
          if (mounted)
            ToastService.showErrorToast(context, 'Location not found');
        }
      } else {
        if (mounted) ToastService.showErrorToast(context, 'Location not found');
      }
    } catch (e) {
      debugPrint('Fallback API geocoding failed: $e');
      if (mounted) ToastService.showErrorToast(context, 'Location not found');
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: context.onPrimaryColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Stack(
                children: [
                  _buildMap(),
                  _buildRadiusText(),
                  _buildSearchOverlay(),
                  _buildUseCurrentLocationFloating(),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.onPrimaryColor,
                boxShadow: [
                  BoxShadow(
                      color:
                          context.isDarkMode ? Colors.black45 : Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, -5))
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_showFullForm) _buildRadiusSlider(),
                  _buildBottomForm(),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.addAddress,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    double initialZoom = _getZoomForRadius(_radius);
    return Padding(
      padding: EdgeInsets.zero,
      child: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: _lastMapPosition, zoom: initialZoom),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        onCameraMove: _onCameraMove,
        onCameraIdle: _onCameraIdle,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        circles: {
          Circle(
            circleId: const CircleId('radius_circle'),
            center: _lastMapPosition,
            radius: _radius * 1000,
            fillColor: Colors.black.withOpacity(0.3),
            strokeColor: Colors.black,
            strokeWidth: 2,
          ),
        },
        polylines: {
          Polyline(
            polylineId: const PolylineId('radius_line'),
            points: [
              _lastMapPosition,
              LatLng(
                _lastMapPosition.latitude,
                _lastMapPosition.longitude +
                    (_radius /
                        (111.32 *
                            math.cos(
                                _lastMapPosition.latitude * math.pi / 180))),
              ),
            ],
            color: Colors.black,
            width: 3,
          ),
        },
      ),
    );
  }

  Widget _buildRadiusText() {
    final double metersPerPixel = 156543.03392 *
        math.cos(_lastMapPosition.latitude * math.pi / 180) /
        math.pow(2, _currentZoom);
    final double radiusInPixels =
        ((_radius * 1000) / metersPerPixel).clamp(0.0, 5000.0);

    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Center(
          child: Transform.translate(
            offset: Offset(radiusInPixels / 2, 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                formattedRadius,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.selectRadius,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                formattedRadius,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: _radius.clamp(0.01, 10.0),
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
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 10,
      left: 16,
      right: 16,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: context.onPrimaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: context.isDarkMode ? Colors.black45 : Colors.black12,
                blurRadius: 10)
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: context.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _mapSearchController,
                decoration: InputDecoration(
                  hintText: 'Search for area, locality...',
                  hintStyle:
                      TextStyle(color: context.subTextColor, fontSize: 14),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => _searchLocation(value),
                onChanged: (val) => setState(() {}),
              ),
            ),
            if (_mapSearchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _mapSearchController.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUseCurrentLocationFloating() {
    if (_showFullForm) return const SizedBox.shrink();
    return Positioned(
      top: 70,
      right: 16,
      child: InkWell(
        onTap: _getCurrentLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: context.onPrimaryColor,
            borderRadius: BorderRadius.circular(30),
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
              Icon(Icons.my_location, color: context.primaryColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: _showFullForm
            ? _buildDetailedAddressForm()
            : _buildConfirmationView(),
      ),
    );
  }

  Widget _buildConfirmationView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.findingProductsFor,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.onPrimaryColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dividerColor),
            boxShadow: [BoxShadow(color: context.dividerColor, blurRadius: 5)],
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: context.primaryColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentAddress.split(',').first,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _currentAddress,
                      style:
                          TextStyle(fontSize: 12, color: context.subTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _showFullForm = true),
                child: Text(AppLocalizations.of(context)!.change,
                    style: TextStyle(
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.isPickOnly
                ? _onConfirmLocation
                : () => setState(() => _showFullForm = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    widget.isPickOnly
                        ? 'Confirm Location'
                        : 'Enter complete address',
                    style: TextStyle(
                        color: context.onPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
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

  Widget _buildDetailedAddressForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.enterCompleteAddress,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => setState(() => _showFullForm = false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(AppLocalizations.of(context)!.saveAddressAs1,
            style: TextStyle(fontSize: 14, color: context.subTextColor)),
        const SizedBox(height: 10),
        _buildLabelSelector(),
        const SizedBox(height: 20),
        _buildTextField('Flat / House no / Building name *', _houseController),
        _buildTextField('Floor (optional)', _floorController),
        _buildLocationDetails(),
        const SizedBox(height: 10),
        _buildDefaultToggle(),
        const SizedBox(height: 10),
        _buildSaveButton(),
      ],
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(labels.length, (index) {
        final isSelected = _selectedLabel == labels[index];
        return InkWell(
          onTap: () => setState(() => _selectedLabel = labels[index]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.primaryColor.withOpacity(0.1)
                  : context.surfaceColor,
              border: Border.all(
                  color:
                      isSelected ? context.primaryColor : context.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icons[index],
                    color: isSelected ? context.primaryColor : Colors.grey,
                    size: 20),
                const SizedBox(width: 6),
                Text(labels[index],
                    style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? context.primaryColor
                            : context.textColor)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14, color: context.subTextColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLocationDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white10
            : context.dividerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.areaSectorLocality,
                    style:
                        TextStyle(fontSize: 12, color: context.subTextColor)),
                const SizedBox(height: 4),
                Text(
                  _currentAddress,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                setState(() => _showFullForm = false), // Go back to map view
            child: Text(AppLocalizations.of(context)!.change,
                style: TextStyle(color: context.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultToggle() {
    return SwitchListTile(
      title: Text(AppLocalizations.of(context)!.setAsDefaultAddress,
          style: TextStyle(fontSize: 16)),
      value: _isDefault,
      activeColor: context.primaryColor,
      onChanged: (val) => setState(() => _isDefault = val),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(AppLocalizations.of(context)!.saveAddress,
            style: TextStyle(
                color: context.onPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _onSave() async {
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

    final addressController = context.read<AddressController>();

    if (widget.editAddress != null) {
      final updatedAddress = AddressModel(
        id: widget.editAddress!.id,
        label: finalLabel,
        address: fullAddress,
        latitude: _lastMapPosition.latitude,
        longitude: _lastMapPosition.longitude,
        isDefault: _isDefault ? 1 : 0,
      );

      final response = await addressController.updateAddress(
          updatedAddress.id!, updatedAddress);
      if (!mounted) return;

      if (response.success) {
        context.read<LocationController>().setLocation(
              _lastMapPosition.latitude,
              _lastMapPosition.longitude,
              fullAddress,
              radius: _radius,
              label: finalLabel,
            );
        ToastService.showSuccessToast(context, 'Address updated successfully');
        Navigator.pop(context);
      } else {
        ToastService.showErrorToast(context, response.message);
      }
    } else {
      final newAddress = AddressModel(
        label: finalLabel,
        address: fullAddress,
        latitude: _lastMapPosition.latitude,
        longitude: _lastMapPosition.longitude,
        isDefault:
            _isDefault ? 1 : (addressController.addresses.isEmpty ? 1 : 0),
      );

      final response = await addressController.saveAddress(newAddress);
      if (!mounted) return;

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
    }
  }
}
