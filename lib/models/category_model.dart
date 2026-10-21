/// Categoría de clase (Cardio, Strength, Yoga, etc.)
class CategoryModel {
  final String id;
  final String name;
  final String? iconUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
    };
  }
}
