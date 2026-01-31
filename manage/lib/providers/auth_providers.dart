import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user.dart';
import '../models/invite_code.dart';
import '../repositories/auth_repository.dart';

export '../models/user.dart' show FarmMembership, UserRole;
export '../models/invite_code.dart' show InviteCode, InviteCodeValidation;
export '../repositories/auth_repository.dart' show TeamMemberResult;

/// Provider for the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream provider for Firebase Auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Stream provider for current app user with full profile
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.watchCurrentUser();
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(data: (user) => user != null, orElse: () => false);
});

/// Provider for checking if auth state is loading
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});

/// Notifier for managing auth operations using modern Riverpod pattern
class AuthNotifier extends Notifier<AsyncValue<AppUser?>> {
  late AuthRepository _repository;

  @override
  AsyncValue<AppUser?> build() {
    _repository = ref.watch(authRepositoryProvider);
    _init();
    return const AsyncValue.loading();
  }

  void _init() {
    _repository.watchCurrentUser().listen(
      (user) async {
        if (user != null) {
          // Run migration to ensure user has 'roles' array in farm memberships
          await _repository.migrateUserFarmRoles();
        }
        state = AsyncValue.data(user);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.signInWithEmail(
      email: email,
      password: password,
    );
    if (result.success && result.user != null) {
      state = AsyncValue.data(result.user);
    } else {
      // Keep current state on failure, error is in result
      state = const AsyncValue.data(null);
    }
    return result;
  }

  Future<AuthResult> registerWithEmail(
    String email,
    String password,
    String? displayName,
  ) async {
    state = const AsyncValue.loading();
    final result = await _repository.registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    if (result.success && result.user != null) {
      state = AsyncValue.data(result.user);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  Future<AuthResult> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await _repository.signInWithGoogle();
    if (result.success && result.user != null) {
      state = AsyncValue.data(result.user);
    } else {
      state = const AsyncValue.data(null);
    }
    return result;
  }

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    return await _repository.sendPasswordResetEmail(email);
  }

  Future<AuthResult> resendVerificationEmail(String email) async {
    return await _repository.resendVerificationEmail(email);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }

  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    final result = await _repository.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      phoneNumber: phoneNumber,
    );

    // Update provider state with the new user data
    if (result.success && result.user != null) {
      state = AsyncValue.data(result.user);
    }

    return result;
  }

  Future<String> createFarm(String farmName) async {
    return await _repository.createFarm(farmName);
  }

  Future<void> setActiveFarm(String farmId) async {
    await _repository.setActiveFarm(farmId);
  }

  /// Validate an invite code without using it
  /// Use this to show the user what role/farm they're joining before confirming
  Future<InviteCodeValidation> validateInviteCode(String code) async {
    return await _repository.validateInviteCode(code);
  }

  /// Check if there are any pending invite codes for a specific email
  Future<List<InviteCode>> getPendingInvitesForEmail(String email) async {
    return await _repository.getPendingInvitesForEmail(email);
  }

  /// Join a farm using an invite code
  Future<FarmMembership?> joinFarmWithCode(String code) async {
    return await _repository.joinFarmWithCode(code);
  }

  /// Generate an invite code for a farm (owner/manager only)
  /// Returns code like "MGR-ABC123" where prefix indicates role
  Future<String?> generateInviteCode(
    String farmId,
    UserRole role, {
    required String email,
    int maxUses = 1,
    Duration validity = const Duration(days: 7),
  }) async {
    return await _repository.generateInviteCode(
      farmId,
      role,
      email: email,
      maxUses: maxUses,
      validity: validity,
    );
  }

