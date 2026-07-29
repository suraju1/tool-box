class CollectionModel {
  final int id;
  final String name;
  final int itemCount;
  final String createdAt;
  final bool isMember;

  CollectionModel({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.createdAt,
    this.isMember = false,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      itemCount: json['member_count'] ?? json['item_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
      isMember: json['is_member'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'item_count': itemCount,
      'member_count': itemCount,
      'created_at': createdAt,
      'is_member': isMember,
    };
  }
}
