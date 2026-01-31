import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../repositories/reminder_repository.dart';
import '../config/supabase_config.dart';

/// Service to automatically generate reminders from various records
class ReminderService {
  final ReminderRepository _reminderRepository;
  final SupabaseClient _client;

  ReminderService({
    ReminderRepository? reminderRepository,
    SupabaseClient? client,
  }) : _reminderRepository = reminderRepository ?? ReminderRepository(),
       _client = client ?? SupabaseConfig.client;

  /// Generate reminders from a breeding record
  Future<void> generateBreedingReminders(BreedingRecord record) async {
    final settings = await _reminderRepository.getSettings(record.farmId);
    if (!settings.breedingRemindersEnabled) return;

    // Get animal info for display
    final animalTag = await _getAnimalTag(record.animalId);
    final animalSpecies = await _getAnimalSpecies(record.animalId);
    final deliveryTerm = GestationPeriods.deliveryTermForSpecies(animalSpecies);

    // Expected delivery date reminder
    if (record.expectedDeliveryDate != null &&
        record.status == BreedingStatus.pregnant) {
      await _reminderRepository.upsertReminderForSource(
        farmId: record.farmId,
        sourceRecordId: record.id,
        sourceType: 'breeding_delivery',
        type: ReminderType.breeding,
        title: 'Expected $deliveryTerm: ${animalTag ?? record.animalId}',
        description:
            'Animal is expected to give birth. Prepare birthing area and monitor closely.',
        dueDate: record.expectedDeliveryDate!,
        priority: ReminderPriority.high,
        animalId: record.animalId,
        animalTagId: animalTag,
        advanceNoticeDays: settings.defaultAdvanceNoticeDays,
      );
    }

    // Heat cycle reminder based on species
    if (record.status == BreedingStatus.inHeat ||
        record.status == BreedingStatus.failed) {
      final heatCycleDays = animalSpecies != null
          ? GestationPeriods.heatCycleForSpecies(animalSpecies)
          : 21;
      if (heatCycleDays > 0) {
        final nextHeatDate = record.heatDate.add(Duration(days: heatCycleDays));
        if (nextHeatDate.isAfter(DateTime.now())) {
          await _reminderRepository.upsertReminderForSource(
            farmId: record.farmId,
            sourceRecordId: record.id,
            sourceType: 'breeding_heat',
            type: ReminderType.breeding,
            title: 'Expected Heat Cycle: ${animalTag ?? record.animalId}',
            description:
                'Animal may come into heat. Monitor for signs and prepare for breeding.',
            dueDate: nextHeatDate,
            priority: ReminderPriority.medium,
            animalId: record.animalId,
            animalTagId: animalTag,
            advanceNoticeDays: 2,
          );
        }
      }
    }
  }

  /// Generate reminders from a health record
  Future<void> generateHealthReminders(HealthRecord record) async {
    final settings = await _reminderRepository.getSettings(record.farmId);
    if (!settings.healthRemindersEnabled) return;

    // Get animal tag for display
    final animalTag = await _getAnimalTag(record.animalId);

    // Vaccination next due reminder
    if (record.type == HealthRecordType.vaccination &&
        record.nextDueDate != null &&
        record.nextDueDate!.isAfter(DateTime.now())) {
      await _reminderRepository.upsertReminderForSource(
        farmId: record.farmId,
        sourceRecordId: record.id,
        sourceType: 'health_vaccination',
        type: ReminderType.health,
        title:
            'Vaccination Due: ${record.vaccineName ?? 'Scheduled vaccination'}',
        description:
            'Animal ${animalTag ?? record.animalId} requires vaccination: ${record.vaccineName ?? record.title}',
        dueDate: record.nextDueDate!,
        priority: ReminderPriority.high,
        animalId: record.animalId,
        animalTagId: animalTag,
        advanceNoticeDays: settings.defaultAdvanceNoticeDays,
      );
    }

    // Follow-up reminder
    if (record.followUpDate != null &&
        record.followUpDate!.isAfter(DateTime.now()) &&
        record.status != HealthStatus.completed) {
      await _reminderRepository.upsertReminderForSource(
        farmId: record.farmId,
        sourceRecordId: record.id,
        sourceType: 'health_followup',
        type: ReminderType.health,
        title: 'Follow-up: ${record.title}',
        description:
            record.followUpNotes ??
            'Follow-up required for ${animalTag ?? record.animalId}',
        dueDate: record.followUpDate!,
        priority:
            record.severity == Severity.critical ||
                record.severity == Severity.high
            ? ReminderPriority.high
            : ReminderPriority.medium,
        animalId: record.animalId,
        animalTagId: animalTag,
        advanceNoticeDays: 1,
      );
    }

    // Medication end reminder (when course ends)
    if (record.type == HealthRecordType.medication &&
        record.durationDays != null &&
        record.status == HealthStatus.inProgress) {
      final endDate = record.date.add(Duration(days: record.durationDays!));
      if (endDate.isAfter(DateTime.now())) {
        await _reminderRepository.upsertReminderForSource(
          farmId: record.farmId,
          sourceRecordId: record.id,
          sourceType: 'health_medication_end',
          type: ReminderType.health,
          title: 'Medication Complete: ${record.medicationName ?? 'Treatment'}',
          description:
              'Medication course for ${animalTag ?? record.animalId} should be completed. Review health status.',
          dueDate: endDate,
          priority: ReminderPriority.medium,
          animalId: record.animalId,
          animalTagId: animalTag,
          advanceNoticeDays: 0,
        );
      }
    }

    // Withdrawal period reminder
    if (record.withdrawalEndDate != null &&
        record.withdrawalEndDate!.isAfter(DateTime.now())) {
      await _reminderRepository.upsertReminderForSource(
        farmId: record.farmId,
        sourceRecordId: record.id,
        sourceType: 'health_withdrawal',
        type: ReminderType.health,
        title: 'Withdrawal Period Ends',
        description:
            'Withdrawal period for ${animalTag ?? record.animalId} ends. Animal can be sold/processed.',
        dueDate: record.withdrawalEndDate!,
        priority: ReminderPriority.medium,
        animalId: record.animalId,
        animalTagId: animalTag,
        advanceNoticeDays: 1,
      );
    }
  }

