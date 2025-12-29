class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String type; // 'income' or 'expense'

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      type: data['type'] ?? 'expense',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'icon': icon, 'type': type};
  }
}
