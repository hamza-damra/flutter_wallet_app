class AppAvatars {
  AppAvatars._();

  static const String basePath = 'assets/avatars/';

  static const List<String> avatarList = [
    '${basePath}avatar_1.svg',
    '${basePath}avatar_2.svg',
    '${basePath}avatar_3.svg',
    '${basePath}avatar_4.svg',
    '${basePath}avatar_5.svg',
    '${basePath}avatar_6.svg',
    '${basePath}avatar_7.svg',
    '${basePath}avatar_8.svg',
    '${basePath}avatar_9.svg',
    '${basePath}avatar_10.svg',
    '${basePath}avatar_11.svg',
    '${basePath}avatar_12.svg',
  ];

  static String getDefaultAvatar() => avatarList[0];

  static bool isAppAvatar(String? photoUrl) {
    if (photoUrl == null) return false;
    return avatarList.contains(photoUrl);
  }
}
