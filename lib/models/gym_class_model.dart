import 'enums.dart';
import 'category_model.dart';

/// Molde de la clase de entrenamiento
class GymClassModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? categoryId;
  final ClassIntensity intensity;
  final int durationMinutes;
  final double basePrice;
  final CategoryModel? category;

  const GymClassModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.intensity = ClassIntensity.medium,
    required this.durationMinutes,
    this.basePrice = 0.0,
    this.category,
  });

  factory GymClassModel.fromJson(Map<String, dynamic> json) {
    return GymClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as String?,
      intensity: ClassIntensity.fromString(json['intensity'] as String?),
      durationMinutes: json['duration_minutes'] as int? ?? 45,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      category: json['categories'] != null
          ? CategoryModel.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
    );
  }

  GymClassModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? categoryId,
    ClassIntensity? intensity,
    int? durationMinutes,
    double? basePrice,
    CategoryModel? category,
  }) {
    return GymClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      intensity: intensity ?? this.intensity,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      basePrice: basePrice ?? this.basePrice,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'category_id': categoryId,
      'intensity': intensity.toDbString(),
      'duration_minutes': durationMinutes,
      'base_price': basePrice,
    };
  }
}
