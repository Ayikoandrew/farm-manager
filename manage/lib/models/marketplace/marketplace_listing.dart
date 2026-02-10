import 'marketplace_enums.dart';

/// Marketplace listing model
class MarketplaceListing {
  final String id;
  final String sellerId;
  final String? animalId;

  // Animal details
  final String species;
  final String? breed;
  final String? name;
  final String? tagNumber;
  final int? ageMonths;
  final double? weightKg;
  final String? gender;
  final bool isPregnant;
  final bool isLactating;

  // Health info
  final String healthStatus;
  final bool vaccinated;
  final DateTime? lastVaccinationDate;
  final bool dewormed;
  final String? healthNotes;

  // Listing details
  final String title;
  final String? description;
  final ListingType listingType;
  final ListingStatus status;

  // Pricing
  final double price;
  final String currency;
  final bool negotiable;
  final double? minAcceptablePrice;

  // Quantity
  final int quantity;
  final String unit;

  // Location
  final double? latitude;
  final double? longitude;
  final String region;
  final String? district;
  final String? address;
  final bool hideExactLocation;

  // Delivery
  final DeliveryMethod deliveryMethod;
  final int? deliveryRadiusKm;
  final double? deliveryFee;

  // Media
  final List<String> photoUrls;
  final String? videoUrl;
  final List<String> documentUrls;

  // Stats
  final int viewsCount;
  final int inquiriesCount;
  final int favoritesCount;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime? soldAt;

  // Joined seller info (from view)
  final String? sellerName;
  final double? sellerRating;
  final int? sellerReviews;
  final VerificationLevel? sellerVerification;
  final String? sellerRegion;

  // Computed distance (from search)
  final double? distanceKm;

