import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/invite_code.dart';
import '../models/user.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final AppUser? user;

  AuthResult({required this.success, this.errorMessage, this.user});

  factory AuthResult.success(AppUser user) =>
      AuthResult(success: true, user: user);

  factory AuthResult.failure(String message) =>
      AuthResult(success: false, errorMessage: message);
}

/// Result of creating a team member account
class TeamMemberResult {
  final bool success;
  final String? errorMessage;
  final String? email;
  final String? inviteCode;
  final String? name;
  final UserRole? role;
  final String? farmName;

  TeamMemberResult({
    required this.success,
    this.errorMessage,
    this.email,
    this.inviteCode,
    this.name,
    this.role,
    this.farmName,
  });

  factory TeamMemberResult.success({
    required String email,
    required String inviteCode,
    required String name,
    required UserRole role,
    required String farmName,
  }) => TeamMemberResult(
    success: true,
    email: email,
    inviteCode: inviteCode,
    name: name,
    role: role,
    farmName: farmName,
  );

  factory TeamMemberResult.failure(String message) =>
      TeamMemberResult(success: false, errorMessage: message);
}

/// Represents a member of a farm with their details
class FarmMember {
  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final List<UserRole> roles;
  final DateTime joinedAt;

  FarmMember({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.roles,
    required this.joinedAt,
  });

  /// Primary role (highest priority role)
  UserRole get primaryRole => roles.isNotEmpty ? roles.first : UserRole.worker;

  String get displayNameOrEmail => displayName ?? email;
}

/// Repository for handling Supabase Authentication
class AuthRepository {
  final SupabaseClient _client = SupabaseConfig.client;
  static const String _usersTable = 'users';
  static const String _farmsTable = 'farms';
  static const String _inviteCodesTable = 'invite_codes';

