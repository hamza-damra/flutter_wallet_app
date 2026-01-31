class TransactionModel {
  final String id;
  final int? localId; // Local database ID for updates
  final String userId;
  final String title;
  final String? titleAr;
  final double amount;
  final String type; // 'income' or 'expense'
  final String categoryId;
  final String categoryName; // Denormalized for easier display
  final String categoryIcon; // Denormalized
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    this.localId,
    required this.userId,
    required this.title,
    this.titleAr,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> data) {
    return TransactionModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      titleAr: data['titleAr'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'expense',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? 'Uncategorized',
      categoryIcon: data['categoryIcon'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt']).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt']).toDate()
          : (data['createdAt'] != null
                ? (data['createdAt']).toDate()
                : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'titleAr': titleAr,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
