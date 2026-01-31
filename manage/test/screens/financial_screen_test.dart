import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manage/screens/financial/financial_screen.dart';

void main() {
  group('FinancialScreen Widget Tests', () {
    Widget createTestWidget() {
      return const ProviderScope(
        child: MaterialApp(home: FinancialScreen()),
      );
    }

    testWidgets('should display Financial Tracking title in app bar', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Financial Tracking'), findsOneWidget);
    });

    testWidgets('should have tab bar with 3 tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('should have Overview tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Overview'), findsOneWidget);
    });

    testWidgets('should have Income tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Income'), findsOneWidget);
    });

    testWidgets('should have Expenses tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Expenses'), findsOneWidget);
    });

    testWidgets('should have currency settings button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.currency_exchange), findsOneWidget);
    });

    testWidgets('should have reports button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
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

  group('FinancialScreen Tab Navigation', () {
    testWidgets('can tap on Income tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FinancialScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(find.text('Income'), findsOneWidget);
    });

    testWidgets('can tap on Expenses tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FinancialScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      expect(find.text('Expenses'), findsOneWidget);
    });

    testWidgets('can tap on Overview tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FinancialScreen()),
        ),
      );
      await tester.pump();

      // First go to another tab
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      // Then go back to Overview
      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
    });
  });

  group('FinancialScreen Action Buttons', () {
    testWidgets('currency button should have tooltip', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FinancialScreen()),
        ),
      );
      await tester.pump();

      final currencyButton = find.byIcon(Icons.currency_exchange);
      expect(currencyButton, findsOneWidget);

      // Long press to show tooltip
      await tester.longPress(currencyButton);
      await tester.pumpAndSettle();

      expect(find.text('Currency Settings'), findsOneWidget);
    });

    testWidgets('reports button should have tooltip', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: FinancialScreen()),
        ),
      );
      await tester.pump();

      final reportsButton = find.byIcon(Icons.bar_chart);
      expect(reportsButton, findsOneWidget);

      // Long press to show tooltip
      await tester.longPress(reportsButton);
      await tester.pumpAndSettle();

      expect(find.text('Reports'), findsOneWidget);
    });
  });
}
