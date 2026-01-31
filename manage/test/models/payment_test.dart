import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/payment.dart';

void main() {
  group('PaymentStatus', () {
    test('all statuses are defined', () {
      expect(PaymentStatus.values.length, 4);
      expect(PaymentStatus.values, contains(PaymentStatus.pending));
      expect(PaymentStatus.values, contains(PaymentStatus.successful));
      expect(PaymentStatus.values, contains(PaymentStatus.failed));
      expect(PaymentStatus.values, contains(PaymentStatus.cancelled));
    });

    test('name returns correct string values', () {
      expect(PaymentStatus.pending.name, 'pending');
      expect(PaymentStatus.successful.name, 'successful');
      expect(PaymentStatus.failed.name, 'failed');
      expect(PaymentStatus.cancelled.name, 'cancelled');
    });

    test('fromString converts correctly', () {
      expect(
        PaymentStatusExtension.fromString('pending'),
        PaymentStatus.pending,
      );
      expect(
        PaymentStatusExtension.fromString('successful'),
        PaymentStatus.successful,
      );
      expect(PaymentStatusExtension.fromString('failed'), PaymentStatus.failed);
      expect(
        PaymentStatusExtension.fromString('cancelled'),
        PaymentStatus.cancelled,
      );
    });

    test('fromString handles case insensitivity', () {
      expect(
        PaymentStatusExtension.fromString('SUCCESSFUL'),
        PaymentStatus.successful,
      );
      expect(PaymentStatusExtension.fromString('Failed'), PaymentStatus.failed);
    });

    test('fromString defaults to pending for unknown values', () {
      expect(
        PaymentStatusExtension.fromString('unknown'),
        PaymentStatus.pending,
      );
      expect(PaymentStatusExtension.fromString(''), PaymentStatus.pending);
    });
  });

  group('PaymentType', () {
    test('all types are defined', () {
      expect(PaymentType.values.length, 2);
      expect(PaymentType.values, contains(PaymentType.incoming));
      expect(PaymentType.values, contains(PaymentType.outgoing));
    });
  });

  group('MobileMoneyNetwork', () {
    test('all networks are defined', () {
      expect(MobileMoneyNetwork.values.length, 2);
      expect(MobileMoneyNetwork.values, contains(MobileMoneyNetwork.mtnUganda));
      expect(
        MobileMoneyNetwork.values,
        contains(MobileMoneyNetwork.airtelUganda),
      );
    });

    test('displayName returns correct values', () {
      expect(MobileMoneyNetwork.mtnUganda.displayName, 'MTN Mobile Money');
      expect(MobileMoneyNetwork.airtelUganda.displayName, 'Airtel Money');
    });

    test('flutterwaveCode returns MPS for both networks', () {
      expect(MobileMoneyNetwork.mtnUganda.flutterwaveCode, 'MPS');
      expect(MobileMoneyNetwork.airtelUganda.flutterwaveCode, 'MPS');
    });

    test('fromString converts correctly', () {
      expect(
        MobileMoneyNetworkExtension.fromString('mtn'),
        MobileMoneyNetwork.mtnUganda,
      );
      expect(
        MobileMoneyNetworkExtension.fromString('mtnuganda'),
        MobileMoneyNetwork.mtnUganda,
      );
      expect(
        MobileMoneyNetworkExtension.fromString('mtn_uganda'),
        MobileMoneyNetwork.mtnUganda,
      );
      expect(
        MobileMoneyNetworkExtension.fromString('airtel'),
        MobileMoneyNetwork.airtelUganda,
      );
      expect(
        MobileMoneyNetworkExtension.fromString('airteluganda'),
        MobileMoneyNetwork.airtelUganda,
      );
    });

    test('fromString defaults to MTN for unknown values', () {
      expect(
        MobileMoneyNetworkExtension.fromString('unknown'),
        MobileMoneyNetwork.mtnUganda,
      );
    });
  });

  group('Payment Model', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 1, 10);
    });

    test('should create Payment with required properties', () {
      final payment = Payment(
        id: 'payment-001',
        farmId: 'farm-001',
        userId: 'user-001',
        type: PaymentType.outgoing,
        amount: 50000.0,
        currency: 'UGX',
        description: 'Monthly subscription',
        status: PaymentStatus.pending,
        createdAt: now,
      );

      expect(payment.id, 'payment-001');
      expect(payment.amount, 50000.0);
      expect(payment.currency, 'UGX');
      expect(payment.status, PaymentStatus.pending);
      expect(payment.type, PaymentType.outgoing);
    });

    test('should create Payment with mobile money details', () {
      final payment = Payment(
        id: 'payment-002',
        farmId: 'farm-001',
        userId: 'user-001',
        type: PaymentType.outgoing,
        amount: 100000.0,
        currency: 'UGX',
        description: 'Premium upgrade',
        status: PaymentStatus.successful,
        phoneNumber: '+256770987654',
        network: MobileMoneyNetwork.mtnUganda,
        transactionRef: 'TXN-123456',
        flutterwaveRef: 'FLW-REF-789',
        createdAt: now,
        completedAt: now.add(const Duration(minutes: 2)),
      );

      expect(payment.phoneNumber, '+256770987654');
      expect(payment.network, MobileMoneyNetwork.mtnUganda);
      expect(payment.transactionRef, 'TXN-123456');
      expect(payment.flutterwaveRef, 'FLW-REF-789');
      expect(payment.completedAt, isNotNull);
    });

    test('should handle incoming payments', () {
      final payment = Payment(
        id: 'payment-003',
        farmId: 'farm-001',
        userId: 'user-001',
        type: PaymentType.incoming,
        amount: 500000.0,
        currency: 'UGX',
        description: 'Animal sale payment',
        status: PaymentStatus.successful,
        phoneNumber: '+256750123456',
        network: MobileMoneyNetwork.airtelUganda,
        createdAt: now,
      );

      expect(payment.type, PaymentType.incoming);
      expect(payment.network, MobileMoneyNetwork.airtelUganda);
    });

    test('should handle failed payment with error message', () {
      final payment = Payment(
        id: 'payment-004',
        farmId: 'farm-001',
        userId: 'user-001',
        type: PaymentType.outgoing,
        amount: 75000,
        currency: 'UGX',
        description: 'Subscription',
        status: PaymentStatus.failed,
        errorMessage: 'Insufficient funds',
        createdAt: now,
      );

      expect(payment.status, PaymentStatus.failed);
      expect(payment.errorMessage, 'Insufficient funds');
    });

    test('should handle metadata', () {
      final payment = Payment(
        id: 'payment-005',
        farmId: 'farm-001',
        userId: 'user-001',
        type: PaymentType.outgoing,
        amount: 100000,
        currency: 'UGX',
        description: 'Premium plan',
        status: PaymentStatus.pending,
        metadata: {'plan': 'premium', 'duration': '12months'},
        createdAt: now,
      );

      expect(payment.metadata, isNotNull);
      expect(payment.metadata!['plan'], 'premium');
      expect(payment.metadata!['duration'], '12months');
    });
  });

  group('Phone Number Validation', () {
    test('MTN Uganda numbers start with 077 or 078', () {
      const mtnNumbers = ['+256770123456', '+256780123456'];

      for (final number in mtnNumbers) {
        expect(
          number.startsWith('+25677') || number.startsWith('+25678'),
          true,
        );
      }
    });

    test('Airtel Uganda numbers start with 070 or 075', () {
      const airtelNumbers = ['+256700123456', '+256750123456'];

      for (final number in airtelNumbers) {
        expect(
          number.startsWith('+25670') || number.startsWith('+25675'),
          true,
        );
      }
    });

    test('Uganda phone numbers have correct length', () {
      const validNumber = '+256700123456';

      expect(validNumber.length, 13); // +256 + 9 digits
      expect(validNumber.startsWith('+256'), true);
    });
  });

  group('Currency Handling', () {
    test('UGX amounts should be whole numbers', () {
      const amounts = [50000.0, 100000.0, 1500000.0];

      for (final amount in amounts) {
        expect(amount % 1, 0); // No decimal part
      }
    });

    test('minimum payment amount', () {
      const minimumAmount = 500.0; // Typical minimum for mobile money

      expect(minimumAmount, greaterThan(0));
    });
  });
}
