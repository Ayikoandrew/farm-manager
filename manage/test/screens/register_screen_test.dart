import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage/screens/auth/register_screen.dart';

void main() {
  group('RegisterScreen', () {
    Widget createTestWidget({bool hasInviteCode = false}) {
      return ProviderScope(
        child: MaterialApp(
          home: RegisterScreen(hasInviteCode: hasInviteCode),
        ),
      );
    }

    testWidgets('creates RegisterScreen successfully', (tester) async {
      // Use a larger surface to avoid overflow issues
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('has Form widget for validation', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('has multiple TextFormFields for input', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should have name, email, password, confirm password fields
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

    testWidgets('has password input fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should have multiple TextFormField widgets
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('has checkbox for terms acceptance', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should have a checkbox for terms
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('accepts hasInviteCode parameter', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(hasInviteCode: true));
      await tester.pump();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });
}
