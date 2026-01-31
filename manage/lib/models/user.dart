/// User roles for farm access control
enum UserRole {
  owner, // Full access, can manage users
  manager, // Can add/edit records, view reports
  worker, // Can add daily records (feeding, weight)
  vet, // Access to health and breeding records
}

/// Extension to convert UserRole to/from string
extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.manager:
        return 'manager';
      case UserRole.worker:
        return 'worker';
      case UserRole.vet:
        return 'vet';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      case 'worker':
        return UserRole.worker;
      case 'vet':
        return UserRole.vet;
      default:
        return UserRole.worker;
    }
  }
}

/// Farm membership with role(s)
class FarmMembership {
  final String farmId;
  final String farmName;
  final UserRole role; // Primary role for backward compatibility
  final List<UserRole> roles; // All roles (includes primary)
  final DateTime joinedAt;

  FarmMembership({
    required this.farmId,
    required this.farmName,
    required this.role,
    List<UserRole>? roles,
    required this.joinedAt,
  }) : roles = roles ?? [role];

  /// Create from Supabase row (snake_case fields)
  factory FarmMembership.fromSupabase(Map<String, dynamic> map) {
    final primaryRole = UserRoleExtension.fromString(map['role'] ?? 'worker');
    final rolesList =
        (map['roles'] as List<dynamic>?)
            ?.map((r) => UserRoleExtension.fromString(r as String))
            .toList() ??
        [primaryRole];

    return FarmMembership(
      farmId: map['farm_id'] ?? map['farmId'] ?? '',
      farmName: map['farm_name'] ?? map['farmName'] ?? '',
      role: primaryRole,
      roles: rolesList.isNotEmpty ? rolesList : [primaryRole],
      joinedAt: map['joined_at'] != null
          ? DateTime.parse(map['joined_at'])
          : DateTime.now(),
    );
  }

  /// Convert to Supabase row (snake_case fields)
  Map<String, dynamic> toSupabase() {
    return {
      'farm_id': farmId,
      'farm_name': farmName,
      'role': role.name,
      'roles': roles.map((r) => r.name).toList(),
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated roles
  FarmMembership copyWithRoles(List<UserRole> newRoles) {
    return FarmMembership(
      farmId: farmId,
      farmName: farmName,
      role: newRoles.isNotEmpty ? newRoles.first : role,
      roles: newRoles,
      joinedAt: joinedAt,
    );
  }
}

/// App user model
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final List<FarmMembership> farms;
  final String? activeFarmId;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.farms = const [],
    this.activeFarmId,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// Get the active farm membership
  FarmMembership? get activeFarm {
    if (activeFarmId == null) return farms.isNotEmpty ? farms.first : null;
    return farms.where((f) => f.farmId == activeFarmId).firstOrNull;
  }

  /// Get the user's primary role in the active farm
  UserRole? get activeRole => activeFarm?.role;

  /// Get all user roles in the active farm
  List<UserRole> get activeRoles => activeFarm?.roles ?? [];

  /// Check if user has at least the specified role level
  /// Now checks all roles, not just the primary role
  bool hasRoleOrHigher(UserRole requiredRole) {
    final roles = activeRoles;
    if (roles.isEmpty) return false;

    const roleHierarchy = [
      UserRole.worker,
      UserRole.vet,
      UserRole.manager,
      UserRole.owner,
    ];

    final requiredIndex = roleHierarchy.indexOf(requiredRole);
    // Check if any of the user's roles meets or exceeds the required role
    return roles.any((role) => roleHierarchy.indexOf(role) >= requiredIndex);
  }

  /// Check if user has a specific role (exact match)
  bool hasRole(UserRole role) => activeRoles.contains(role);

  /// Create from Supabase row (snake_case fields)
  factory AppUser.fromSupabase(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      displayName: data['display_name'],
      photoUrl: data['photo_url'],
      phoneNumber: data['phone_number'],
      farms:
          (data['farms'] as List<dynamic>?)
              ?.map(
                (f) => FarmMembership.fromSupabase(f as Map<String, dynamic>),
              )
              .toList() ??
          [],
      activeFarmId: data['active_farm_id'],
      createdAt: DateTime.parse(
        data['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastLoginAt: data['last_login_at'] != null
          ? DateTime.parse(data['last_login_at'])
          : null,
    );
  }

  /// Convert to Supabase row (snake_case fields)
  Map<String, dynamic> toSupabase() {
    return {
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'phone_number': phoneNumber,
      'farms': farms.map((f) => f.toSupabase()).toList(),
      'active_farm_id': activeFarmId,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    List<FarmMembership>? farms,
    String? activeFarmId,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      farms: farms ?? this.farms,
      activeFarmId: activeFarmId ?? this.activeFarmId,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
