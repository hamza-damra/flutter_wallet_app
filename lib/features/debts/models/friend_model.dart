class FriendModel {
  final String id; // localId.toString() or remoteId
  final String userId;
  final String name;
  final String? nameAr;
  final String? phoneNumber;
  final double netBalance; // Calculated
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendModel({
    required this.id,
    required this.userId,
    required this.name,
    this.nameAr,
    this.phoneNumber,
    this.netBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'nameAr': nameAr,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FriendModel.fromMap(String id, Map<String, dynamic> map) {
    return FriendModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      nameAr: map['nameAr'],
      phoneNumber: map['phoneNumber'],
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt']?.toDate() ?? DateTime.now()),
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'])
          : (map['updatedAt']?.toDate() ?? DateTime.now()),
    );
  }
}
