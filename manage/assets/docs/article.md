# Integrating GenUI: Building AI-Powered Interactive Interfaces in Flutter

A comprehensive guide to creating dynamic, AI-generated user interfaces using the GenUI library with Google's Gemini AI.

---

## Table of Contents

1. [Introduction](#introduction)
2. [What is GenUI?](#what-is-genui)
3. [Why Use GenUI?](#why-use-genui)
4. [Architecture Overview](#architecture-overview)
5. [Prerequisites](#prerequisites)
6. [Step 1: Setting Up Dependencies](#step-1-setting-up-dependencies)
7. [Step 2: Creating the Catalog](#step-2-creating-the-catalog)
8. [Step 3: Building GenUI Components](#step-3-building-genui-components)
9. [Step 4: Configuring the Content Generator](#step-4-configuring-the-content-generator)
10. [Step 5: Building the Conversation Interface](#step-5-building-the-conversation-interface)
11. [Step 6: Handling Tool Calls](#step-6-handling-tool-calls)
12. [Real-World Example: Farm Reminder System](#real-world-example-farm-reminder-system)
13. [Common Pitfalls and Solutions](#common-pitfalls-and-solutions)
14. [Best Practices](#best-practices)
15. [Conclusion](#conclusion)

---

## Introduction

Modern applications increasingly leverage AI to enhance user experiences. But what if, instead of just generating text responses, your AI assistant could dynamically render interactive UI components? This is the promise of **GenUI** (Generative UI) — a paradigm where AI models don't just respond with words, but with functional, interactive interfaces.

In this article, we'll explore how to integrate GenUI into a Flutter application, using a real-world farm management app as our case study. By the end, you'll understand how to enable an AI assistant to generate forms, cards, and other interactive widgets on-the-fly based on user requests.

---

## What is GenUI?

**GenUI** (Generative User Interface) is a library and architectural pattern that bridges AI language models with native UI frameworks. Instead of the AI returning plain text that you then parse and render, GenUI allows the AI to directly specify UI components through a structured schema.

### The Core Concept

```
Traditional Flow:
User → AI → Text Response → Manual Parsing → UI

GenUI Flow:
User → AI → Structured Component Definition → Automatic UI Rendering
```

With GenUI, when a user says "Create a reminder for tomorrow," the AI doesn't just respond with "I'll create a reminder for tomorrow." Instead, it returns a structured definition that automatically renders an interactive reminder form.

### Key Components

1. **Catalog**: A registry of available UI components the AI can use
2. **Schema**: JSON Schema definitions describing each component's properties
3. **Widget Builders**: Functions that transform AI-generated data into Flutter widgets
4. **Content Generator**: The bridge between your app and the AI model
5. **Conversation Manager**: Handles the back-and-forth between user and AI

---

## Why Use GenUI?

### 1. **Reduced Friction**

Traditional chatbots require users to navigate away from the conversation to perform actions. GenUI embeds actions directly in the conversation flow.

```
Without GenUI:
User: "I want to add a reminder"
Bot: "Please go to Settings > Reminders > Add New"
User: *navigates away, loses context*

With GenUI:
User: "I want to add a reminder"
Bot: *renders an interactive reminder form inline*
User: *fills form without leaving the conversation*
```

### 2. **Context Preservation**

The AI maintains conversation context and can pre-fill forms based on prior discussion:

```
User: "Remind me to vaccinate the goats next Tuesday"
AI: *renders form with title="Vaccinate goats", date=next Tuesday already filled*
```

### 3. **Type Safety**

GenUI uses JSON Schema to validate AI outputs, ensuring the data conforms to expected structures before rendering.

### 4. **Flexibility**

You define what components are available. The AI intelligently chooses which to use based on user intent.

### 5. **Reduced Development Time**

Instead of building complex intent parsing and command routing, you define components declaratively and let the AI handle user intent interpretation.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────────┐    ┌───────────────┐ │
│  │   User UI    │───▶│  GenUI           │───▶│   AI Model    │ │
│  │  (Chat)      │    │  Conversation    │    │   (Gemini)    │ │
│  └──────────────┘    └──────────────────┘    └───────────────┘ │
│         ▲                    │                       │          │
│         │                    ▼                       │          │
│         │            ┌──────────────────┐           │          │
│         │            │  A2UI Message    │           │          │
│         │            │  Processor       │◀──────────┘          │
│         │            └──────────────────┘                      │
│         │                    │                                  │
│         │                    ▼                                  │
│         │            ┌──────────────────┐                      │
│         │            │    Catalog       │                      │
│         │            │  (Component      │                      │
│         │            │   Registry)      │                      │
│         │            └──────────────────┘                      │
│         │                    │                                  │
│         │                    ▼                                  │
│         │            ┌──────────────────┐                      │
│         └────────────│  Widget Builder  │                      │
│                      │  (Your Custom    │                      │
│                      │   Components)    │                      │
│                      └──────────────────┘                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

Before starting, ensure you have:

- Flutter 3.10 or higher
- A Google AI Studio API key (for Gemini)
- Basic understanding of Flutter and Riverpod (or your preferred state management)
- Familiarity with JSON Schema concepts

---

## Step 1: Setting Up Dependencies

Add the required packages to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # GenUI core library
  genui: ^0.8.0
  
  # JSON Schema builder for defining component schemas
  json_schema_builder: ^1.0.0
  
  # Google's Generative AI SDK
  google_generative_ai: ^0.4.0
  
  # State management (recommended)
  flutter_riverpod: ^2.4.0
```

Run `flutter pub get` to install the dependencies.

---

## Step 2: Creating the Catalog

The catalog is the heart of GenUI. It defines what components the AI can generate and how to render them.

### Understanding the Catalog Structure

A catalog is a list of `CatalogItem` objects, each containing:

1. **name**: Unique identifier for the component
2. **dataSchema**: JSON Schema defining the component's properties
3. **widgetBuilder**: Function that creates the Flutter widget

### Creating Your Catalog File

Create `lib/config/genui_catalog.dart`:

```dart
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// Import your custom GenUI components
import '../screens/genui_components/reminder_form.dart';

final List<CatalogItem> farmTools = [
  CatalogItem(
    name: 'createReminder',
    dataSchema: Schema.object(
      properties: {
        'title': Schema.string(
          description: 'Title of the reminder, e.g. "Vaccinate pig 123"',
        ),
        'description': Schema.string(
          description: 'Optional detailed description',
        ),
        'dueDate': Schema.string(
          description: 'Due date in ISO format (YYYY-MM-DD)',
        ),
        'daysFromNow': Schema.integer(
          description: 'Days from today (alternative to dueDate)',
        ),
        'priority': Schema.string(
          description: 'Priority: "low", "medium", "high", or "urgent"',
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
];
```

### Schema Design Best Practices

1. **Be Descriptive**: The `description` field helps the AI understand when and how to use each property.

2. **Mark Required Fields**: Only mark fields as required if the component truly cannot function without them.

3. **Use Appropriate Types**: 
   - `Schema.string()` for text
   - `Schema.integer()` for whole numbers
   - `Schema.number()` for decimals
   - `Schema.boolean()` for true/false
   - `Schema.array()` for lists
   - `Schema.object()` for nested structures

4. **Provide Enum Values**: When a field has limited options, specify them:

```dart
'priority': Schema.string(
  description: 'Priority level',
  enumValues: ['low', 'medium', 'high', 'urgent'],
),
```

---

## Step 3: Building GenUI Components

GenUI components are regular Flutter widgets that receive data from the AI. The key difference is they're designed to work with dynamic, AI-provided data.

### Creating a GenUI Component

Create `lib/screens/genui_components/reminder_form.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenUiReminderForm extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialData;

  const GenUiReminderForm({
    super.key,
    required this.initialData,
  });

  @override
  ConsumerState<GenUiReminderForm> createState() => _GenUiReminderFormState();
}

class _GenUiReminderFormState extends ConsumerState<GenUiReminderForm> {
  // Controllers for form fields
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  // State variables
  DateTime? _selectedDate;
  String _priority = 'medium';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _initializeFromAIData();
  }

  void _initializeFromAIData() {
    // The AI provides data through initialData
    // We parse it and pre-fill our form
    
    _titleController = TextEditingController(
      text: widget.initialData['title'] as String? ?? '',
    );
    
    _descriptionController = TextEditingController(
      text: widget.initialData['description'] as String? ?? '',
    );
    
    // Handle date - could be ISO string or days from now
    if (widget.initialData['dueDate'] != null) {
      _selectedDate = DateTime.tryParse(
        widget.initialData['dueDate'] as String,
      );
    } else if (widget.initialData['daysFromNow'] != null) {
      final days = widget.initialData['daysFromNow'] as int;
      _selectedDate = DateTime.now().add(Duration(days: days));
    }
    
    // Priority with fallback
    _priority = widget.initialData['priority'] as String? ?? 'medium';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReminder() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Call your actual reminder creation logic here
      // await ref.read(reminderProvider.notifier).createReminder(...);
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Success state - show confirmation
    if (_isSubmitted) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              Text(
                'Reminder Created!',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                _titleController.text,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Form state
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.alarm, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Create Reminder', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),

            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Date picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Select due date',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 12),

            // Priority dropdown
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: ['low', 'medium', 'high', 'urgent'].map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 16),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReminder,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Key Patterns in GenUI Components

1. **Accept `initialData` Map**: This is how AI-generated data flows into your component.

2. **Parse in `initState`**: Transform raw AI data into your component's state.

3. **Handle Missing Data**: Always provide fallbacks — the AI might not provide every field.

4. **Maintain Local State**: Once initialized, the component manages its own state for user interactions.

5. **Show Success States**: Transform the component after successful submission to provide feedback.

---

## Step 4: Configuring the Content Generator

The content generator is the bridge between your app and the AI model. It configures how requests are sent and responses are processed.

### Creating the Content Generator

```dart
import 'package:genui/genui.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  GenUiConversation? _conversation;
  A2uiMessageProcessor? _processor;
  
  final String _apiKey = 'YOUR_GEMINI_API_KEY';

  @override
  void initState() {
    super.initState();
    _initializeGenUI();
  }

  void _initializeGenUI() {
    // Create catalogs from your defined tools
    final catalogs = [
      Catalog(id: 'farm', items: farmTools),
    ];

    // Initialize the message processor
    _processor = A2uiMessageProcessor(catalogs: catalogs);

    // Build the content generator
    final contentGenerator = GeminiContentGenerator(
      apiKey: _apiKey,
      modelName: 'gemini-2.5-flash',
      catalogs: catalogs,
      additionalSystemPrompt: '''
You are a helpful farm management assistant.

AVAILABLE TOOLS:
1. **createReminder** - Create a reminder
   Required: title
   Optional: description, dueDate, daysFromNow, priority

When users ask to create reminders, use the createReminder tool.

EXAMPLE:
User: "Remind me to feed the chickens tomorrow"
→ Use createReminder with title="Feed the chickens", daysFromNow=1
''',
    );

    // Create the conversation manager
    _conversation = GenUiConversation(
      contentGenerator: contentGenerator,
      a2uiMessageProcessor: _processor!,
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.error}')),
        );
      },
    );
  }
  
  // ... rest of implementation
}
```

### System Prompt Design

The system prompt is crucial for guiding the AI's behavior. Include:

1. **Role Definition**: Who is the AI?
2. **Available Tools**: List all tools with clear descriptions
3. **Required vs Optional Fields**: Help the AI understand what's needed
4. **Examples**: Show input → output mappings
5. **Constraints**: What should the AI NOT do?

---

## Step 5: Building the Conversation Interface

Now let's create the chat interface that displays messages and rendered components.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Farm Assistant')),
    body: Column(
      children: [
        // Message list
        Expanded(
          child: GenUiChatView(
            conversation: _conversation!,
            messageBuilder: (context, message) {
              return _buildMessage(message);
            },
          ),
        ),
        
        // Input field
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_inputController.text),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMessage(GenUiMessage message) {
  if (message.isUser) {
    return _buildUserMessage(message.text);
  } else {
    return _buildAssistantMessage(message);
  }
}

Widget _buildUserMessage(String text) {
  return Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    ),
  );
}

Widget _buildAssistantMessage(GenUiMessage message) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Text content (if any)
      if (message.text.isNotEmpty)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: MarkdownBody(data: message.text),
        ),
      
      // Rendered components (if any)
      if (message.surfaces.isNotEmpty)
        ...message.surfaces.map((surface) => 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: surface.widget,
          ),
        ),
    ],
  );
}

Future<void> _sendMessage(String text) async {
  if (text.trim().isEmpty) return;
  
  _inputController.clear();
  
  await _conversation?.sendMessage(text);
}
```

---

## Step 6: Handling Tool Calls

Sometimes the AI generates malformed tool calls. Here's how to handle them gracefully.

### Common Issues and Fixes

```dart
class RobustGeminiContentGenerator extends GeminiContentGenerator {
  @override
  Future<ContentGeneratorResponse> processToolCall(
    FunctionCall call,
  ) async {
    var toolName = call.name;
    var safeArgs = Map<String, dynamic>.from(call.args);

    // Fix 1: Handle direct component calls
    // AI might call 'createReminder' directly instead of 'render_farm'
    final knownComponents = ['createReminder', 'showAnimal', 'logFeeding'];
    
    if (knownComponents.contains(toolName)) {
      // Wrap in proper GenUI structure
      safeArgs = {
        'surfaceId': 'surface_${DateTime.now().microsecondsSinceEpoch}',
        'components': [
          {
            'id': 'comp_${DateTime.now().microsecondsSinceEpoch}',
            'component': {
              toolName: Map<String, dynamic>.from(call.args),
            },
          },
        ],
      };
      toolName = 'render_farm';
    }

    // Fix 2: Handle Map instead of List for components
    if (safeArgs['components'] is Map) {
      final map = safeArgs['components'] as Map;
      safeArgs['components'] = map.entries.map((e) {
        final item = Map<String, dynamic>.from(e.value as Map);
        item['id'] ??= e.key.toString();
        return item;
      }).toList();
    }

    // Fix 3: Ensure component wrapper exists
    if (safeArgs['components'] is List) {
      final fixed = (safeArgs['components'] as List).map((item) {
        if (item is Map && !item.containsKey('component')) {
          // Find the component type key
          final componentKey = item.keys.firstWhere(
            (k) => knownComponents.contains(k),
            orElse: () => null,
          );
          if (componentKey != null) {
            return {
              'id': item['id'] ?? 'gen_${DateTime.now().microsecondsSinceEpoch}',
              'component': {
                componentKey: item[componentKey],
              },
            };
          }
        }
        return item;
      }).toList();
      safeArgs['components'] = fixed;
    }

    return super.processToolCall(
      FunctionCall(toolName, safeArgs),
    );
  }
}
```

---

## Real-World Example: Farm Reminder System

Let's walk through a complete example from our farm management app.

### The User Journey

1. **User opens the Farm Assistant**
2. **User types**: "Remind me to vaccinate the goats next Tuesday"
3. **AI processes** the request and determines:
   - Intent: Create a reminder
   - Title: "Vaccinate the goats"
   - Date: Next Tuesday (calculated as days from now)
4. **AI generates** a tool call:
```json
{
  "surfaceId": "surface_1706612345",
  "components": [{
    "id": "reminder_1",
    "component": {
      "createReminder": {
        "title": "Vaccinate the goats",
        "daysFromNow": 5,
        "type": "health",
        "priority": "medium"
      }
    }
  }]
}
```
5. **GenUI renders** the `GenUiReminderForm` widget with pre-filled data
6. **User reviews** and optionally modifies the form
7. **User taps** "Create Reminder"
8. **Form submits** to the backend
9. **Success state** displays inline

### The Complete Flow Diagram

```
┌────────────────┐
│  User Input    │
│  "Remind me    │
│  to vaccinate  │
│  goats next    │
│  Tuesday"      │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│  Gemini AI     │
│  Processes     │
│  Intent        │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│  Tool Call     │
│  Generated     │
│  {createReminder│
│   title:...    │
│   daysFromNow:5}│
└───────┬────────┘
        │
        ▼
┌────────────────┐
│  A2UI Message  │
│  Processor     │
│  Matches       │
│  Catalog Item  │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│  Widget        │
│  Builder       │
│  Invoked       │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│  GenUiReminder │
│  Form Widget   │
│  Rendered      │
│  (Pre-filled)  │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│  User Reviews  │
│  & Submits     │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│  Backend API   │
│  Called        │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│  Success State │
│  Displayed     │
└────────────────┘
```

---

## Common Pitfalls and Solutions

### Pitfall 1: AI Uses Generic UI Components

**Problem**: AI generates `{componentType: "Card", children: [...]}` instead of your catalog items.

**Solution**: Add explicit instructions in your system prompt:

```
DO NOT use generic components like Card, Button, Text.
ONLY use these specific tools: createReminder, showAnimal, logFeeding.
```

### Pitfall 2: Catalog ID Mismatch

**Problem**: AI calls `render_standard_catalog` but you registered `render_farm`.

**Solution**: Register multiple catalog IDs:

```dart
_processor = A2uiMessageProcessor(catalogs: catalogs);
// Also register alternative IDs the AI might use
_processor.registerCatalog('standard_catalog', catalogs.first);
```

### Pitfall 3: Missing Required Fields

**Problem**: AI doesn't provide all required fields.

**Solution**: Handle gracefully in your component:

```dart
_titleController = TextEditingController(
  text: widget.initialData['title'] as String? ?? '', // Fallback to empty
);
```

### Pitfall 4: Date Format Inconsistencies

**Problem**: AI provides dates in various formats.

**Solution**: Try multiple parsing strategies:

```dart
DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    // Try ISO format
    var date = DateTime.tryParse(value);
    if (date != null) return date;
    
    // Try other formats...
  }
  if (value is int) {
    // Might be days from now
    return DateTime.now().add(Duration(days: value));
  }
  return null;
}
```

### Pitfall 5: Form Overflow

**Problem**: Rendered form is too tall for the available space.

**Solution**: Constrain height and make scrollable:

```dart
Card(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 400),
    child: SingleChildScrollView(
      child: Column(
        // ... form fields
      ),
    ),
  ),
)
```

---

## Best Practices

### 1. **Keep Components Focused**

Each GenUI component should do one thing well. Don't create a "SuperForm" that handles everything.

```dart
// ✅ Good: Focused components
- createReminder
- createInviteCode
- showAnimalCard

// ❌ Bad: Kitchen sink component
- createAnything
```

### 2. **Validate AI Output**

Never trust AI-generated data blindly:

```dart
void _initializeFromAIData() {
  // Validate and sanitize
  final rawTitle = widget.initialData['title'];
  if (rawTitle is String && rawTitle.length <= 200) {
    _titleController.text = rawTitle;
  }
}
```

### 3. **Provide Rich Feedback**

Show loading, success, and error states:

```dart
if (_isSubmitting) return LoadingIndicator();
if (_isSubmitted) return SuccessMessage();
if (_error != null) return ErrorMessage(_error);
return FormWidget();
```

### 4. **Use Descriptive Schema Fields**

Help the AI understand your components:

```dart
Schema.string(
  description: 'Priority level. Use "urgent" for time-sensitive tasks, '
      '"high" for important tasks, "medium" for regular tasks, '
      '"low" for tasks that can wait.',
  enumValues: ['low', 'medium', 'high', 'urgent'],
)
```

### 5. **Log for Debugging**

During development, log tool calls:

```dart
debugPrint('Tool call: ${call.name}');
debugPrint('Args: ${jsonEncode(call.args)}');
```

### 6. **Handle Errors Gracefully**

Wrap component rendering in error boundaries:

```dart
try {
  return widgetBuilder(context);
} catch (e) {
  return ErrorWidget('Failed to render component: $e');
}
```

### 7. **Test with Various Phrasings**

Users express the same intent differently:

```
"Create a reminder"
"Remind me to..."
"I need to remember to..."
"Set an alert for..."
"Don't let me forget to..."
```

Ensure your system prompt and examples cover these variations.

---

## Conclusion

GenUI represents a powerful paradigm shift in how we build AI-powered applications. Instead of treating AI as a text-in-text-out system, GenUI enables rich, interactive experiences embedded directly in the conversation flow.

### Key Takeaways

1. **Define Clear Catalogs**: Your catalog is the contract between AI and UI.

2. **Build Robust Components**: Handle missing data, validate inputs, show clear states.

3. **Guide the AI**: System prompts with examples dramatically improve output quality.

4. **Handle Edge Cases**: AI output can be unpredictable — build defensive code.

5. **Iterate Based on Usage**: Monitor how users interact and refine your prompts.

### What's Next?

- **Multi-step Workflows**: Chain multiple GenUI components for complex tasks
- **Streaming Responses**: Render components as they're generated
- **User Customization**: Let users define their own quick actions
- **Analytics**: Track which components are used most

GenUI is still evolving, but the foundations laid here will serve you well as the ecosystem matures. The future of AI interfaces isn't just about better chatbots — it's about intelligent systems that can dynamically create the exact interface a user needs, when they need it.

---

## Resources

- [GenUI Package on pub.dev](https://pub.dev/packages/genui)
- [Google Generative AI SDK](https://pub.dev/packages/google_generative_ai)
- [JSON Schema Specification](https://json-schema.org/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Google AI Studio](https://aistudio.google.com/)

---

*This article was written based on real-world implementation experience building a farm management application with GenUI and Gemini AI. The patterns and code examples are production-tested and designed to handle the quirks of AI-generated content.*
