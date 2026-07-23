class AddressModel {
  final int? id;
  final int? userId;
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final int isDefault;
  final double? radius;

  AddressModel({
    this.id,
    this.userId,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    this.radius,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      userId: json['user_id'],
      label: json['label'] ?? '',
      address: json['address'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      isDefault: json['is_default'] ?? 0,
      radius: double.tryParse(json['radius']?.toString() ?? json['radius_km']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      if (radius != null) 'radius': radius,
      if (radius != null) 'radius_km': radius,
    };
  }
}

