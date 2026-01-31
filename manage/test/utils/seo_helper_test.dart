import 'package:flutter_test/flutter_test.dart';
import 'package:manage/utils/seo_helper.dart';

void main() {
  group('SeoHelper Constants', () {
    test('appName is correct', () {
      expect(SeoHelper.appName, 'Farm Manager');
    });

    test('baseUrl is correct', () {
      expect(SeoHelper.baseUrl, 'https://farmmanager.com');
    });

    test('defaultImage uses baseUrl', () {
      expect(SeoHelper.defaultImage, contains(SeoHelper.baseUrl));
      expect(SeoHelper.defaultImage, contains('Icon-512.png'));
    });
  });

  group('SeoHelper.configurePage', () {
    test('method exists and accepts required parameters', () {
      // Just verify the method can be called without errors
      // On non-web platforms, it returns early
      expect(
        () => SeoHelper.configurePage(
          title: 'Test Page',
          description: 'Test description',
        ),
        returnsNormally,
      );
    });

    test('method accepts optional parameters', () {
      expect(
        () => SeoHelper.configurePage(
          title: 'Test Page',
          description: 'Test description',
          path: '/test',
          image: 'https://example.com/image.png',
          keywords: ['test', 'keywords'],
        ),
        returnsNormally,
      );
    });
  });

  group('SeoHelper Page Configurations', () {
    test('configureHomePage does not throw', () {
      expect(() => SeoHelper.configureHomePage(), returnsNormally);
    });

    test('configureAnimalsPage does not throw', () {
      expect(() => SeoHelper.configureAnimalsPage(), returnsNormally);
    });

    test('configureAnimalDetailPage does not throw', () {
      expect(
        () => SeoHelper.configureAnimalDetailPage('Bessie', 'Cattle'),
        returnsNormally,
      );
    });

    test('configureFeedingPage does not throw', () {
      expect(() => SeoHelper.configureFeedingPage(), returnsNormally);
    });

    test('configureWeightPage does not throw', () {
      expect(() => SeoHelper.configureWeightPage(), returnsNormally);
    });

    test('configureBreedingPage does not throw', () {
      expect(() => SeoHelper.configureBreedingPage(), returnsNormally);
    });

    test('configureHealthPage does not throw', () {
      expect(() => SeoHelper.configureHealthPage(), returnsNormally);
    });

    test('configureMlAnalyticsPage does not throw', () {
      expect(() => SeoHelper.configureMlAnalyticsPage(), returnsNormally);
    });

    test('configureFinancialPage does not throw', () {
      expect(() => SeoHelper.configureFinancialPage(), returnsNormally);
    });
  });

  group('SeoHelper Method Signatures', () {
    test('configureAnimalDetailPage accepts animal name and species', () {
      // Verify method signature with various inputs
      expect(
        () => SeoHelper.configureAnimalDetailPage('Pig #123', 'Pig'),
        returnsNormally,
      );
      expect(
        () => SeoHelper.configureAnimalDetailPage('Cow-001', 'Cattle'),
        returnsNormally,
      );
      expect(
        () => SeoHelper.configureAnimalDetailPage('Sheep A', 'Sheep'),
        returnsNormally,
      );
    });

    test('configurePage title is required', () {
      // This is validated at compile time, but we can verify it works
      expect(
        () => SeoHelper.configurePage(title: '', description: 'Description'),
        returnsNormally,
      );
    });

    test('configurePage description is required', () {
      expect(
        () => SeoHelper.configurePage(title: 'Title', description: ''),
        returnsNormally,
      );
    });

    test('configurePage handles empty keywords list', () {
      expect(
        () => SeoHelper.configurePage(
          title: 'Title',
          description: 'Description',
          keywords: [],
        ),
        returnsNormally,
      );
    });

    test('configurePage handles single keyword', () {
      expect(
        () => SeoHelper.configurePage(
          title: 'Title',
          description: 'Description',
          keywords: ['single'],
        ),
        returnsNormally,
      );
    });

    test('configurePage handles many keywords', () {
      expect(
        () => SeoHelper.configurePage(
          title: 'Title',
          description: 'Description',
          keywords: ['one', 'two', 'three', 'four', 'five'],
        ),
        returnsNormally,
      );
    });
  });

  group('SeoHelper Edge Cases', () {
    test('handles special characters in title', () {
      expect(
        () => SeoHelper.configurePage(
          title: 'Test & Title <Special>',
          description: 'Description',
        ),
        returnsNormally,
      );
    });

    test('handles unicode in description', () {
      expect(
        () => SeoHelper.configurePage(
          title: 'Title',
          description: 'Description with émojis 🐰',
        ),
        returnsNormally,
      );
    });

    test('handles long path', () {
      expect(
        () => SeoHelper.configurePage(
          title: 'Title',
          description: 'Description',
          path: '/very/long/path/to/some/resource/deep/in/the/app',
        ),
        returnsNormally,
      );
    });

    test('handles absolute image URL', () {
      expect(
        () => SeoHelper.configurePage(
          title: 'Title',
          description: 'Description',
          image: 'https://cdn.example.com/images/farm.jpg',
        ),
        returnsNormally,
      );
    });
  });
}
