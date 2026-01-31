import 'package:intl/intl.dart';

/// Supported currencies in the app
enum Currency {
  usd, // US Dollar
  ugx, // Ugandan Shilling
  kes, // Kenyan Shilling
  tzs, // Tanzanian Shilling
  rwf, // Rwandan Franc
  eur, // Euro
  gbp, // British Pound
  zar, // South African Rand
  ngn, // Nigerian Naira
  ghs, // Ghanaian Cedi
  etb, // Ethiopian Birr
  xof, // West African CFA Franc
  xaf, // Central African CFA Franc
}

/// Currency configuration with symbol, code, and formatting details
class CurrencyConfig {
  final Currency currency;
  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;
  final bool symbolBefore; // true if symbol comes before the amount

  const CurrencyConfig({
    required this.currency,
    required this.code,
    required this.symbol,
    required this.name,
    this.decimalDigits = 2,
    this.symbolBefore = true,
  });

  /// Get all supported currencies
  static List<CurrencyConfig> get all => [
    const CurrencyConfig(
      currency: Currency.usd,
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar',
    ),
    const CurrencyConfig(
      currency: Currency.ugx,
      code: 'UGX',
      symbol: 'UGX',
      name: 'Ugandan Shilling',
      decimalDigits: 0,
    ),
    const CurrencyConfig(
      currency: Currency.kes,
      code: 'KES',
      symbol: 'KSh',
      name: 'Kenyan Shilling',
    ),
    const CurrencyConfig(
      currency: Currency.tzs,
      code: 'TZS',
      symbol: 'TSh',
      name: 'Tanzanian Shilling',
      decimalDigits: 0,
    ),
    const CurrencyConfig(
      currency: Currency.rwf,
      code: 'RWF',
      symbol: 'FRw',
      name: 'Rwandan Franc',
      decimalDigits: 0,
    ),
    const CurrencyConfig(
      currency: Currency.eur,
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
    ),
    const CurrencyConfig(
      currency: Currency.gbp,
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
    ),
    const CurrencyConfig(
      currency: Currency.zar,
      code: 'ZAR',
      symbol: 'R',
      name: 'South African Rand',
    ),
    const CurrencyConfig(
      currency: Currency.ngn,
      code: 'NGN',
      symbol: '₦',
      name: 'Nigerian Naira',
    ),
    const CurrencyConfig(
      currency: Currency.ghs,
      code: 'GHS',
      symbol: 'GH₵',
      name: 'Ghanaian Cedi',
    ),
    const CurrencyConfig(
      currency: Currency.etb,
      code: 'ETB',
      symbol: 'Br',
      name: 'Ethiopian Birr',
    ),
    const CurrencyConfig(
      currency: Currency.xof,
      code: 'XOF',
      symbol: 'CFA',
      name: 'West African CFA Franc',
      decimalDigits: 0,
    ),
    const CurrencyConfig(
      currency: Currency.xaf,
      code: 'XAF',
      symbol: 'FCFA',
      name: 'Central African CFA Franc',
      decimalDigits: 0,
    ),
  ];

  /// Get currency config by currency enum
  static CurrencyConfig fromCurrency(Currency currency) {
    return all.firstWhere(
      (c) => c.currency == currency,
      orElse: () => all.first, // Default to USD
    );
  }

  /// Get currency config by code string
  static CurrencyConfig fromCode(String code) {
    return all.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => all.first, // Default to USD
    );
  }

  /// Get currency config by currency name (enum name)
  static CurrencyConfig fromName(String name) {
    try {
      final currency = Currency.values.firstWhere(
        (c) => c.name == name.toLowerCase(),
      );
      return fromCurrency(currency);
    } catch (_) {
      return all.first; // Default to USD
    }
  }
}

/// Currency formatter for consistent money display
class CurrencyFormatter {
  final CurrencyConfig config;
  late final NumberFormat _formatter;

  CurrencyFormatter(this.config) {
    _formatter = NumberFormat.currency(
      symbol: '${config.symbol} ',
      decimalDigits: config.decimalDigits,
    );
  }

  /// Format an amount with currency symbol
  String format(double amount) {
    return _formatter.format(amount);
  }

  /// Format an amount with compact notation (e.g., 1.2M, 500K)
  String formatCompact(double amount) {
    final compact = NumberFormat.compact();
    return '${config.symbol} ${compact.format(amount)}';
  }

  /// Format without symbol (just the number)
  String formatNumber(double amount) {
    final numberFormat = NumberFormat.decimalPattern();
    if (config.decimalDigits == 0) {
      return numberFormat.format(amount.round());
    }
    return numberFormat.format(amount);
  }

  /// Parse a formatted string back to double
  double? parse(String value) {
    try {
      // Remove currency symbol and spaces
      final cleaned = value
          .replaceAll(config.symbol, '')
          .replaceAll(config.code, '')
          .replaceAll(',', '')
          .trim();
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }
}

/// Extension for easy currency formatting on double
extension CurrencyExtension on double {
  String formatCurrency(CurrencyConfig config) {
    return CurrencyFormatter(config).format(this);
  }

  String formatCurrencyCompact(CurrencyConfig config) {
    return CurrencyFormatter(config).formatCompact(this);
  }
}
