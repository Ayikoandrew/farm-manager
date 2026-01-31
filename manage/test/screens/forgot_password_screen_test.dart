import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage/screens/auth/forgot_password_screen.dart';

void main() {
  group('ForgotPasswordScreen', () {
    Widget createTestWidget() {
      return ProviderScope(
        child: MaterialApp(
          home: const ForgotPasswordScreen(),
        ),
      );
    }

    testWidgets('creates ForgotPasswordScreen successfully', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('has Scaffold as root widget', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has Form widget for validation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('has AppBar with back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
      // AppBar should have back button somewhere in widget tree
      expect(find.byIcon(Icons.arrow_back), findsWidgets);
    });

    testWidgets('has email text field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('uses SafeArea for proper layout', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(SafeArea), findsWidgets);
    });
  });
}
