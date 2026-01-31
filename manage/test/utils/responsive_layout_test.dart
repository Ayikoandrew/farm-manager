import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage/utils/responsive_layout.dart';

void main() {
  group('Breakpoints', () {
    test('mobile breakpoint is 600', () {
      expect(Breakpoints.mobile, 600);
    });

    test('tablet breakpoint is 900', () {
      expect(Breakpoints.tablet, 900);
    });

    test('desktop breakpoint is 1200', () {
      expect(Breakpoints.desktop, 1200);
    });

    test('widescreen breakpoint is 1800', () {
      expect(Breakpoints.widescreen, 1800);
    });

    test('breakpoints are in ascending order', () {
      expect(Breakpoints.mobile, lessThan(Breakpoints.tablet));
      expect(Breakpoints.tablet, lessThan(Breakpoints.desktop));
      expect(Breakpoints.desktop, lessThan(Breakpoints.widescreen));
    });
  });

  group('DeviceType', () {
    test('DeviceType has all expected values', () {
      expect(DeviceType.values.length, 4);
      expect(DeviceType.values, contains(DeviceType.mobile));
      expect(DeviceType.values, contains(DeviceType.tablet));
      expect(DeviceType.values, contains(DeviceType.desktop));
      expect(DeviceType.values, contains(DeviceType.widescreen));
    });
  });

  group('getDeviceType', () {
    testWidgets('returns mobile for width < 600', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(getDeviceType(context), DeviceType.mobile);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns tablet for width >= 600 and < 900', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1024)),
          child: Builder(
            builder: (context) {
              expect(getDeviceType(context), DeviceType.tablet);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns desktop for width >= 900 and < 1200', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: Builder(
            builder: (context) {
              expect(getDeviceType(context), DeviceType.desktop);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns widescreen for width >= 1200', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(getDeviceType(context), DeviceType.widescreen);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('isMobile', () {
    testWidgets('returns true for width < 600', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(isMobile(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns false for width >= 600', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, 800)),
          child: Builder(
            builder: (context) {
              expect(isMobile(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('isTabletOrLarger', () {
    testWidgets('returns false for width < 600', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(500, 800)),
          child: Builder(
            builder: (context) {
              expect(isTabletOrLarger(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns true for width >= 600', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 800)),
          child: Builder(
            builder: (context) {
              expect(isTabletOrLarger(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('isDesktopOrLarger', () {
    testWidgets('returns false for width < 900', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Builder(
            builder: (context) {
              expect(isDesktopOrLarger(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns true for width >= 900', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 800)),
          child: Builder(
            builder: (context) {
              expect(isDesktopOrLarger(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('isWidescreen', () {
    testWidgets('returns false for width < 1200', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1100, 800)),
          child: Builder(
            builder: (context) {
              expect(isWidescreen(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('returns true for width >= 1200', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(isWidescreen(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('ResponsiveLayout Widget', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ResponsiveLayout(child: Text('Test Content'))),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('applies padding when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              padding: EdgeInsets.all(16),
              child: Text('Padded Content'),
            ),
          ),
        ),
      );

      expect(find.text('Padded Content'), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('uses default maxWidth of 1200', (tester) async {
      const layout = ResponsiveLayout(child: Text('Content'));
      expect(layout.maxWidth, 1200);
    });

    testWidgets('accepts custom maxWidth', (tester) async {
      const layout = ResponsiveLayout(maxWidth: 800, child: Text('Content'));
      expect(layout.maxWidth, 800);
    });

    testWidgets('centerOnLargeScreens defaults to true', (tester) async {
      const layout = ResponsiveLayout(child: Text('Content'));
      expect(layout.centerOnLargeScreens, isTrue);
    });
  });

  group('ResponsiveBody Widget', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ResponsiveBody(child: Text('Body Content'))),
        ),
      );

      expect(find.text('Body Content'), findsOneWidget);
    });

    testWidgets('uses default maxWidth of 1200', (tester) async {
      const body = ResponsiveBody(child: Text('Content'));
      expect(body.maxWidth, 1200);
    });

    testWidgets('uses default padding of 16', (tester) async {
      const body = ResponsiveBody(child: Text('Content'));
      expect(body.padding, const EdgeInsets.all(16));
    });

    testWidgets('accepts custom padding', (tester) async {
      const body = ResponsiveBody(
        padding: EdgeInsets.all(24),
        child: Text('Content'),
      );
      expect(body.padding, const EdgeInsets.all(24));
    });

    testWidgets('wraps in SingleChildScrollView', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveBody(child: Text('Scrollable Content')),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('EdgeInsetsExtension', () {
    test('horizontal returns sum of left and right for EdgeInsets', () {
      const insets = EdgeInsets.symmetric(horizontal: 20, vertical: 10);
      expect(insets.horizontal, 40);
    });

    test('horizontal returns correct value for asymmetric EdgeInsets', () {
      const insets = EdgeInsets.only(left: 10, right: 30);
      expect(insets.horizontal, 40);
    });
  });

  group('ResponsiveGrid Widget', () {
    testWidgets('renders all children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGrid(
              children: const [Text('Item 1'), Text('Item 2'), Text('Item 3')],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('uses default column values', (tester) async {
      const grid = ResponsiveGrid(children: []);
      expect(grid.mobileColumns, 2);
      expect(grid.tabletColumns, 3);
      expect(grid.desktopColumns, 4);
      expect(grid.widescreenColumns, 5);
    });

    testWidgets('uses default spacing', (tester) async {
      const grid = ResponsiveGrid(children: []);
      expect(grid.spacing, 12);
      expect(grid.runSpacing, 12);
    });

    testWidgets('accepts custom column counts', (tester) async {
      const grid = ResponsiveGrid(
        mobileColumns: 1,
        tabletColumns: 2,
        desktopColumns: 3,
        widescreenColumns: 4,
        children: [],
      );
      expect(grid.mobileColumns, 1);
      expect(grid.tabletColumns, 2);
      expect(grid.desktopColumns, 3);
      expect(grid.widescreenColumns, 4);
    });

    testWidgets('uses GridView.builder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ResponsiveGrid(children: const [Text('Item')])),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('ResponsiveStatGrid Widget', () {
    testWidgets('renders all children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveStatGrid(
              children: const [
                Card(child: Text('Stat 1')),
                Card(child: Text('Stat 2')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Stat 1'), findsOneWidget);
      expect(find.text('Stat 2'), findsOneWidget);
    });

    testWidgets('uses default spacing of 12', (tester) async {
      const grid = ResponsiveStatGrid(children: []);
      expect(grid.spacing, 12);
    });
  });

  group('ResponsiveListGrid Widget', () {
    testWidgets('renders all children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveListGrid(
              children: const [Text('List Item 1'), Text('List Item 2')],
            ),
          ),
        ),
      );

      expect(find.text('List Item 1'), findsOneWidget);
      expect(find.text('List Item 2'), findsOneWidget);
    });

    testWidgets('uses default minItemWidth of 300', (tester) async {
      const grid = ResponsiveListGrid(children: []);
      expect(grid.minItemWidth, 300);
    });

    testWidgets('uses default spacing values', (tester) async {
      const grid = ResponsiveListGrid(children: []);
      expect(grid.spacing, 12);
      expect(grid.runSpacing, 12);
    });

    testWidgets('shows as Column on mobile width', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveListGrid(
              children: const [Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('ResponsiveTwoColumn Widget', () {
    testWidgets('renders both columns', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveTwoColumn(
              leftColumn: Text('Left'),
              rightColumn: Text('Right'),
            ),
          ),
        ),
      );

      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
    });

    testWidgets('uses default flex values of 1', (tester) async {
      const twoColumn = ResponsiveTwoColumn(
        leftColumn: Text('Left'),
        rightColumn: Text('Right'),
      );
      expect(twoColumn.leftFlex, 1);
      expect(twoColumn.rightFlex, 1);
    });

    testWidgets('uses default spacing of 24', (tester) async {
      const twoColumn = ResponsiveTwoColumn(
        leftColumn: Text('Left'),
        rightColumn: Text('Right'),
      );
      expect(twoColumn.spacing, 24);
    });

    testWidgets('accepts custom flex values', (tester) async {
      const twoColumn = ResponsiveTwoColumn(
        leftColumn: Text('Left'),
        rightColumn: Text('Right'),
        leftFlex: 2,
        rightFlex: 3,
      );
      expect(twoColumn.leftFlex, 2);
      expect(twoColumn.rightFlex, 3);
    });
  });

  group('ResponsiveBuilder Widget', () {
    testWidgets('renders mobile widget by default', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              mobile: Text('Mobile'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('falls back to mobile when other widgets are null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ResponsiveBuilder(mobile: Text('Mobile Only'))),
        ),
      );

      expect(find.text('Mobile Only'), findsOneWidget);
    });

    testWidgets('mobile widget is required', (tester) async {
      // This is a compile-time check, just verify the widget can be created
      const builder = ResponsiveBuilder(mobile: Text('Required Mobile'));
      expect(builder.mobile, isNotNull);
      expect(builder.tablet, isNull);
      expect(builder.desktop, isNull);
      expect(builder.widescreen, isNull);
    });
  });
}
