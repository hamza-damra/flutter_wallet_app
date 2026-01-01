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
}
