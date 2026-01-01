class FriendModel {
  final String id; // localId.toString() or remoteId
  final String userId;
  final String name;
  final String? phoneNumber;
  final double netBalance; // Calculated
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendModel({
    required this.id,
    required this.userId,
    required this.name,
    this.phoneNumber,
    this.netBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });
}
