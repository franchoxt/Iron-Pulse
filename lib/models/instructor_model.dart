/// Instructor de IRON PULSE
class InstructorModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final double rating;

  const InstructorModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.rating = 5.0,
  });

  factory InstructorModel.fromJson(Map<String, dynamic> json) {
    return InstructorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'bio': bio,
      'rating': rating,
    };
  }
}