  /// Stream of auth state changes
  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user);

  /// Current Supabase user
  User? get currentUser => _client.auth.currentUser;

  /// Stream of current app user - watches both auth state AND database
  Stream<AppUser?> watchCurrentUser() {
    return authStateChanges.switchMap((user) {
      if (user == null) return Stream.value(null);
      return watchAppUser(user.id);
    });
  }

  /// Get app user by ID
  Future<AppUser?> getAppUser(String userId) async {
    final response = await _client
        .from(_usersTable)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return AppUser.fromSupabase(response);
  }

  /// Watch app user by ID
  Stream<AppUser?> watchAppUser(String userId) {
    return _client
        .from(_usersTable)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) return null;
          return AppUser.fromSupabase(data.first);
        });
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return AuthResult.failure('Sign in failed');
      }

      // Check if user document exists, create if not
      AppUser? appUser = await getAppUser(response.user!.id);
      if (appUser == null) {
        appUser = await _createUserDocument(response.user!);
      } else {
        // Update last login
        await _updateLastLogin(response.user!.id);
      }

      return AuthResult.success(appUser);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.message));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Register with email and password
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      if (response.user == null) {
        return AuthResult.failure('Registration failed');
      }

      // Create user document in database
      final appUser = await _createUserDocument(
        response.user!,
        displayName: displayName,
      );

      return AuthResult.success(appUser);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.message));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // For web, use Supabase OAuth flow (redirects to Google)
      if (kIsWeb) {
        // Get the current URL origin for redirect (works for both local and deployed)
        final redirectUrl = Uri.base.origin;
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
        // OAuth flow redirects the page, so we return success
        // The actual user will be available after redirect
        return AuthResult(success: true);
      }

      // For mobile, use native Google Sign-In
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        return AuthResult.failure(
          'Google sign in is not supported on this platform',
        );
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        return AuthResult.failure('Failed to get Google authentication token');
      }

      // Sign in with Supabase using Google ID token
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );

      if (response.user == null) {
        return AuthResult.failure('Google sign in failed');
      }

      // Check if user document exists, create if not
      AppUser? appUser = await getAppUser(response.user!.id);
      if (appUser == null) {
        appUser = await _createUserDocument(
          response.user!,
          displayName: googleUser.displayName,
          photoUrl: googleUser.photoUrl,
        );
      } else {
        await _updateLastLogin(response.user!.id);
      }

      return AuthResult.success(appUser);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.message));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.message));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Resend email verification
  Future<AuthResult> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email.trim());
      return AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e.message));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
    // Only sign out from Google if supported
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore errors if Google Sign-In wasn't initialized
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return AuthResult.failure('Not signed in');
      }

      // Update user metadata in Supabase Auth
      if (displayName != null) {
        await _client.auth.updateUser(
          UserAttributes(data: {'display_name': displayName}),
        );
      }

      // Update database record
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (displayName != null) updates['display_name'] = displayName;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;

      await _client.from(_usersTable).update(updates).eq('id', user.id);

      final appUser = await getAppUser(user.id);
      return AuthResult.success(appUser!);
    } catch (e) {
      return AuthResult.failure('Failed to update profile');
    }
  }

  /// Update user's active farm
  Future<void> setActiveFarm(String farmId) async {
    final user = currentUser;
    if (user == null) return;

    await _client
        .from(_usersTable)
        .update({'active_farm_id': farmId})
        .eq('id', user.id);
  }

  /// Create a new farm and add user as owner
  Future<String> createFarm(String farmName) async {
    final user = currentUser;
    if (user == null) throw Exception('Not signed in');

    // Create farm document
    final farmResponse = await _client
        .from(_farmsTable)
        .insert({
          'name': farmName,
          'owner_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final farmId = farmResponse['id'] as String;

    // Get current user data to update farms array
    final userData = await _client
        .from(_usersTable)
        .select('farms')
        .eq('id', user.id)
        .single();

    final currentFarms = (userData['farms'] as List<dynamic>?) ?? [];

    // Add farm membership to user
    final membership = FarmMembership(
      farmId: farmId,
      farmName: farmName,
      role: UserRole.owner,
      joinedAt: DateTime.now(),
    );

    await _client
        .from(_usersTable)
        .update({
          'farms': [...currentFarms, membership.toSupabase()],
          'active_farm_id': farmId,
        })
        .eq('id', user.id);

    return farmId;
  }

  /// Create a team member invite
  Future<TeamMemberResult> createTeamMember({
    required String farmId,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    final user = currentUser;
    if (user == null) {
      return TeamMemberResult.failure('Not signed in');
    }

    // Get farm details
    final farmData = await _client
        .from(_farmsTable)
        .select('name')
        .eq('id', farmId)
        .maybeSingle();

    if (farmData == null) {
      return TeamMemberResult.failure('Farm not found');
    }
    final farmName = farmData['name'] as String;

    try {
      // Generate a personal invite code for this team member
      final code = InviteCode.generateCode(role);
      final expiresAt = DateTime.now().add(const Duration(days: 7));

      // Store the invite
      await _client.from(_inviteCodesTable).insert({
        'code': code,
        'farm_id': farmId,
        'farm_name': farmName,
        'role': role.name,
        'created_by': user.id,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_used': false,
        'max_uses': 1,
        'use_count': 0,
        'email': email.trim(),
      });

      return TeamMemberResult.success(
        email: email.trim(),
        inviteCode: code,
        name: name,
        role: role,
        farmName: farmName,
      );
    } catch (e) {
      return TeamMemberResult.failure('Failed to create invite: $e');
    }
  }

  /// Generate an invite code for a farm with role-specific prefix
  Future<String?> generateInviteCode(
    String farmId,
    UserRole role, {
    required String email,
    int maxUses = 1,
    Duration validity = const Duration(days: 7),
  }) async {
    final user = currentUser;
    if (user == null) return null;

    // Get farm name for the invite
    final farmData = await _client
        .from(_farmsTable)
        .select('name')
        .eq('id', farmId)
        .maybeSingle();

    if (farmData == null) return null;
    final farmName = farmData['name'] as String;

    // Generate a secure code with role prefix
    final code = InviteCode.generateCode(role);
    final expiresAt = DateTime.now().add(validity);

    await _client.from(_inviteCodesTable).insert({
      'code': code,
      'farm_id': farmId,
      'farm_name': farmName,
      'email': email.toLowerCase().trim(),
      'role': role.name,
      'created_by': user.id,
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_used': false,
      'max_uses': maxUses,
      'use_count': 0,
    });

    return code;
  }

  /// Validate an invite code without using it
  Future<InviteCodeValidation> validateInviteCode(String code) async {
    final normalizedCode = code.toUpperCase().trim();

    // First check format
    if (!InviteCode.isValidFormat(normalizedCode)) {
      return InviteCodeValidation.invalid(
        'Invalid code format. Codes should look like: MGR-ABC123',
      );
    }

    final inviteData = await _client
        .from(_inviteCodesTable)
        .select()
        .eq('code', normalizedCode)
        .maybeSingle();

    if (inviteData == null) {
      return InviteCodeValidation.invalid('Invite code not found');
    }

    final inviteCode = InviteCode.fromSupabase(inviteData);

    if (inviteCode.isExpired) {
      return InviteCodeValidation.invalid('This invite code has expired');
    }

    if (inviteCode.used ||
        (inviteCode.maxUses > 0 && inviteCode.useCount >= inviteCode.maxUses)) {
      return InviteCodeValidation.invalid(
        'This invite code has already been used',
      );
    }

    // Check if the invite code was created for a specific email
    final user = currentUser;
    if (user != null &&
        inviteCode.email != null &&
        inviteCode.email!.isNotEmpty) {
      final userEmail = user.email?.toLowerCase().trim();
      final inviteEmail = inviteCode.email!.toLowerCase().trim();

      if (userEmail != inviteEmail) {
        return InviteCodeValidation.invalid(
          'This invite code was created for a different email address ($inviteEmail)',
        );
      }
    }

    // Check if user is already a member of this farm
    if (user != null) {
      final appUser = await getAppUser(user.id);
      if (appUser != null) {
        final alreadyMember = appUser.farms.any(
          (f) => f.farmId == inviteCode.farmId,
        );
        if (alreadyMember) {
          return InviteCodeValidation.invalid(
            'You are already a member of this farm',
          );
        }
      }
    }

    return InviteCodeValidation.valid(inviteCode);
  }

  /// Check if there are any pending invite codes for a specific email
  Future<List<InviteCode>> getPendingInvitesForEmail(String email) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();

      final results = await _client
          .from(_inviteCodesTable)
          .select()
          .eq('email', normalizedEmail)
          .eq('is_used', false)
          .gte('expires_at', DateTime.now().toIso8601String());

      return (results as List)
          .map((data) => InviteCode.fromSupabase(data))
          .where((invite) => invite.isValid)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Join a farm using an invite code
  Future<FarmMembership?> joinFarmWithCode(String code) async {
    final user = currentUser;
    if (user == null) return null;

    final normalizedCode = code.toUpperCase().trim();

    try {
      // Get the invite
      final inviteData = await _client
          .from(_inviteCodesTable)
          .select()
          .eq('code', normalizedCode)
          .single();

      final inviteCode = InviteCode.fromSupabase(inviteData);

      // Check if expired
      if (inviteCode.isExpired) {
        throw Exception('This invite code has expired');
      }

      // Check if already used
      if (inviteCode.used ||
          (inviteCode.maxUses > 0 &&
              inviteCode.useCount >= inviteCode.maxUses)) {
        throw Exception('This invite code has already been used');
      }

      // Check if the invite code was created for a specific email
      if (inviteCode.email != null && inviteCode.email!.isNotEmpty) {
        final userEmail = user.email?.toLowerCase().trim();
        final inviteEmail = inviteCode.email!.toLowerCase().trim();

        if (userEmail != inviteEmail) {
          throw Exception(
            'This invite code was created for $inviteEmail, but you are signed in as $userEmail',
          );
        }
      }

      // Check if user is already a member of this farm
      final appUser = await getAppUser(user.id);
      if (appUser != null) {
        final alreadyMember = appUser.farms.any(
          (f) => f.farmId == inviteCode.farmId,
        );
        if (alreadyMember) {
          throw Exception('You are already a member of this farm');
        }
      }

      // Create membership
      final membership = FarmMembership(
        farmId: inviteCode.farmId,
        farmName: inviteCode.farmName,
        role: inviteCode.role,
        roles: [inviteCode.role],
        joinedAt: DateTime.now(),
      );

      // Mark invite as used
      if (inviteCode.maxUses == 1) {
        await _client
            .from(_inviteCodesTable)
            .update({
              'is_used': true,
              'used_by': user.id,
              'used_at': DateTime.now().toIso8601String(),
              'use_count': inviteCode.useCount + 1,
            })
            .eq('code', normalizedCode);
      } else {
        await _client
            .from(_inviteCodesTable)
            .update({'use_count': inviteCode.useCount + 1})
            .eq('code', normalizedCode);
      }

      // Get current farms and add new membership
      final userData = await _client
          .from(_usersTable)
          .select('farms')
          .eq('id', user.id)
          .single();

      final currentFarms = (userData['farms'] as List<dynamic>?) ?? [];

      await _client
          .from(_usersTable)
          .update({
            'farms': [...currentFarms, membership.toSupabase()],
            'active_farm_id': inviteCode.farmId,
          })
          .eq('id', user.id);

      return membership;
    } catch (e) {
      return null;
    }
  }

  /// Delete account
  Future<AuthResult> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        return AuthResult.failure('Not signed in');
      }

      // Delete user document
      await _client.from(_usersTable).delete().eq('id', user.id);

      // Note: Deleting Supabase Auth user requires admin API or Edge Function
      // For now, just sign out
      await signOut();

      return AuthResult(success: true);
    } catch (e) {
      return AuthResult.failure('Failed to delete account');
    }
  }

  /// Create user document in database
  Future<AppUser> _createUserDocument(
    User supabaseUser, {
    String? displayName,
    String? photoUrl,
  }) async {
    final appUser = AppUser(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName: displayName ?? supabaseUser.userMetadata?['display_name'],
      photoUrl: photoUrl ?? supabaseUser.userMetadata?['avatar_url'],
      phoneNumber: supabaseUser.phone,
      farms: [],
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    try {
      // First check if user already exists (might be created by database trigger)
      final existing = await _client
          .from(_usersTable)
          .select('id')
          .eq('id', supabaseUser.id)
          .maybeSingle();

      if (existing != null) {
        // User exists (created by trigger), just update with additional info
        await _client
            .from(_usersTable)
            .update({
              'display_name': appUser.displayName,
              'photo_url': appUser.photoUrl,
              'phone_number': appUser.phoneNumber,
              'last_login_at': DateTime.now().toIso8601String(),
            })
            .eq('id', supabaseUser.id);
      } else {
        // User doesn't exist, try to create
        await _client.from(_usersTable).insert({
          'id': supabaseUser.id,
          ...appUser.toSupabase(),
        });
      }
    } catch (e) {
      // If insert fails due to RLS, the trigger should have created the user
      // Try to fetch the user instead
      debugPrint('User document creation note: $e');
    }

    // Return the user data (either created or fetched)
    final userData = await getAppUser(supabaseUser.id);
    return userData ?? appUser;
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String userId) async {
    await _client
        .from(_usersTable)
        .update({'last_login_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  // ==================== FARM SETTINGS ====================

  /// Get farm settings
  Future<Map<String, dynamic>?> getFarmSettings(String farmId) async {
    return await _client
        .from(_farmsTable)
        .select()
        .eq('id', farmId)
        .maybeSingle();
  }

  /// Watch farm settings
  Stream<Map<String, dynamic>?> watchFarmSettings(String farmId) {
    return _client
        .from(_farmsTable)
        .stream(primaryKey: ['id'])
        .eq('id', farmId)
        .map((data) => data.isEmpty ? null : data.first);
  }

  /// Update farm currency
  Future<void> updateFarmCurrency(String farmId, String currencyCode) async {
    await _client
        .from(_farmsTable)
        .update({
          'currency': currencyCode,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', farmId);
  }

  /// Update farm settings
  Future<void> updateFarmSettings(
    String farmId,
    Map<String, dynamic> settings,
  ) async {
    await _client
        .from(_farmsTable)
        .update({...settings, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', farmId);
  }

  // ==================== TEAM MANAGEMENT ====================

  /// Get all members of a farm
  Future<List<FarmMember>> getFarmMembers(String farmId) async {
    // Query all users who have this farm in their farms array
    final allUsers = await _client.from(_usersTable).select();
    final members = <FarmMember>[];

    for (final userData in allUsers) {
      final user = AppUser.fromSupabase(userData);
      final farmMembership = user.farms
          .where((f) => f.farmId == farmId)
          .firstOrNull;

      if (farmMembership != null) {
        final roles = List<UserRole>.from(farmMembership.roles);
        roles.sort((a, b) {
          const roleOrder = {
            UserRole.owner: 0,
            UserRole.manager: 1,
            UserRole.vet: 2,
            UserRole.worker: 3,
          };
          return (roleOrder[a] ?? 4).compareTo(roleOrder[b] ?? 4);
        });

        members.add(
          FarmMember(
            userId: user.id,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
            roles: roles,
            joinedAt: farmMembership.joinedAt,
          ),
        );
      }
    }

    members.sort((a, b) {
      const roleOrder = {
        UserRole.owner: 0,
        UserRole.manager: 1,
        UserRole.vet: 2,
        UserRole.worker: 3,
      };
      return (roleOrder[a.primaryRole] ?? 4).compareTo(
        roleOrder[b.primaryRole] ?? 4,
      );
    });

    return members;
  }

  /// Watch farm members (stream version)
  Stream<List<FarmMember>> watchFarmMembers(String farmId) {
    return _client.from(_usersTable).stream(primaryKey: ['id']).map((snapshot) {
      final members = <FarmMember>[];

      for (final userData in snapshot) {
        final user = AppUser.fromSupabase(userData);
        final farmMembership = user.farms
            .where((f) => f.farmId == farmId)
            .firstOrNull;

        if (farmMembership != null) {
          final roles = List<UserRole>.from(farmMembership.roles);
          roles.sort((a, b) {
            const roleOrder = {
              UserRole.owner: 0,
              UserRole.manager: 1,
              UserRole.vet: 2,
              UserRole.worker: 3,
            };
            return (roleOrder[a] ?? 4).compareTo(roleOrder[b] ?? 4);
          });

          members.add(
            FarmMember(
              userId: user.id,
              email: user.email,
              displayName: user.displayName,
              photoUrl: user.photoUrl,
              roles: roles,
              joinedAt: farmMembership.joinedAt,
            ),
          );
        }
      }

      members.sort((a, b) {
        const roleOrder = {
          UserRole.owner: 0,
          UserRole.manager: 1,
          UserRole.vet: 2,
          UserRole.worker: 3,
        };
        return (roleOrder[a.primaryRole] ?? 4).compareTo(
          roleOrder[b.primaryRole] ?? 4,
        );
      });

      return members;
    });
  }

  /// Remove a member from a farm
  Future<bool> removeFarmMember({
    required String farmId,
    required String memberUserId,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    // Get current user's role in this farm
    final currentAppUser = await getAppUser(user.id);
    if (currentAppUser == null) return false;

    final currentMembership = currentAppUser.farms
        .where((f) => f.farmId == farmId)
        .firstOrNull;
    if (currentMembership == null) return false;

    // Only owners and managers can remove members
    if (currentMembership.role != UserRole.owner &&
        currentMembership.role != UserRole.manager) {
      return false;
    }

    // Get the member being removed
    final memberUser = await getAppUser(memberUserId);
    if (memberUser == null) return false;

    final memberMembership = memberUser.farms
        .where((f) => f.farmId == farmId)
        .firstOrNull;
    if (memberMembership == null) return false;

    // Can't remove yourself
    if (memberUserId == user.id) return false;

    // Can't remove an owner
    if (memberMembership.role == UserRole.owner) return false;

    // Managers can only remove workers and vets, not other managers
    if (currentMembership.role == UserRole.manager &&
        memberMembership.role == UserRole.manager) {
      return false;
    }

    // Remove the farm from member's farms array
    final updatedFarms = memberUser.farms
        .where((f) => f.farmId != farmId)
        .map((f) => f.toSupabase())
        .toList();

    // Update the member's document
    final updateData = <String, dynamic>{'farms': updatedFarms};

    if (memberUser.activeFarmId == farmId) {
      updateData['active_farm_id'] = updatedFarms.isNotEmpty
          ? updatedFarms.first['farm_id']
          : null;
    }

    await _client.from(_usersTable).update(updateData).eq('id', memberUserId);

    return true;
  }

  /// Change a member's role(s) in a farm
  Future<bool> changeMemberRole({
    required String farmId,
    required String memberUserId,
    required UserRole newRole,
    List<UserRole>? additionalRoles,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    // Get current user's role
    final currentAppUser = await getAppUser(user.id);
    if (currentAppUser == null) return false;

    final currentMembership = currentAppUser.farms
        .where((f) => f.farmId == farmId)
        .firstOrNull;
    if (currentMembership == null) return false;

    // Only owners can change roles
    if (currentMembership.role != UserRole.owner) return false;

    // Combine primary and additional roles
    final allNewRoles = <UserRole>{newRole};
    if (additionalRoles != null) {
      allNewRoles.addAll(additionalRoles);
    }

    // Can't change your own role if you're the only owner
    if (memberUserId == user.id && !allNewRoles.contains(UserRole.owner)) {
      final members = await getFarmMembers(farmId);
      final ownerCount = members
          .where((m) => m.roles.contains(UserRole.owner))
          .length;
      if (ownerCount <= 1) return false;
    }

    // Can't set someone as owner (for security)
    if (allNewRoles.contains(UserRole.owner)) return false;

    // Get the member
    final memberUser = await getAppUser(memberUserId);
    if (memberUser == null) return false;

    // Update the member's farms array with new role(s)
    final updatedFarms = memberUser.farms.map((f) {
      if (f.farmId == farmId) {
        return FarmMembership(
          farmId: f.farmId,
          farmName: f.farmName,
          role: newRole,
          roles: allNewRoles.toList(),
          joinedAt: f.joinedAt,
        ).toSupabase();
      }
      return f.toSupabase();
    }).toList();

    await _client
        .from(_usersTable)
        .update({'farms': updatedFarms})
        .eq('id', memberUserId);

    return true;
  }

  /// Convert auth error messages to user-friendly messages
  String _getAuthErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (message.contains('Email not confirmed')) {
      return 'Please verify your email address';
    }
    if (message.contains('User already registered')) {
      return 'An account already exists with this email';
    }
    if (message.contains('Password should be at least')) {
      return 'Password is too weak. Use at least 6 characters';
    }
    if (message.contains('Invalid email')) {
      return 'Invalid email address';
    }
    if (message.contains('Email rate limit exceeded')) {
      return 'Too many attempts. Please try again later';
    }
    return message;
  }

  /// Migrate existing farm memberships to include 'roles' array
  Future<void> migrateUserFarmRoles() async {
    final user = currentUser;
    if (user == null) return;

    final userData = await _client
        .from(_usersTable)
        .select('farms')
        .eq('id', user.id)
        .maybeSingle();

    if (userData == null) return;

    final farms = userData['farms'] as List<dynamic>? ?? [];

    bool needsUpdate = false;
    final updatedFarms = farms.map((farmData) {
      final farm = farmData as Map<String, dynamic>;
      final role = farm['role'] as String?;
      final existingRoles = farm['roles'] as List<dynamic>?;

      if (existingRoles == null || existingRoles.isEmpty) {
        needsUpdate = true;
        return {
          ...farm,
          'roles': [role ?? 'worker'],
        };
      }
      return farm;
    }).toList();

    if (needsUpdate) {
      await _client
          .from(_usersTable)
          .update({'farms': updatedFarms})
          .eq('id', user.id);
    }
  }
}
