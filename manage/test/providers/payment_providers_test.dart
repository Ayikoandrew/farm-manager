import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage/providers/payment_providers.dart';
import 'package:manage/models/payment.dart';
import 'package:manage/utils/currency_utils.dart';

void main() {
  group('Payment Provider Type Verification', () {
    test('paymentRepositoryProvider is a Provider', () {
      expect(paymentRepositoryProvider, isA<Provider>());
    });

    test('ugxFormatterProvider is a Provider', () {
      expect(ugxFormatterProvider, isA<Provider>());
    });

    test('walletBalanceProvider is a StreamProvider', () {
      expect(walletBalanceProvider, isA<StreamProvider>());
    });

    test('paymentFilterProvider is a NotifierProvider', () {
      expect(paymentFilterProvider, isA<NotifierProvider>());
    });

    test('paymentHistoryProvider is a StreamProvider', () {
      expect(paymentHistoryProvider, isA<StreamProvider>());
    });
  });

  group('Currency Formatter Provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('ugxFormatterProvider creates CurrencyFormatter for UGX', () {
      final formatter = container.read(ugxFormatterProvider);
      expect(formatter, isA<CurrencyFormatter>());
    });

    test('ugxFormatterProvider formats currency correctly', () {
      final formatter = container.read(ugxFormatterProvider);
      final formatted = formatter.format(1000);
      expect(formatted, contains('1,000'));
    });
  });

  group('Payment Filter Notifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('paymentFilterProvider starts with empty filter', () {
      final filter = container.read(paymentFilterProvider);
      expect(filter.type, isNull);
      expect(filter.status, isNull);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
      expect(filter.searchQuery, isNull);
    });

    test('PaymentFilterNotifier can set type', () {
      final notifier = container.read(paymentFilterProvider.notifier);
      notifier.setType(PaymentType.incoming);
      expect(container.read(paymentFilterProvider).type, PaymentType.incoming);
    });

    test('PaymentFilterNotifier can clear type', () {
      final notifier = container.read(paymentFilterProvider.notifier);
      notifier.setType(PaymentType.incoming);
      notifier.setType(null);
      expect(container.read(paymentFilterProvider).type, isNull);
    });

    test('PaymentFilterNotifier can set status', () {
      final notifier = container.read(paymentFilterProvider.notifier);
      notifier.setStatus(PaymentStatus.pending);
      expect(
        container.read(paymentFilterProvider).status,
        PaymentStatus.pending,
      );
    });

    test('PaymentFilterNotifier can clear status', () {
      final notifier = container.read(paymentFilterProvider.notifier);
      notifier.setStatus(PaymentStatus.pending);
      notifier.setStatus(null);
      expect(container.read(paymentFilterProvider).status, isNull);
    });

    test('PaymentFilterNotifier can set date range', () {
      final notifier = container.read(paymentFilterProvider.notifier);
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 12, 31);

      notifier.setDateRange(start, end);

      final filter = container.read(paymentFilterProvider);
      expect(filter.startDate, start);
      expect(filter.endDate, end);
    });

    test('PaymentFilterNotifier can clear date range', () {
      final notifier = container.read(paymentFilterProvider.notifier);
      notifier.setDateRange(DateTime(2024, 1, 1), DateTime(2024, 12, 31));
      notifier.setDateRange(null, null);

      final filter = container.read(paymentFilterProvider);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
    });

    test('PaymentFilterNotifier can set search query', () {
      final notifier = container.read(paymentFilterProvider.notifier);
      notifier.setSearchQuery('test search');
      expect(container.read(paymentFilterProvider).searchQuery, 'test search');
    });

    test('PaymentFilterNotifier can clear search query', () {
      final notifier = container.read(paymentFilterProvider.notifier);
      notifier.setSearchQuery('test');
      notifier.setSearchQuery(null);
      expect(container.read(paymentFilterProvider).searchQuery, isNull);
    });

    test('PaymentFilterNotifier clears search on empty string', () {
      final notifier = container.read(paymentFilterProvider.notifier);
      notifier.setSearchQuery('test');
      notifier.setSearchQuery('');
      expect(container.read(paymentFilterProvider).searchQuery, isNull);
    });

    test('PaymentFilterNotifier clearFilters resets all fields', () {
      final notifier = container.read(paymentFilterProvider.notifier);

      // Set all filters
      notifier.setType(PaymentType.outgoing);
      notifier.setStatus(PaymentStatus.successful);
      notifier.setDateRange(DateTime(2024, 1, 1), DateTime(2024, 12, 31));
      notifier.setSearchQuery('test');

      // Clear all
      notifier.clearFilters();

      final filter = container.read(paymentFilterProvider);
      expect(filter.type, isNull);
      expect(filter.status, isNull);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
      expect(filter.searchQuery, isNull);
    });
  });

  group('Payment History Provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('paymentHistoryProvider returns AsyncValue when no farm', () {
      final history = container.read(paymentHistoryProvider);
      expect(history, isA<AsyncValue<List<Payment>>>());
    });
  });

  group('Filtered Payments Provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('filteredPaymentsProvider returns AsyncValue when no farm', () {
      final payments = container.read(filteredPaymentsProvider);
      expect(payments, isA<AsyncValue<List<Payment>>>());
    });
  });

  group('Payment Stats Provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('paymentStatsProvider returns AsyncValue', () {
      final stats = container.read(paymentStatsProvider);
      expect(stats, isA<AsyncValue<PaymentStats>>());
    });
  });

  group('Payment Stats With Range Provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('paymentStatsWithRangeProvider accepts null date range', () {
      final stats = container.read(paymentStatsWithRangeProvider(null));
      expect(stats, isA<AsyncValue<PaymentStats>>());
    });

    test('paymentStatsWithRangeProvider accepts DateRange', () {
      final dateRange = DateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 12, 31),
      );
      final stats = container.read(paymentStatsWithRangeProvider(dateRange));
      expect(stats, isA<AsyncValue<PaymentStats>>());
    });
  });

  group('Pending Payments Provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('pendingPaymentsProvider returns AsyncValue when no farm', () {
      final pending = container.read(pendingPaymentsProvider);
      expect(pending, isA<AsyncValue<List<Payment>>>());
    });
  });

  group('Payment Provider (by ID)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('paymentProvider accepts string id parameter', () {
      final payment = container.read(paymentProvider('test-payment-id'));
      expect(payment, isA<AsyncValue<Payment?>>());
    });
  });

  group('DateRange Helper Class', () {
    test('DateRange creates instance with start and end dates', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 12, 31);
      final range = DateRange(start: start, end: end);

      expect(range.start, start);
      expect(range.end, end);
    });

    test('DateRange can represent a single day', () {
      final date = DateTime(2024, 6, 15);
      final range = DateRange(start: date, end: date);

      expect(range.start, range.end);
    });

    test('DateRange end is after start', () {
      final range = DateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 12, 31),
      );

      expect(range.end.isAfter(range.start), isTrue);
    });
  });

  group('PaymentFilter Model', () {
    test('PaymentFilter creates empty instance', () {
      const filter = PaymentFilter();
      expect(filter.type, isNull);
      expect(filter.status, isNull);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
      expect(filter.searchQuery, isNull);
    });

    test('PaymentFilter copyWith creates modified copy', () {
      const filter = PaymentFilter();
      final modified = filter.copyWith(type: PaymentType.incoming);

      expect(modified.type, PaymentType.incoming);
      expect(modified.status, isNull);
    });

    test('PaymentFilter copyWith with clearType removes type', () {
      final filter = const PaymentFilter().copyWith(type: PaymentType.incoming);
      final cleared = filter.copyWith(clearType: true);

      expect(cleared.type, isNull);
    });
  });

  group('Payment Types', () {
    test('PaymentType enum has expected values', () {
      expect(PaymentType.values, contains(PaymentType.incoming));
      expect(PaymentType.values, contains(PaymentType.outgoing));
    });

    test('PaymentStatus enum has expected values', () {
      expect(PaymentStatus.values, contains(PaymentStatus.pending));
      expect(PaymentStatus.values, contains(PaymentStatus.successful));
      expect(PaymentStatus.values, contains(PaymentStatus.failed));
    });
  });
}
