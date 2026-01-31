/// Reminder Repository Tests - Migrated to Supabase Mock Testing
/// Uses MockSupabaseDatabase instead of FakeFirebaseFirestore

import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/reminder.dart';
import '../mocks/mock_supabase.dart';

/// Mock ReminderRepository for testing with MockSupabaseDatabase
class MockReminderRepository {
  final MockSupabaseDatabase db;
  static const String _table = 'reminders';

  MockReminderRepository({required this.db});

  /// Create a reminder
  Future<String> createReminder(Reminder reminder) async {
    final data = reminder.toSupabase();
    final inserted = db.insert(_table, data);
    return inserted['id'] as String;
  }

  /// Get a single reminder by ID
  Future<Reminder?> getReminder(String id) async {
    final data = db.selectSingle(_table, where: {'id': id});
    if (data == null) return null;
    return Reminder.fromSupabase(data);
  }

  /// Get reminder by source record
  Future<Reminder?> getReminderBySourceRecord(
    String farmId,
    String sourceRecordId,
    String sourceType,
  ) async {
    final allReminders = db.select(_table, where: {'farm_id': farmId});
    final matching = allReminders
        .where(
          (json) =>
              json['source_record_id'] == sourceRecordId &&
              json['source_type'] == sourceType &&
              json['status'] != ReminderStatus.completed.name,
        )
        .toList();
    if (matching.isEmpty) return null;
    return Reminder.fromSupabase(matching.first);
  }

  /// Update a reminder
  Future<void> updateReminder(Reminder reminder) async {
    db.update(_table, reminder.toSupabase(), where: {'id': reminder.id});
  }

