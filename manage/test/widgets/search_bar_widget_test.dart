import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage/widgets/search_bar_widget.dart';

void main() {
  group('SearchBarWidget', () {
    testWidgets('displays hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              hintText: 'Search animals',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Search animals'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('calls onChanged when text is entered', (WidgetTester tester) async {
      String searchText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              hintText: 'Search',
              onChanged: (value) => searchText = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();

      expect(searchText, equals('test query'));
    });

    testWidgets('shows clear button when text is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              hintText: 'Search',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Initially, clear button should not be visible
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should now be visible
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clears text when clear button is pressed', (WidgetTester tester) async {
      String searchText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              hintText: 'Search',
              onChanged: (value) => searchText = value,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      expect(searchText, equals('test'));

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(searchText, equals(''));
      expect(find.byIcon(Icons.clear), findsNothing);
    });
  });
}
