import 'dart:math';
import 'user.dart';

/// Invite code for joining a farm with a specific role
class InviteCode {
  final String code;
  final String farmId;
  final String farmName;
  final String? email; // Email address this invite was created for
  final UserRole role;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;
  final String? usedBy;
  final DateTime? usedAt;
  final int maxUses;
  final int useCount;

  InviteCode({
    required this.code,
    required this.farmId,
    required this.farmName,
    this.email,
    required this.role,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.used = false,
    this.usedBy,
    this.usedAt,
    this.maxUses = 1,
    this.useCount = 0,
  });

  /// Check if the invite code is valid (not expired, not fully used)
  bool get isValid {
    if (used) return false;
    if (DateTime.now().isAfter(expiresAt)) return false;
    if (maxUses > 0 && useCount >= maxUses) return false;
    return true;
  }

  /// Check if the code is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get remaining uses
  int get remainingUses =>
      maxUses > 0 ? maxUses - useCount : -1; // -1 = unlimited

  /// Get role prefix for the code
  static String getRolePrefix(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'OWN';
      case UserRole.manager:
        return 'MGR';
      case UserRole.worker:
        return 'WRK';
      case UserRole.vet:
        return 'VET';
    }
  }

  /// Parse role from code prefix
  static UserRole? getRoleFromCode(String code) {
    final upperCode = code.toUpperCase().trim();
    if (upperCode.startsWith('OWN-')) return UserRole.owner;
    if (upperCode.startsWith('MGR-')) return UserRole.manager;
    if (upperCode.startsWith('WRK-')) return UserRole.worker;
    if (upperCode.startsWith('VET-')) return UserRole.vet;
    return null; // Invalid or legacy code
  }

  /// Get human-readable role name
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.manager:
        return 'Manager';
      case UserRole.worker:
        return 'Worker';
      case UserRole.vet:
        return 'Veterinarian';
    }
  }

  /// Get role description
  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Full access to all features, can manage team members and invite others';
      case UserRole.manager:
        return 'Can add/edit animals, view reports, and manage daily operations';
      case UserRole.worker:
        return 'Can record daily activities like feeding and weight measurements';
      case UserRole.vet:
        return 'Access to health records, breeding data, and medical history';
    }
  }

  /// Generate a secure invite code with role prefix
  static String generateCode(UserRole role) {
    final prefix = getRolePrefix(role);
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final suffix = List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return '$prefix-$suffix';
  }

  /// Validate code format
  static bool isValidFormat(String code) {
    final upperCode = code.toUpperCase().trim();
    final regex = RegExp(r'^(OWN|MGR|WRK|VET)-[A-Z0-9]{6}$');
    return regex.hasMatch(upperCode);
  }

  /// Create from Supabase row (snake_case fields)
  factory InviteCode.fromSupabase(Map<String, dynamic> data) {
    return InviteCode(
      code: data['code'] ?? data['id'] ?? '',
      farmId: data['farm_id'] ?? '',
      farmName: data['farm_name'] ?? 'Unknown Farm',
      email: data['email'] as String?,
      role: UserRoleExtension.fromString(data['role'] as String),
      createdBy: data['created_by'] ?? '',
      createdAt: DateTime.parse(
        data['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: DateTime.parse(
        data['expires_at'] ??
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      ),
      used: data['is_used'] ?? false,
      usedBy: data['used_by'],
      usedAt: data['used_at'] != null ? DateTime.parse(data['used_at']) : null,
      maxUses: data['max_uses'] ?? 1,
      useCount: data['use_count'] ?? 0,
    );
  }

  /// Convert to Supabase row (snake_case fields)
  Map<String, dynamic> toSupabase() {
    return {
      'code': code,
      'farm_id': farmId,
      'farm_name': farmName,
      if (email != null) 'email': email,
      'role': role.name,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_used': used,
      'used_by': usedBy,
      'used_at': usedAt?.toIso8601String(),
      'max_uses': maxUses,
      'use_count': useCount,
    };
  }

  @override
  String toString() => 'InviteCode($code, role: ${role.name}, farm: $farmName)';
}

/// Result of validating an invite code
class InviteCodeValidation {
  final bool isValid;
  final InviteCode? inviteCode;
  final String? errorMessage;

  InviteCodeValidation._({
    required this.isValid,
    this.inviteCode,
    this.errorMessage,
  });

  factory InviteCodeValidation.valid(InviteCode code) {
    return InviteCodeValidation._(isValid: true, inviteCode: code);
  }

  factory InviteCodeValidation.invalid(String message) {
    return InviteCodeValidation._(isValid: false, errorMessage: message);
  }
}
