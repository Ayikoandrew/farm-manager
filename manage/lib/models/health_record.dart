enum HealthRecordType {
  vaccination,
  medication,
  checkup,
  treatment,
  surgery,
  observation,
}

/// Status of a health issue or treatment
enum HealthStatus { pending, inProgress, completed, cancelled }

/// Severity level for health observations
enum Severity { low, medium, high, critical }

/// Extension for HealthRecordType display names and icons
extension HealthRecordTypeExtension on HealthRecordType {
  String get displayName {
    switch (this) {
      case HealthRecordType.vaccination:
        return 'Vaccination';
      case HealthRecordType.medication:
        return 'Medication';
      case HealthRecordType.checkup:
        return 'Checkup';
      case HealthRecordType.treatment:
        return 'Treatment';
      case HealthRecordType.surgery:
        return 'Surgery';
      case HealthRecordType.observation:
        return 'Observation';
    }
  }

  String get iconName {
    switch (this) {
      case HealthRecordType.vaccination:
        return 'vaccines';
      case HealthRecordType.medication:
        return 'medication';
      case HealthRecordType.checkup:
        return 'stethoscope';
      case HealthRecordType.treatment:
        return 'healing';
      case HealthRecordType.surgery:
        return 'local_hospital';
      case HealthRecordType.observation:
        return 'visibility';
    }
  }
}

/// A health record for an animal
class HealthRecord {
  final String id;
  final String farmId;
  final String animalId;
  final String? animalTagId; // Denormalized for easy display
  final HealthRecordType type;
  final DateTime date;
  final String title;
  final String? description;
  final HealthStatus status;
  final Severity? severity;

  // Vaccination specific
  final String? vaccineName;
  final String? vaccineManufacturer;
  final String? batchNumber;
  final DateTime? nextDueDate;

  // Medication specific
  final String? medicationName;
  final String? dosage;
  final String? frequency; // e.g., "twice daily"
  final int? durationDays;
  final DateTime? withdrawalEndDate; // For meat/milk safety

  // Treatment/Checkup specific
  final List<String> symptoms;
  final String? diagnosis;
  final String? treatment;
  final double? temperature; // Body temperature
  final double? weight; // Weight at time of record

  // Vet info
  final String? veterinarianName;
  final String? veterinarianContact;
  final double? cost;

  // Follow-up
  final DateTime? followUpDate;
  final String? followUpNotes;

  // Metadata
  final String recordedBy; // User ID who created the record
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> attachmentUrls; // Photos, documents

  HealthRecord({
    required this.id,
    required this.farmId,
    required this.animalId,
    this.animalTagId,
    required this.type,
    required this.date,
    required this.title,
    this.description,
    this.status = HealthStatus.completed,
    this.severity,
    this.vaccineName,
    this.vaccineManufacturer,
    this.batchNumber,
    this.nextDueDate,
    this.medicationName,
    this.dosage,
    this.frequency,
    this.durationDays,
    this.withdrawalEndDate,
    this.symptoms = const [],
    this.diagnosis,
    this.treatment,
    this.temperature,
    this.weight,
    this.veterinarianName,
    this.veterinarianContact,
    this.cost,
    this.followUpDate,
    this.followUpNotes,
    required this.recordedBy,
    required this.createdAt,
    required this.updatedAt,
    this.attachmentUrls = const [],
  });

  /// Check if this record has a pending follow-up
  bool get hasUpcomingFollowUp {
    if (followUpDate == null) return false;
    return followUpDate!.isAfter(DateTime.now());
  }

  /// Check if this record is overdue for follow-up
  bool get isFollowUpOverdue {
    if (followUpDate == null) return false;
    return followUpDate!.isBefore(DateTime.now()) &&
        status != HealthStatus.completed;
  }

  /// Check if animal is in withdrawal period (for medications)
  bool get isInWithdrawalPeriod {
    if (withdrawalEndDate == null) return false;
    return DateTime.now().isBefore(withdrawalEndDate!);
  }

