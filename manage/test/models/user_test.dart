import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/user.dart';

void main() {
  group('UserRole', () {
    test('all roles are defined', () {
      expect(UserRole.values.length, 4);
      expect(UserRole.values, contains(UserRole.owner));
      expect(UserRole.values, contains(UserRole.manager));
      expect(UserRole.values, contains(UserRole.worker));
      expect(UserRole.values, contains(UserRole.vet));
    });

    test('name returns correct string value', () {
      expect(UserRole.owner.name, 'owner');
      expect(UserRole.manager.name, 'manager');
      expect(UserRole.worker.name, 'worker');
      expect(UserRole.vet.name, 'vet');
    });

    test('fromString converts correctly', () {
      expect(UserRoleExtension.fromString('owner'), UserRole.owner);
      expect(UserRoleExtension.fromString('manager'), UserRole.manager);
      expect(UserRoleExtension.fromString('worker'), UserRole.worker);
      expect(UserRoleExtension.fromString('vet'), UserRole.vet);
    });

    test('fromString handles case insensitivity', () {
      expect(UserRoleExtension.fromString('OWNER'), UserRole.owner);
      expect(UserRoleExtension.fromString('Manager'), UserRole.manager);
      expect(UserRoleExtension.fromString('WORKER'), UserRole.worker);
    });

    test('fromString defaults to worker for unknown values', () {
      expect(UserRoleExtension.fromString('unknown'), UserRole.worker);
      expect(UserRoleExtension.fromString('admin'), UserRole.worker);
      expect(UserRoleExtension.fromString(''), UserRole.worker);
    });
  });

  group('FarmMembership', () {
    test('should create FarmMembership with required properties', () {
      final membership = FarmMembership(
        farmId: 'farm-001',
        farmName: 'Green Acres Farm',
        role: UserRole.owner,
        joinedAt: DateTime(2025, 1, 1),
      );

      expect(membership.farmId, 'farm-001');
      expect(membership.farmName, 'Green Acres Farm');
      expect(membership.role, UserRole.owner);
      expect(membership.roles, [UserRole.owner]);
    });

    test('should create FarmMembership with multiple roles', () {
      final membership = FarmMembership(
        farmId: 'farm-001',
        farmName: 'Green Acres Farm',
        role: UserRole.manager,
        roles: [UserRole.manager, UserRole.vet],
        joinedAt: DateTime(2025, 1, 1),
      );

      expect(membership.role, UserRole.manager);
      expect(membership.roles.length, 2);
      expect(membership.roles, contains(UserRole.manager));
      expect(membership.roles, contains(UserRole.vet));
    });

    test('fromSupabase should parse correctly', () {
      final map = {
        'farm_id': 'farm-002',
        'farm_name': 'Sunny Farms',
        'role': 'manager',
        'roles': ['manager', 'worker'],
        'joined_at': null, // Will default to DateTime.now()
      };

      final membership = FarmMembership.fromSupabase(map);

      expect(membership.farmId, 'farm-002');
      expect(membership.farmName, 'Sunny Farms');
      expect(membership.role, UserRole.manager);
      expect(membership.roles.length, 2);
    });

    test('toSupabase should convert correctly', () {
      final membership = FarmMembership(
        farmId: 'farm-001',
        farmName: 'Test Farm',
        role: UserRole.worker,
        joinedAt: DateTime(2025, 6, 15),
      );

      final map = membership.toSupabase();

      expect(map['farm_id'], 'farm-001');
      expect(map['farm_name'], 'Test Farm');
      expect(map['role'], 'worker');
      expect(map['roles'], ['worker']);
    });

    test('copyWithRoles should update roles correctly', () {
      final membership = FarmMembership(
        farmId: 'farm-001',
        farmName: 'Test Farm',
        role: UserRole.worker,
        joinedAt: DateTime(2025, 1, 1),
      );

      final updated = membership.copyWithRoles([
        UserRole.manager,
        UserRole.vet,
      ]);

      expect(updated.role, UserRole.manager); // First role becomes primary
      expect(updated.roles.length, 2);
      expect(updated.farmId, 'farm-001'); // Unchanged
    });
  });

  group('AppUser Model', () {
    late AppUser user;
    late DateTime createdAt;

    setUp(() {
      createdAt = DateTime(2025, 1, 1);
      user = AppUser(
        id: 'user-001',
        email: 'farmer@example.com',
        displayName: 'John Farmer',
        photoUrl: 'https://example.com/photo.jpg',
        phoneNumber: '+256700123456',
        farms: [
          FarmMembership(
            farmId: 'farm-001',
            farmName: 'Green Acres',
            role: UserRole.owner,
            joinedAt: createdAt,
          ),
          FarmMembership(
            farmId: 'farm-002',
            farmName: 'Sunny Fields',
            role: UserRole.manager,
            joinedAt: createdAt,
          ),
        ],
        activeFarmId: 'farm-001',
        createdAt: createdAt,
        lastLoginAt: DateTime(2026, 1, 10),
      );
    });

    test('should create AppUser with all properties', () {
      expect(user.id, 'user-001');
      expect(user.email, 'farmer@example.com');
      expect(user.displayName, 'John Farmer');
      expect(user.phoneNumber, '+256700123456');
      expect(user.farms.length, 2);
      expect(user.activeFarmId, 'farm-001');
    });

    test('activeFarm returns correct farm membership', () {
      expect(user.activeFarm, isNotNull);
      expect(user.activeFarm!.farmId, 'farm-001');
      expect(user.activeFarm!.farmName, 'Green Acres');
    });

    test('activeFarm returns first farm when activeFarmId is null', () {
      final userNoActive = AppUser(
        id: 'user-002',
        email: 'test@example.com',
        farms: [
          FarmMembership(
            farmId: 'farm-003',
            farmName: 'Default Farm',
            role: UserRole.worker,
            joinedAt: createdAt,
          ),
        ],
        createdAt: createdAt,
      );

      expect(userNoActive.activeFarm, isNotNull);
      expect(userNoActive.activeFarm!.farmId, 'farm-003');
    });

    test('activeFarm returns null for user with no farms', () {
      final userNoFarms = AppUser(
        id: 'user-003',
        email: 'nofarms@example.com',
        farms: [],
        createdAt: createdAt,
      );

      expect(userNoFarms.activeFarm, isNull);
    });

    test('activeRole returns correct role', () {
      expect(user.activeRole, UserRole.owner);
    });

    test('activeRoles returns all roles for active farm', () {
      expect(user.activeRoles, contains(UserRole.owner));
    });

    test('hasRoleOrHigher works correctly for owner', () {
      expect(user.hasRoleOrHigher(UserRole.worker), true);
      expect(user.hasRoleOrHigher(UserRole.vet), true);
      expect(user.hasRoleOrHigher(UserRole.manager), true);
      expect(user.hasRoleOrHigher(UserRole.owner), true);
    });

    test('hasRoleOrHigher works correctly for manager', () {
      final managerUser = AppUser(
        id: 'user-004',
        email: 'manager@example.com',
        farms: [
          FarmMembership(
            farmId: 'farm-001',
            farmName: 'Test Farm',
            role: UserRole.manager,
            joinedAt: createdAt,
          ),
        ],
        activeFarmId: 'farm-001',
        createdAt: createdAt,
      );

      expect(managerUser.hasRoleOrHigher(UserRole.worker), true);
      expect(managerUser.hasRoleOrHigher(UserRole.vet), true);
      expect(managerUser.hasRoleOrHigher(UserRole.manager), true);
      expect(managerUser.hasRoleOrHigher(UserRole.owner), false);
    });

    test('hasRoleOrHigher works correctly for worker', () {
      final workerUser = AppUser(
        id: 'user-005',
        email: 'worker@example.com',
        farms: [
          FarmMembership(
            farmId: 'farm-001',
            farmName: 'Test Farm',
            role: UserRole.worker,
            joinedAt: createdAt,
          ),
        ],
        activeFarmId: 'farm-001',
        createdAt: createdAt,
      );

      expect(workerUser.hasRoleOrHigher(UserRole.worker), true);
      expect(workerUser.hasRoleOrHigher(UserRole.vet), false);
      expect(workerUser.hasRoleOrHigher(UserRole.manager), false);
      expect(workerUser.hasRoleOrHigher(UserRole.owner), false);
    });

    test('hasRoleOrHigher returns false for user with no farms', () {
      final noFarmsUser = AppUser(
        id: 'user-006',
        email: 'nofarms@example.com',
        farms: [],
        createdAt: createdAt,
      );

      expect(noFarmsUser.hasRoleOrHigher(UserRole.worker), false);
    });

    test('hasRoleOrHigher works with multiple roles', () {
      final multiRoleUser = AppUser(
        id: 'user-007',
        email: 'multi@example.com',
        farms: [
          FarmMembership(
            farmId: 'farm-001',
            farmName: 'Test Farm',
            role: UserRole.worker,
            roles: [UserRole.worker, UserRole.vet],
            joinedAt: createdAt,
          ),
        ],
        activeFarmId: 'farm-001',
        createdAt: createdAt,
      );

      expect(multiRoleUser.hasRoleOrHigher(UserRole.worker), true);
      expect(multiRoleUser.hasRoleOrHigher(UserRole.vet), true);
      expect(multiRoleUser.hasRoleOrHigher(UserRole.manager), false);
    });

    test('copyWith should create new instance with updated values', () {
      final updatedUser = user.copyWith(
        displayName: 'Jane Farmer',
        activeFarmId: 'farm-002',
      );

      expect(updatedUser.displayName, 'Jane Farmer');
      expect(updatedUser.activeFarmId, 'farm-002');
      expect(updatedUser.id, user.id); // Unchanged
      expect(updatedUser.email, user.email); // Unchanged
    });

    test('should handle user without optional fields', () {
      final minimalUser = AppUser(
        id: 'user-008',
        email: 'minimal@example.com',
        createdAt: createdAt,
      );

      expect(minimalUser.displayName, isNull);
      expect(minimalUser.photoUrl, isNull);
      expect(minimalUser.phoneNumber, isNull);
      expect(minimalUser.farms, isEmpty);
      expect(minimalUser.lastLoginAt, isNull);
    });
  });
}
