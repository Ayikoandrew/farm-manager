import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder.dart';
import '../config/supabase_config.dart';

class ReminderRepository {
  final SupabaseClient _client;
  static const String _table = 'reminders';
  static const String _settingsTable = 'reminder_settings';

  ReminderRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  /// Watch all reminders for a farm
  Stream<List<Reminder>> watchReminders(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('due_date')
        .map(
          (data) => data.map((json) => Reminder.fromSupabase(json)).toList(),
        );
  }

  /// Watch pending reminders for a farm (sorted by priority and due date)
  Stream<List<Reminder>> watchPendingReminders(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('due_date')
        .map((data) {
          final reminders = data
              .where((json) => json['status'] == ReminderStatus.pending.name)
              .map((json) => Reminder.fromSupabase(json))
              .toList();
          // Sort by priority first, then by due date
          reminders.sort((a, b) {
            final priorityCompare = a.priority.sortOrder.compareTo(
              b.priority.sortOrder,
            );
            if (priorityCompare != 0) return priorityCompare;
            return a.dueDate.compareTo(b.dueDate);
          });
          return reminders;
        });
  }

  /// Watch active reminders (pending and should be shown)
  Stream<List<Reminder>> watchActiveReminders(String farmId) {
    return watchPendingReminders(farmId).map((reminders) {
      return reminders.where((r) => r.shouldShow).toList();
    });
  }

  /// Watch overdue reminders
  Stream<List<Reminder>> watchOverdueReminders(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('due_date')
        .map(
          (data) => data
              .where(
                (json) =>
                    json['status'] == ReminderStatus.pending.name &&
                    DateTime.parse(json['due_date']).isBefore(DateTime.now()),
              )
              .map((json) => Reminder.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch reminders for a specific animal
  Stream<List<Reminder>> watchAnimalReminders(String animalId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('animal_id', animalId)
        .order('due_date')
        .map(
          (data) => data
              .where((json) => json['status'] == ReminderStatus.pending.name)
              .map((json) => Reminder.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch reminders by type
  Stream<List<Reminder>> watchRemindersByType(
    String farmId,
    ReminderType type,
  ) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('due_date')
        .map(
          (data) => data
              .where(
                (json) =>
                    json['type'] == type.name &&
                    json['status'] == ReminderStatus.pending.name,
              )
              .map((json) => Reminder.fromSupabase(json))
              .toList(),
        );
  }

  /// Get a single reminder by ID
  Future<Reminder?> getReminder(String id) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Reminder.fromSupabase(response);
  }

  /// Get reminder by source record ID (to prevent duplicates)
  Future<Reminder?> getReminderBySourceRecord(
    String farmId,
    String sourceRecordId,
    String sourceType,
  ) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('farm_id', farmId)
        .eq('source_record_id', sourceRecordId)
        .eq('source_type', sourceType)
        .eq('status', ReminderStatus.pending.name)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Reminder.fromSupabase(response);
  }

  /// Create a new reminder
  Future<String> createReminder(Reminder reminder) async {
    final response = await _client
        .from(_table)
        .insert(reminder.toSupabase())
        .select('id')
        .single();
    return response['id'] as String;
  }

  /// Update a reminder
  Future<void> updateReminder(Reminder reminder) async {
    await _client
        .from(_table)
        .update({
          ...reminder.toSupabase(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reminder.id);
  }

  /// Mark reminder as completed
  Future<void> completeReminder(String id) async {
    await _client
        .from(_table)
        .update({
          'status': ReminderStatus.completed.name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Dismiss reminder
  Future<void> dismissReminder(String id) async {
    await _client
        .from(_table)
        .update({
          'status': ReminderStatus.dismissed.name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Snooze reminder for specified duration
  Future<void> snoozeReminder(String id, Duration duration) async {
    final snoozedUntil = DateTime.now().add(duration);
    await _client
        .from(_table)
        .update({
          'status': ReminderStatus.snoozed.name,
          'snoozed_until': snoozedUntil.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Unsnooze reminder (set back to pending)
  Future<void> unsnoozeReminder(String id) async {
    await _client
        .from(_table)
        .update({
          'status': ReminderStatus.pending.name,
          'snoozed_until': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Delete reminders by source record
  Future<void> deleteRemindersBySourceRecord(
    String sourceRecordId,
    String sourceType,
  ) async {
    await _client
        .from(_table)
        .delete()
        .eq('source_record_id', sourceRecordId)
        .eq('source_type', sourceType);
  }

  /// Get count of active reminders
  Future<int> getActiveReminderCount(String farmId) async {
    final response = await _client
        .from(_table)
        .select('id')
        .eq('farm_id', farmId)
        .eq('status', ReminderStatus.pending.name);
    return (response as List).length;
  }

  // ============ Settings Methods ============

  /// Get reminder settings for a farm
  Future<ReminderSettings> getSettings(String farmId) async {
    final response = await _client
        .from(_settingsTable)
        .select()
        .eq('farm_id', farmId)
        .maybeSingle();
    if (response == null) {
      return ReminderSettings(farmId: farmId);
    }
    return ReminderSettings.fromSupabase(response);
  }

  /// Watch reminder settings for a farm
  Stream<ReminderSettings> watchSettings(String farmId) {
    return _client
        .from(_settingsTable)
        .stream(primaryKey: ['farm_id'])
        .eq('farm_id', farmId)
        .map((data) {
          if (data.isEmpty) {
            return ReminderSettings(farmId: farmId);
          }
          return ReminderSettings.fromSupabase(data.first);
        });
  }

  /// Save reminder settings
  Future<void> saveSettings(ReminderSettings settings) async {
    await _client.from(_settingsTable).upsert(settings.toSupabase());
  }

  /// Create or update reminder (upsert based on source record)
  Future<void> upsertReminderForSource({
    required String farmId,
    required String sourceRecordId,
    required String sourceType,
    required ReminderType type,
    required String title,
    String? description,
    required DateTime dueDate,
    ReminderPriority priority = ReminderPriority.medium,
    String? animalId,
    String? animalTagId,
    int advanceNoticeDays = 3,
  }) async {
    // Check if reminder already exists for this source
    final existing = await getReminderBySourceRecord(
      farmId,
      sourceRecordId,
      sourceType,
    );

    final now = DateTime.now();

    if (existing != null) {
      // Update existing reminder
      await updateReminder(
        existing.copyWith(
          title: title,
          description: description,
          dueDate: dueDate,
          priority: priority,
          animalId: animalId,
          animalTagId: animalTagId,
          advanceNoticeDays: advanceNoticeDays,
          updatedAt: now,
        ),
      );
    } else {
      // Create new reminder
      await createReminder(
        Reminder(
          id: '',
          farmId: farmId,
          animalId: animalId,
          animalTagId: animalTagId,
          type: type,
          title: title,
          description: description,
          dueDate: dueDate,
          priority: priority,
          sourceRecordId: sourceRecordId,
          sourceType: sourceType,
          advanceNoticeDays: advanceNoticeDays,
          isAutoGenerated: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}