  /// Generate weight check reminders for animals
  Future<void> generateWeightCheckReminder({
    required String farmId,
    required String animalId,
    DateTime? lastWeightDate,
  }) async {
    final settings = await _reminderRepository.getSettings(farmId);
    if (!settings.weightCheckRemindersEnabled) return;

    final animalTag = await _getAnimalTag(animalId);

    // Calculate next weight check date
    final baseDate = lastWeightDate ?? DateTime.now();
    final nextCheckDate = baseDate.add(
      Duration(days: settings.weightCheckIntervalDays),
    );

    if (nextCheckDate.isAfter(DateTime.now())) {
      await _reminderRepository.upsertReminderForSource(
        farmId: farmId,
        sourceRecordId: animalId,
        sourceType: 'weight_check',
        type: ReminderType.weightCheck,
        title: 'Weight Check: ${animalTag ?? animalId}',
        description:
            'Time to record weight for ${animalTag ?? animalId}. Regular monitoring helps track growth.',
        dueDate: nextCheckDate,
        priority: ReminderPriority.low,
        animalId: animalId,
        animalTagId: animalTag,
        advanceNoticeDays: 1,
      );
    }
  }

  /// Remove reminders when source record is deleted or resolved
  Future<void> removeRemindersForRecord(
    String sourceRecordId,
    String sourceType,
  ) async {
    await _reminderRepository.deleteRemindersBySourceRecord(
      sourceRecordId,
      sourceType,
    );
  }

  /// Sync all reminders for a farm (batch generation)
  Future<void> syncAllReminders(String farmId) async {
    // Fetch all data in parallel first
    final results = await Future.wait([
      _client
          .from('breeding_records')
          .select()
          .eq('farm_id', farmId)
          .inFilter('status', [
            BreedingStatus.pregnant.name,
            BreedingStatus.inHeat.name,
            BreedingStatus.bred.name,
          ]),
      _client.from('health_records').select().eq('farm_id', farmId).inFilter(
        'status',
        [HealthStatus.pending.name, HealthStatus.inProgress.name],
      ),
      _client
          .from('health_records')
          .select()
          .eq('farm_id', farmId)
          .eq('type', HealthRecordType.vaccination.name)
          .gte('next_due_date', DateTime.now().toIso8601String()),
    ]);

    final breedingData = results[0] as List<dynamic>;
    final healthData = results[1] as List<dynamic>;
    final vaccinationData = results[2] as List<dynamic>;

    // Process breeding records in parallel (batch of 5 at a time)
    final breedingRecords = breedingData
        .map((row) => BreedingRecord.fromSupabase(row))
        .toList();
    for (var i = 0; i < breedingRecords.length; i += 5) {
      final batch = breedingRecords.skip(i).take(5);
      await Future.wait(
        batch.map((record) => generateBreedingReminders(record)),
      );
    }

    // Combine and deduplicate health records
    final allHealthRows = <String, dynamic>{};
    for (final row in healthData) {
      allHealthRows[row['id'] as String] = row;
    }
    for (final row in vaccinationData) {
      allHealthRows[row['id'] as String] = row;
    }

    // Process health records in parallel (batch of 5 at a time)
    final healthRecords = allHealthRows.values
        .map((row) => HealthRecord.fromSupabase(row))
        .toList();
    for (var i = 0; i < healthRecords.length; i += 5) {
      final batch = healthRecords.skip(i).take(5);
      await Future.wait(batch.map((record) => generateHealthReminders(record)));
    }
  }

  /// Get animal tag ID for display
  Future<String?> _getAnimalTag(String animalId) async {
    try {
      final data = await _client
          .from('animals')
          .select('tag_id')
          .eq('id', animalId)
          .maybeSingle();
      if (data != null) {
        return data['tag_id'] as String?;
      }
    } catch (e) {
      // Ignore errors, just return null
    }
    return null;
  }

  /// Get animal species for species-specific terms
  Future<AnimalType?> _getAnimalSpecies(String animalId) async {
    try {
      final data = await _client
          .from('animals')
          .select('species')
          .eq('id', animalId)
          .maybeSingle();
      if (data != null) {
        final speciesStr = data['species'] as String?;
        if (speciesStr != null) {
          return AnimalType.values.firstWhere(
            (e) => e.name == speciesStr,
            orElse: () => AnimalType.other,
          );
        }
      }
    } catch (e) {
      // Ignore errors, just return null
    }
    return null;
  }
}
