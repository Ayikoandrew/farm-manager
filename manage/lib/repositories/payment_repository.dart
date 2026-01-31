import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/payment.dart';
import '../config/supabase_config.dart';

/// Flutterwave configuration
class FlutterwaveConfig {
  // TODO: Replace with your actual Flutterwave keys
  // Get these from https://dashboard.flutterwave.com/settings/apis
  static const String publicKey = '9d47cbe3-619e-423f-9895-15714a93478a';
  static const String secretKey = 'Ztk3bGPMkcwPfSXHiza8lZnwMYaavqll';
  static const String encryptionKey =
      'VDyG0Bb22EBktZERd/KUE1UAmm3tmQbj9I3eK6MD55U=';

  // Set to false for production
  static const bool isTestMode = true;

  // Base URL for Flutterwave API
  static String get baseUrl => 'https://api.flutterwave.com/v3';

  // Redirect URL after payment (for web)
  static const String redirectUrl = 'https://yourapp.com/payment/callback';
}

/// Payment repository for handling Flutterwave mobile money
class PaymentRepository {
  final SupabaseClient _client = SupabaseConfig.client;
  final _uuid = const Uuid();
  static const String _paymentsTable = 'payments';
  static const String _walletsTable = 'wallets';
  static const String _usersTable = 'users';

