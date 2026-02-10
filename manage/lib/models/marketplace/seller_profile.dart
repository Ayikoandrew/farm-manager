import 'marketplace_enums.dart';

/// Seller profile for marketplace
class SellerProfile {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? farmName;
  final String? farmDescription;
  final int? yearsExperience;
  final String? phoneNumber;
  final String? whatsappNumber;
  final double? latitude;
  final double? longitude;
  final String region;
  final String? district;
  final String? village;
  final String? address;
  final VerificationLevel verificationLevel;
  final DateTime? verifiedAt;
  final int totalListings;
  final int activeListings;
  final int totalSales;
  final double avgRating;
  final int totalReviews;
  final double responseRate;
  final double? avgResponseTimeHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  SellerProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.farmName,
    this.farmDescription,
    this.yearsExperience,
    this.phoneNumber,
    this.whatsappNumber,
    this.latitude,
    this.longitude,
    required this.region,
    this.district,
    this.village,
    this.address,
    this.verificationLevel = VerificationLevel.unverified,
    this.verifiedAt,
    this.totalListings = 0,
    this.activeListings = 0,
    this.totalSales = 0,
    this.avgRating = 0,
    this.totalReviews = 0,
    this.responseRate = 0,
    this.avgResponseTimeHours,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      farmName: json['farm_name'] as String?,
      farmDescription: json['farm_description'] as String?,
      yearsExperience: json['years_experience'] as int?,
      phoneNumber: json['phone_number'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      region: json['region'] as String,
      district: json['district'] as String?,
      village: json['village'] as String?,
      address: json['address'] as String?,
      verificationLevel: VerificationLevel.fromString(
        json['verification_level'] as String?,
      ),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      totalListings: json['total_listings'] as int? ?? 0,
      activeListings: json['active_listings'] as int? ?? 0,
      totalSales: json['total_sales'] as int? ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      responseRate: (json['response_rate'] as num?)?.toDouble() ?? 0,
      avgResponseTimeHours: (json['avg_response_time_hours'] as num?)
          ?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'bio': bio,
      'farm_name': farmName,
      'farm_description': farmDescription,
      'years_experience': yearsExperience,
      'phone_number': phoneNumber,
      'whatsapp_number': whatsappNumber,
      'region': region,
      'district': district,
      'village': village,
      'address': address,
      'verification_level': verificationLevel.name,
    };
  }

  /// Create location point for database insert
  String? get locationPoint {
    if (latitude != null && longitude != null) {
      return 'POINT($longitude $latitude)';
    }
    return null;
  }

  bool get hasLocation => latitude != null && longitude != null;

  String get locationDisplay {
    final parts = <String>[];
    if (village != null) parts.add(village!);
    if (district != null) parts.add(district!);
    parts.add(region);
    return parts.join(', ');
  }

  String get ratingDisplay {
    if (totalReviews == 0) return 'No reviews yet';
    return '${avgRating.toStringAsFixed(1)} ⭐ ($totalReviews reviews)';
  }

  SellerProfile copyWith({
    String? displayName,
    String? bio,
    String? farmName,
    String? farmDescription,
    int? yearsExperience,
    String? phoneNumber,
    String? whatsappNumber,
    double? latitude,
    double? longitude,
    String? region,
    String? district,
    String? village,
    String? address,
  }) {
    return SellerProfile(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      farmName: farmName ?? this.farmName,
      farmDescription: farmDescription ?? this.farmDescription,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      region: region ?? this.region,
      district: district ?? this.district,
      village: village ?? this.village,
      address: address ?? this.address,
      verificationLevel: verificationLevel,
      verifiedAt: verifiedAt,
      totalListings: totalListings,
      activeListings: activeListings,
      totalSales: totalSales,
      avgRating: avgRating,
      totalReviews: totalReviews,
      responseRate: responseRate,
      avgResponseTimeHours: avgResponseTimeHours,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
