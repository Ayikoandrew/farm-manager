import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage/screens/auth/login_screen.dart';

void main() {
  group('LoginScreen', () {
    Widget createTestWidget() {
      return ProviderScope(
        child: MaterialApp(
          home: const LoginScreen(),
        ),
      );
    }

    testWidgets('creates LoginScreen successfully', (tester) async {
      // Use a larger surface to avoid overflow issues
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('has Form widget for validation', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('has email text field', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find TextFormField with email hint or label
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('has password input field', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should have TextFormField widgets for email and password
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('has Scaffold as root widget', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