  /// Days until withdrawal period ends
  int? get daysUntilWithdrawalEnds {
    if (withdrawalEndDate == null) return null;
    final diff = withdrawalEndDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  factory HealthRecord.fromSupabase(Map<String, dynamic> data) {
    return HealthRecord(
      id: data['id'] ?? '',
      farmId: data['farm_id'] ?? '',
      animalId: data['animal_id'] ?? '',
      animalTagId: data['animal_tag_id'],
      type: HealthRecordType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => HealthRecordType.observation,
      ),
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      title: data['title'] ?? '',
      description: data['description'] ?? data['notes'], // fallback to notes
      status: HealthStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => HealthStatus.completed,
      ),
      severity: data['severity'] != null
          ? Severity.values.firstWhere(
              (e) => e.name == data['severity'],
              orElse: () => Severity.low,
            )
          : null,
      vaccineName: data['vaccine_name'],
      vaccineManufacturer: data['vaccine_manufacturer'],
      batchNumber: data['batch_number'],
      nextDueDate: data['next_due_date'] != null
          ? DateTime.parse(data['next_due_date'])
          : null,
      medicationName:
          data['medication_name'] ??
          data['medication'], // schema uses 'medication'
      dosage: data['dosage'],
      frequency: data['frequency'],
      durationDays: data['duration_days'],
      withdrawalEndDate: data['withdrawal_end_date'] != null
          ? DateTime.parse(data['withdrawal_end_date'])
          : null,
      symptoms: List<String>.from(data['symptoms'] ?? []),
      diagnosis: data['diagnosis'],
      treatment: data['treatment'],
      temperature: (data['temperature'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      veterinarianName:
          data['veterinarian_name'] ??
          data['veterinarian'], // schema uses 'veterinarian'
      veterinarianContact: data['veterinarian_contact'],
      cost: (data['cost'] as num?)?.toDouble(),
      followUpDate: data['follow_up_date'] != null
          ? DateTime.parse(data['follow_up_date'])
          : null,
      followUpNotes: data['follow_up_notes'],
      recordedBy: data['recorded_by'] ?? '',
      createdAt: DateTime.parse(
        data['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        data['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      attachmentUrls: List<String>.from(data['attachment_urls'] ?? []),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'farm_id': farmId,
      'animal_id': animalId,
      'type': type.name,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'status': status.name,
      'veterinarian': veterinarianName,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'medication': medicationName,
      'dosage': dosage,
      'vaccine_name': vaccineName,
      'next_due_date': nextDueDate?.toIso8601String(),
      'follow_up_date': followUpDate?.toIso8601String(),
      'withdrawal_end_date': withdrawalEndDate?.toIso8601String(),
      'cost': cost,
      'notes': followUpNotes ?? description,
    };
  }

  HealthRecord copyWith({
    String? id,
    String? farmId,
    String? animalId,
    String? animalTagId,
    HealthRecordType? type,
    DateTime? date,
    String? title,
    String? description,
    HealthStatus? status,
    Severity? severity,
    String? vaccineName,
    String? vaccineManufacturer,
    String? batchNumber,
    DateTime? nextDueDate,
    String? medicationName,
    String? dosage,
    String? frequency,
    int? durationDays,
    DateTime? withdrawalEndDate,
    List<String>? symptoms,
    String? diagnosis,
    String? treatment,
    double? temperature,
    double? weight,
    String? veterinarianName,
    String? veterinarianContact,
    double? cost,
    DateTime? followUpDate,
    String? followUpNotes,
    String? recordedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachmentUrls,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      animalId: animalId ?? this.animalId,
      animalTagId: animalTagId ?? this.animalTagId,
      type: type ?? this.type,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      vaccineName: vaccineName ?? this.vaccineName,
      vaccineManufacturer: vaccineManufacturer ?? this.vaccineManufacturer,
      batchNumber: batchNumber ?? this.batchNumber,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      durationDays: durationDays ?? this.durationDays,
      withdrawalEndDate: withdrawalEndDate ?? this.withdrawalEndDate,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      temperature: temperature ?? this.temperature,
      weight: weight ?? this.weight,
      veterinarianName: veterinarianName ?? this.veterinarianName,
      veterinarianContact: veterinarianContact ?? this.veterinarianContact,
      cost: cost ?? this.cost,
      followUpDate: followUpDate ?? this.followUpDate,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    );
  }
}

/// Common vaccines for livestock
class CommonVaccines {
  static const List<String> pig = [
    'Porcine Circovirus (PCV2)',
    'Porcine Parvovirus (PPV)',
    'Erysipelas',
    'Mycoplasma hyopneumoniae',
    'PRRS (Porcine Reproductive and Respiratory Syndrome)',
    'Swine Influenza',
    'E. coli',
    'Clostridium',
    'Actinobacillus pleuropneumoniae (APP)',
    'Leptospirosis',
  ];

  static const List<String> cattle = [
    'Foot and Mouth Disease (FMD)',
    'Brucellosis',
    'Blackleg',
    'Anthrax',
    'Hemorrhagic Septicemia (HS)',
    'Bovine Viral Diarrhea (BVD)',
    'Infectious Bovine Rhinotracheitis (IBR)',
    'Leptospirosis',
    'Rabies',
    'Clostridial diseases',
  ];

  static const List<String> goat = [
    'Peste des Petits Ruminants (PPR)',
    'Enterotoxemia',
    'Foot and Mouth Disease (FMD)',
    'Goat Pox',
    'Contagious Caprine Pleuropneumonia (CCPP)',
    'Tetanus',
    'Rabies',
    'Clostridial diseases',
  ];

  static const List<String> poultry = [
    'Newcastle Disease',
    'Infectious Bronchitis',
    'Gumboro (IBD)',
    'Fowl Pox',
    'Marek\'s Disease',
    'Avian Influenza',
    'Fowl Cholera',
    'Mycoplasma',
  ];
}

/// Common symptoms for health observations
class CommonSymptoms {
  static const List<String> general = [
    'Loss of appetite',
    'Lethargy',
    'Weight loss',
    'Fever',
    'Dehydration',
    'Difficulty breathing',
    'Coughing',
    'Nasal discharge',
    'Eye discharge',
    'Diarrhea',
    'Vomiting',
    'Lameness',
    'Skin lesions',
    'Hair loss',
    'Swelling',
    'Behavioral changes',
    'Isolation from herd',
    'Reduced milk production',
  ];
}
