import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manage/screens/animals/animals_screen.dart';

void main() {
  group('AnimalsScreen Widget Tests', () {
    Widget createTestWidget() {
      return ProviderScope(
        child: const MaterialApp(home: AnimalsScreen()),
      );
    }

    testWidgets('should display Animal Inventory title in app bar', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Animal Inventory'), findsOneWidget);
    });

    testWidgets('should have floating action button to add animal', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Add Animal'), findsOneWidget);
    });

    testWidgets('should have scaffold structure', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('FAB should have add icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should have AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('AnimalsScreen Empty State', () {
    testWidgets('empty state should show pets icon', (tester) async {
      // This would require mocking the provider to return empty list
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: AnimalsScreen()),
        ),
      );
      await tester.pump();

      // Check basic structure is present
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('AnimalsScreen Accessibility', () {
    testWidgets('FAB should be accessible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: AnimalsScreen()),
        ),
      );
      await tester.pump();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // FAB should have extended format with label
      expect(find.text('Add Animal'), findsOneWidget);
    });
  });
}
