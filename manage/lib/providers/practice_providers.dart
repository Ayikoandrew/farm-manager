import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manage/models/user.dart';
import 'package:manage/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authState = ref.watch(authRepositoryProvider);
  return authState.authStateChanges;
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final currentUserState = ref.watch(authRepositoryProvider);
  return currentUserState.watchCurrentUser();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(data: (user) => user != null, orElse: () => false);
});

class AuthNotifier extends Notifier<AsyncValue<AppUser?>> {
  late AuthRepository _repository;

  @override
  AsyncValue<AppUser?> build() {
    _repository = ref.watch(authRepositoryProvider);
    _init();
    return const AsyncLoading();
  }

  void _init() {
    _repository.watchCurrentUser().listen((user) {
      if (user != null) {
        _repository.migrateUserFarmRoles();
        state = AsyncData(user);
      }
    }, onError: (error, stackTrace) => AsyncError(error, stackTrace));
  }

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    AsyncLoading();
    final result = await _repository.signInWithEmail(
      email: email,
      password: password,
    );
    if (result.success && result.user != null) {
      state = AsyncValue.data(result.user);
    } else {
      state = AsyncValue.data(null);
    }
    return result;
  }
}
