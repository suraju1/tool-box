class CollectionModel {
  final int id;
  final String name;
  final int itemCount;
  final String createdAt;

  CollectionModel({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.createdAt,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      itemCount: json['member_count'] ?? json['item_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'item_count': itemCount,
      'member_count': itemCount,
      'created_at': createdAt,
    };
  }
}
