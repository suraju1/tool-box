import 'package:hive_flutter/hive_flutter.dart';

class LocalLocationService {
  static const String _boxName = 'location_box';
  static const String _savedAddressesKey = 'saved_addresses';
  static const String _lastSelectedLocationKey = 'last_selected_location';

  /// Save the list of addresses to Hive
  static Future<void> saveAddresses(List<Map<String, String>> addresses) async {
    final box = Hive.box(_boxName);
    await box.put(_savedAddressesKey, addresses);
  }

  // Load the list of addresses from Hive
  static List<Map<String, String>> loadAddresses() {
    final box = Hive.box(_boxName);
    final List? data = box.get(_savedAddressesKey);
    if (data == null) return [];

    // Cast to List<Map<String, String>>
    return data.map((item) => Map<String, String>.from(item)).toList();
  }

  /// Save the last selected location (lat, lng, address)
  static Future<void> saveLastSelectedLocation(
      Map<String, String> location) async {
    final box = Hive.box(_boxName);
    await box.put(_lastSelectedLocationKey, location);
  }

  /// Load the last selected location
  static Map<String, String>? loadLastSelectedLocation() {
    final box = Hive.box(_boxName);
    final Map? data = box.get(_lastSelectedLocationKey);
    if (data == null) return null;
    return Map<String, String>.from(data);
  }

  static const String _addressRadiusMapKey = 'address_radius_map';

  static Future<void> saveAddressRadius(String key, double radius) async {
    if (key.trim().isEmpty) return;
    final box = Hive.box(_boxName);
    final Map? existing = box.get(_addressRadiusMapKey);
    final Map map = existing != null ? Map.from(existing) : {};
    map[key.trim()] = radius;
    await box.put(_addressRadiusMapKey, map);
  }

  static double? getAddressRadius(String key) {
    if (key.trim().isEmpty) return null;
    final box = Hive.box(_boxName);
    final Map? map = box.get(_addressRadiusMapKey);
    if (map == null || map[key.trim()] == null) return null;
    return double.tryParse(map[key.trim()].toString());
  }

  static Future<void> removeAddressRadius(String key) async {
    if (key.trim().isEmpty) return;
    final box = Hive.box(_boxName);
    final Map? existing = box.get(_addressRadiusMapKey);
    if (existing == null || !existing.containsKey(key.trim())) return;
    final Map map = Map.from(existing);
    map.remove(key.trim());
    await box.put(_addressRadiusMapKey, map);
  }
}

