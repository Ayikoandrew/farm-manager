import 'package:flutter_test/flutter_test.dart';
import 'package:manage/utils/currency_utils.dart';

void main() {
  group('Currency Enum', () {
    test('all currencies are defined', () {
      expect(Currency.values.length, 13);
      expect(Currency.values, contains(Currency.usd));
      expect(Currency.values, contains(Currency.ugx));
      expect(Currency.values, contains(Currency.kes));
      expect(Currency.values, contains(Currency.tzs));
      expect(Currency.values, contains(Currency.rwf));
      expect(Currency.values, contains(Currency.eur));
      expect(Currency.values, contains(Currency.gbp));
      expect(Currency.values, contains(Currency.zar));
      expect(Currency.values, contains(Currency.ngn));
      expect(Currency.values, contains(Currency.ghs));
      expect(Currency.values, contains(Currency.etb));
      expect(Currency.values, contains(Currency.xof));
      expect(Currency.values, contains(Currency.xaf));
    });

    test('name property returns correct values', () {
      expect(Currency.usd.name, 'usd');
      expect(Currency.ugx.name, 'ugx');
      expect(Currency.eur.name, 'eur');
    });
  });

  group('CurrencyConfig', () {
    test('all currencies have configs', () {
      expect(CurrencyConfig.all.length, 13);
    });

    test('USD config is correct', () {
      final config = CurrencyConfig.fromCurrency(Currency.usd);
      expect(config.code, 'USD');
      expect(config.symbol, '\$');
      expect(config.name, 'US Dollar');
      expect(config.decimalDigits, 2);
    });

    test('UGX config is correct with no decimals', () {
      final config = CurrencyConfig.fromCurrency(Currency.ugx);
      expect(config.code, 'UGX');
      expect(config.symbol, 'UGX');
      expect(config.name, 'Ugandan Shilling');
      expect(config.decimalDigits, 0);
    });

    test('EUR config is correct', () {
      final config = CurrencyConfig.fromCurrency(Currency.eur);
      expect(config.code, 'EUR');
      expect(config.symbol, '€');
      expect(config.name, 'Euro');
      expect(config.decimalDigits, 2);
    });

    test('KES config is correct', () {
      final config = CurrencyConfig.fromCurrency(Currency.kes);
      expect(config.code, 'KES');
      expect(config.symbol, 'KSh');
      expect(config.name, 'Kenyan Shilling');
    });

    test('fromCode returns correct config', () {
      final config1 = CurrencyConfig.fromCode('USD');
      expect(config1.currency, Currency.usd);

      final config2 = CurrencyConfig.fromCode('ugx');
      expect(config2.currency, Currency.ugx);

      final config3 = CurrencyConfig.fromCode('EUR');
      expect(config3.currency, Currency.eur);
    });

    test('fromCode returns default for unknown code', () {
      final config = CurrencyConfig.fromCode('UNKNOWN');
      expect(config.currency, Currency.usd); // Default to USD
    });

    test('fromName returns correct config', () {
      final config1 = CurrencyConfig.fromName('usd');
      expect(config1.currency, Currency.usd);

      final config2 = CurrencyConfig.fromName('ugx');
      expect(config2.currency, Currency.ugx);
    });

    test('fromName returns default for unknown name', () {
      final config = CurrencyConfig.fromName('unknown');
      expect(config.currency, Currency.usd); // Default to USD
    });

    test('African currencies have correct symbols', () {
      expect(CurrencyConfig.fromCurrency(Currency.ngn).symbol, '₦');
      expect(CurrencyConfig.fromCurrency(Currency.ghs).symbol, 'GH₵');
      expect(CurrencyConfig.fromCurrency(Currency.zar).symbol, 'R');
    });

    test('CFA franc currencies have no decimals', () {
      final xof = CurrencyConfig.fromCurrency(Currency.xof);
      final xaf = CurrencyConfig.fromCurrency(Currency.xaf);
      expect(xof.decimalDigits, 0);
      expect(xaf.decimalDigits, 0);
    });
  });

  group('CurrencyFormatter', () {
    test('formats USD correctly', () {
      final config = CurrencyConfig.fromCurrency(Currency.usd);
      final formatter = CurrencyFormatter(config);
      final formatted = formatter.format(1234.56);
      expect(formatted, contains('\$'));
      expect(formatted, contains('1,234'));
    });

    test('formats UGX correctly without decimals', () {
      final config = CurrencyConfig.fromCurrency(Currency.ugx);
      final formatter = CurrencyFormatter(config);
      final formatted = formatter.format(1500000);
      expect(formatted, contains('UGX'));
      expect(formatted, contains('1,500,000'));
    });

    test('formats large UGX amounts', () {
      final config = CurrencyConfig.fromCurrency(Currency.ugx);
      final formatter = CurrencyFormatter(config);
      final formatted = formatter.format(10000000);
      expect(formatted, contains('10,000,000'));
    });

    test('formats zero correctly', () {
      final usdFormatter = CurrencyFormatter(
        CurrencyConfig.fromCurrency(Currency.usd),
      );
      final ugxFormatter = CurrencyFormatter(
        CurrencyConfig.fromCurrency(Currency.ugx),
      );

      expect(usdFormatter.format(0), contains('0'));
      expect(ugxFormatter.format(0), contains('0'));
    });

    test('formats negative amounts correctly', () {
      final config = CurrencyConfig.fromCurrency(Currency.ugx);
      final formatter = CurrencyFormatter(config);
      final formatted = formatter.format(-5000);
      expect(formatted, contains('-'));
      expect(formatted, contains('5,000'));
    });

    test('formatCompact formats large numbers', () {
      final config = CurrencyConfig.fromCurrency(Currency.ugx);
      final formatter = CurrencyFormatter(config);
      final formatted = formatter.formatCompact(1500000);
      expect(formatted, contains('UGX'));
      // Compact format may vary by locale, just check it's shorter than full format
      expect(formatted.length, lessThan(formatter.format(1500000).length));
    });

    test('formatNumber formats without symbol', () {
      final config = CurrencyConfig.fromCurrency(Currency.usd);
      final formatter = CurrencyFormatter(config);
      final formatted = formatter.formatNumber(1234.56);
      expect(formatted, isNot(contains('\$')));
      expect(formatted, contains('1,234'));
    });

    test('parse converts formatted string back to double', () {
      final config = CurrencyConfig.fromCurrency(Currency.usd);
      final formatter = CurrencyFormatter(config);
      final parsed = formatter.parse('\$ 1,234.56');
      expect(parsed, 1234.56);
    });

    test('parse returns null for invalid input', () {
      final config = CurrencyConfig.fromCurrency(Currency.usd);
      final formatter = CurrencyFormatter(config);
      expect(formatter.parse('invalid'), isNull);
      expect(formatter.parse('abc'), isNull);
    });
  });

  group('CurrencyExtension', () {
    test('formatCurrency extension works on double', () {
      final config = CurrencyConfig.fromCurrency(Currency.ugx);
      final formatted = 500000.0.formatCurrency(config);
      expect(formatted, contains('UGX'));
      expect(formatted, contains('500,000'));
    });

    test('formatCurrencyCompact extension works on double', () {
      final config = CurrencyConfig.fromCurrency(Currency.ugx);
      final formatted = 1500000.0.formatCurrencyCompact(config);
      expect(formatted, contains('UGX'));
    });
  });

  group('East African Currencies', () {
    test('Kenyan Shilling config', () {
      final config = CurrencyConfig.fromCurrency(Currency.kes);
      expect(config.code, 'KES');
      expect(config.symbol, 'KSh');
      expect(config.decimalDigits, 2);
    });

    test('Tanzanian Shilling config', () {
      final config = CurrencyConfig.fromCurrency(Currency.tzs);
      expect(config.code, 'TZS');
      expect(config.symbol, 'TSh');
      expect(config.decimalDigits, 0);
    });

    test('Rwandan Franc config', () {
      final config = CurrencyConfig.fromCurrency(Currency.rwf);
      expect(config.code, 'RWF');
      expect(config.symbol, 'FRw');
      expect(config.decimalDigits, 0);
    });

    test('Ethiopian Birr config', () {
      final config = CurrencyConfig.fromCurrency(Currency.etb);
      expect(config.code, 'ETB');
      expect(config.symbol, 'Br');
    });
  });

  group('Currency Formatting Edge Cases', () {
    test('handles very large amounts', () {
      final config = CurrencyConfig.fromCurrency(Currency.ugx);
      final formatter = CurrencyFormatter(config);
      final formatted = formatter.format(999999999999.0);
      expect(formatted.isNotEmpty, true);
    });

    test('handles very small amounts', () {
      final config = CurrencyConfig.fromCurrency(Currency.usd);
      final formatter = CurrencyFormatter(config);
      final formatted = formatter.format(0.01);
      expect(formatted, contains('0.01'));
    });

    test('handles decimal rounding', () {
      final config = CurrencyConfig.fromCurrency(Currency.usd);
      final formatter = CurrencyFormatter(config);
      final formatted = formatter.format(1234.567);
      // Should round to 2 decimal places
      expect(formatted, contains('1,234.57'));
    });
  });
}
