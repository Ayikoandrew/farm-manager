class WeightRecord {
  final String id;
  final String farmId;
  final String animalId;
  final DateTime date;
  final double weight; // in kg
  final String? notes;
  final DateTime createdAt;

  WeightRecord({
    required this.id,
    required this.farmId,
    required this.animalId,
    required this.date,
    required this.weight,
    this.notes,
    required this.createdAt,
  });

  /// Create from Supabase row (snake_case fields)
  factory WeightRecord.fromSupabase(Map<String, dynamic> data) {
    return WeightRecord(
      id: data['id'] ?? '',
      farmId: data['farm_id'] ?? '',
      animalId: data['animal_id'] ?? '',
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      weight: (data['weight'] ?? 0).toDouble(),
      notes: data['notes'],
      createdAt: DateTime.parse(
        data['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert to Supabase row (snake_case fields)
  Map<String, dynamic> toSupabase() {
    return {
      'farm_id': farmId,
      'animal_id': animalId,
      'date': date.toIso8601String(),
      'weight': weight,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WeightRecord copyWith({
    String? id,
    String? farmId,
    String? animalId,
    DateTime? date,
    double? weight,
    String? notes,
    DateTime? createdAt,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      animalId: animalId ?? this.animalId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
