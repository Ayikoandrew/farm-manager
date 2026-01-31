enum PaymentStatus { pending, successful, failed, cancelled }

extension PaymentStatusExtension on PaymentStatus {
  String get name {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.successful:
        return 'successful';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'successful':
        return PaymentStatus.successful;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }
}

/// Payment type enum
enum PaymentType {
  incoming, // Money received
  outgoing, // Money sent
}

/// Mobile money network enum
enum MobileMoneyNetwork { mtnUganda, airtelUganda }

extension MobileMoneyNetworkExtension on MobileMoneyNetwork {
  String get displayName {
    switch (this) {
      case MobileMoneyNetwork.mtnUganda:
        return 'MTN Mobile Money';
      case MobileMoneyNetwork.airtelUganda:
        return 'Airtel Money';
    }
  }

  String get flutterwaveCode {
    switch (this) {
      case MobileMoneyNetwork.mtnUganda:
        return 'MPS'; // MTN Uganda
      case MobileMoneyNetwork.airtelUganda:
        return 'MPS'; // Airtel Uganda uses same code
    }
  }

  static MobileMoneyNetwork fromString(String value) {
    switch (value.toLowerCase()) {
      case 'mtn':
      case 'mtnuganda':
      case 'mtn_uganda':
        return MobileMoneyNetwork.mtnUganda;
      case 'airtel':
      case 'airteluganda':
      case 'airtel_uganda':
        return MobileMoneyNetwork.airtelUganda;
      default:
        return MobileMoneyNetwork.mtnUganda;
    }
  }
}

/// Payment model
class Payment {
  final String id;
  final String farmId;
  final String userId;
  final PaymentType type;
  final double amount;
  final String currency;
  final String description;
  final PaymentStatus status;
  final String? transactionRef;
  final String? flutterwaveRef;
  final String? phoneNumber;
  final MobileMoneyNetwork? network;
  final String? recipientName;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.farmId,
    required this.userId,
    required this.type,
    required this.amount,
    this.currency = 'UGX',
    required this.description,
    required this.status,
    this.transactionRef,
    this.flutterwaveRef,
    this.phoneNumber,
    this.network,
    this.recipientName,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  /// Create from Supabase row (snake_case fields)
  factory Payment.fromSupabase(Map<String, dynamic> data) {
    return Payment(
      id: data['id'] ?? '',
      farmId: data['farm_id'] ?? '',
      userId: data['user_id'] ?? '',
      type: data['type'] == 'outgoing'
          ? PaymentType.outgoing
          : PaymentType.incoming,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'UGX',
      description: data['description'] ?? '',
      status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
      transactionRef: data['transaction_ref'],
      flutterwaveRef: data['flutterwave_ref'],
      phoneNumber: data['phone_number'],
      network: data['network'] != null
          ? MobileMoneyNetworkExtension.fromString(data['network'])
          : null,
      recipientName: data['recipient_name'],
      errorMessage: data['error_message'],
      createdAt: DateTime.parse(
        data['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'])
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Supabase row (snake_case fields)
  Map<String, dynamic> toSupabase() {
    return {
      'farm_id': farmId,
      'user_id': userId,
      'type': type == PaymentType.outgoing ? 'outgoing' : 'incoming',
      'amount': amount,
      'currency': currency,
      'description': description,
      'status': status.name,
      'transaction_ref': transactionRef,
      'flutterwave_ref': flutterwaveRef,
      'phone_number': phoneNumber,
      'network': network?.name,
      'recipient_name': recipientName,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Payment copyWith({
    PaymentStatus? status,
    String? flutterwaveRef,
    String? errorMessage,
    DateTime? completedAt,
  }) {
    return Payment(
      id: id,
      farmId: farmId,
      userId: userId,
      type: type,
      amount: amount,
      currency: currency,
      description: description,
      status: status ?? this.status,
      transactionRef: transactionRef,
      flutterwaveRef: flutterwaveRef ?? this.flutterwaveRef,
      phoneNumber: phoneNumber,
      network: network,
      recipientName: recipientName,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata,
    );
  }
}

/// Wallet balance model
class WalletBalance {
  final String farmId;
  final double balance;
  final String currency;
  final DateTime lastUpdated;

  WalletBalance({
    required this.farmId,
    required this.balance,
    this.currency = 'UGX',
    required this.lastUpdated,
  });

  /// Create from Supabase row (snake_case fields)
  factory WalletBalance.fromSupabase(Map<String, dynamic> data) {
    return WalletBalance(
      farmId: data['farm_id'] ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'UGX',
      lastUpdated: DateTime.parse(
        data['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

/// Payment statistics model
class PaymentStats {
  final double totalReceived;
  final double totalSent;
  final double netAmount;
  final int transactionCount;
  final int successfulCount;
  final int pendingCount;
  final int failedCount;

  PaymentStats({
    required this.totalReceived,
    required this.totalSent,
    required this.netAmount,
    required this.transactionCount,
    required this.successfulCount,
    required this.pendingCount,
    required this.failedCount,
  });

  factory PaymentStats.empty() {
    return PaymentStats(
      totalReceived: 0,
      totalSent: 0,
      netAmount: 0,
      transactionCount: 0,
      successfulCount: 0,
      pendingCount: 0,
      failedCount: 0,
    );
  }

  double get successRate =>
      transactionCount > 0 ? (successfulCount / transactionCount) * 100 : 0;
}

/// Payment filter options
class PaymentFilter {
  final PaymentType? type;
  final PaymentStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  const PaymentFilter({
    this.type,
    this.status,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  PaymentFilter copyWith({
    PaymentType? type,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool clearType = false,
    bool clearStatus = false,
    bool clearDates = false,
    bool clearSearch = false,
  }) {
    return PaymentFilter(
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasFilters =>
      type != null ||
      status != null ||
      startDate != null ||
      endDate != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);
}
