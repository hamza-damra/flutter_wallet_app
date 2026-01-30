class DebtTransactionModel {
  final String id;
  final String userId;
  final String friendId;

  final double amount;
  final String type; // 'lent' or 'borrowed'
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtTransactionModel({
    required this.id,
    required this.userId,
    required this.friendId,

    required this.amount,
    required this.type,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'friendId': friendId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DebtTransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return DebtTransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      friendId: map['friendId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'lent',
      date: map['date'] is String
          ? DateTime.parse(map['date'])
          : (map['date']?.toDate() ?? DateTime.now()),
      note: map['note'],
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt']?.toDate() ?? DateTime.now()),
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'])
          : (map['updatedAt']?.toDate() ?? DateTime.now()),
    );
  }
}
