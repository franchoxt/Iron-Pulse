/// Reseña de un cliente sobre un instructor
class InstructorReviewModel {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final double rating;
  final String comment;
  final String timeAgo;

  const InstructorReviewModel({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    this.rating = 5.0,
    required this.comment,
    this.timeAgo = 'Recently',
  });

  factory InstructorReviewModel.fromJson(Map<String, dynamic> json) {
    return InstructorReviewModel(
      id: json['id'] as String? ?? 'rev-${DateTime.now().millisecondsSinceEpoch}',
      authorName: json['author_name'] as String? ?? 'Client',
      authorAvatar: json['author_avatar'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment'] as String? ?? '',
      timeAgo: json['time_ago'] as String? ?? 'Recently',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'rating': rating,
      'comment': comment,
      'time_ago': timeAgo,
    };
  }
}

/// Instructor de IRON PULSE
class InstructorModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final double rating;
  final List<String> specialties;
  final String yearsExperience;
  final String classesCount;
  final String certification;
  final List<InstructorReviewModel> reviews;
  final String? userId;

  const InstructorModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.rating = 5.0,
    this.specialties = const ['YOGA', 'PILATES'],
    this.yearsExperience = '8+',
    this.classesCount = '2k+',
    this.certification = 'Certified Instructor',
    this.reviews = const [],
    this.userId,
  });

  factory InstructorModel.fromJson(Map<String, dynamic> json) {
    List<InstructorReviewModel> parsedReviews = [];
    if (json['reviews'] != null && json['reviews'] is List) {
      parsedReviews = (json['reviews'] as List)
          .map((r) => InstructorReviewModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    List<String> parsedSpecialties = const ['YOGA', 'PILATES'];
    if (json['specialties'] != null && json['specialties'] is List) {
      parsedSpecialties = List<String>.from(json['specialties'] as List);
    }

    return InstructorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      specialties: parsedSpecialties,
      yearsExperience: (json['years_experience'] as String?) ?? '8+',
      classesCount: (json['classes_count'] as String?) ?? '2k+',
      certification: (json['certification'] as String?) ?? 'Certified Instructor',
      reviews: parsedReviews,
      userId: json['user_id'] as String?,
    );
  }

  InstructorModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? bio,
    double? rating,
    List<String>? specialties,
    String? yearsExperience,
    String? classesCount,
    String? certification,
    List<InstructorReviewModel>? reviews,
    String? userId,
  }) {
    return InstructorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      specialties: specialties ?? this.specialties,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      classesCount: classesCount ?? this.classesCount,
      certification: certification ?? this.certification,
      reviews: reviews ?? this.reviews,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'bio': bio,
      'rating': rating,
      'specialties': specialties,
      'years_experience': yearsExperience,
      'classes_count': classesCount,
      'certification': certification,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      if (userId != null) 'user_id': userId,
    };
  }
}
