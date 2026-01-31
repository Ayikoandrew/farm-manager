import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_record.dart';
import '../config/supabase_config.dart';

class HealthRepository {
  final SupabaseClient _client;
  static const String _table = 'health_records';

  HealthRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  /// Watch all health records for a farm
  Stream<List<HealthRecord>> watchHealthRecords(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('date', ascending: false)
        .map(
          (data) =>
              data.map((json) => HealthRecord.fromSupabase(json)).toList(),
        );
  }

  /// Get health records with pagination
  Future<List<HealthRecord>> getHealthRecordsPaginated(
    String farmId, {
    required int limit,
    required int offset,
  }) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('farm_id', farmId)
        .order('date', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => HealthRecord.fromSupabase(json))
        .toList();
  }

  /// Watch health records for a specific animal
  Stream<List<HealthRecord>> watchAnimalHealthRecords(String animalId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('animal_id', animalId)
        .order('date', ascending: false)
        .map(
          (data) =>
              data.map((json) => HealthRecord.fromSupabase(json)).toList(),
        );
  }

  /// Watch health records by type
  Stream<List<HealthRecord>> watchHealthRecordsByType(
    String farmId,
    HealthRecordType type,
  ) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('date', ascending: false)
        .map(
          (data) => data
              .where((json) => json['type'] == type.name)
              .map((json) => HealthRecord.fromSupabase(json))
              .toList(),
        );
  }

  /// Get upcoming vaccinations (next due date within specified days)
  Stream<List<HealthRecord>> watchUpcomingVaccinations(
    String farmId, {
    int withinDays = 30,
  }) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: withinDays));

    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('next_due_date')
        .map(
          (data) => data
              .where(
                (json) =>
                    json['type'] == HealthRecordType.vaccination.name &&
                    json['next_due_date'] != null &&
                    DateTime.parse(json['next_due_date']).isAfter(now) &&
                    DateTime.parse(json['next_due_date']).isBefore(futureDate),
              )
              .map((json) => HealthRecord.fromSupabase(json))
              .toList(),
        );
  }

  /// Get records with pending follow-ups
  Stream<List<HealthRecord>> watchPendingFollowUps(String farmId) {
    final now = DateTime.now();

    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .map(
          (data) => data
              .where(
                (json) =>
                    json['follow_up_date'] != null &&
                    DateTime.parse(json['follow_up_date']).isBefore(now) &&
                    json['status'] != HealthStatus.completed.name,
              )
              .map((json) => HealthRecord.fromSupabase(json))
              .toList(),
        );
  }

  /// Get animals currently in withdrawal period
  Stream<List<HealthRecord>> watchAnimalsInWithdrawal(String farmId) {
    final now = DateTime.now();

    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('withdrawal_end_date')
        .map(
          (data) => data
              .where(
                (json) =>
                    json['withdrawal_end_date'] != null &&
                    DateTime.parse(json['withdrawal_end_date']).isAfter(now),
              )
              .map((json) => HealthRecord.fromSupabase(json))
              .toList(),
        );
  }

  /// Get all health records for a farm
  Future<List<HealthRecord>> getHealthRecords(String farmId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('farm_id', farmId)
        .order('date', ascending: false);
    return (response as List)
        .map((json) => HealthRecord.fromSupabase(json))
        .toList();
  }

  /// Get health records for a specific animal
  Future<List<HealthRecord>> getAnimalHealthRecords(String animalId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('animal_id', animalId)
        .order('date', ascending: false);
    return (response as List)
        .map((json) => HealthRecord.fromSupabase(json))
        .toList();
  }

  /// Get a single health record
  Future<HealthRecord?> getHealthRecord(String id) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return HealthRecord.fromSupabase(response);
  }

  /// Add a new health record
  Future<String> addHealthRecord(HealthRecord record) async {
    final response = await _client
        .from(_table)
        .insert(record.toSupabase())
        .select('id')
        .single();
    return response['id'] as String;
  }

  /// Update an existing health record
  Future<void> updateHealthRecord(HealthRecord record) async {
    await _client.from(_table).update(record.toSupabase()).eq('id', record.id);
  }

  /// Delete a health record
  Future<void> deleteHealthRecord(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Add batch health records (e.g., vaccinating multiple animals)
  Future<void> addBatchHealthRecords(List<HealthRecord> records) async {
    await _client
        .from(_table)
        .insert(records.map((r) => r.toSupabase()).toList());
  }

  /// Get health summary for an animal
  Future<HealthSummary> getAnimalHealthSummary(String animalId) async {
    final records = await getAnimalHealthRecords(animalId);

    int vaccinationCount = 0;
    int medicationCount = 0;
    int checkupCount = 0;
    int treatmentCount = 0;
    DateTime? lastCheckup;
    DateTime? nextVaccinationDue;
    bool inWithdrawal = false;

    for (final record in records) {
      switch (record.type) {
        case HealthRecordType.vaccination:
          vaccinationCount++;
          if (record.nextDueDate != null) {
            if (nextVaccinationDue == null ||
                record.nextDueDate!.isBefore(nextVaccinationDue)) {
              nextVaccinationDue = record.nextDueDate;
            }
          }
          break;
        case HealthRecordType.medication:
          medicationCount++;
          if (record.isInWithdrawalPeriod) {
            inWithdrawal = true;
          }
          break;
        case HealthRecordType.checkup:
          checkupCount++;
          if (lastCheckup == null || record.date.isAfter(lastCheckup)) {
            lastCheckup = record.date;
          }
          break;
        case HealthRecordType.treatment:
        case HealthRecordType.surgery:
          treatmentCount++;
          break;
        case HealthRecordType.observation:
          break;
      }
    }

    return HealthSummary(
      totalRecords: records.length,
      vaccinationCount: vaccinationCount,
      medicationCount: medicationCount,
      checkupCount: checkupCount,
      treatmentCount: treatmentCount,
      lastCheckup: lastCheckup,
      nextVaccinationDue: nextVaccinationDue,
      isInWithdrawalPeriod: inWithdrawal,
    );
  }

  /// Get farm-wide health statistics
  Future<FarmHealthStats> getFarmHealthStats(String farmId) async {
    final records = await getHealthRecords(farmId);
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    int totalRecords = records.length;
    int recordsLast30Days = 0;
    int upcomingVaccinations = 0;
    int overdueFollowUps = 0;
    int animalsInWithdrawal = 0;
    Set<String> sickAnimals = {};
    Map<HealthRecordType, int> recordsByType = {};

    for (final record in records) {
      // Count by type
      recordsByType[record.type] = (recordsByType[record.type] ?? 0) + 1;

      // Records in last 30 days
      if (record.date.isAfter(thirtyDaysAgo)) {
        recordsLast30Days++;
      }

      // Upcoming vaccinations
      if (record.type == HealthRecordType.vaccination &&
          record.nextDueDate != null &&
          record.nextDueDate!.isAfter(now) &&
          record.nextDueDate!.isBefore(now.add(const Duration(days: 30)))) {
        upcomingVaccinations++;
      }

      // Overdue follow-ups
      if (record.followUpDate != null &&
          record.followUpDate!.isBefore(now) &&
          record.status != HealthStatus.completed) {
        overdueFollowUps++;
      }

      // Animals in withdrawal
      if (record.isInWithdrawalPeriod) {
        animalsInWithdrawal++;
      }

      // Track sick animals (recent treatments)
      if ((record.type == HealthRecordType.treatment ||
              record.type == HealthRecordType.medication) &&
          record.date.isAfter(thirtyDaysAgo)) {
        sickAnimals.add(record.animalId);
      }
    }

    return FarmHealthStats(
      totalRecords: totalRecords,
      recordsLast30Days: recordsLast30Days,
      upcomingVaccinations: upcomingVaccinations,
      overdueFollowUps: overdueFollowUps,
      animalsInWithdrawal: animalsInWithdrawal,
      animalsUnderTreatment: sickAnimals.length,
      recordsByType: recordsByType,
    );
  }
}

/// Health summary for a single animal
class HealthSummary {
  final int totalRecords;
  final int vaccinationCount;
  final int medicationCount;
  final int checkupCount;
  final int treatmentCount;
  final DateTime? lastCheckup;
  final DateTime? nextVaccinationDue;
  final bool isInWithdrawalPeriod;

  HealthSummary({
    required this.totalRecords,
    required this.vaccinationCount,
    required this.medicationCount,
    required this.checkupCount,
    required this.treatmentCount,
    this.lastCheckup,
    this.nextVaccinationDue,
    required this.isInWithdrawalPeriod,
  });
}

/// Farm-wide health statistics
class FarmHealthStats {
  final int totalRecords;
  final int recordsLast30Days;
  final int upcomingVaccinations;
  final int overdueFollowUps;
  final int animalsInWithdrawal;
  final int animalsUnderTreatment;
  final Map<HealthRecordType, int> recordsByType;

  FarmHealthStats({
    required this.totalRecords,
    required this.recordsLast30Days,
    required this.upcomingVaccinations,
    required this.overdueFollowUps,
    required this.animalsInWithdrawal,
    required this.animalsUnderTreatment,
    required this.recordsByType,
  });
}
