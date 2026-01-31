// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manage/router/app_router.dart';
import 'package:manage/screens/dashboard_screen.dart';

void main() {
  setUpAll(() {
    // Initialize the coordinator before tests
    initRouter();
  });

  testWidgets('App smoke test - MaterialApp.router builds correctly', (
    WidgetTester tester,
  ) async {
    // Build our app with router and verify it builds without errors
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      ),
    );

    // Just verify the widget tree builds - actual content requires Firestore mocks
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('DashboardScreen renders scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DashboardScreen())),
    );

    // Dashboard should render a Scaffold
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('DashboardScreen has correct AppBar title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DashboardScreen())),
    );

    // AppBar should show Farm Dashboard
    expect(find.text('Farm Dashboard'), findsOneWidget);
  });
}
