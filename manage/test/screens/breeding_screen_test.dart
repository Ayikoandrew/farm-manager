import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manage/screens/breeding/breeding_screen.dart';

void main() {
  group('BreedingScreen Widget Tests', () {
    Widget createTestWidget() {
      return const ProviderScope(
        child: MaterialApp(home: BreedingScreen()),
      );
    }

    testWidgets('should display Breeding Management title in app bar', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Breeding Management'), findsOneWidget);
    });

    testWidgets('should have tab bar with 3 tabs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('should have All tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('should have In Heat tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('In Heat'), findsOneWidget);
    });

    testWidgets('should have Pregnant tab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Pregnant'), findsOneWidget);
    });

    testWidgets('should have FAB to add new record', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Record'), findsOneWidget);
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

    testWidgets('should use DefaultTabController', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(DefaultTabController), findsOneWidget);
    });
  });

  group('BreedingScreen Tab Navigation', () {
    testWidgets('can tap on In Heat tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: BreedingScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('In Heat'));
      await tester.pumpAndSettle();

      expect(find.text('In Heat'), findsOneWidget);
    });

    testWidgets('can tap on Pregnant tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: BreedingScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Pregnant'));
      await tester.pumpAndSettle();

      expect(find.text('Pregnant'), findsOneWidget);
    });

    testWidgets('can tap on All tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: BreedingScreen()),
        ),
      );
      await tester.pump();

      // First go to another tab
      await tester.tap(find.text('Pregnant'));
      await tester.pumpAndSettle();

      // Then go back to All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
    });
  });

  group('BreedingScreen FAB', () {
    testWidgets('FAB is extended with icon and label', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: BreedingScreen()),
        ),
      );
      await tester.pump();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // Should be extended format
      expect(find.text('New Record'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
