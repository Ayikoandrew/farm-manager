/// Marketplace Enums
enum ListingType {
  sale,
  auction,
  trade;

  String get displayName => switch (this) {
    ListingType.sale => 'For Sale',
    ListingType.auction => 'Auction',
    ListingType.trade => 'Trade',
  };

  static ListingType fromString(String value) => ListingType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ListingType.sale,
  );
}

enum ListingStatus {
  draft,
  active,
  sold,
  expired,
  cancelled;

  String get displayName => switch (this) {
    ListingStatus.draft => 'Draft',
    ListingStatus.active => 'Active',
    ListingStatus.sold => 'Sold',
    ListingStatus.expired => 'Expired',
    ListingStatus.cancelled => 'Cancelled',
  };

  bool get isEditable =>
      this == ListingStatus.draft || this == ListingStatus.active;

  static ListingStatus fromString(String value) => ListingStatus.values
      .firstWhere((e) => e.name == value, orElse: () => ListingStatus.draft);
}

enum InquiryStatus {
  pending,
  responded,
  accepted,
  rejected,
  expired;

  String get displayName => switch (this) {
    InquiryStatus.pending => 'Pending',
    InquiryStatus.responded => 'Responded',
    InquiryStatus.accepted => 'Accepted',
    InquiryStatus.rejected => 'Rejected',
    InquiryStatus.expired => 'Expired',
  };

  static InquiryStatus fromString(String value) => InquiryStatus.values
      .firstWhere((e) => e.name == value, orElse: () => InquiryStatus.pending);
}

enum TransactionStatus {
  pending,
  paid,
  completed,
  disputed,
  cancelled,
  refunded;

  String get displayName => switch (this) {
    TransactionStatus.pending => 'Pending',
    TransactionStatus.paid => 'Paid',
    TransactionStatus.completed => 'Completed',
    TransactionStatus.disputed => 'Disputed',
    TransactionStatus.cancelled => 'Cancelled',
    TransactionStatus.refunded => 'Refunded',
  };

  bool get isActive =>
      this == TransactionStatus.pending || this == TransactionStatus.paid;

  static TransactionStatus fromString(String value) =>
      TransactionStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TransactionStatus.pending,
      );
}

enum DeliveryMethod {
  pickup,
  delivery,
  both;

  String get displayName => switch (this) {
    DeliveryMethod.pickup => 'Pickup Only',
    DeliveryMethod.delivery => 'Delivery Available',
    DeliveryMethod.both => 'Pickup or Delivery',
  };

  static DeliveryMethod fromString(String value) => DeliveryMethod.values
      .firstWhere((e) => e.name == value, orElse: () => DeliveryMethod.pickup);
}

enum VerificationLevel {
  unverified,
  phoneVerified,
  idVerified,
  farmVerified;

  String get displayName => switch (this) {
    VerificationLevel.unverified => 'Unverified',
    VerificationLevel.phoneVerified => 'Phone Verified',
    VerificationLevel.idVerified => 'ID Verified',
    VerificationLevel.farmVerified => 'Farm Verified',
  };

  String get badge => switch (this) {
    VerificationLevel.unverified => '',
    VerificationLevel.phoneVerified => '📱',
    VerificationLevel.idVerified => '✅',
    VerificationLevel.farmVerified => '🏆',
  };

  bool get isVerified => this != VerificationLevel.unverified;

  static VerificationLevel fromString(String? value) {
    if (value == null) return VerificationLevel.unverified;
    final normalized = value.replaceAll('_', '').toLowerCase();
    return switch (normalized) {
      'phoneverified' => VerificationLevel.phoneVerified,
      'idverified' => VerificationLevel.idVerified,
      'farmverified' => VerificationLevel.farmVerified,
      _ => VerificationLevel.unverified,
    };
  }
}

enum ReportReason {
  fraud,
  misrepresentation,
  inappropriate,
  spam,
  other;

  String get displayName => switch (this) {
    ReportReason.fraud => 'Fraud/Scam',
    ReportReason.misrepresentation => 'Misrepresentation',
    ReportReason.inappropriate => 'Inappropriate Content',
    ReportReason.spam => 'Spam',
    ReportReason.other => 'Other',
  };

  static ReportReason fromString(String value) => ReportReason.values
      .firstWhere((e) => e.name == value, orElse: () => ReportReason.other);
}

enum MessageType {
  text,
  image,
  location,
  offer,
  system;

  static MessageType fromString(String? value) => MessageType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => MessageType.text,
  );
}

enum OfferStatus {
  pending,
  accepted,
  rejected,
  countered,
  expired;

  static OfferStatus? fromString(String? value) {
    if (value == null) return null;
    return OfferStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OfferStatus.pending,
    );
  }
}
