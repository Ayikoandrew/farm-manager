import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../repositories/payment_repository.dart';
import '../utils/currency_utils.dart';
import 'providers.dart';

/// Provider for UGX currency formatter (specifically for mobile money payments)
final ugxFormatterProvider = Provider<CurrencyFormatter>((ref) {
  return CurrencyFormatter(CurrencyConfig.fromCurrency(Currency.ugx));
});

/// Provider for the payment repository
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

/// Provider for wallet balance of active farm
final walletBalanceProvider = StreamProvider<WalletBalance?>((ref) {
  final farmId = ref.watch(activeFarmIdProvider);
  if (farmId == null) {
    return Stream.value(null);
  }

  final repository = ref.read(paymentRepositoryProvider);
  return repository.watchWalletBalance(farmId);
});

/// Provider for payment filter state
class PaymentFilterNotifier extends Notifier<PaymentFilter> {
  @override
  PaymentFilter build() => const PaymentFilter();

  void setType(PaymentType? type) {
    state = state.copyWith(type: type, clearType: type == null);
  }

  void setStatus(PaymentStatus? status) {
    state = state.copyWith(status: status, clearStatus: status == null);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      clearDates: start == null && end == null,
    );
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.isEmpty,
    );
  }

  void clearFilters() {
    state = const PaymentFilter();
  }
}

final paymentFilterProvider =
    NotifierProvider<PaymentFilterNotifier, PaymentFilter>(
      PaymentFilterNotifier.new,
    );

/// Provider for payment history with filters
final paymentHistoryProvider = StreamProvider<List<Payment>>((ref) {
  final farmId = ref.watch(activeFarmIdProvider);
  if (farmId == null) {
    return Stream.value([]);
  }

  final filter = ref.watch(paymentFilterProvider);
  final repository = ref.read(paymentRepositoryProvider);

  return repository.watchPaymentHistory(
    farmId,
    type: filter.type,
    status: filter.status,
  );
});

/// Provider for filtered payments (includes search and date filtering)
final filteredPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final farmId = ref.watch(activeFarmIdProvider);
  if (farmId == null) return [];

  final filter = ref.watch(paymentFilterProvider);
  final repository = ref.read(paymentRepositoryProvider);

  // If there's a search query, use the search method
  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    return repository.searchPayments(farmId, filter.searchQuery!);
  }

  // Otherwise use the filtered history
  return repository.getPaymentHistory(
    farmId,
    type: filter.type,
    status: filter.status,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

/// Provider for payment statistics
final paymentStatsProvider = FutureProvider<PaymentStats>((ref) async {
  final farmId = ref.watch(activeFarmIdProvider);
  if (farmId == null) return PaymentStats.empty();

  final repository = ref.read(paymentRepositoryProvider);
  return repository.getPaymentStats(farmId);
});

/// Provider for payment statistics with date range
final paymentStatsWithRangeProvider =
    FutureProvider.family<PaymentStats, DateRange?>((ref, dateRange) async {
      final farmId = ref.watch(activeFarmIdProvider);
      if (farmId == null) return PaymentStats.empty();

      final repository = ref.read(paymentRepositoryProvider);
      return repository.getPaymentStats(
        farmId,
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );
    });

/// Provider for pending payments
final pendingPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final farmId = ref.watch(activeFarmIdProvider);
  if (farmId == null) return [];

  final repository = ref.read(paymentRepositoryProvider);
  return repository.getPendingPayments(farmId);
});

/// Provider for getting a specific payment
final paymentProvider = FutureProvider.family<Payment?, String>((
  ref,
  paymentId,
) async {
  final repository = ref.read(paymentRepositoryProvider);
  return repository.getPayment(paymentId);
});

/// Date range helper class
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  /// Today
  factory DateRange.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    return DateRange(start: start, end: end);
  }

  /// This week
  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(start.year, start.month, start.day);
    final end = startOfWeek
        .add(const Duration(days: 7))
        .subtract(const Duration(milliseconds: 1));
    return DateRange(start: startOfWeek, end: end);
  }

  /// This month
  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(milliseconds: 1));
    return DateRange(start: start, end: end);
  }

  /// Last 30 days
  factory DateRange.last30Days() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = end.subtract(const Duration(days: 30));
    return DateRange(start: start, end: end);
  }

  /// This year
  factory DateRange.thisYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(
      now.year + 1,
      1,
      1,
    ).subtract(const Duration(milliseconds: 1));
    return DateRange(start: start, end: end);
  }
}

/// State notifier for handling payment operations
class PaymentNotifier extends Notifier<PaymentState> {
  late final PaymentRepository _repository;

  @override
  PaymentState build() {
    _repository = ref.read(paymentRepositoryProvider);
    return PaymentState.initial();
  }

  /// Initiate mobile money collection (receive money)
  Future<PaymentResult> collectMoney({
    required double amount,
    required String phoneNumber,
    required MobileMoneyNetwork network,
    required String description,
    String? customerEmail,
    String? customerName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.initiateMobileMoneyCollection(
      amount: amount,
      phoneNumber: phoneNumber,
      network: network,
      description: description,
      customerEmail: customerEmail,
      customerName: customerName,
    );

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        lastPaymentId: result.paymentId,
        lastTxRef: result.txRef,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
    }

    return result;
  }

  /// Initiate mobile money transfer (send money)
  Future<PaymentResult> sendMoney({
    required double amount,
    required String phoneNumber,
    required MobileMoneyNetwork network,
    required String recipientName,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.initiateMobileMoneyTransfer(
      amount: amount,
      phoneNumber: phoneNumber,
      network: network,
      recipientName: recipientName,
      description: description,
    );

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        lastPaymentId: result.paymentId,
        lastTxRef: result.txRef,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.errorMessage);
    }

    return result;
  }

  /// Verify a payment
  Future<Payment?> verifyPayment(String txRef) async {
    state = state.copyWith(isLoading: true, error: null);

    final payment = await _repository.verifyPayment(txRef);

    state = state.copyWith(isLoading: false);
    return payment;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Payment state
class PaymentState {
  final bool isLoading;
  final String? error;
  final String? lastPaymentId;
  final String? lastTxRef;

  PaymentState({
    required this.isLoading,
    this.error,
    this.lastPaymentId,
    this.lastTxRef,
  });

  factory PaymentState.initial() => PaymentState(isLoading: false);

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    String? lastPaymentId,
    String? lastTxRef,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastPaymentId: lastPaymentId ?? this.lastPaymentId,
      lastTxRef: lastTxRef ?? this.lastTxRef,
    );
  }
}

/// Provider for payment operations
final paymentNotifierProvider = NotifierProvider<PaymentNotifier, PaymentState>(
  PaymentNotifier.new,
);
