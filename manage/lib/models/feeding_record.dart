class FeedingRecord {
  final String id;
  final String farmId;
  final String animalId;
  final DateTime date;
  final String feedType;
  final double quantity; // in kg
  final String? notes;
  final DateTime createdAt;

  FeedingRecord({
    required this.id,
    required this.farmId,
    required this.animalId,
    required this.date,
    required this.feedType,
    required this.quantity,
    this.notes,
    required this.createdAt,
  });

  /// Create from Supabase row (snake_case fields)
  factory FeedingRecord.fromSupabase(Map<String, dynamic> data) {
    return FeedingRecord(
      id: data['id'] ?? '',
      farmId: data['farm_id'] ?? '',
      animalId: data['animal_id'] ?? '',
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      feedType: data['feed_type'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
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
      'feed_type': feedType,
      'quantity': quantity,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FeedingRecord copyWith({
    String? id,
    String? farmId,
    String? animalId,
    DateTime? date,
    String? feedType,
    double? quantity,
    String? notes,
    DateTime? createdAt,
  }) {
    return FeedingRecord(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      animalId: animalId ?? this.animalId,
      date: date ?? this.date,
      feedType: feedType ?? this.feedType,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
