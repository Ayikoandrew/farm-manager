import 'package:flutter/foundation.dart';
import 'package:meta_seo/meta_seo.dart';

class SeoHelper {
  static const String appName = 'Farm Manager';
  static const String baseUrl = 'https://farmmanager.com';
  static const String defaultImage = '$baseUrl/icons/Icon-512.png';

  static void configurePage({
    required String title,
    required String description,
    String? path,
    String? image,
    List<String>? keywords,
  }) {
    if (!kIsWeb) return;

    final meta = MetaSEO();
    final fullTitle = '$title | $appName';
    final pageImage = image ?? defaultImage;

    meta.author(author: 'Farm Manager Team');
    meta.description(description: description);
    meta.keywords(keywords: keywords?.join(', ') ?? _defaultKeywords);

    meta.ogTitle(ogTitle: fullTitle);
    meta.ogDescription(ogDescription: description);
    meta.ogImage(ogImage: pageImage);

    meta.twitterTitle(twitterTitle: fullTitle);
    meta.twitterDescription(twitterDescription: description);
    meta.twitterImage(twitterImage: pageImage);

    meta.robots(robotsName: RobotsName.robots, content: 'index, follow');
  }

  static void configureHomePage() {
    configurePage(
      title: 'Dashboard',
      description:
          'Farm Manager - Comprehensive livestock management application. '
          'Track animals, feeding schedules, weight records, and breeding history.',
      path: '/',
      keywords: [
        'farm management',
        'livestock',
        'animal tracking',
        'farming app',
        'agriculture',
      ],
    );
  }

  static void configureAnimalsPage() {
    configurePage(
      title: 'Animal Inventory',
      description:
          'Manage your complete animal inventory. Track cattle, sheep, goats, '
          'pigs, and poultry with detailed records and health information.',
      path: '/animals',
      keywords: [
        'animal inventory',
        'livestock management',
        'cattle tracking',
        'farm animals',
      ],
    );
  }

  static void configureAnimalDetailPage(String animalName, String species) {
    configurePage(
      title: animalName,
      description:
          'Detailed profile for $animalName ($species). '
          'View health records, weight history, and breeding information.',
      path: '/animals/detail',
      keywords: [species.toLowerCase(), 'animal profile', 'livestock record'],
    );
  }

  static void configureFeedingPage() {
    configurePage(
      title: 'Feeding Records',
      description:
          'Track and manage feeding schedules for all your livestock. '
          'Monitor feed types, quantities, and feeding patterns.',
      path: '/feeding',
      keywords: [
        'feeding schedule',
        'animal nutrition',
        'livestock feeding',
        'feed management',
      ],
    );
  }

  static void configureWeightPage() {
    configurePage(
      title: 'Weight Records',
      description:
          'Monitor weight progression of your livestock. Track growth rates '
          'and identify health trends through weight history.',
      path: '/weight',
      keywords: [
        'weight tracking',
        'animal growth',
        'livestock weight',
        'growth monitoring',
      ],
    );
  }

  static void configureBreedingPage() {
    configurePage(
      title: 'Breeding Management',
      description:
          'Manage breeding records and programs. Track mating dates, '
          'expected births, and breeding success rates.',
      path: '/breeding',
      keywords: [
        'breeding records',
        'livestock breeding',
        'animal reproduction',
        'breeding management',
      ],
    );
  }

  static void configureHealthPage() {
    configurePage(
      title: 'Health Management',
      description:
          'Track animal health records including vaccinations, medications, '
          'treatments, and vet visits. Monitor withdrawal periods and follow-ups.',
      path: '/health',
      keywords: [
        'animal health',
        'vaccination records',
        'livestock medication',
        'veterinary care',
        'health management',
        'withdrawal periods',
      ],
    );
  }

  static void configureMlAnalyticsPage() {
    configurePage(
      title: 'ML Analytics',
      description:
          'Advanced machine learning analytics for your farm. Get predictive '
          'insights on growth, health, and breeding outcomes.',
      path: '/ml-analytics',
      keywords: [
        'farm analytics',
        'machine learning',
        'predictive farming',
        'agricultural AI',
      ],
    );
  }

  static void configureFinancialPage() {
    configurePage(
      title: 'Financial Tracking',
      description:
          'Track farm income and expenses, manage budgets, analyze profitability, '
          'and generate financial reports for your livestock operation.',
      path: '/financial',
      keywords: [
        'farm finances',
        'expense tracking',
        'income management',
        'farm budget',
        'profitability analysis',
        'agricultural finance',
      ],
    );
  }

  static const String _defaultKeywords =
      'farm management, livestock, animal tracking, agriculture, farming app, '
      'cattle, sheep, goats, pigs, poultry, feeding schedule, weight tracking, '
      'breeding records, farm analytics';
}
