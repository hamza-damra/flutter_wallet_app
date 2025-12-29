class UserModel {
  final String uid;
  final String email;
  final DateTime createdAt;

  UserModel({required this.uid, required this.email, required this.createdAt});

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt']).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'createdAt': createdAt};
  }
}
