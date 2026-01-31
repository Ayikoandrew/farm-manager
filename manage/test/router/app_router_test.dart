import 'package:flutter_test/flutter_test.dart';
import 'package:manage/router/app_router.dart';

void main() {
  group('AppRouter Tests', () {
    setUpAll(() {
      // Initialize the coordinator once before all tests
      initRouter();
    });

    group('Route URI Parsing', () {
      test('should parse root URI to DashboardRoute', () {
        final route = coordinator.parseRouteFromUri(Uri.parse('/'));
        expect(route, isA<DashboardRoute>());
      });

      test('should parse empty path to DashboardRoute', () {
        final route = coordinator.parseRouteFromUri(Uri.parse(''));
        expect(route, isA<DashboardRoute>());
      });

      test('should parse /animals to AnimalsRoute', () {
        final route = coordinator.parseRouteFromUri(Uri.parse('/animals'));
        expect(route, isA<AnimalsRoute>());
      });

      test('should parse /animals/:id to AnimalsRoute (fallback)', () {
        final route = coordinator.parseRouteFromUri(Uri.parse('/animals/123'));
        expect(route, isA<AnimalsRoute>());
      });

      test('should parse /feeding to FeedingRoute', () {
        final route = coordinator.parseRouteFromUri(Uri.parse('/feeding'));
        expect(route, isA<FeedingRoute>());
      });

      test('should parse /weight to WeightRoute', () {
        final route = coordinator.parseRouteFromUri(Uri.parse('/weight'));
        expect(route, isA<WeightRoute>());
      });

      test('should parse /breeding to BreedingRoute', () {
        final route = coordinator.parseRouteFromUri(Uri.parse('/breeding'));
        expect(route, isA<BreedingRoute>());
      });

      test('should parse /ml to MLRoute', () {
        final route = coordinator.parseRouteFromUri(Uri.parse('/ml'));
        expect(route, isA<MLRoute>());
      });

      test('should parse unknown path to NotFoundRoute', () {
        final route = coordinator.parseRouteFromUri(Uri.parse('/unknown'));
        expect(route, isA<NotFoundRoute>());
      });

      test('should parse deeply nested unknown path to NotFoundRoute', () {
        final route = coordinator.parseRouteFromUri(
          Uri.parse('/some/deep/path'),
        );
        expect(route, isA<NotFoundRoute>());
      });
    });

    group('Route toUri()', () {
      test('DashboardRoute should return / URI', () {
        final route = DashboardRoute();
        expect(route.toUri().toString(), '/');
      });

      test('AnimalsRoute should return /animals URI', () {
        final route = AnimalsRoute();
        expect(route.toUri().toString(), '/animals');
      });

      test('FeedingRoute should return /feeding URI', () {
        final route = FeedingRoute();
        expect(route.toUri().toString(), '/feeding');
      });

      test('WeightRoute should return /weight URI', () {
        final route = WeightRoute();
        expect(route.toUri().toString(), '/weight');
      });

      test('BreedingRoute should return /breeding URI', () {
        final route = BreedingRoute();
        expect(route.toUri().toString(), '/breeding');
      });

      test('MLRoute should return /ml URI', () {
        final route = MLRoute();
        expect(route.toUri().toString(), '/ml');
      });

      test('NotFoundRoute should return /404 URI', () {
        final route = NotFoundRoute();
        expect(route.toUri().toString(), '/404');
      });
    });

    group('initRouter()', () {
      test('should initialize coordinator', () {
        // coordinator is already initialized in setUp
        expect(coordinator, isNotNull);
        expect(coordinator, isA<AppCoordinator>());
      });
    });
  });
}
