class SavedUserCollectionInfo {
  final int collectionId;
  final String collectionName;

  SavedUserCollectionInfo({
    required this.collectionId,
    required this.collectionName,
  });

  factory SavedUserCollectionInfo.fromJson(Map<String, dynamic> json) {
    return SavedUserCollectionInfo(
      collectionId: int.tryParse((json['collection_id'] ?? '0').toString()) ?? 0,
      collectionName: json['collection_name'] ?? '',
    );
  }
}

class SavedUserModel {
  final int id;
  final String fullName;
  final String? location;
  final String? profileImage;
  final String? bio;
  final String avgStars;
  final int totalRatings;
  final String savedAt;
  final List<SavedUserCollectionInfo> collections;

  SavedUserModel({
    required this.id,
    required this.fullName,
    this.location,
    this.profileImage,
    this.bio,
    required this.avgStars,
    required this.totalRatings,
    required this.savedAt,
    this.collections = const [],
  });

  factory SavedUserModel.fromJson(Map<String, dynamic> json) {
    List<SavedUserCollectionInfo> parsedCollections = [];
    if (json['collections'] is List) {
      parsedCollections = (json['collections'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => SavedUserCollectionInfo.fromJson(e))
          .toList();
    }

    return SavedUserModel(
      id: int.tryParse((json['user_id'] ?? json['id'] ?? '0').toString()) ?? 0,
      fullName: json['full_name'] ?? json['name'] ?? '',
      location: json['location'],
      profileImage: json['profile_image'],
      bio: json['bio'],
      avgStars: (json['avg_stars'] ?? json['rating'] ?? '0.0').toString(),
      totalRatings: int.tryParse((json['total_ratings'] ?? '0').toString()) ?? 0,
      savedAt: json['saved_at'] ?? json['created_at'] ?? '',
      collections: parsedCollections,
    );
  }
}
