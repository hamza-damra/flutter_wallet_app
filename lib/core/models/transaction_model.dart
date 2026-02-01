class DebtRelatedInfo {
  final int debtEventId;
  final String friendId;
  final String debtEventType;

  DebtRelatedInfo({
    required this.debtEventId,
    required this.friendId,
    required this.debtEventType,
  });

  Map<String, dynamic> toMap() {
    return {
      'debtEventId': debtEventId,
      'friendId': friendId,
      'debtEventType': debtEventType,
    };
  }

  factory DebtRelatedInfo.fromMap(Map<String, dynamic> map) {
    return DebtRelatedInfo(
      debtEventId: map['debtEventId'] ?? 0,
      friendId: map['friendId'] ?? '',
      debtEventType: map['debtEventType'] ?? '',
    );
  }
}

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
  final DebtRelatedInfo? debtRelated; // Link to debt event if this is debt-related

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
    this.debtRelated,
  });

  bool get isDebtRelated => debtRelated != null;

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
      debtRelated: data['debtRelated'] != null
          ? DebtRelatedInfo.fromMap(data['debtRelated'] as Map<String, dynamic>)
          : null,
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
      if (debtRelated != null) 'debtRelated': debtRelated!.toMap(),
    };
  }

  TransactionModel copyWith({
    String? id,
    int? localId,
    String? userId,
    String? title,
    String? titleAr,
    double? amount,
    String? type,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    DateTime? createdAt,
    DateTime? updatedAt,
    DebtRelatedInfo? debtRelated,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      debtRelated: debtRelated ?? this.debtRelated,
    );
  }
}
