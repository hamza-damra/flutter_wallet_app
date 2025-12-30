import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final currentProfile = ref.read(userProfileProvider).value;
    if (currentProfile == null) {
      state = AsyncValue.error('User profile not found', StackTrace.current);
      return;
    }

    final updatedProfile = currentProfile.copyWith(
      displayNameAr: displayNameAr,
      displayNameEn: displayNameEn,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
    );

    state = await AsyncValue.guard(() async {
      await ref.read(firestoreServiceProvider).updateUser(updatedProfile);
    });
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, AsyncValue<void>>(
      ProfileController.new,
    );
