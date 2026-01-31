import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:manage/screens/genui_components/animal_card.dart';
import 'package:manage/screens/genui_components/feeding_form.dart';
import 'package:manage/screens/genui_components/invite_code_form.dart';
import 'package:manage/screens/genui_components/reminder_form.dart';

final List<CatalogItem> farmTools = [
  CatalogItem(
    name: 'showAnimal',
    dataSchema: Schema.object(
      properties: {
        'name': Schema.string(description: 'Name of the animal'),
        'tagId': Schema.string(description: 'Tag ID of the animal'),
        'species': Schema.string(description: 'Species e.g. Cow, Goat'),
        'breed': Schema.string(description: 'Brief info about breed'),
        'status': Schema.string(
          description: 'current status: healthy, sick...',
        ),
      },
      required: ['tagId', 'species'],
    ),
    widgetBuilder: (context) {
      return GenUiAnimalCard(data: context.data as Map<String, dynamic>);
    },
  ),
  CatalogItem(
    name: 'logFeeding',
    dataSchema: Schema.object(
      properties: {
        'animalId': Schema.string(description: 'Tag ID of the animal'),
        'feedType': Schema.string(description: 'The feed type of the animal'),
        'quantity': Schema.number(description: 'The feed amount'),
        'date': Schema.string(),
      },
      required: ['animalId', 'feedType', 'quantity'],
    ),
    widgetBuilder: (context) {
      return GenUiFeedingForm(
        initialData: context.data as Map<String, dynamic>,
      );
    },
  ),
  CatalogItem(
    name: 'createReminder',
    dataSchema: Schema.object(
      properties: {
        'title': Schema.string(
          description: 'Title of the reminder, e.g. "Vaccinate pig 123"',
        ),
        'description': Schema.string(
          description: 'Optional detailed description of what needs to be done',
        ),
        'dueDate': Schema.string(
          description: 'Due date in ISO format (YYYY-MM-DD), e.g. "2026-02-15"',
        ),
        'daysFromNow': Schema.integer(
          description:
              'Alternative to dueDate: number of days from today. Use 1 for tomorrow, 7 for next week, etc.',
        ),
        'type': Schema.string(
          description:
              'Type of reminder: "breeding", "health", "weightCheck", or "custom"',
        ),
        'priority': Schema.string(
          description: 'Priority level: "low", "medium", "high", or "urgent"',
        ),
        'animalTagId': Schema.string(
          description:
              'Optional: Tag ID of the animal this reminder is related to',
        ),
      },
      required: ['title'],
    ),
    widgetBuilder: (context) {
      return GenUiReminderForm(
        initialData: context.data as Map<String, dynamic>,
      );
    },
  ),
  CatalogItem(
    name: 'createInviteCode',
    dataSchema: Schema.object(
      properties: {
        'email': Schema.string(
          description: 'Email address of the person to invite. Required field.',
        ),
        'role': Schema.string(
          description:
              'Role to assign: "owner", "manager", "worker", or "vet". Defaults to "worker" if not specified.',
        ),
        'maxUses': Schema.integer(
          description:
              'Maximum number of times this code can be used. Default is 1 (single use). Use higher values for team onboarding.',
        ),
        'validityDays': Schema.integer(
          description:
              'Number of days the code is valid. Default is 7 days. Use 1 for urgent invites, 30 for longer validity.',
        ),
      },
      required: ['email'],
    ),
    widgetBuilder: (context) {
      return GenUiInviteCodeForm(
        initialData: context.data as Map<String, dynamic>,
      );
    },
  ),
];
