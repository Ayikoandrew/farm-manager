import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manage/screens/health/health_screen.dart';

void main() {
  group('HealthScreen Widget Tests', () {
    Widget createTestWidget() {
      return const ProviderScope(
        child: MaterialApp(home: HealthScreen()),
      );
    }

    testWidgets('should display Health Management title in app bar', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Health Management'), findsOneWidget);
    });

    testWidgets('should have tab bar with 5 tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(5));
    });

    testWidgets('should have All tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('should have Vaccinations tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Vaccinations'), findsOneWidget);
    });

    testWidgets('should have Medications tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Medications'), findsOneWidget);
    });

    testWidgets('should have Treatments tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Treatments'), findsOneWidget);
    });

    testWidgets('should have Alerts tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Alerts'), findsOneWidget);
    });

    testWidgets('should have FAB to add record', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Record'), findsOneWidget);
    });

    testWidgets('FAB should have add icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should have scaffold structure', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have TabBarView for content', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TabBarView), findsOneWidget);
    });
  });

  group('HealthScreen Tab Navigation', () {
    testWidgets('can tap on Vaccinations tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HealthScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Vaccinations'));
      await tester.pumpAndSettle();

      // Tab should be selected
      expect(find.text('Vaccinations'), findsOneWidget);
    });

    testWidgets('can tap on Medications tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HealthScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Medications'));
      await tester.pumpAndSettle();

      expect(find.text('Medications'), findsOneWidget);
    });

    testWidgets('can tap on Alerts tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HealthScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      expect(find.text('Alerts'), findsOneWidget);
    });
  });
}
