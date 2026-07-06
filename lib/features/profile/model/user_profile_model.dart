class UserProfileModel {
  final UserDetails userDetails;
  final TradeStats tradeStats;
  final List<Review> reviews;
  final bool? isSaved;
  final bool? isRated;
  final int showTradeHistory;

  UserProfileModel({
    required this.userDetails,
    required this.tradeStats,
    required this.reviews,
    this.isSaved,
    this.isRated,
    this.showTradeHistory = 1,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final userDetailsJson =
        Map<String, dynamic>.from(json['user_details'] ?? {});
    if (json['review_stats'] != null &&
        userDetailsJson['review_stats'] == null) {
      userDetailsJson['review_stats'] = json['review_stats'];
    }
    if (json['user_type'] != null &&
        userDetailsJson['user_type'] == null) {
      userDetailsJson['user_type'] = json['user_type'];
    }

    return UserProfileModel(
      userDetails: UserDetails.fromJson(userDetailsJson),
      tradeStats: TradeStats.fromJson(json['trade_stats'] ?? {}),
      reviews: (json['reviews'] as List? ??
              json['user_reviews'] as List? ??
              json['recent_reviews'] as List?)
              ?.map((e) => Review.fromJson(e))
              .toList() ??
          [],
      isSaved: json['isSaved'] ?? json['is_saved'] == 1 || json['is_saved'] == true,
      isRated: json['isRated'] ?? json['is_rated'] == 1 || json['is_rated'] == true,
      showTradeHistory: json['show_trade_history'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_details': userDetails.toJson(),
      'trade_stats': tradeStats.toJson(),
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'isSaved': isSaved,
      'isRated': isRated,
      'show_trade_history': showTradeHistory,
    };
  }
}

class UserDetails {
  final int id;
  final String fullName;
  final String? location;
  final String? image;
  final String? bio;
  final String? email;
  final String? phoneNumber;
  final int profileVisibility;
  final int showTradeHistory;
  final String? gender;
  final String? dateOfBirth;
  final dynamic latitude;
  final dynamic longitude;
  final String averageRating;
  final int totalReviews;
  final int totalLikes;
  final int totalDislikes;
  final int savedCount;
  final String? remainingBalance;
  final bool termsAccepted;
  final String? giverType;
  final String? takerType;
  final int? age;
  final String? occupation;
  final String? educationalQualification;
  final String? country;
  final String? state;
  final String? city;
  final String? pinCode;
  final String? address;
  final String? churchName;
  final String? fatherOrPastorName;
  final String? churchCity;
  final String? churchPinCode;
  final String? churchAddress;
  final String? churchPhoneNumber;

  UserDetails({
    required this.id,
    required this.fullName,
    this.location,
    this.image,
    this.bio,
    this.email,
    this.phoneNumber,
    this.profileVisibility = 1,
    this.showTradeHistory = 1,
    this.gender,
    this.dateOfBirth,
    this.latitude,
    this.longitude,
    required this.averageRating,
    required this.totalReviews,
    this.totalLikes = 0,
    this.totalDislikes = 0,
    this.savedCount = 0,
    this.remainingBalance,
    this.termsAccepted = true,
    this.giverType,
    this.takerType,
    this.age,
    this.occupation,
    this.educationalQualification,
    this.country,
    this.state,
    this.city,
    this.pinCode,
    this.address,
    this.churchName,
    this.fatherOrPastorName,
    this.churchCity,
    this.churchPinCode,
    this.churchAddress,
    this.churchPhoneNumber,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    final reviewStats = json['review_stats'] is Map<String, dynamic>
        ? json['review_stats'] as Map<String, dynamic>
        : <String, dynamic>{};
        
    final userTypeJson = json['user_type'] is Map<String, dynamic>
        ? json['user_type'] as Map<String, dynamic>
        : null;

    return UserDetails(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      location: json['location'],
      image: json['image'],
      bio: json['bio'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      profileVisibility: json['profile_visibility'] ?? 1,
      showTradeHistory: json['show_trade_history'] ?? 1,
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      averageRating: json['average_rating']?.toString() ?? '0.0',
      totalReviews: json['total_reviews'] ?? 0,
      totalLikes: _parseInt(json['total_likes'] ?? reviewStats['likes']),
      totalDislikes:
          _parseInt(json['total_dislikes'] ?? reviewStats['dislikes']),
      savedCount: _parseInt(json['saved_count'] ?? json['saved_users_count'] ?? 0),
      remainingBalance: json['remaining_balance']?.toString(),
      termsAccepted:
          json['terms_accepted'] == 1 || json['terms_accepted'] == true,
      giverType: userTypeJson?['giver']?.toString(),
      takerType: userTypeJson?['taker']?.toString(),
      age: _parseInt(json['age']),
      occupation: json['occupation'],
      educationalQualification: json['educational_qualification'],
      country: json['country'],
      state: json['state'],
      city: json['city'],
      pinCode: json['pin_code'],
      address: json['address'],
      churchName: json['church_name'],
      fatherOrPastorName: json['father_or_pastor_name'],
      churchCity: json['church_city'],
      churchPinCode: json['church_pin_code'],
      churchAddress: json['church_address'],
      churchPhoneNumber: json['church_phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'location': location,
      'image': image,
      'bio': bio,
      'email': email,
      'phone_number': phoneNumber,
      'profile_visibility': profileVisibility,
      'show_trade_history': showTradeHistory,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'latitude': latitude,
      'longitude': longitude,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'total_likes': totalLikes,
      'total_dislikes': totalDislikes,
      'saved_count': savedCount,
      'remaining_balance': remainingBalance,
      'terms_accepted': termsAccepted ? 1 : 0,
      'user_type': {
        'giver': giverType,
        'taker': takerType,
      },
      'age': age,
      'occupation': occupation,
      'educational_qualification': educationalQualification,
      'country': country,
      'state': state,
      'city': city,
      'pin_code': pinCode,
      'address': address,
      'church_name': churchName,
      'father_or_pastor_name': fatherOrPastorName,
      'church_city': churchCity,
      'church_pin_code': churchPinCode,
      'church_address': churchAddress,
      'church_phone_number': churchPhoneNumber,
    };
  }
}

class TradeStats {
  final int totalGives;
  final int totalTakes;
  final int totalTrades;
  final int sentOffers;
  final int receivedOffers;

  TradeStats({
    required this.totalGives,
    required this.totalTakes,
    required this.totalTrades,
    this.sentOffers = 0,
    this.receivedOffers = 0,
  });

  factory TradeStats.fromJson(Map<String, dynamic> json) {
    return TradeStats(
      totalGives: _parseInt(json['total_gives']),
      totalTakes: _parseInt(json['total_takes']),
      totalTrades: _parseInt(json['total_trades']),
      sentOffers: _parseInt(json['sent_offers']),
      receivedOffers: _parseInt(json['received_offers']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_gives': totalGives,
      'total_takes': totalTakes,
      'total_trades': totalTrades,
      'sent_offers': sentOffers,
      'received_offers': receivedOffers,
    };
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class Review {
  final int id;
  final int? userId;
  final int? reviewerId;
  final String? reviewerName;
  final String? reviewerImage;
  final dynamic rating;
  final String? feedbackLabel;
  final String? comment;
  final String createdAt;
  final int likesCount;
  final int dislikesCount;
  final String? userReaction;

  Review({
    required this.id,
    this.userId,
    this.reviewerId,
    this.reviewerName,
    this.reviewerImage,
    required this.rating,
    this.feedbackLabel,
    this.comment,
    required this.createdAt,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.userReaction,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      userId: json['user_id'],
      reviewerId: json['reviewer_id'],
      reviewerName: json['reviewer_name'],
      reviewerImage: json['reviewer_image'],
      rating: json['rating'] ?? 0,
      feedbackLabel: json['feedback_label'],
      comment: json['comment'],
      createdAt: json['created_at'] ?? '',
      likesCount: _parseInt(json['likes_count']),
      dislikesCount: _parseInt(json['dislikes_count']),
      userReaction: json['user_reaction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'reviewer_id': reviewerId,
      'reviewer_name': reviewerName,
      'reviewer_image': reviewerImage,
      'rating': rating,
      'feedback_label': feedbackLabel,
      'comment': comment,
      'created_at': createdAt,
      'likes_count': likesCount,
      'dislikes_count': dislikesCount,
      'user_reaction': userReaction,
    };
  }
}
