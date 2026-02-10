import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage/screens/auth/profile_screen.dart';

void main() {
  group('ProfileScreen', () {
    Widget createTestWidget() {
      return ProviderScope(child: MaterialApp(home: const ProfileScreen()));
    }

    testWidgets('creates ProfileScreen successfully', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('has Scaffold as root widget', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has AppBar with Profile title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('has edit button in AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should have edit icon button in AppBar
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('shows content structure after pump', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Should have AppBar with Profile title
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