  /// Create a team member account directly (owner/manager only)
  /// Returns credentials to share with the new team member
  Future<TeamMemberResult> createTeamMember({
    required String farmId,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    return await _repository.createTeamMember(
      farmId: farmId,
      email: email,
      name: name,
      role: role,
    );
  }

  Future<AuthResult> deleteAccount() async {
    final result = await _repository.deleteAccount();
    if (result.success) {
      state = const AsyncValue.data(null);
    }
    return result;
  }
}

/// Provider for AuthNotifier
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<AppUser?>>(() {
      return AuthNotifier();
    });

/// Provider for current user's primary role in active farm
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user?.activeRole,
    orElse: () => null,
  );
});

/// Provider for all current user's roles in active farm
final currentUserRolesProvider = Provider<List<UserRole>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user?.activeRoles ?? [],
    orElse: () => [],
  );
});

/// Provider to check if current user has a specific role (exact match)
final hasExactRoleProvider = Provider.family<bool, UserRole>((ref, role) {
  final roles = ref.watch(currentUserRolesProvider);
  return roles.contains(role);
});

/// Provider to check if current user has a specific role or higher
final hasRoleProvider = Provider.family<bool, UserRole>((ref, requiredRole) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user?.hasRoleOrHigher(requiredRole) ?? false,
    orElse: () => false,
  );
});

/// Provider for farm members - watches all members of the active farm
final farmMembersProvider = StreamProvider<List<FarmMember>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;

  if (user == null || user.activeFarmId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(authRepositoryProvider);
  return repository.watchFarmMembers(user.activeFarmId!);
});

/// Provider for removing a farm member
final removeFarmMemberProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return (String farmId, String memberUserId) async {
    return await repository.removeFarmMember(
      farmId: farmId,
      memberUserId: memberUserId,
    );
  };
});

/// Provider for changing a member's role(s)
final changeMemberRoleProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return (
    String farmId,
    String memberUserId,
    UserRole newRole, {
    List<UserRole>? additionalRoles,
  }) async {
    return await repository.changeMemberRole(
      farmId: farmId,
      memberUserId: memberUserId,
      newRole: newRole,
      additionalRoles: additionalRoles,
    );
  };
});

/// Model for admin notifications
class AdminNotification {
  final String id;
  final String type;
  final String userId;
  final String? farmId;
  final String title;
  final String message;
  final String? category;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool read;

  AdminNotification({
    required this.id,
    required this.type,
    required this.userId,
    this.farmId,
    required this.title,
    required this.message,
    this.category,
    this.actionUrl,
    this.metadata,
    required this.createdAt,
    this.readAt,
    required this.read,
  });

  factory AdminNotification.fromSupabase(Map<String, dynamic> data) {
    return AdminNotification(
      id: data['id'] ?? '',
      type: data['type'] ?? '',
      userId: data['user_id'] ?? '',
      farmId: data['farm_id'],
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      category: data['category'],
      actionUrl: data['action_url'],
      metadata: data['metadata'] is Map
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      readAt: data['read_at'] != null
          ? DateTime.tryParse(data['read_at'])
          : null,
      read: data['is_read'] ?? false,
    );
  }
}

/// Provider for admin notifications (team member joins, etc.)
final adminNotificationsProvider = StreamProvider<List<AdminNotification>>((
  ref,
) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);

      return SupabaseConfig.client
          .from('admin_notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50)
          .map(
            (data) =>
                data.map((row) => AdminNotification.fromSupabase(row)).toList(),
          );
    },
    loading: () => Stream.value([]),
    error: (e, st) => Stream.value([]),
  );
});

/// Provider for unread admin notification count
final unreadAdminNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(adminNotificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.read).length,
    orElse: () => 0,
  );
});

/// Mark an admin notification as read
Future<void> markAdminNotificationAsRead(String notificationId) async {
  await SupabaseConfig.client
      .from('admin_notifications')
      .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
      .eq('id', notificationId);
}

/// Mark all admin notifications as read for a user
Future<void> markAllAdminNotificationsAsRead(String userId) async {
  await SupabaseConfig.client
      .from('admin_notifications')
      .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
      .eq('user_id', userId)
      .eq('is_read', false);
}