  /// Complete a reminder
  Future<void> completeReminder(String id) async {
    db.update(
      _table,
      {
        'status': ReminderStatus.completed.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: {'id': id},
    );
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    db.delete(_table, where: {'id': id});
  }

  /// Watch reminders for a farm
  Stream<List<Reminder>> watchReminders(String farmId) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) => data.map((json) => Reminder.fromSupabase(json)).toList(),
        );
  }

  /// Watch pending reminders
  Stream<List<Reminder>> watchPendingReminders(String farmId) {
    return db.stream(_table, where: {'farm_id': farmId}).map((data) {
      final pending = data
          .where((json) => json['status'] == ReminderStatus.pending.name)
          .map((json) => Reminder.fromSupabase(json))
          .toList();
      // Sort by priority (high first) then due date
      pending.sort((a, b) {
        final priorityCompare = a.priority.sortOrder.compareTo(
          b.priority.sortOrder,
        );
        if (priorityCompare != 0) return priorityCompare;
        return a.dueDate.compareTo(b.dueDate);
      });
      return pending;
    });
  }

  /// Watch reminders for an animal
  Stream<List<Reminder>> watchAnimalReminders(String animalId) {
    return db
        .stream(_table)
        .map(
          (data) => data
              .where(
                (json) =>
                    json['animal_id'] == animalId &&
                    json['status'] == ReminderStatus.pending.name,
              )
              .map((json) => Reminder.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch reminders by type
  Stream<List<Reminder>> watchRemindersByType(
    String farmId,
    ReminderType type,
  ) {
    return db
        .stream(_table, where: {'farm_id': farmId})
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

  /// Watch overdue reminders
  Stream<List<Reminder>> watchOverdueReminders(String farmId) {
    final now = DateTime.now();
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) => data
              .where((json) {
                if (json['status'] != ReminderStatus.pending.name) return false;
                final dueDate = DateTime.parse(json['due_date']);
                return dueDate.isBefore(now);
              })
              .map((json) => Reminder.fromSupabase(json))
              .toList(),
        );
  }

  /// Snooze a reminder
  Future<void> snoozeReminder(String id, Duration duration) async {
    final snoozedUntil = DateTime.now().add(duration);
    db.update(
      _table,
      {
        'status': ReminderStatus.snoozed.name,
        'snoozed_until': snoozedUntil.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: {'id': id},
    );
  }
}

void main() {
  late MockSupabaseDatabase mockDb;
  late MockReminderRepository repository;

  setUp(() {
    mockDb = MockSupabaseDatabase();
    repository = MockReminderRepository(db: mockDb);
  });

  tearDown(() {
    mockDb.dispose();
  });

  Reminder createTestReminder({
    String id = 'reminder-1',
    String farmId = 'farm-1',
    String? animalId,
    ReminderType type = ReminderType.health,
    String title = 'Test Reminder',
    String? description,
    DateTime? dueDate,
    ReminderPriority priority = ReminderPriority.medium,
    ReminderStatus status = ReminderStatus.pending,
    DateTime? snoozedUntil,
    int advanceNoticeDays = 7,
    String? sourceRecordId,
    String? sourceType,
  }) {
    return Reminder(
      id: id,
      farmId: farmId,
      animalId: animalId,
      type: type,
      title: title,
      description: description,
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
      priority: priority,
      status: status,
      snoozedUntil: snoozedUntil,
      advanceNoticeDays: advanceNoticeDays,
      sourceRecordId: sourceRecordId,
      sourceType: sourceType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> addReminderToDb(Reminder reminder) async {
    final data = reminder.toSupabase();
    data['id'] = reminder.id;
    mockDb.insert('reminders', data);
  }

  group('ReminderRepository', () {
    group('createReminder', () {
      test('should create a reminder and return document ID', () async {
        final reminder = createTestReminder();

        final docId = await repository.createReminder(reminder);

        expect(docId, isNotEmpty);
        final data = mockDb.selectSingle('reminders', where: {'id': docId});
        expect(data, isNotNull);
      });

      test('should store reminder data correctly', () async {
        final reminder = createTestReminder(
          title: 'Health Check Due',
          type: ReminderType.health,
          priority: ReminderPriority.high,
        );

        final docId = await repository.createReminder(reminder);

        final data = mockDb.selectSingle('reminders', where: {'id': docId});
        expect(data!['title'], 'Health Check Due');
        expect(data['type'], 'health');
        expect(data['priority'], 'high');
      });
    });

    group('getReminder', () {
      test('should return reminder when exists', () async {
        final reminder = createTestReminder();
        await addReminderToDb(reminder);

        final result = await repository.getReminder(reminder.id);

        expect(result, isNotNull);
        expect(result!.title, reminder.title);
      });

      test('should return null when reminder does not exist', () async {
        final result = await repository.getReminder('non-existent');

        expect(result, isNull);
      });
    });

    group('getReminderBySourceRecord', () {
      test('should return reminder matching source record', () async {
        final reminder = createTestReminder(
          sourceRecordId: 'health-record-123',
          sourceType: 'vaccination',
          status: ReminderStatus.pending,
        );
        await addReminderToDb(reminder);

        final result = await repository.getReminderBySourceRecord(
          'farm-1',
          'health-record-123',
          'vaccination',
        );

        expect(result, isNotNull);
        expect(result!.sourceRecordId, 'health-record-123');
      });

      test('should return null when no matching source record', () async {
        final result = await repository.getReminderBySourceRecord(
          'farm-1',
          'non-existent',
          'vaccination',
        );

        expect(result, isNull);
      });

      test('should not return completed reminders', () async {
        final reminder = createTestReminder(
          sourceRecordId: 'health-record-123',
          sourceType: 'vaccination',
          status: ReminderStatus.completed,
        );
        await addReminderToDb(reminder);

        final result = await repository.getReminderBySourceRecord(
          'farm-1',
          'health-record-123',
          'vaccination',
        );

        expect(result, isNull);
      });
    });

    group('updateReminder', () {
      test('should update reminder data', () async {
        final reminder = createTestReminder();
        await addReminderToDb(reminder);

        final updatedReminder = reminder.copyWith(
          title: 'Updated Title',
          priority: ReminderPriority.high,
        );
        await repository.updateReminder(updatedReminder);

        final data = mockDb.selectSingle(
          'reminders',
          where: {'id': reminder.id},
        );
        expect(data!['title'], 'Updated Title');
        expect(data['priority'], 'high');
      });
    });

    group('completeReminder', () {
      test('should mark reminder as completed', () async {
        final reminder = createTestReminder(status: ReminderStatus.pending);
        await addReminderToDb(reminder);

        await repository.completeReminder(reminder.id);

        final data = mockDb.selectSingle(
          'reminders',
          where: {'id': reminder.id},
        );
        expect(data!['status'], 'completed');
      });
    });

    group('deleteReminder', () {
      test('should delete reminder', () async {
        final reminder = createTestReminder();
        await addReminderToDb(reminder);

        await repository.deleteReminder(reminder.id);

        final data = mockDb.selectSingle(
          'reminders',
          where: {'id': reminder.id},
        );
        expect(data, isNull);
      });
    });

    group('watchReminders', () {
      test('should emit reminders for farm', () async {
        await addReminderToDb(createTestReminder(id: 'r1', farmId: 'farm-1'));

        final stream = repository.watchReminders('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<Reminder>>().having((list) => list.length, 'length', 1),
          ),
        );
      });

      test('should emit empty list for farm with no reminders', () async {
        final stream = repository.watchReminders('empty-farm');

        await expectLater(stream.first, completion(isEmpty));
      });
    });

    group('watchPendingReminders', () {
      test('should emit only pending reminders', () async {
        await addReminderToDb(
          createTestReminder(
            id: 'r1',
            farmId: 'farm-1',
            status: ReminderStatus.pending,
          ),
        );
        await addReminderToDb(
          createTestReminder(
            id: 'r2',
            farmId: 'farm-1',
            status: ReminderStatus.completed,
          ),
        );

        final stream = repository.watchPendingReminders('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<Reminder>>().having(
              (list) => list.every((r) => r.status == ReminderStatus.pending),
              'all pending',
              isTrue,
            ),
          ),
        );
      });

      test('should sort by priority then due date', () async {
        final today = DateTime.now();

        await addReminderToDb(
          createTestReminder(
            id: 'r1',
            farmId: 'farm-1',
            priority: ReminderPriority.low,
            dueDate: today,
            status: ReminderStatus.pending,
          ),
        );
        await addReminderToDb(
          createTestReminder(
            id: 'r2',
            farmId: 'farm-1',
            priority: ReminderPriority.high,
            dueDate: today.add(const Duration(days: 5)),
            status: ReminderStatus.pending,
          ),
        );

        final stream = repository.watchPendingReminders('farm-1');
        final reminders = await stream.first;

        // High priority should come first even if due later
        expect(reminders.first.priority, ReminderPriority.high);
      });
    });

    group('watchAnimalReminders', () {
      test('should emit only reminders for specific animal', () async {
        await addReminderToDb(
          createTestReminder(
            id: 'r1',
            animalId: 'animal-1',
            status: ReminderStatus.pending,
          ),
        );
        await addReminderToDb(
          createTestReminder(
            id: 'r2',
            animalId: 'animal-2',
            status: ReminderStatus.pending,
          ),
        );

        final stream = repository.watchAnimalReminders('animal-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<Reminder>>().having(
              (list) => list.every((r) => r.animalId == 'animal-1'),
              'all for animal-1',
              isTrue,
            ),
          ),
        );
      });
    });

    group('watchRemindersByType', () {
      test('should emit only reminders of specified type', () async {
        await addReminderToDb(
          createTestReminder(
            id: 'r1',
            farmId: 'farm-1',
            type: ReminderType.health,
            status: ReminderStatus.pending,
          ),
        );
        await addReminderToDb(
          createTestReminder(
            id: 'r2',
            farmId: 'farm-1',
            type: ReminderType.breeding,
            status: ReminderStatus.pending,
          ),
        );

        final stream = repository.watchRemindersByType(
          'farm-1',
          ReminderType.health,
        );

        await expectLater(
          stream.first,
          completion(
            isA<List<Reminder>>().having(
              (list) => list.every((r) => r.type == ReminderType.health),
              'all health',
              isTrue,
            ),
          ),
        );
      });
    });

    group('watchOverdueReminders', () {
      test('should emit only overdue pending reminders', () async {
        final pastDate = DateTime.now().subtract(const Duration(days: 5));
        final futureDate = DateTime.now().add(const Duration(days: 5));

        await addReminderToDb(
          createTestReminder(
            id: 'r1',
            farmId: 'farm-1',
            dueDate: pastDate,
            status: ReminderStatus.pending,
          ),
        );
        await addReminderToDb(
          createTestReminder(
            id: 'r2',
            farmId: 'farm-1',
            dueDate: futureDate,
            status: ReminderStatus.pending,
          ),
        );

        final stream = repository.watchOverdueReminders('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<Reminder>>().having((list) => list.length, 'length', 1),
          ),
        );
      });
    });

    group('snoozeReminder', () {
      test('should set snoozed until date using duration', () async {
        final reminder = createTestReminder();
        await addReminderToDb(reminder);

        await repository.snoozeReminder(reminder.id, const Duration(days: 1));

        final data = mockDb.selectSingle(
          'reminders',
          where: {'id': reminder.id},
        );
        expect(data!['snoozed_until'], isNotNull);
        expect(data['status'], 'snoozed');
      });
    });

    group('Reminder Types', () {
      test('should handle health reminders', () async {
        final reminder = createTestReminder(
          type: ReminderType.health,
          title: 'Health Check Due',
        );

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.type, ReminderType.health);
      });

      test('should handle breeding reminders', () async {
        final reminder = createTestReminder(
          type: ReminderType.breeding,
          title: 'Heat Check Due',
        );

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.type, ReminderType.breeding);
      });

      test('should handle weight check reminders', () async {
        final reminder = createTestReminder(
          type: ReminderType.weightCheck,
          title: 'Weekly Weight Recording',
        );

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.type, ReminderType.weightCheck);
      });

      test('should handle custom reminders', () async {
        final reminder = createTestReminder(
          type: ReminderType.custom,
          title: 'Farm Inspection',
        );

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.type, ReminderType.custom);
      });
    });

    group('Reminder Priorities', () {
      test('should handle high priority reminders', () async {
        final reminder = createTestReminder(priority: ReminderPriority.high);

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.priority, ReminderPriority.high);
      });

      test('should handle medium priority reminders', () async {
        final reminder = createTestReminder(priority: ReminderPriority.medium);

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.priority, ReminderPriority.medium);
      });

      test('should handle low priority reminders', () async {
        final reminder = createTestReminder(priority: ReminderPriority.low);

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.priority, ReminderPriority.low);
      });

      test('should handle urgent priority reminders', () async {
        final reminder = createTestReminder(priority: ReminderPriority.urgent);

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.priority, ReminderPriority.urgent);
      });
    });

    group('Reminder Status', () {
      test('should handle pending status', () async {
        final reminder = createTestReminder(status: ReminderStatus.pending);

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.status, ReminderStatus.pending);
      });

      test('should handle completed status', () async {
        final reminder = createTestReminder(status: ReminderStatus.completed);

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.status, ReminderStatus.completed);
      });

      test('should handle dismissed status', () async {
        final reminder = createTestReminder(status: ReminderStatus.dismissed);

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.status, ReminderStatus.dismissed);
      });

      test('should handle snoozed status', () async {
        final reminder = createTestReminder(
          status: ReminderStatus.snoozed,
          snoozedUntil: DateTime.now().add(const Duration(hours: 1)),
        );

        final docId = await repository.createReminder(reminder);
        final result = await repository.getReminder(docId);

        expect(result!.status, ReminderStatus.snoozed);
      });
    });
  });
}
