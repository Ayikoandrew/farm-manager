import 'marketplace_enums.dart';

/// Transaction record for completed/in-progress sales
class MarketplaceTransaction {
  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final String? conversationId;
  final Map<String, dynamic> animalSnapshot;
  final double agreedPrice;
  final String currency;
  final int quantity;
  final String? paymentMethod;
  final String? paymentReference;
  final String paymentStatus;
  final double amountPaid;
  final DeliveryMethod? deliveryMethod;
  final String? deliveryAddress;
  final double deliveryFee;
  final DateTime? deliveryDate;
  final TransactionStatus status;
  final bool buyerConfirmed;
  final bool sellerConfirmed;
  final String? disputeReason;
  final DateTime? disputeOpenedAt;
  final DateTime? disputeResolvedAt;
  final String? disputeResolution;
  final String? buyerNotes;
  final String? sellerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  MarketplaceTransaction({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    this.conversationId,
    required this.animalSnapshot,
    required this.agreedPrice,
    this.currency = 'UGX',
    this.quantity = 1,
    this.paymentMethod,
    this.paymentReference,
    this.paymentStatus = 'pending',
    this.amountPaid = 0,
    this.deliveryMethod,
    this.deliveryAddress,
    this.deliveryFee = 0,
    this.deliveryDate,
    this.status = TransactionStatus.pending,
    this.buyerConfirmed = false,
    this.sellerConfirmed = false,
    this.disputeReason,
    this.disputeOpenedAt,
    this.disputeResolvedAt,
    this.disputeResolution,
    this.buyerNotes,
    this.sellerNotes,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory MarketplaceTransaction.fromJson(Map<String, dynamic> json) {
    return MarketplaceTransaction(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      conversationId: json['conversation_id'] as String?,
      animalSnapshot: json['animal_snapshot'] as Map<String, dynamic>,
      agreedPrice: (json['agreed_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'UGX',
      quantity: json['quantity'] as int? ?? 1,
      paymentMethod: json['payment_method'] as String?,
      paymentReference: json['payment_reference'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      deliveryMethod: json['delivery_method'] != null
          ? DeliveryMethod.fromString(json['delivery_method'] as String)
          : null,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      status: TransactionStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      buyerConfirmed: json['buyer_confirmed'] as bool? ?? false,
      sellerConfirmed: json['seller_confirmed'] as bool? ?? false,
      disputeReason: json['dispute_reason'] as String?,
      disputeOpenedAt: json['dispute_opened_at'] != null
          ? DateTime.parse(json['dispute_opened_at'] as String)
          : null,
      disputeResolvedAt: json['dispute_resolved_at'] != null
          ? DateTime.parse(json['dispute_resolved_at'] as String)
          : null,
      disputeResolution: json['dispute_resolution'] as String?,
      buyerNotes: json['buyer_notes'] as String?,
      sellerNotes: json['seller_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
    );
  }

  double get totalAmount => agreedPrice + deliveryFee;
  double get balanceRemaining => totalAmount - amountPaid;
  bool get isFullyPaid => amountPaid >= totalAmount;
  bool get isDisputed => status == TransactionStatus.disputed;
  bool get canComplete => buyerConfirmed && sellerConfirmed && isFullyPaid;

  Map<String, dynamic> toJson() {
    return {
      'listing_id': listingId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'conversation_id': conversationId,
      'animal_snapshot': animalSnapshot,
      'agreed_price': agreedPrice,
      'currency': currency,
      'quantity': quantity,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'payment_status': paymentStatus,
      'amount_paid': amountPaid,
      'delivery_method': deliveryMethod?.name,
      'delivery_address': deliveryAddress,
      'delivery_fee': deliveryFee,
      'delivery_date': deliveryDate?.toIso8601String(),
      'status': status.name,
      'buyer_confirmed': buyerConfirmed,
      'seller_confirmed': sellerConfirmed,
      'dispute_reason': disputeReason,
      'buyer_notes': buyerNotes,
      'seller_notes': sellerNotes,
    };
  }

  MarketplaceTransaction copyWith({
    String? id,
    String? listingId,
    String? buyerId,
    String? sellerId,
    String? conversationId,
    Map<String, dynamic>? animalSnapshot,
    double? agreedPrice,
    String? currency,
    int? quantity,
    String? paymentMethod,
    String? paymentReference,
    String? paymentStatus,
    double? amountPaid,
    DeliveryMethod? deliveryMethod,
    String? deliveryAddress,
    double? deliveryFee,
    DateTime? deliveryDate,
    TransactionStatus? status,
    bool? buyerConfirmed,
    bool? sellerConfirmed,
    String? disputeReason,
    DateTime? disputeOpenedAt,
    DateTime? disputeResolvedAt,
    String? disputeResolution,
    String? buyerNotes,
    String? sellerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return MarketplaceTransaction(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      conversationId: conversationId ?? this.conversationId,
      animalSnapshot: animalSnapshot ?? this.animalSnapshot,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountPaid: amountPaid ?? this.amountPaid,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      buyerConfirmed: buyerConfirmed ?? this.buyerConfirmed,
      sellerConfirmed: sellerConfirmed ?? this.sellerConfirmed,
      disputeReason: disputeReason ?? this.disputeReason,
      disputeOpenedAt: disputeOpenedAt ?? this.disputeOpenedAt,
      disputeResolvedAt: disputeResolvedAt ?? this.disputeResolvedAt,
      disputeResolution: disputeResolution ?? this.disputeResolution,
      buyerNotes: buyerNotes ?? this.buyerNotes,
      sellerNotes: sellerNotes ?? this.sellerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}

/// Review left for a seller
class MarketplaceReview {
  final String id;
  final String? transactionId;
  final String reviewerId;
  final String sellerId;
  final String? listingId;
  final int rating;
  final int? communicationRating;
  final int? accuracyRating;
  final int? deliveryRating;
  final String? title;
  final String? reviewText;
  final bool verifiedPurchase;
  final List<String>? photoUrls;
  final String? sellerResponse;
  final DateTime? sellerRespondedAt;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? reviewerName;
  final String? reviewerPhoto;

  MarketplaceReview({
    required this.id,
    this.transactionId,
    required this.reviewerId,
    required this.sellerId,
    this.listingId,
    required this.rating,
    this.communicationRating,
    this.accuracyRating,
    this.deliveryRating,
    this.title,
    this.reviewText,
    this.verifiedPurchase = false,
    this.photoUrls,
    this.sellerResponse,
    this.sellerRespondedAt,
    this.isVisible = true,
    required this.createdAt,
    required this.updatedAt,
    this.reviewerName,
    this.reviewerPhoto,
  });

  factory MarketplaceReview.fromJson(Map<String, dynamic> json) {
    return MarketplaceReview(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String?,
      reviewerId: json['reviewer_id'] as String,
      sellerId: json['seller_id'] as String,
      listingId: json['listing_id'] as String?,
      rating: json['rating'] as int,
      communicationRating: json['communication_rating'] as int?,
      accuracyRating: json['accuracy_rating'] as int?,
      deliveryRating: json['delivery_rating'] as int?,
      title: json['title'] as String?,
      reviewText: json['review_text'] as String?,
      verifiedPurchase: json['verified_purchase'] as bool? ?? false,
      photoUrls: (json['photo_urls'] as List<dynamic>?)?.cast<String>(),
      sellerResponse: json['seller_response'] as String?,
      sellerRespondedAt: json['seller_responded_at'] != null
          ? DateTime.parse(json['seller_responded_at'] as String)
          : null,
      isVisible: json['is_visible'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      reviewerName: json['reviewer_name'] as String?,
      reviewerPhoto: json['reviewer_photo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'reviewer_id': reviewerId,
      'seller_id': sellerId,
      'listing_id': listingId,
      'rating': rating,
      'communication_rating': communicationRating,
      'accuracy_rating': accuracyRating,
      'delivery_rating': deliveryRating,
      'title': title,
      'review_text': reviewText,
      'photo_urls': photoUrls,
      'verified_purchase': verifiedPurchase,
    };
  }

  /// Returns star emoji display for the rating
  String get ratingDisplay => '⭐' * rating;

  /// Calculates average of all sub-ratings (if provided)
  double get averageSubRating {
    final ratings = <int>[];
    if (communicationRating != null) ratings.add(communicationRating!);
    if (accuracyRating != null) ratings.add(accuracyRating!);
    if (deliveryRating != null) ratings.add(deliveryRating!);
    if (ratings.isEmpty) return rating.toDouble();
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  /// Whether seller has responded to this review
  bool get hasSellerResponse =>
      sellerResponse != null && sellerResponse!.isNotEmpty;

  /// Time since review was created
  Duration get age => DateTime.now().difference(createdAt);

  MarketplaceReview copyWith({
    String? id,
    String? transactionId,
    String? reviewerId,
    String? sellerId,
    String? listingId,
    int? rating,
    int? communicationRating,
    int? accuracyRating,
    int? deliveryRating,
    String? title,
    String? reviewText,
    bool? verifiedPurchase,
    List<String>? photoUrls,
    String? sellerResponse,
    DateTime? sellerRespondedAt,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reviewerName,
    String? reviewerPhoto,
  }) {
    return MarketplaceReview(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      reviewerId: reviewerId ?? this.reviewerId,
      sellerId: sellerId ?? this.sellerId,
      listingId: listingId ?? this.listingId,
      rating: rating ?? this.rating,
      communicationRating: communicationRating ?? this.communicationRating,
      accuracyRating: accuracyRating ?? this.accuracyRating,
      deliveryRating: deliveryRating ?? this.deliveryRating,
      title: title ?? this.title,
      reviewText: reviewText ?? this.reviewText,
      verifiedPurchase: verifiedPurchase ?? this.verifiedPurchase,
      photoUrls: photoUrls ?? this.photoUrls,
      sellerResponse: sellerResponse ?? this.sellerResponse,
      sellerRespondedAt: sellerRespondedAt ?? this.sellerRespondedAt,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerPhoto: reviewerPhoto ?? this.reviewerPhoto,
    );
  }
}

/// Favorite/saved listing
class MarketplaceFavorite {
  final String id;
  final String userId;
  final String listingId;
  final String? notes;
  final double? priceAtSave;
  final bool notifyPriceDrop;
  final DateTime createdAt;

  MarketplaceFavorite({
    required this.id,
    required this.userId,
    required this.listingId,
    this.notes,
    this.priceAtSave,
    this.notifyPriceDrop = false,
    required this.createdAt,
  });

  factory MarketplaceFavorite.fromJson(Map<String, dynamic> json) {
    return MarketplaceFavorite(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      listingId: json['listing_id'] as String,
      notes: json['notes'] as String?,
      priceAtSave: (json['price_at_save'] as num?)?.toDouble(),
      notifyPriceDrop: json['notify_price_drop'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Report against a listing/user/review
class MarketplaceReport {
  final String id;
  final String reporterId;
  final String? listingId;
  final String? sellerId;
  final String? reviewId;
  final String? messageId;
  final ReportReason reason;
  final String description;
  final List<String>? evidenceUrls;
  final String status;
  final String? resolution;
  final DateTime createdAt;

  MarketplaceReport({
    required this.id,
    required this.reporterId,
    this.listingId,
    this.sellerId,
    this.reviewId,
    this.messageId,
    required this.reason,
    required this.description,
    this.evidenceUrls,
    this.status = 'pending',
    this.resolution,
    required this.createdAt,
  });

  factory MarketplaceReport.fromJson(Map<String, dynamic> json) {
    return MarketplaceReport(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      listingId: json['listing_id'] as String?,
      sellerId: json['seller_id'] as String?,
      reviewId: json['review_id'] as String?,
      messageId: json['message_id'] as String?,
      reason: ReportReason.fromString(json['reason'] as String),
      description: json['description'] as String,
      evidenceUrls: (json['evidence_urls'] as List<dynamic>?)?.cast<String>(),
      status: json['status'] as String? ?? 'pending',
      resolution: json['resolution'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reporter_id': reporterId,
      'listing_id': listingId,
      'seller_id': sellerId,
      'review_id': reviewId,
      'message_id': messageId,
      'reason': reason.name,
      'description': description,
      'evidence_urls': evidenceUrls,
    };
  }
}

/// Saved search for notifications
class MarketplaceSavedSearch {
  final String id;
  final String userId;
  final String name;
  final Map<String, dynamic> criteria;
  final bool notifyNewListings;
  final bool notifyPriceDrops;
  final String notificationFrequency;
  final DateTime? lastNotifiedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplaceSavedSearch({
    required this.id,
    required this.userId,
    required this.name,
    required this.criteria,
    this.notifyNewListings = true,
    this.notifyPriceDrops = false,
    this.notificationFrequency = 'daily',
    this.lastNotifiedAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketplaceSavedSearch.fromJson(Map<String, dynamic> json) {
    return MarketplaceSavedSearch(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      criteria: json['criteria'] as Map<String, dynamic>,
      notifyNewListings: json['notify_new_listings'] as bool? ?? true,
      notifyPriceDrops: json['notify_price_drops'] as bool? ?? false,
      notificationFrequency:
          json['notification_frequency'] as String? ?? 'daily',
      lastNotifiedAt: json['last_notified_at'] != null
          ? DateTime.parse(json['last_notified_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'criteria': criteria,
      'notify_new_listings': notifyNewListings,
      'notify_price_drops': notifyPriceDrops,
      'notification_frequency': notificationFrequency,
      'is_active': isActive,
    };
  }
}
