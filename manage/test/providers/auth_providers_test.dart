import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage/providers/auth_providers.dart';

void main() {
  group('Auth Provider Type Verification', () {
    test('authRepositoryProvider is a Provider', () {
      expect(authRepositoryProvider, isA<Provider>());
    });

    test('authStateProvider is a StreamProvider', () {
      expect(authStateProvider, isA<StreamProvider>());
    });

    test('currentUserProvider is a StreamProvider', () {
      expect(currentUserProvider, isA<StreamProvider>());
    });

    test('isAuthenticatedProvider is a Provider', () {
      expect(isAuthenticatedProvider, isA<Provider>());
    });

    test('isAuthLoadingProvider is a Provider', () {
      expect(isAuthLoadingProvider, isA<Provider>());
    });

    test('currentUserRoleProvider is a Provider', () {
      expect(currentUserRoleProvider, isA<Provider>());
    });

    test('currentUserRolesProvider is a Provider', () {
      expect(currentUserRolesProvider, isA<Provider>());
    });

    test('farmMembersProvider is a StreamProvider', () {
      expect(farmMembersProvider, isA<StreamProvider>());
    });

    test('removeFarmMemberProvider is a Provider', () {
      expect(removeFarmMemberProvider, isA<Provider>());
    });

    test('changeMemberRoleProvider is a Provider', () {
      expect(changeMemberRoleProvider, isA<Provider>());
    });

    test('authNotifierProvider is a NotifierProvider', () {
      expect(authNotifierProvider, isA<NotifierProvider>());
    });
  });

  group('AdminNotification Model', () {
    test('creates instance with required fields', () {
      final notification = AdminNotification(
        id: 'notif-1',
        type: 'member_joined',
        recipientUserId: 'user-1',
        farmId: 'farm-1',
        farmName: 'Test Farm',
        createdAt: DateTime.now(),
        read: false,
      );

      expect(notification.id, 'notif-1');
      expect(notification.type, 'member_joined');
      expect(notification.recipientUserId, 'user-1');
      expect(notification.farmId, 'farm-1');
      expect(notification.farmName, 'Test Farm');
      expect(notification.read, isFalse);
    });

    test('creates instance with optional fields', () {
      final notification = AdminNotification(
        id: 'notif-2',
        type: 'member_joined',
        recipientUserId: 'user-1',
        farmId: 'farm-1',
        farmName: 'Test Farm',
        joinerUserId: 'joiner-1',
        joinerName: 'John Doe',
        joinerEmail: 'john@example.com',
        joinerRole: 'worker',
        createdAt: DateTime.now(),
        read: true,
      );

      expect(notification.joinerUserId, 'joiner-1');
      expect(notification.joinerName, 'John Doe');
      expect(notification.joinerEmail, 'john@example.com');
      expect(notification.joinerRole, 'worker');
      expect(notification.read, isTrue);
    });

    test('handles null optional fields', () {
      final notification = AdminNotification(
        id: 'notif-3',
        type: 'member_removed',
        recipientUserId: 'user-1',
        farmId: 'farm-1',
        farmName: 'Test Farm',
        createdAt: DateTime.now(),
        read: false,
      );

      expect(notification.joinerUserId, isNull);
      expect(notification.joinerName, isNull);
      expect(notification.removedBy, isNull);
      expect(notification.removedByName, isNull);
    });
  });

  group('UserRole enum', () {
    test('UserRole has expected values', () {
      expect(UserRole.values, contains(UserRole.owner));
      expect(UserRole.values, contains(UserRole.manager));
      expect(UserRole.values, contains(UserRole.worker));
      expect(UserRole.values, contains(UserRole.vet));
    });

    test('UserRole values count', () {
      expect(UserRole.values.length, 4);
    });
  });

  group('Exported Types', () {
    test('FarmMembership is exported', () {
      expect(FarmMembership, isNotNull);
    });

    test('InviteCode is exported', () {
      expect(InviteCode, isNotNull);
    });

    test('InviteCodeValidation is exported', () {
      expect(InviteCodeValidation, isNotNull);
    });

    test('TeamMemberResult is exported', () {
      expect(TeamMemberResult, isNotNull);
    });
  });

  group('Family Providers', () {
    test('hasRoleProvider is a Provider.family', () {
      // Just verify it can be called with a role
      final provider = hasRoleProvider(UserRole.owner);
      expect(provider, isNotNull);
    });

    test('hasExactRoleProvider is a Provider.family', () {
      final provider = hasExactRoleProvider(UserRole.manager);
      expect(provider, isNotNull);
    });
  });
}
