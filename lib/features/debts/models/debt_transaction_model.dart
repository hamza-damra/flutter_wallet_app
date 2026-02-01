enum DebtEventType {
  borrow,    // I borrowed from a friend
  lend,      // I lent to a friend
  settlePay, // I paid my friend back
  settleReceive, // I received repayment from my friend
}

extension DebtEventTypeExtension on DebtEventType {
  String get value {
    switch (this) {
      case DebtEventType.borrow:
        return 'borrow';
      case DebtEventType.lend:
        return 'lend';
      case DebtEventType.settlePay:
        return 'settle_pay';
      case DebtEventType.settleReceive:
        return 'settle_receive';
    }
  }

  static DebtEventType fromString(String value) {
    switch (value) {
      case 'borrow':
      case 'borrowed': // Legacy support
        return DebtEventType.borrow;
      case 'lend':
      case 'lent': // Legacy support
        return DebtEventType.lend;
      case 'settle_pay':
        return DebtEventType.settlePay;
      case 'settle_receive':
        return DebtEventType.settleReceive;
      default:
        return DebtEventType.lend;
    }
  }

  bool get isSettlement => this == DebtEventType.settlePay || this == DebtEventType.settleReceive;
  
  bool get increasesMainBalance => this == DebtEventType.borrow || this == DebtEventType.settleReceive;
  
  bool get decreasesMainBalance => this == DebtEventType.lend || this == DebtEventType.settlePay;
}

class DebtTransactionModel {
  final String id;
  final String userId;
  final String friendId;

  final double amount;
  final DebtEventType type;
  final DateTime date;
  final String? note;
  final bool settled;
  final DateTime? settledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool affectMainBalance;
  final int? linkedTransactionId;

  DebtTransactionModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.settled = false,
    this.settledAt,
    required this.createdAt,
    required this.updatedAt,
    this.affectMainBalance = false,
    this.linkedTransactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'friendId': friendId,
      'amount': amount,
      'type': type.value,
      'date': date.toIso8601String(),
      'note': note,
      'settled': settled,
      'settledAt': settledAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'affectMainBalance': affectMainBalance,
      'linkedTransactionId': linkedTransactionId,
    };
  }

  factory DebtTransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return DebtTransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      friendId: map['friendId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: DebtEventTypeExtension.fromString(map['type'] ?? 'lend'),
      date: map['date'] is String
          ? DateTime.parse(map['date'])
          : (map['date']?.toDate() ?? DateTime.now()),
      note: map['note'],
      settled: map['settled'] ?? false,
      settledAt: map['settledAt'] != null
          ? (map['settledAt'] is String
              ? DateTime.parse(map['settledAt'])
              : map['settledAt']?.toDate())
          : null,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt']?.toDate() ?? DateTime.now()),
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'])
          : (map['updatedAt']?.toDate() ?? DateTime.now()),
      affectMainBalance: map['affectMainBalance'] ?? false,
      linkedTransactionId: map['linkedTransactionId'],
    );
  }

  DebtTransactionModel copyWith({
    String? id,
    String? userId,
    String? friendId,
    double? amount,
    DebtEventType? type,
    DateTime? date,
    String? note,
    bool? settled,
    DateTime? settledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? affectMainBalance,
    int? linkedTransactionId,
  }) {
    return DebtTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      settled: settled ?? this.settled,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      affectMainBalance: affectMainBalance ?? this.affectMainBalance,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
    );
  }
}
