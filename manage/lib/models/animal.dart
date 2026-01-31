enum AnimalStatus { healthy, sick, pregnant, nursing, sold, deceased }

enum Gender { male, female }

enum AnimalType {
  cattle,
  goat,
  sheep,
  pig,
  poultry,
  rabbit,
  other;

  String get displayName {
    return switch (this) {
      AnimalType.cattle => 'Cattle',
      AnimalType.goat => 'Goat',
      AnimalType.sheep => 'Sheep',
      AnimalType.pig => 'Pig',
      AnimalType.poultry => 'Poultry',
      AnimalType.rabbit => 'Rabbit',
      AnimalType.other => 'Other',
    };
  }

  String get icon {
    return switch (this) {
      AnimalType.cattle => '🐄',
      AnimalType.goat => '🐐',
      AnimalType.sheep => '🐑',
      AnimalType.pig => '🐷',
      AnimalType.poultry => '🐔',
      AnimalType.rabbit => '🐰',
      AnimalType.other => '🐾',
    };
  }
}

class Animal {
  final String id;
  final String farmId;
  final String tagId;
  final String? name;
  final AnimalType species;
  final String? breed;
  final Gender gender;
  final DateTime? birthDate;
  final double? currentWeight;
  final AnimalStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Media
  final String? photoUrl; // Profile photo URL
  final List<String> photoGallery; // Additional photos

  // Lineage
  final String? motherId;
  final String? fatherId;

  // Purchase info
  final double? purchasePrice;
  final DateTime? purchaseDate;

  Animal({
    required this.id,
    required this.farmId,
    required this.tagId,
    this.name,
    required this.species,
    this.breed,
    required this.gender,
    this.birthDate,
    this.currentWeight,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.photoGallery = const [],
    this.motherId,
    this.fatherId,
    this.purchasePrice,
    this.purchaseDate,
  });

  int? get ageInDays =>
      birthDate != null ? DateTime.now().difference(birthDate!).inDays : null;

  String get ageFormatted {
    final days = ageInDays;
    if (days == null) return 'Unknown';
    if (days < 30) return '$days days';
    if (days < 365) return '${(days / 30).floor()} months';
    final years = (days / 365).floor();
    final remainingMonths = ((days % 365) / 30).floor();
    return '$years yr${years > 1 ? 's' : ''} $remainingMonths mo';
  }

  String get displayName => name ?? tagId;

  /// Create from Supabase row (snake_case fields)
  factory Animal.fromSupabase(Map<String, dynamic> data) {
    return Animal(
      id: data['id'] ?? '',
      farmId: data['farm_id'] ?? '',
      tagId: data['tag_id'] ?? '',
      name: data['name'],
      species: AnimalType.values.firstWhere(
        (e) => e.name == data['species'],
        orElse: () => AnimalType.cattle,
      ),
      breed: data['breed'],
      gender: Gender.values.firstWhere(
        (e) => e.name == data['gender'],
        orElse: () => Gender.female,
      ),
      birthDate: data['date_of_birth'] != null
          ? DateTime.parse(data['date_of_birth'])
          : null,
      currentWeight: data['current_weight'] != null
          ? (data['current_weight'] as num).toDouble()
          : null,
      status: AnimalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AnimalStatus.healthy,
      ),
      notes: data['notes'],
      createdAt: DateTime.parse(
        data['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        data['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      photoUrl: data['photo_url'],
      photoGallery: List<String>.from(data['photo_gallery'] ?? []),
      motherId: data['mother_id'],
      fatherId: data['father_id'],
      purchasePrice: data['purchase_price'] != null
          ? (data['purchase_price'] as num).toDouble()
          : null,
      purchaseDate: data['purchase_date'] != null
          ? DateTime.parse(data['purchase_date'])
          : null,
    );
  }

  /// Convert to Supabase row (snake_case fields)
  Map<String, dynamic> toSupabase() {
    return {
      'farm_id': farmId,
      'tag_id': tagId,
      'name': name,
      'species': species.name,
      'breed': breed,
      'gender': gender.name,
      'date_of_birth': birthDate?.toIso8601String(),
      'current_weight': currentWeight,
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'photo_url': photoUrl,
      'photo_gallery': photoGallery,
      'mother_id': motherId,
      'father_id': fatherId,
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate?.toIso8601String(),
    };
  }

  Animal copyWith({
    String? id,
    String? farmId,
    String? tagId,
    String? name,
    AnimalType? species,
    String? breed,
    Gender? gender,
    DateTime? birthDate,
    double? currentWeight,
    AnimalStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? photoUrl,
    List<String>? photoGallery,
    String? motherId,
    String? fatherId,
    double? purchasePrice,
    DateTime? purchaseDate,
  }) {
    return Animal(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      tagId: tagId ?? this.tagId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      currentWeight: currentWeight ?? this.currentWeight,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      photoGallery: photoGallery ?? this.photoGallery,
      motherId: motherId ?? this.motherId,
      fatherId: fatherId ?? this.fatherId,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }
}
