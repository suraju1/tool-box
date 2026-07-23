import 'package:flutter/material.dart';
import 'package:tool_bocs/core/api/api_response.dart';
import 'package:tool_bocs/core/services/local_location_service.dart';
import 'package:tool_bocs/features/address/model/address_model.dart';
import 'package:tool_bocs/features/address/service/address_service.dart';

class AddressController extends ChangeNotifier {
  final AddressService _addressService = AddressService();

  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((element) => element.isDefault == 1);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _addressService.fetchMyAddresses();

    if (response.success && response.data != null) {
      _addresses = response.data!.map((addr) {
        double? rad = addr.radius;
        if (addr.id != null) {
          double? idRad = LocalLocationService.getAddressRadius(addr.id!.toString());
          if (rad == null && idRad != null) {
            rad = idRad;
          } else if (rad == null && idRad == null) {
            LocalLocationService.removeAddressRadius(addr.address.trim());
          }
        } else {
          rad = rad ?? LocalLocationService.getAddressRadius(addr.address.trim());
        }
        if (rad != null && rad != addr.radius) {
          return AddressModel(
            id: addr.id,
            userId: addr.userId,
            label: addr.label,
            address: addr.address,
            latitude: addr.latitude,
            longitude: addr.longitude,
            isDefault: addr.isDefault,
            radius: rad,
          );
        }
        return addr;
      }).toList();
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ApiResponse<AddressModel>> saveAddress(AddressModel address) async {
    if (address.radius != null) {
      if (address.id != null) {
        LocalLocationService.saveAddressRadius(address.id.toString(), address.radius!);
      } else {
        LocalLocationService.saveAddressRadius(address.address.trim(), address.radius!);
      }
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _addressService.saveAddress(address);

    if (response.success && response.data != null) {
      if (address.radius != null && response.data!.id != null) {
        LocalLocationService.saveAddressRadius(response.data!.id.toString(), address.radius!);
      }
      // If the new address is marked as default, clear other defaults locally
      if (address.isDefault == 1) {
        await fetchAddresses(); 
      } else {
        AddressModel toAdd = response.data!;
        if (toAdd.radius == null && address.radius != null) {
          toAdd = AddressModel(
            id: toAdd.id,
            userId: toAdd.userId,
            label: toAdd.label,
            address: toAdd.address,
            latitude: toAdd.latitude,
            longitude: toAdd.longitude,
            isDefault: toAdd.isDefault,
            radius: address.radius,
          );
        }
        _addresses.add(toAdd);
      }
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }

  Future<ApiResponse<AddressModel>> updateAddress(int id, AddressModel address) async {
    if (address.radius != null) {
      LocalLocationService.saveAddressRadius(id.toString(), address.radius!);
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _addressService.updateAddress(id, address);

    if (response.success) {
      await fetchAddresses(); // Refresh list to reflect changes
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }

  Future<ApiResponse<AddressModel>> setAsDefault(int id) async {
    try {
      final address = _addresses.firstWhere((e) => e.id == id);
      final updatedAddress = AddressModel(
        id: address.id,
        label: address.label,
        address: address.address,
        latitude: address.latitude,
        longitude: address.longitude,
        isDefault: 1,
        radius: address.radius,
      );
      return updateAddress(id, updatedAddress);
    } catch (e) {
      return ApiResponse(success: false, message: 'Address not found');
    }
  }


  Future<ApiResponse<dynamic>> deleteAddress(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _addressService.deleteAddress(id);

    if (response.success) {
      _addresses.removeWhere((element) => element.id == id);
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
    return response;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
