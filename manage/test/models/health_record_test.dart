import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/health_record.dart';

void main() {
  group('HealthRecordType', () {
    test('all types are defined', () {
      expect(HealthRecordType.values.length, 6);
      expect(HealthRecordType.values, contains(HealthRecordType.vaccination));
      expect(HealthRecordType.values, contains(HealthRecordType.medication));
      expect(HealthRecordType.values, contains(HealthRecordType.checkup));
      expect(HealthRecordType.values, contains(HealthRecordType.treatment));
      expect(HealthRecordType.values, contains(HealthRecordType.surgery));
      expect(HealthRecordType.values, contains(HealthRecordType.observation));
    });

    test('displayName returns correct values', () {
      expect(HealthRecordType.vaccination.displayName, 'Vaccination');
      expect(HealthRecordType.medication.displayName, 'Medication');
      expect(HealthRecordType.checkup.displayName, 'Checkup');
      expect(HealthRecordType.treatment.displayName, 'Treatment');
      expect(HealthRecordType.surgery.displayName, 'Surgery');
      expect(HealthRecordType.observation.displayName, 'Observation');
    });

    test('iconName returns correct values', () {
      expect(HealthRecordType.vaccination.iconName, 'vaccines');
      expect(HealthRecordType.medication.iconName, 'medication');
      expect(HealthRecordType.checkup.iconName, 'stethoscope');
      expect(HealthRecordType.treatment.iconName, 'healing');
      expect(HealthRecordType.surgery.iconName, 'local_hospital');
      expect(HealthRecordType.observation.iconName, 'visibility');
    });
  });

  group('HealthStatus', () {
    test('all statuses are defined', () {
      expect(HealthStatus.values.length, 4);
      expect(HealthStatus.values, contains(HealthStatus.pending));
      expect(HealthStatus.values, contains(HealthStatus.inProgress));
      expect(HealthStatus.values, contains(HealthStatus.completed));
      expect(HealthStatus.values, contains(HealthStatus.cancelled));
    });

    test('name property returns correct values', () {
      expect(HealthStatus.pending.name, 'pending');
      expect(HealthStatus.inProgress.name, 'inProgress');
      expect(HealthStatus.completed.name, 'completed');
      expect(HealthStatus.cancelled.name, 'cancelled');
    });
  });

  group('Severity', () {
    test('all severities are defined', () {
      expect(Severity.values.length, 4);
      expect(Severity.values, contains(Severity.low));
      expect(Severity.values, contains(Severity.medium));
      expect(Severity.values, contains(Severity.high));
      expect(Severity.values, contains(Severity.critical));
    });

    test('name property returns correct values', () {
      expect(Severity.low.name, 'low');
      expect(Severity.medium.name, 'medium');
      expect(Severity.high.name, 'high');
      expect(Severity.critical.name, 'critical');
    });
  });

  group('HealthRecord Model', () {
    late HealthRecord vaccinationRecord;
    late HealthRecord medicationRecord;
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 1, 10);
      vaccinationRecord = HealthRecord(
        id: 'health-001',
        farmId: 'farm-001',
        animalId: 'animal-001',
        animalTagId: 'PIG-001',
        type: HealthRecordType.vaccination,
        date: now,
        title: 'PRRS Vaccination',
        description: 'Routine PRRS vaccination',
        status: HealthStatus.completed,
        vaccineName: 'PRRS-MLV',
        vaccineManufacturer: 'Boehringer',
        batchNumber: 'BATCH-2026-001',
        nextDueDate: now.add(const Duration(days: 180)),
        veterinarianName: 'Dr. Smith',
        veterinarianContact: '+256700000001',
        cost: 50000.0,
        recordedBy: 'user-001',
        createdAt: now,
        updatedAt: now,
      );

      medicationRecord = HealthRecord(
        id: 'health-002',
        farmId: 'farm-001',
        animalId: 'animal-002',
        animalTagId: 'PIG-002',
        type: HealthRecordType.medication,
        date: now,
        title: 'Antibiotic Treatment',
        description: 'Treatment for respiratory infection',
        status: HealthStatus.inProgress,
        severity: Severity.medium,
        symptoms: ['coughing', 'fever', 'loss of appetite'],
        diagnosis: 'Respiratory infection',
        medicationName: 'Amoxicillin',
        dosage: '500mg',
        frequency: 'twice daily',
        durationDays: 7,
        withdrawalEndDate: now.add(const Duration(days: 14)),
        temperature: 39.5,
        weight: 45.0,
        veterinarianName: 'Dr. Johnson',
        cost: 75000.0,
        followUpDate: now.add(const Duration(days: 3)),
        recordedBy: 'user-001',
        createdAt: now,
        updatedAt: now,
      );
    });

    test('should create vaccination record with all properties', () {
      expect(vaccinationRecord.id, 'health-001');
      expect(vaccinationRecord.type, HealthRecordType.vaccination);
      expect(vaccinationRecord.status, HealthStatus.completed);
      expect(vaccinationRecord.vaccineName, 'PRRS-MLV');
      expect(vaccinationRecord.vaccineManufacturer, 'Boehringer');
      expect(vaccinationRecord.batchNumber, 'BATCH-2026-001');
      expect(vaccinationRecord.nextDueDate, isNotNull);
    });

    test('should create medication record with symptoms and diagnosis', () {
      expect(medicationRecord.id, 'health-002');
      expect(medicationRecord.type, HealthRecordType.medication);
      expect(medicationRecord.status, HealthStatus.inProgress);
      expect(medicationRecord.severity, Severity.medium);
      expect(medicationRecord.symptoms.length, 3);
      expect(medicationRecord.diagnosis, 'Respiratory infection');
      expect(medicationRecord.medicationName, 'Amoxicillin');
      expect(medicationRecord.dosage, '500mg');
      expect(medicationRecord.durationDays, 7);
    });

    test('should handle medication with withdrawal period', () {
      expect(medicationRecord.withdrawalEndDate, isNotNull);
      expect(
        medicationRecord.withdrawalEndDate!.isAfter(medicationRecord.date),
        true,
      );
    });

    test('toSupabase should convert vaccination to map correctly', () {
      final map = vaccinationRecord.toSupabase();

      expect(map['farm_id'], 'farm-001');
      expect(map['animal_id'], 'animal-001');
      expect(map['type'], 'vaccination');
      expect(map['title'], 'PRRS Vaccination');
      expect(map['status'], 'completed');
      expect(map['vaccine_name'], 'PRRS-MLV');
    });

    test('toSupabase should convert medication to map correctly', () {
      final map = medicationRecord.toSupabase();

      expect(map['type'], 'medication');
      expect(map.containsKey('symptoms'), isFalse);
      expect(map['medication'], 'Amoxicillin');
      expect(map['dosage'], '500mg');
    });

    test('copyWith should create new instance with updated values', () {
      final updatedRecord = vaccinationRecord.copyWith(
        status: HealthStatus.pending,
        title: 'Updated Vaccination',
      );

      expect(updatedRecord.status, HealthStatus.pending);
      expect(updatedRecord.title, 'Updated Vaccination');
      expect(updatedRecord.id, vaccinationRecord.id);
      expect(updatedRecord.vaccineName, vaccinationRecord.vaccineName);
    });

    test('should create checkup record', () {
      final checkupRecord = HealthRecord(
        id: 'health-003',
        farmId: 'farm-001',
        animalId: 'animal-003',
        type: HealthRecordType.checkup,
        date: now,
        title: 'Routine Checkup',
        status: HealthStatus.completed,
        temperature: 38.5,
        weight: 50.0,
        veterinarianName: 'Dr. Smith',
        recordedBy: 'user-001',
        createdAt: now,
        updatedAt: now,
      );

      expect(checkupRecord.type, HealthRecordType.checkup);
      expect(checkupRecord.temperature, 38.5);
      expect(checkupRecord.weight, 50.0);
    });

    test('should create surgery record', () {
      final surgeryRecord = HealthRecord(
        id: 'health-004',
        farmId: 'farm-001',
        animalId: 'animal-004',
        type: HealthRecordType.surgery,
        date: now,
        title: 'Castration',
        description: 'Routine castration procedure',
        status: HealthStatus.completed,
        treatment: 'Surgical castration under local anesthesia',
        veterinarianName: 'Dr. Johnson',
        cost: 100000.0,
        followUpDate: now.add(const Duration(days: 7)),
        followUpNotes: 'Check wound healing',
        recordedBy: 'user-001',
        createdAt: now,
        updatedAt: now,
      );

      expect(surgeryRecord.type, HealthRecordType.surgery);
      expect(surgeryRecord.treatment, isNotNull);
      expect(surgeryRecord.followUpDate, isNotNull);
    });

    test('should create observation record with severity', () {
      final observationRecord = HealthRecord(
        id: 'health-005',
        farmId: 'farm-001',
        animalId: 'animal-005',
        type: HealthRecordType.observation,
        date: now,
        title: 'Limping observed',
        description: 'Animal showing signs of limping on rear left leg',
        status: HealthStatus.pending,
        severity: Severity.high,
        symptoms: ['limping', 'reduced mobility'],
        recordedBy: 'user-001',
        createdAt: now,
        updatedAt: now,
      );

      expect(observationRecord.type, HealthRecordType.observation);
      expect(observationRecord.severity, Severity.high);
      expect(observationRecord.symptoms.length, 2);
    });

    test('should handle record without optional fields', () {
      final minimalRecord = HealthRecord(
        id: 'health-006',
        farmId: 'farm-001',
        animalId: 'animal-006',
        type: HealthRecordType.observation,
        date: now,
        title: 'General observation',
        status: HealthStatus.completed,
        recordedBy: 'user-001',
        createdAt: now,
        updatedAt: now,
      );

      expect(minimalRecord.description, isNull);
      expect(minimalRecord.severity, isNull);
      expect(minimalRecord.symptoms, isEmpty);
      expect(minimalRecord.veterinarianName, isNull);
      expect(minimalRecord.cost, isNull);
    });
  });

  group('Health Record Status Transitions', () {
    test('can transition from pending to inProgress', () {
      final record = HealthRecord(
        id: 'health-001',
        farmId: 'farm-001',
        animalId: 'animal-001',
        type: HealthRecordType.treatment,
        date: DateTime.now(),
        title: 'Treatment',
        status: HealthStatus.pending,
        recordedBy: 'user-001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = record.copyWith(status: HealthStatus.inProgress);
      expect(updated.status, HealthStatus.inProgress);
    });

    test('can transition from inProgress to completed', () {
      final record = HealthRecord(
        id: 'health-001',
        farmId: 'farm-001',
        animalId: 'animal-001',
        type: HealthRecordType.treatment,
        date: DateTime.now(),
        title: 'Treatment',
        status: HealthStatus.inProgress,
        recordedBy: 'user-001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = record.copyWith(status: HealthStatus.completed);
      expect(updated.status, HealthStatus.completed);
    });

    test('can cancel a pending record', () {
      final record = HealthRecord(
        id: 'health-001',
        farmId: 'farm-001',
        animalId: 'animal-001',
        type: HealthRecordType.vaccination,
        date: DateTime.now(),
        title: 'Scheduled Vaccination',
        status: HealthStatus.pending,
        recordedBy: 'user-001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = record.copyWith(status: HealthStatus.cancelled);
      expect(updated.status, HealthStatus.cancelled);
    });
  });

  group('Vaccination Due Dates', () {
    test('nextDueDate should be after current date', () {
      final now = DateTime.now();
      final nextDue = now.add(const Duration(days: 180));

      final record = HealthRecord(
        id: 'health-001',
        farmId: 'farm-001',
        animalId: 'animal-001',
        type: HealthRecordType.vaccination,
        date: now,
        title: 'Vaccination',
        status: HealthStatus.completed,
        nextDueDate: nextDue,
        recordedBy: 'user-001',
        createdAt: now,
        updatedAt: now,
      );

      expect(record.nextDueDate!.isAfter(now), true);
    });
  });
}
