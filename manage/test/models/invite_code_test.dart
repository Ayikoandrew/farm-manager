import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/invite_code.dart';
import 'package:manage/models/user.dart';

void main() {
  group('InviteCode Model', () {
    late DateTime now;
    late DateTime expiresAt;

    setUp(() {
      now = DateTime(2026, 1, 10);
      expiresAt = now.add(const Duration(days: 7));
    });

    test('should create InviteCode with required properties', () {
      final code = InviteCode(
        code: 'MGR-ABC123',
        farmId: 'farm-001',
        farmName: 'Happy Ranch',
        role: UserRole.manager,
        createdBy: 'user-001',
        createdAt: now,
        expiresAt: expiresAt,
      );

      expect(code.code, 'MGR-ABC123');
      expect(code.farmId, 'farm-001');
      expect(code.farmName, 'Happy Ranch');
      expect(code.role, UserRole.manager);
      expect(code.createdBy, 'user-001');
    });

    test('should create InviteCode with default values', () {
      final code = InviteCode(
        code: 'WRK-XYZ789',
        farmId: 'farm-001',
        farmName: 'Test Farm',
        role: UserRole.worker,
        createdBy: 'user-001',
        createdAt: now,
        expiresAt: expiresAt,
      );

      expect(code.used, false);
      expect(code.usedBy, null);
      expect(code.usedAt, null);
      expect(code.maxUses, 1);
      expect(code.useCount, 0);
    });

    test('should create InviteCode with all properties', () {
      final usedAt = now.add(const Duration(hours: 1));
      final code = InviteCode(
        code: 'VET-DEF456',
        farmId: 'farm-002',
        farmName: 'Large Farm',
        role: UserRole.vet,
        createdBy: 'admin-001',
        createdAt: now,
        expiresAt: expiresAt,
        used: true,
        usedBy: 'user-002',
        usedAt: usedAt,
        maxUses: 5,
        useCount: 2,
      );

      expect(code.used, true);
      expect(code.usedBy, 'user-002');
      expect(code.usedAt, usedAt);
      expect(code.maxUses, 5);
      expect(code.useCount, 2);
    });

    test('should handle all user roles', () {
      for (final role in UserRole.values) {
        final code = InviteCode(
          code: '${InviteCode.getRolePrefix(role)}-ABC123',
          farmId: 'farm-001',
          farmName: 'Test Farm',
          role: role,
          createdBy: 'user-001',
          createdAt: now,
          expiresAt: expiresAt,
        );

        expect(code.role, role);
      }
    });
  });

  group('InviteCode.isValid', () {
    late DateTime now;
    late DateTime futureDate;
    late DateTime pastDate;

    setUp(() {
      now = DateTime.now();
      futureDate = now.add(const Duration(days: 7));
      pastDate = now.subtract(const Duration(days: 1));
    });

    test('should be valid when not used, not expired, and uses available', () {
      final code = InviteCode(
        code: 'MGR-ABC123',
        farmId: 'farm-001',
        farmName: 'Test Farm',
        role: UserRole.manager,
        createdBy: 'user-001',
        createdAt: now,
        expiresAt: futureDate,
        used: false,
        useCount: 0,
        maxUses: 5,
      );

      expect(code.isValid, true);
    });

    test('should be invalid when used flag is true', () {
      final code = InviteCode(
        code: 'MGR-ABC123',
        farmId: 'farm-001',
        farmName: 'Test Farm',
        role: UserRole.manager,
        createdBy: 'user-001',
        createdAt: now,
        expiresAt: futureDate,
        used: true,
      );

      expect(code.isValid, false);
    });

    test('should be invalid when expired', () {
      final code = InviteCode(
        code: 'MGR-ABC123',
        farmId: 'farm-001',
        farmName: 'Test Farm',
        role: UserRole.manager,
        createdBy: 'user-001',
        createdAt: pastDate.subtract(const Duration(days: 7)),
        expiresAt: pastDate,
      );

      expect(code.isValid, false);
      expect(code.isExpired, true);
    });

    test('should be invalid when max uses reached', () {
      final code = InviteCode(
        code: 'MGR-ABC123',
        farmId: 'farm-001',
        farmName: 'Test Farm',
        role: UserRole.manager,
        createdBy: 'user-001',
        createdAt: now,
        expiresAt: futureDate,
        maxUses: 3,
        useCount: 3,
      );

      expect(code.isValid, false);
    });

    test('should calculate remaining uses correctly', () {
      final code = InviteCode(
        code: 'MGR-ABC123',
        farmId: 'farm-001',
        farmName: 'Test Farm',
        role: UserRole.manager,
        createdBy: 'user-001',
        createdAt: now,
        expiresAt: futureDate,
        maxUses: 5,
        useCount: 2,
      );

      expect(code.remainingUses, 3);
    });
  });

  group('InviteCode.generateCode', () {
    test('should generate code with correct prefix for each role', () {
      expect(InviteCode.generateCode(UserRole.owner).startsWith('OWN-'), true);
      expect(
        InviteCode.generateCode(UserRole.manager).startsWith('MGR-'),
        true,
      );
      expect(InviteCode.generateCode(UserRole.worker).startsWith('WRK-'), true);
      expect(InviteCode.generateCode(UserRole.vet).startsWith('VET-'), true);
    });

    test('should generate codes with valid format', () {
      for (final role in UserRole.values) {
        final code = InviteCode.generateCode(role);
        expect(InviteCode.isValidFormat(code), true);
      }
    });

    test('should generate unique codes', () {
      final codes = <String>{};
      for (var i = 0; i < 100; i++) {
        codes.add(InviteCode.generateCode(UserRole.manager));
      }
      // With secure random, 100 codes should all be unique
      expect(codes.length, 100);
    });

    test('should generate codes with correct length', () {
      final code = InviteCode.generateCode(UserRole.worker);
      // Format: XXX-XXXXXX (3 + 1 + 6 = 10 characters)
      expect(code.length, 10);
    });
  });

  group('InviteCode.getRolePrefix', () {
    test('should return correct prefix for each role', () {
      expect(InviteCode.getRolePrefix(UserRole.owner), 'OWN');
      expect(InviteCode.getRolePrefix(UserRole.manager), 'MGR');
      expect(InviteCode.getRolePrefix(UserRole.worker), 'WRK');
      expect(InviteCode.getRolePrefix(UserRole.vet), 'VET');
    });
  });

  group('InviteCode.getRoleFromCode', () {
    test('should parse role from valid code prefixes', () {
      expect(InviteCode.getRoleFromCode('OWN-ABC123'), UserRole.owner);
      expect(InviteCode.getRoleFromCode('MGR-ABC123'), UserRole.manager);
      expect(InviteCode.getRoleFromCode('WRK-ABC123'), UserRole.worker);
      expect(InviteCode.getRoleFromCode('VET-ABC123'), UserRole.vet);
    });

    test('should handle lowercase codes', () {
      expect(InviteCode.getRoleFromCode('own-abc123'), UserRole.owner);
      expect(InviteCode.getRoleFromCode('mgr-xyz789'), UserRole.manager);
    });

    test('should handle mixed case codes', () {
      expect(InviteCode.getRoleFromCode('Own-ABC123'), UserRole.owner);
      expect(InviteCode.getRoleFromCode('Mgr-XyZ789'), UserRole.manager);
    });

    test('should return null for invalid prefix', () {
      expect(InviteCode.getRoleFromCode('XXX-ABC123'), null);
      expect(InviteCode.getRoleFromCode('invalid'), null);
      expect(InviteCode.getRoleFromCode(''), null);
    });

    test('should handle codes with leading/trailing spaces', () {
      expect(InviteCode.getRoleFromCode('  OWN-ABC123  '), UserRole.owner);
    });
  });

  group('InviteCode.getRoleDisplayName', () {
    test('should return correct display names', () {
      expect(InviteCode.getRoleDisplayName(UserRole.owner), 'Owner');
      expect(InviteCode.getRoleDisplayName(UserRole.manager), 'Manager');
      expect(InviteCode.getRoleDisplayName(UserRole.worker), 'Worker');
      expect(InviteCode.getRoleDisplayName(UserRole.vet), 'Veterinarian');
    });
  });

  group('InviteCode.getRoleDescription', () {
    test('should return descriptions for all roles', () {
      for (final role in UserRole.values) {
        final description = InviteCode.getRoleDescription(role);
        expect(description.isNotEmpty, true);
        expect(description.length, greaterThan(20));
      }
    });

    test('owner description mentions team management', () {
      final description = InviteCode.getRoleDescription(UserRole.owner);
      expect(description.toLowerCase().contains('team'), true);
    });

    test('vet description mentions health records', () {
      final description = InviteCode.getRoleDescription(UserRole.vet);
      expect(description.toLowerCase().contains('health'), true);
    });
  });

  group('InviteCode.isValidFormat', () {
    test('should accept valid formats', () {
      expect(InviteCode.isValidFormat('OWN-ABC123'), true);
      expect(InviteCode.isValidFormat('MGR-XYZ789'), true);
      expect(InviteCode.isValidFormat('WRK-DEF456'), true);
      expect(InviteCode.isValidFormat('VET-GHI012'), true);
    });

    test('should accept lowercase codes', () {
      expect(InviteCode.isValidFormat('own-abc123'), true);
      expect(InviteCode.isValidFormat('mgr-xyz789'), true);
    });

    test('should reject invalid prefixes', () {
      expect(InviteCode.isValidFormat('XXX-ABC123'), false);
      expect(InviteCode.isValidFormat('ABC-DEF123'), false);
    });

    test('should reject wrong suffix length', () {
      expect(InviteCode.isValidFormat('MGR-ABC'), false); // Too short
      expect(InviteCode.isValidFormat('MGR-ABCDEFGH'), false); // Too long
    });

    test('should reject wrong format', () {
      expect(InviteCode.isValidFormat('MGRABC123'), false); // No dash
      expect(InviteCode.isValidFormat('MGR--ABC123'), false); // Double dash
      expect(InviteCode.isValidFormat(''), false); // Empty
    });
  });

  group('InviteCode.toFirestore', () {
    test('should convert to map correctly', () {
      final code = InviteCode(
        code: 'MGR-ABC123',
        farmId: 'farm-001',
        farmName: 'Test Farm',
        role: UserRole.manager,
        createdBy: 'user-001',
        createdAt: DateTime(2026, 1, 10),
        expiresAt: DateTime(2026, 1, 17),
        used: false,
        maxUses: 5,
        useCount: 2,
      );

      final map = code.toSupabase();

      expect(map['farm_id'], 'farm-001');
      expect(map['farm_name'], 'Test Farm');
      expect(map['role'], 'manager');
      expect(map['created_by'], 'user-001');
      expect(map['is_used'], false);
      expect(map['max_uses'], 5);
      expect(map['use_count'], 2);
    });
  });

  group('InviteCode.toString', () {
    test('should return readable string representation', () {
      final code = InviteCode(
        code: 'MGR-ABC123',
        farmId: 'farm-001',
        farmName: 'Happy Ranch',
        role: UserRole.manager,
        createdBy: 'user-001',
        createdAt: DateTime(2026, 1, 10),
        expiresAt: DateTime(2026, 1, 17),
      );

      final str = code.toString();
      expect(str.contains('MGR-ABC123'), true);
      expect(str.contains('manager'), true);
      expect(str.contains('Happy Ranch'), true);
    });
  });

  group('InviteCodeValidation', () {
    test('should create valid result', () {
      final inviteCode = InviteCode(
        code: 'MGR-ABC123',
        farmId: 'farm-001',
        farmName: 'Test Farm',
        role: UserRole.manager,
        createdBy: 'user-001',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final validation = InviteCodeValidation.valid(inviteCode);

      expect(validation.isValid, true);
      expect(validation.inviteCode, inviteCode);
      expect(validation.errorMessage, null);
    });

    test('should create invalid result with error message', () {
      final validation = InviteCodeValidation.invalid('Code has expired');

      expect(validation.isValid, false);
      expect(validation.inviteCode, null);
      expect(validation.errorMessage, 'Code has expired');
    });
  });
}