  MarketplaceListing({
    required this.id,
    required this.sellerId,
    this.animalId,
    required this.species,
    this.breed,
    this.name,
    this.tagNumber,
    this.ageMonths,
    this.weightKg,
    this.gender,
    this.isPregnant = false,
    this.isLactating = false,
    this.healthStatus = 'healthy',
    this.vaccinated = false,
    this.lastVaccinationDate,
    this.dewormed = false,
    this.healthNotes,
    required this.title,
    this.description,
    this.listingType = ListingType.sale,
    this.status = ListingStatus.draft,
    required this.price,
    this.currency = 'UGX',
    this.negotiable = true,
    this.minAcceptablePrice,
    this.quantity = 1,
    this.unit = 'head',
    this.latitude,
    this.longitude,
    required this.region,
    this.district,
    this.address,
    this.hideExactLocation = true,
    this.deliveryMethod = DeliveryMethod.pickup,
    this.deliveryRadiusKm,
    this.deliveryFee,
    this.photoUrls = const [],
    this.videoUrl,
    this.documentUrls = const [],
    this.viewsCount = 0,
    this.inquiriesCount = 0,
    this.favoritesCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.expiresAt,
    this.soldAt,
    this.sellerName,
    this.sellerRating,
    this.sellerReviews,
    this.sellerVerification,
    this.sellerRegion,
    this.distanceKm,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    return MarketplaceListing(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      animalId: json['animal_id'] as String?,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      name: json['name'] as String?,
      tagNumber: json['tag_number'] as String?,
      ageMonths: json['age_months'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
      isPregnant: json['is_pregnant'] as bool? ?? false,
      isLactating: json['is_lactating'] as bool? ?? false,
      healthStatus: json['health_status'] as String? ?? 'healthy',
      vaccinated: json['vaccinated'] as bool? ?? false,
      lastVaccinationDate: json['last_vaccination_date'] != null
          ? DateTime.parse(json['last_vaccination_date'] as String)
          : null,
      dewormed: json['dewormed'] as bool? ?? false,
      healthNotes: json['health_notes'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      listingType: ListingType.fromString(
        json['listing_type'] as String? ?? 'sale',
      ),
      status: ListingStatus.fromString(json['status'] as String? ?? 'draft'),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'UGX',
      negotiable: json['negotiable'] as bool? ?? true,
      minAcceptablePrice: (json['min_acceptable_price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit'] as String? ?? 'head',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      region: json['region'] as String,
      district: json['district'] as String?,
      address: json['address'] as String?,
      hideExactLocation: json['hide_exact_location'] as bool? ?? true,
      deliveryMethod: DeliveryMethod.fromString(
        json['delivery_method'] as String? ?? 'pickup',
      ),
      deliveryRadiusKm: json['delivery_radius_km'] as int?,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
      photoUrls: (json['photo_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      videoUrl: json['video_url'] as String?,
      documentUrls:
          (json['document_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      viewsCount: json['views_count'] as int? ?? 0,
      inquiriesCount: json['inquiries_count'] as int? ?? 0,
      favoritesCount: json['favorites_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      soldAt: json['sold_at'] != null
          ? DateTime.parse(json['sold_at'] as String)
          : null,
      // View fields
      sellerName: json['seller_name'] as String?,
      sellerRating: (json['seller_rating'] as num?)?.toDouble(),
      sellerReviews: json['seller_reviews'] as int?,
      sellerVerification: json['seller_verification'] != null
          ? VerificationLevel.fromString(json['seller_verification'] as String)
          : null,
      sellerRegion: json['seller_region'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'animal_id': animalId,
      'species': species,
      'breed': breed,
      'name': name,
      'tag_number': tagNumber,
      'age_months': ageMonths,
      'weight_kg': weightKg,
      'gender': gender,
      'is_pregnant': isPregnant,
      'is_lactating': isLactating,
      'health_status': healthStatus,
      'vaccinated': vaccinated,
      'last_vaccination_date': lastVaccinationDate?.toIso8601String(),
      'dewormed': dewormed,
      'health_notes': healthNotes,
      'title': title,
      'description': description,
      'listing_type': listingType.name,
      'status': status.name,
      'price': price,
      'currency': currency,
      'negotiable': negotiable,
      'min_acceptable_price': minAcceptablePrice,
      'quantity': quantity,
      'unit': unit,
      'region': region,
      'district': district,
      'address': address,
      'hide_exact_location': hideExactLocation,
      'delivery_method': deliveryMethod.name,
      'delivery_radius_km': deliveryRadiusKm,
      'delivery_fee': deliveryFee,
      'photo_urls': photoUrls,
      'video_url': videoUrl,
      'document_urls': documentUrls,
    };
  }

  /// For creating a new listing (insert)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id');

    if (latitude != null && longitude != null) {
      json['location'] = 'POINT($longitude $latitude)';
    }

    return json;
  }

  // Display helpers
  String get primaryPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : '';

  bool get hasPhotos => photoUrls.isNotEmpty;

  String get locationDisplay {
    final parts = <String>[];
    if (district != null) parts.add(district!);
    parts.add(region);
    return parts.join(', ');
  }

  String get priceDisplay {
    final formatter = _formatPrice(price);
    return '$formatter $currency';
  }

  String get ageDisplay {
    if (ageMonths == null) return 'Age unknown';
    if (ageMonths! < 12) return '$ageMonths months';
    final years = ageMonths! ~/ 12;
    final months = ageMonths! % 12;
    if (months == 0) return '$years year${years > 1 ? 's' : ''}';
    return '$years year${years > 1 ? 's' : ''} $months month${months > 1 ? 's' : ''}';
  }

  String get weightDisplay {
    if (weightKg == null) return 'Weight unknown';
    return '${weightKg!.toStringAsFixed(1)} kg';
  }

  String get distanceDisplay {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '< 1 km away';
    return '${distanceKm!.toStringAsFixed(1)} km away';
  }

  // String get speciesIcon => switch (species.toLowerCase()) {
  //   'cattle' => '🐄',
  //   'goat' => '🐐',
  //   'sheep' => '🐑',
  //   'pig' => '🐷',
  //   'chicken' => '🐔',
  //   'rabbit' => '🐰',
  //   'duck' => '🦆',
  //   'turkey' => '🦃',
  //   _ => '🐾',
  // };

  static String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  MarketplaceListing copyWith({
    String? animalId,
    String? species,
    String? breed,
    String? name,
    String? tagNumber,
    int? ageMonths,
    double? weightKg,
    String? gender,
    bool? isPregnant,
    bool? isLactating,
    String? healthStatus,
    bool? vaccinated,
    DateTime? lastVaccinationDate,
    bool? dewormed,
    String? healthNotes,
    String? title,
    String? description,
    ListingType? listingType,
    ListingStatus? status,
    double? price,
    String? currency,
    bool? negotiable,
    double? minAcceptablePrice,
    int? quantity,
    String? unit,
    double? latitude,
    double? longitude,
    String? region,
    String? district,
    String? address,
    bool? hideExactLocation,
    DeliveryMethod? deliveryMethod,
    int? deliveryRadiusKm,
    double? deliveryFee,
    List<String>? photoUrls,
    String? videoUrl,
    List<String>? documentUrls,
  }) {
    return MarketplaceListing(
      id: id,
      sellerId: sellerId,
      animalId: animalId ?? this.animalId,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      name: name ?? this.name,
      tagNumber: tagNumber ?? this.tagNumber,
      ageMonths: ageMonths ?? this.ageMonths,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      isPregnant: isPregnant ?? this.isPregnant,
      isLactating: isLactating ?? this.isLactating,
      healthStatus: healthStatus ?? this.healthStatus,
      vaccinated: vaccinated ?? this.vaccinated,
      lastVaccinationDate: lastVaccinationDate ?? this.lastVaccinationDate,
      dewormed: dewormed ?? this.dewormed,
      healthNotes: healthNotes ?? this.healthNotes,
      title: title ?? this.title,
      description: description ?? this.description,
      listingType: listingType ?? this.listingType,
      status: status ?? this.status,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      negotiable: negotiable ?? this.negotiable,
      minAcceptablePrice: minAcceptablePrice ?? this.minAcceptablePrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      region: region ?? this.region,
      district: district ?? this.district,
      address: address ?? this.address,
      hideExactLocation: hideExactLocation ?? this.hideExactLocation,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      photoUrls: photoUrls ?? this.photoUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      documentUrls: documentUrls ?? this.documentUrls,
      viewsCount: viewsCount,
      inquiriesCount: inquiriesCount,
      favoritesCount: favoritesCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      publishedAt: publishedAt,
      expiresAt: expiresAt,
      soldAt: soldAt,
      sellerName: sellerName,
      sellerRating: sellerRating,
      sellerReviews: sellerReviews,
      sellerVerification: sellerVerification,
      sellerRegion: sellerRegion,
      distanceKm: distanceKm,
    );
  }
}
