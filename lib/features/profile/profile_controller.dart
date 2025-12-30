import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ProfileController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> updateProfile({
    String? displayNameAr,
    String? displayNameEn,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      state = AsyncValue.error('No user logged in', StackTrace.current);
      return;
    }

    final currentProfile = ref.read(userProfileProvider).value;

    final updatedProfile =
        currentProfile?.copyWith(
          displayNameAr: displayNameAr,
          displayNameEn: displayNameEn,
          phoneNumber: phoneNumber,
          photoUrl: photoUrl,
        ) ??
        UserModel(
          uid: user.uid,
          email: user.email!,
          displayNameAr: displayNameAr,
          displayNameEn: displayNameEn,
          phoneNumber: phoneNumber,
          photoUrl: photoUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    state = await AsyncValue.guard(() async {
      if (currentProfile == null) {
        await ref.read(firestoreServiceProvider).createUser(updatedProfile);
      } else {
        await ref.read(firestoreServiceProvider).updateUser(updatedProfile);
      }
    });
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, AsyncValue<void>>(
      ProfileController.new,
    );
