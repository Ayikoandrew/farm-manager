import 'animal.dart';

enum BreedingStatus {
  inHeat,
  bred,
  pregnant,
  delivered, // Generic term - farrowed (pig), calved (cattle), kidded (goat)
  failed;

  String get displayName {
    return switch (this) {
      BreedingStatus.inHeat => 'In Heat',
      BreedingStatus.bred => 'Bred',
      BreedingStatus.pregnant => 'Pregnant',
      BreedingStatus.delivered => 'Delivered',
      BreedingStatus.failed => 'Failed',
    };
  }

  /// Get species-specific display name for delivery status
  String displayNameForSpecies(AnimalType? species) {
    if (this != BreedingStatus.delivered) return displayName;
    return switch (species) {
      AnimalType.pig => 'Farrowed',
      AnimalType.cattle => 'Calved',
      AnimalType.goat => 'Kidded',
      AnimalType.sheep => 'Lambed',
      AnimalType.rabbit => 'Kindled',
      AnimalType.poultry => 'Hatched',
      _ => 'Delivered',
    };
  }
}

/// Gestation periods in days for different species
class GestationPeriods {
  static const int pig = 114; // ~3 months, 3 weeks, 3 days
  static const int cattle = 283; // ~9 months
  static const int goat = 150; // ~5 months
  static const int sheep = 147; // ~5 months
  static const int rabbit = 31; // ~1 month
  static const int other = 60; // Default fallback

  /// Get gestation period for a species
  static int forSpecies(AnimalType species) {
    return switch (species) {
      AnimalType.pig => pig,
      AnimalType.cattle => cattle,
      AnimalType.goat => goat,
      AnimalType.sheep => sheep,
      AnimalType.rabbit => rabbit,
      AnimalType.poultry => 21, // Chicken incubation
      AnimalType.other => other,
    };
  }

  /// Get heat cycle interval for a species (days between cycles)
  static int heatCycleForSpecies(AnimalType species) {
    return switch (species) {
      AnimalType.pig => 21,
      AnimalType.cattle => 21,
      AnimalType.goat => 21,
      AnimalType.sheep => 17,
      AnimalType.rabbit => 14, // Can breed frequently
      AnimalType.poultry => 0, // N/A
      AnimalType.other => 21,
    };
  }

  /// Get species-specific term for delivery
  static String deliveryTermForSpecies(AnimalType? species) {
    return switch (species) {
      AnimalType.pig => 'Farrowing',
      AnimalType.cattle => 'Calving',
      AnimalType.goat => 'Kidding',
      AnimalType.sheep => 'Lambing',
      AnimalType.rabbit => 'Kindling',
      AnimalType.poultry => 'Hatching',
      _ => 'Delivery',
    };
  }

  /// Get species-specific term for offspring
  static String offspringTermForSpecies(
    AnimalType? species, {
    bool plural = true,
  }) {
    final term = switch (species) {
      AnimalType.pig => plural ? 'Piglets' : 'Piglet',
      AnimalType.cattle => plural ? 'Calves' : 'Calf',
      AnimalType.goat => plural ? 'Kids' : 'Kid',
      AnimalType.sheep => plural ? 'Lambs' : 'Lamb',
      AnimalType.rabbit => plural ? 'Kits' : 'Kit',
      AnimalType.poultry => plural ? 'Chicks' : 'Chick',
      _ => plural ? 'Offspring' : 'Offspring',
    };
    return term;
  }
}

class BreedingRecord {
  final String id;
  final String farmId;
  final String animalId;
  final String? sireId; // Male animal used for breeding
  final DateTime heatDate;
  final DateTime? breedingDate;
  final DateTime? expectedDeliveryDate; // Generic: was expectedFarrowDate
  final DateTime? actualDeliveryDate; // Generic: was actualFarrowDate
  final BreedingStatus status;
  final int? litterSize;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BreedingRecord({
    required this.id,
    required this.farmId,
    required this.animalId,
    this.sireId,
    required this.heatDate,
    this.breedingDate,
    this.expectedDeliveryDate,
    this.actualDeliveryDate,
    required this.status,
    this.litterSize,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Legacy getters for backward compatibility
  DateTime? get expectedFarrowDate => expectedDeliveryDate;
  DateTime? get actualFarrowDate => actualDeliveryDate;

  int? get daysPregnant {
    if (breedingDate == null || status != BreedingStatus.pregnant) return null;
    return DateTime.now().difference(breedingDate!).inDays;
  }

  int? get daysUntilDelivery {
    if (expectedDeliveryDate == null || status != BreedingStatus.pregnant) {
      return null;
    }
    return expectedDeliveryDate!.difference(DateTime.now()).inDays;
  }

  // Legacy getter
  int? get daysUntilFarrowing => daysUntilDelivery;

  /// Calculate expected delivery date based on species and breeding date
  static DateTime calculateExpectedDeliveryDate(
    DateTime breedingDate,
    AnimalType species,
  ) {
    return breedingDate.add(
      Duration(days: GestationPeriods.forSpecies(species)),
    );
  }

  /// Create from Supabase row (snake_case fields)
  factory BreedingRecord.fromSupabase(Map<String, dynamic> data) {
    // Handle both old 'farrowed' and new 'delivered' status
    var statusStr = data['status'] as String? ?? 'inHeat';
    if (statusStr == 'farrowed') statusStr = 'delivered';

    return BreedingRecord(
      id: data['id'] ?? '',
      farmId: data['farm_id'] ?? '',
      animalId: data['animal_id'] ?? '',
      sireId: data['sire_id'],
      heatDate: DateTime.parse(
        data['heat_date'] ?? DateTime.now().toIso8601String(),
      ),
      breedingDate: data['breeding_date'] != null
          ? DateTime.parse(data['breeding_date'])
          : null,
      // Support both old and new field names
      expectedDeliveryDate: data['expected_delivery_date'] != null
          ? DateTime.parse(data['expected_delivery_date'])
          : data['expected_farrow_date'] != null
          ? DateTime.parse(data['expected_farrow_date'])
          : null,
      actualDeliveryDate: data['actual_delivery_date'] != null
          ? DateTime.parse(data['actual_delivery_date'])
          : data['actual_farrow_date'] != null
          ? DateTime.parse(data['actual_farrow_date'])
          : null,
      status: BreedingStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => BreedingStatus.inHeat,
      ),
      litterSize: data['litter_size'],
      notes: data['notes'],
      createdAt: DateTime.parse(
        data['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        data['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert to Supabase row (snake_case fields)
  Map<String, dynamic> toSupabase() {
    return {
      'farm_id': farmId,
      'animal_id': animalId,
      'sire_id': sireId,
      'heat_date': heatDate.toIso8601String(),
      'breeding_date': breedingDate?.toIso8601String(),
      // Write to both old and new field names for compatibility
      'expected_farrow_date': expectedDeliveryDate?.toIso8601String(),
      'actual_farrow_date': actualDeliveryDate?.toIso8601String(),
      'status': status.name,
      'litter_size': litterSize,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BreedingRecord copyWith({
    String? id,
    String? farmId,
    String? animalId,
    String? sireId,
    DateTime? heatDate,
    DateTime? breedingDate,
    DateTime? expectedDeliveryDate,
    DateTime? actualDeliveryDate,
    BreedingStatus? status,
    int? litterSize,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BreedingRecord(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      animalId: animalId ?? this.animalId,
      sireId: sireId ?? this.sireId,
      heatDate: heatDate ?? this.heatDate,
      breedingDate: breedingDate ?? this.breedingDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      status: status ?? this.status,
      litterSize: litterSize ?? this.litterSize,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
