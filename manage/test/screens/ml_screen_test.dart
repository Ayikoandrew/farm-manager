import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manage/screens/ml/ml_screen.dart';

void main() {
  group('MLScreen Widget Tests', () {
    Widget createTestWidget() {
      return const ProviderScope(child: MaterialApp(home: MLScreen()));
    }

    testWidgets('should display ML Analytics title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ML Analytics'), findsOneWidget);
    });

    testWidgets('should display Machine Learning Hub header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Machine Learning Hub'), findsOneWidget);
      expect(find.text('AI-powered insights for your farm'), findsOneWidget);
    });

    testWidgets('should display all ML model categories', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Weight Predictions'), findsOneWidget);
      expect(find.text('Health Analytics'), findsOneWidget);
      expect(find.text('Breeding Analytics'), findsOneWidget);
      expect(find.text('Feed Optimization'), findsOneWidget);
    });

    testWidgets('should display Growth Forecast model card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Growth Forecast'), findsOneWidget);
      expect(
        find.text('Predict future weight based on historical data'),
        findsOneWidget,
      );
    });

    testWidgets('should display Health Risk Assessment model card', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Health Risk Assessment'), findsOneWidget);
      expect(
        find.text('Identify animals at risk based on patterns'),
        findsOneWidget,
      );
    });

    testWidgets('should display Fertility Prediction model card', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Fertility Prediction'), findsOneWidget);
      expect(
        find.text('Predict optimal breeding times and success rates'),
        findsOneWidget,
      );
    });

    testWidgets('should display Feed Efficiency Analysis model card', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Feed Efficiency Analysis'), findsOneWidget);
      expect(
        find.text('Optimize feed-to-weight conversion ratios'),
        findsOneWidget,
      );
    });

    // Note: Visualizations section was removed from current UI

    testWidgets('should display Data Summary section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Data Summary'), findsOneWidget);
      expect(find.text('Available Training Data'), findsOneWidget);
    });

    testWidgets('should display data record types in summary', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Animal Records'), findsOneWidget);
      expect(find.text('Weight Records'), findsOneWidget);
      expect(find.text('Feeding Records'), findsOneWidget);
      expect(find.text('Breeding Records'), findsOneWidget);
    });

    // Note: Export Data and Train Models buttons were removed from current UI

    testWidgets('should display refresh button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should show snackbar when refresh is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('Refreshing ML data...'), findsOneWidget);
    });

    testWidgets('should display status chips with Not Trained label', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // All models start as Not Trained
      expect(find.text('Not Trained'), findsWidgets);
    });

    testWidgets('should have scrollable content', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should display stat items in header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Models'), findsOneWidget);
      expect(find.text('Predictions'), findsOneWidget);
      expect(find.text('Records'), findsOneWidget);
    });
  });
}