  /// Generate unique transaction reference
  String _generateTxRef() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4().substring(0, 8);
    return 'FM-$timestamp-$uuid';
  }

  /// Get current user's farm ID
  Future<String?> _getCurrentFarmId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from(_usersTable)
        .select('active_farm_id')
        .eq('id', user.id)
        .maybeSingle();
    if (response == null) return null;

    return response['active_farm_id'] as String?;
  }

  /// Initialize mobile money payment (collection/receive money)
  Future<PaymentResult> initiateMobileMoneyCollection({
    required double amount,
    required String phoneNumber,
    required MobileMoneyNetwork network,
    required String description,
    String? customerEmail,
    String? customerName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return PaymentResult.failure('User not authenticated');
    }

    final farmId = await _getCurrentFarmId();
    if (farmId == null) {
      return PaymentResult.failure('No active farm selected');
    }

    final txRef = _generateTxRef();

    try {
      // Create payment record in Supabase first
      final payment = Payment(
        id: '',
        farmId: farmId,
        userId: user.id,
        type: PaymentType.incoming,
        amount: amount,
        currency: 'UGX',
        description: description,
        status: PaymentStatus.pending,
        transactionRef: txRef,
        phoneNumber: phoneNumber,
        network: network,
        createdAt: DateTime.now(),
      );

      final insertedRow = await _client
          .from(_paymentsTable)
          .insert(payment.toSupabase())
          .select()
          .single();

      final paymentId = insertedRow['id'] as String;

      // Call Flutterwave API to initiate charge
      final response = await http.post(
        Uri.parse(
          '${FlutterwaveConfig.baseUrl}/charges?type=mobile_money_uganda',
        ),
        headers: {
          'Authorization': 'Bearer ${FlutterwaveConfig.secretKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tx_ref': txRef,
          'amount': amount.toString(),
          'currency': 'UGX',
          'phone_number': phoneNumber,
          'network': network == MobileMoneyNetwork.mtnUganda ? 'MTN' : 'AIRTEL',
          'email': customerEmail ?? user.email ?? 'customer@farmmanager.com',
          'fullname': customerName ?? 'Farm Customer',
          'redirect_url': FlutterwaveConfig.redirectUrl,
          'meta': {
            'farm_id': farmId,
            'payment_id': paymentId,
            'user_id': user.id,
          },
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        // Update payment with Flutterwave reference
        await _client
            .from(_paymentsTable)
            .update({'flutterwave_ref': responseData['data']['id']?.toString()})
            .eq('id', paymentId);

        return PaymentResult.success(
          paymentId: paymentId,
          txRef: txRef,
          message:
              responseData['data']['processor_response'] ??
              'Payment initiated. Please approve on your phone.',
        );
      } else {
        // Update payment status to failed
        await _client
            .from(_paymentsTable)
            .update({
              'status': 'failed',
              'error_message':
                  responseData['message'] ?? 'Payment initiation failed',
            })
            .eq('id', paymentId);

        return PaymentResult.failure(
          responseData['message'] ?? 'Payment initiation failed',
        );
      }
    } catch (e) {
      return PaymentResult.failure('Error: ${e.toString()}');
    }
  }

  /// Initiate mobile money transfer (disbursement/send money)
  Future<PaymentResult> initiateMobileMoneyTransfer({
    required double amount,
    required String phoneNumber,
    required MobileMoneyNetwork network,
    required String recipientName,
    required String description,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return PaymentResult.failure('User not authenticated');
    }

    final farmId = await _getCurrentFarmId();
    if (farmId == null) {
      return PaymentResult.failure('No active farm selected');
    }

    final txRef = _generateTxRef();

    try {
      // Create payment record
      final payment = Payment(
        id: '',
        farmId: farmId,
        userId: user.id,
        type: PaymentType.outgoing,
        amount: amount,
        currency: 'UGX',
        description: description,
        status: PaymentStatus.pending,
        transactionRef: txRef,
        phoneNumber: phoneNumber,
        network: network,
        recipientName: recipientName,
        createdAt: DateTime.now(),
      );

      final insertedRow = await _client
          .from(_paymentsTable)
          .insert(payment.toSupabase())
          .select()
          .single();

      final paymentId = insertedRow['id'] as String;

      // Call Flutterwave Transfer API
      final response = await http.post(
        Uri.parse('${FlutterwaveConfig.baseUrl}/transfers'),
        headers: {
          'Authorization': 'Bearer ${FlutterwaveConfig.secretKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'account_bank': 'MPS', // Mobile Money
          'account_number': phoneNumber,
          'amount': amount,
          'currency': 'UGX',
          'beneficiary_name': recipientName,
          'reference': txRef,
          'callback_url': '${FlutterwaveConfig.redirectUrl}/transfer',
          'debit_currency': 'UGX',
          'meta': {
            'farm_id': farmId,
            'payment_id': paymentId,
            'mobile_number': phoneNumber,
          },
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        await _client
            .from(_paymentsTable)
            .update({
              'flutterwave_ref': responseData['data']['id']?.toString(),
              'status': responseData['data']['status'] == 'NEW'
                  ? 'pending'
                  : 'successful',
            })
            .eq('id', paymentId);

        return PaymentResult.success(
          paymentId: paymentId,
          txRef: txRef,
          message: 'Transfer initiated successfully',
        );
      } else {
        await _client
            .from(_paymentsTable)
            .update({
              'status': 'failed',
              'error_message': responseData['message'] ?? 'Transfer failed',
            })
            .eq('id', paymentId);

        return PaymentResult.failure(
          responseData['message'] ?? 'Transfer initiation failed',
        );
      }
    } catch (e) {
      return PaymentResult.failure('Error: ${e.toString()}');
    }
  }

  /// Verify payment status
  Future<Payment?> verifyPayment(String transactionRef) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${FlutterwaveConfig.baseUrl}/transactions/verify_by_reference?tx_ref=$transactionRef',
        ),
        headers: {'Authorization': 'Bearer ${FlutterwaveConfig.secretKey}'},
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final txData = responseData['data'];
        final status = txData['status'];

        // Find the payment in Supabase
        final paymentData = await _client
            .from(_paymentsTable)
            .select()
            .eq('transaction_ref', transactionRef)
            .maybeSingle();

        if (paymentData != null) {
          PaymentStatus paymentStatus;

          switch (status) {
            case 'successful':
              paymentStatus = PaymentStatus.successful;
              break;
            case 'failed':
              paymentStatus = PaymentStatus.failed;
              break;
            default:
              paymentStatus = PaymentStatus.pending;
          }

          // Update payment
          final updateData = <String, dynamic>{
            'status': paymentStatus.name,
            'flutterwave_ref': txData['id']?.toString(),
          };
          if (paymentStatus == PaymentStatus.successful) {
            updateData['completed_at'] = DateTime.now().toIso8601String();
          }

          await _client
              .from(_paymentsTable)
              .update(updateData)
              .eq('id', paymentData['id']);

          // If successful incoming payment, update wallet balance
          final payment = Payment.fromSupabase(paymentData);
          if (paymentStatus == PaymentStatus.successful &&
              payment.type == PaymentType.incoming) {
            await _updateWalletBalance(payment.farmId, payment.amount);
          }

          // Fetch updated payment
          final updatedData = await _client
              .from(_paymentsTable)
              .select()
              .eq('id', paymentData['id'])
              .single();

          return Payment.fromSupabase(updatedData);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update wallet balance
  Future<void> _updateWalletBalance(String farmId, double amount) async {
    // Check if wallet exists
    final existing = await _client
        .from(_walletsTable)
        .select()
        .eq('farm_id', farmId)
        .maybeSingle();

    if (existing != null) {
      // Update existing wallet
      final currentBalance = (existing['balance'] as num?)?.toDouble() ?? 0;
      await _client
          .from(_walletsTable)
          .update({
            'balance': currentBalance + amount,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('farm_id', farmId);
    } else {
      // Create new wallet
      await _client.from(_walletsTable).insert({
        'farm_id': farmId,
        'balance': amount,
        'currency': 'UGX',
        'last_updated': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Get wallet balance for farm
  Future<WalletBalance?> getWalletBalance(String farmId) async {
    final data = await _client
        .from(_walletsTable)
        .select()
        .eq('farm_id', farmId)
        .maybeSingle();

    if (data == null) {
      return WalletBalance(
        farmId: farmId,
        balance: 0,
        lastUpdated: DateTime.now(),
      );
    }
    return WalletBalance.fromSupabase(data);
  }

  /// Watch wallet balance
  Stream<WalletBalance> watchWalletBalance(String farmId) {
    return _client
        .from(_walletsTable)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .map((data) {
          if (data.isEmpty) {
            return WalletBalance(
              farmId: farmId,
              balance: 0,
              lastUpdated: DateTime.now(),
            );
          }
          return WalletBalance.fromSupabase(data.first);
        });
  }

  /// Get payment history for farm
  Future<List<Payment>> getPaymentHistory(
    String farmId, {
    int limit = 50,
    PaymentType? type,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from(_paymentsTable).select().eq('farm_id', farmId);

    if (type != null) {
      query = query.eq('type', type.name);
    }

    if (status != null) {
      query = query.eq('status', status.name);
    }

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte(
        'created_at',
        endDate.add(const Duration(days: 1)).toIso8601String(),
      );
    }

    final data = await query.order('created_at', ascending: false).limit(limit);

    return data.map((row) => Payment.fromSupabase(row)).toList();
  }

  /// Watch payment history with filters
  Stream<List<Payment>> watchPaymentHistory(
    String farmId, {
    PaymentType? type,
    PaymentStatus? status,
  }) {
    return _client
        .from(_paymentsTable)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) {
          var payments = data.map((row) => Payment.fromSupabase(row)).toList();

          // Apply filters
          if (type != null) {
            payments = payments.where((p) => p.type == type).toList();
          }
          if (status != null) {
            payments = payments.where((p) => p.status == status).toList();
          }

          return payments;
        });
  }

  /// Get payment statistics for a farm
  Future<PaymentStats> getPaymentStats(
    String farmId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final payments = await getPaymentHistory(
      farmId,
      limit: 1000,
      startDate: startDate,
      endDate: endDate,
    );

    double totalReceived = 0;
    double totalSent = 0;
    int successfulCount = 0;
    int pendingCount = 0;
    int failedCount = 0;

    for (final payment in payments) {
      if (payment.status == PaymentStatus.successful) {
        successfulCount++;
        if (payment.type == PaymentType.incoming) {
          totalReceived += payment.amount;
        } else {
          totalSent += payment.amount;
        }
      } else if (payment.status == PaymentStatus.pending) {
        pendingCount++;
      } else if (payment.status == PaymentStatus.failed) {
        failedCount++;
      }
    }

    return PaymentStats(
      totalReceived: totalReceived,
      totalSent: totalSent,
      netAmount: totalReceived - totalSent,
      transactionCount: payments.length,
      successfulCount: successfulCount,
      pendingCount: pendingCount,
      failedCount: failedCount,
    );
  }

  /// Get pending payments that need verification
  Future<List<Payment>> getPendingPayments(String farmId) async {
    final data = await _client
        .from(_paymentsTable)
        .select()
        .eq('farm_id', farmId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return data.map((row) => Payment.fromSupabase(row)).toList();
  }

  /// Search payments by phone number or description
  Future<List<Payment>> searchPayments(
    String farmId,
    String searchQuery,
  ) async {
    // Get all payments and filter client-side (Supabase full-text search would require setup)
    final payments = await getPaymentHistory(farmId, limit: 200);

    final query = searchQuery.toLowerCase();
    return payments.where((payment) {
      return (payment.phoneNumber?.toLowerCase().contains(query) ?? false) ||
          payment.description.toLowerCase().contains(query) ||
          (payment.recipientName?.toLowerCase().contains(query) ?? false) ||
          (payment.transactionRef?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Get single payment
  Future<Payment?> getPayment(String paymentId) async {
    final data = await _client
        .from(_paymentsTable)
        .select()
        .eq('id', paymentId)
        .maybeSingle();

    if (data == null) return null;
    return Payment.fromSupabase(data);
  }
}

/// Result of a payment operation
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? txRef;
  final String? message;
  final String? errorMessage;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.txRef,
    this.message,
    this.errorMessage,
  });

  factory PaymentResult.success({
    required String paymentId,
    required String txRef,
    String? message,
  }) {
    return PaymentResult(
      success: true,
      paymentId: paymentId,
      txRef: txRef,
      message: message,
    );
  }

  factory PaymentResult.failure(String error) {
    return PaymentResult(success: false, errorMessage: error);
  }
}
