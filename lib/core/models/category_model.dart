class CategoryModel {
  final String id;
  final String? userId; // Null for system defaults, or specific user ID
  final String name;
  final String? nameAr; // Optional Arabic name
  final String icon;
  final String type; // 'income' or 'expense'
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    this.userId,
    required this.name,
    this.nameAr,
    required this.icon,
    required this.type,
    required this.updatedAt,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      userId: data['userId'],
      name: data['name'] ?? '',
      nameAr: data['nameAr'],
      icon: data['icon'] ?? '',
      type: data['type'] ?? 'expense',
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt']).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'nameAr': nameAr,
      'icon': icon,
      'type': type,
      'updatedAt': updatedAt,
    };
  }
}
