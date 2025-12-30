class UserModel {
  final String uid;
  final String email;
  final String? displayName; // Legacy / Fallback
  final String? displayNameAr;
  final String? displayNameEn;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.displayNameAr,
    this.displayNameEn,
    this.photoUrl,
    this.phoneNumber,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      displayNameAr: data['displayNameAr'],
      displayNameEn: data['displayNameEn'],
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt']).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'displayNameAr': displayNameAr,
      'displayNameEn': displayNameEn,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? displayNameAr,
    String? displayNameEn,
    String? photoUrl,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      displayNameAr: displayNameAr ?? this.displayNameAr,
      displayNameEn: displayNameEn ?? this.displayNameEn,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String getLocalizedName(String languageCode) {
    if (languageCode == 'ar') {
      return displayNameAr ?? displayName ?? email.split('@')[0];
    }
    return displayNameEn ?? displayName ?? email.split('@')[0];
  }
}
