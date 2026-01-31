# Building Robust AI Integrations: Error Handling and Fallback Strategies for LLM Tool Calls

A practical guide to making AI-powered features production-ready by handling malformed responses, implementing fallbacks, and ensuring graceful degradation.

---

## Table of Contents

1. [Introduction](#introduction)
2. [The Problem: AI Unpredictability](#the-problem-ai-unpredictability)
3. [Understanding Tool Call Failures](#understanding-tool-call-failures)
4. [Strategy 1: Input Normalization](#strategy-1-input-normalization)
5. [Strategy 2: Schema Validation with Fallbacks](#strategy-2-schema-validation-with-fallbacks)
6. [Strategy 3: Tool Call Transformation](#strategy-3-tool-call-transformation)
7. [Strategy 4: Graceful Degradation](#strategy-4-graceful-degradation)
8. [Strategy 5: Retry with Guidance](#strategy-5-retry-with-guidance)
9. [Real-World Implementation: The Fix Pipeline](#real-world-implementation-the-fix-pipeline)
10. [Testing Your Error Handling](#testing-your-error-handling)
11. [Monitoring and Logging](#monitoring-and-logging)
12. [Best Practices Summary](#best-practices-summary)
13. [Conclusion](#conclusion)

---

## Introduction

You've integrated an AI model into your application. It works beautifully in demos. Then real users arrive, and suddenly you're drowning in error logs:

```
MALFORMED_FUNCTION_CALL
Unhandled format for FinishReason
null value in column "email"
```

Sound familiar?

Large Language Models (LLMs) are incredibly powerful, but they're also probabilistic systems. They don't always follow your carefully crafted schemas. They hallucinate. They misinterpret. They get creative in ways you didn't anticipate.

This article shares battle-tested strategies from building a production farm management app with Gemini AI. We'll explore how to make your AI integration resilient, handling edge cases gracefully without frustrating users.

---

## The Problem: AI Unpredictability

### Why AI Tool Calls Fail

When you define a tool (function) for an AI model to call, you provide a schema:

```dart
Schema.object(
  properties: {
    'title': Schema.string(description: 'Title of the reminder'),
    'priority': Schema.string(description: 'low, medium, high, or urgent'),
  },
  required: ['title'],
)
```

You expect:
```json
{
  "title": "Feed the chickens",
  "priority": "high"
}
```

You might get:
```json
{
  "Title": "Feed the chickens",           // Wrong case
  "priority": "HIGH",                      // Wrong case
  "urgency": "very important"              // Wrong field entirely
}
```

Or even:
```json
{
  "componentType": "Card",
  "children": [
    {"componentType": "Text", "content": "Feed the chickens"}
  ]
}
```

### Categories of AI Misbehavior

| Category | Description | Example |
|----------|-------------|---------|
| **Case Sensitivity** | Wrong capitalization | `Title` vs `title` |
| **Field Naming** | Using synonyms | `urgency` vs `priority` |
| **Structure Deviation** | Different nesting | Map instead of List |
| **Tool Name Errors** | Calling wrong tool | `create_reminder` vs `createReminder` |
| **Schema Hallucination** | Inventing new schema | Generic UI components |
| **Missing Required Fields** | Omitting mandatory data | No `title` provided |
| **Type Mismatches** | Wrong data types | String `"5"` instead of int `5` |

---

## Understanding Tool Call Failures

### The Tool Call Lifecycle

```
┌─────────────────┐
│  User Message   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   AI Model      │
│   Processing    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Tool Call      │────▶│  FAILURE POINT  │
│  Generated      │     │  Malformed JSON │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Schema         │────▶│  FAILURE POINT  │
│  Validation     │     │  Missing fields │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Tool          │────▶│  FAILURE POINT  │
│  Execution      │     │  Runtime errors │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│  Result to      │
│  User           │
└─────────────────┘
```

Each arrow represents a potential failure point. Robust systems handle failures at every stage.

---

## Strategy 1: Input Normalization

The first line of defense is normalizing AI output before processing.

### Case Normalization

```dart
Map<String, dynamic> normalizeKeys(Map<String, dynamic> input) {
  return input.map((key, value) {
    // Convert keys to camelCase
    final normalizedKey = _toCamelCase(key);
    
    // Recursively normalize nested maps
    final normalizedValue = value is Map<String, dynamic>
        ? normalizeKeys(value)
        : value;
    
    return MapEntry(normalizedKey, normalizedValue);
  });
}

String _toCamelCase(String input) {
  // Handle snake_case
  if (input.contains('_')) {
    final parts = input.split('_');
    return parts.first.toLowerCase() +
        parts.skip(1).map((p) => p.capitalize()).join();
  }
  
  // Handle PascalCase -> camelCase
  if (input.isNotEmpty && input[0] == input[0].toUpperCase()) {
    return input[0].toLowerCase() + input.substring(1);
  }
  
  return input;
}
```

### Field Mapping

Create a synonym dictionary for common misnamings:

```dart
const Map<String, String> fieldSynonyms = {
  // Priority variations
  'urgency': 'priority',
  'importance': 'priority',
  'level': 'priority',
  
  // Date variations
  'date': 'dueDate',
  'deadline': 'dueDate',
  'when': 'dueDate',
  'due': 'dueDate',
  
  // Title variations
  'name': 'title',
  'subject': 'title',
  'heading': 'title',
  
  // Description variations
  'details': 'description',
  'notes': 'description',
  'info': 'description',
};

Map<String, dynamic> mapSynonyms(Map<String, dynamic> input) {
  return input.map((key, value) {
    final mappedKey = fieldSynonyms[key.toLowerCase()] ?? key;
    return MapEntry(mappedKey, value);
  });
}
```

### Type Coercion

```dart
dynamic coerceType(dynamic value, Type expectedType) {
  if (value == null) return null;
  
  // Already correct type
  if (value.runtimeType == expectedType) return value;
  
  // String to int
  if (expectedType == int && value is String) {
    return int.tryParse(value);
  }
  
  // String to double
  if (expectedType == double && value is String) {
    return double.tryParse(value);
  }
  
  // Int to double
  if (expectedType == double && value is int) {
    return value.toDouble();
  }
  
  // String to bool
  if (expectedType == bool && value is String) {
    return value.toLowerCase() == 'true';
  }
  
  // String to DateTime
  if (expectedType == DateTime && value is String) {
    return DateTime.tryParse(value);
  }
  
  return value;
}
```

---

## Strategy 2: Schema Validation with Fallbacks

Instead of failing on invalid data, provide sensible defaults.

### The Fallback Pattern

```dart
class ReminderData {
  final String title;
  final String? description;
  final DateTime dueDate;
  final String priority;

  ReminderData._({
    required this.title,
    this.description,
    required this.dueDate,
    required this.priority,
  });

  factory ReminderData.fromAI(Map<String, dynamic> data) {
    // Required field with validation
    final title = data['title'] as String?;
    if (title == null || title.isEmpty) {
      throw ValidationException('Title is required');
    }

    // Optional field - just take it or null
    final description = data['description'] as String?;

    // Field with fallback
    final priority = _parseprioriy(data['priority']) ?? 'medium';

    // Complex field with multiple parsing strategies
    final dueDate = _parseDate(data) ?? DateTime.now().add(Duration(days: 1));

    return ReminderData._(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );
  }

  static String? _parsePriority(dynamic value) {
    if (value == null) return null;
    
    final str = value.toString().toLowerCase();
    const valid = ['low', 'medium', 'high', 'urgent'];
    
    if (valid.contains(str)) return str;
    
    // Fuzzy matching
    if (str.contains('urg') || str.contains('critical')) return 'urgent';
    if (str.contains('high') || str.contains('important')) return 'high';
    if (str.contains('low') || str.contains('minor')) return 'low';
    
    return null; // Fall back to default
  }

  static DateTime? _parseDate(Map<String, dynamic> data) {
    // Try direct date string
    if (data['dueDate'] != null) {
      final parsed = DateTime.tryParse(data['dueDate'].toString());
      if (parsed != null) return parsed;
    }

    // Try relative days
    if (data['daysFromNow'] != null) {
      final days = data['daysFromNow'];
      if (days is int) {
        return DateTime.now().add(Duration(days: days));
      }
      if (days is String) {
        final parsed = int.tryParse(days);
        if (parsed != null) {
          return DateTime.now().add(Duration(days: parsed));
        }
      }
    }

    // Try natural language hints in other fields
    final title = (data['title'] ?? '').toString().toLowerCase();
    if (title.contains('tomorrow')) {
      return DateTime.now().add(Duration(days: 1));
    }
    if (title.contains('next week')) {
      return DateTime.now().add(Duration(days: 7));
    }

    return null; // Use default
  }
}
```

---

## Strategy 3: Tool Call Transformation

Sometimes the AI calls the wrong tool or uses the wrong structure. Transform it into what you need.

### Handling Direct Component Calls

The AI might call `createReminder` directly instead of wrapping it in your GenUI structure:

```dart
FunctionCall transformToolCall(FunctionCall call) {
  final knownComponents = [
    'createReminder',
    'showAnimal',
    'logFeeding',
    'createInviteCode',
  ];

  // Check if AI called a component directly
  final normalizedName = call.name.replaceAll('_', '').toLowerCase();
  final matchedComponent = knownComponents.firstWhere(
    (c) => c.toLowerCase() == normalizedName,
    orElse: () => '',
  );

  if (matchedComponent.isNotEmpty) {
    debugPrint('Transforming direct call "${call.name}" to render_farm');
    
    // Wrap in GenUI structure
    return FunctionCall('render_farm', {
      'surfaceId': 'surface_${DateTime.now().microsecondsSinceEpoch}',
      'components': [
        {
          'id': 'comp_${DateTime.now().microsecondsSinceEpoch}',
          'component': {
            matchedComponent: Map<String, dynamic>.from(call.args),
          },
        },
      ],
    });
  }

  return call;
}
```

### Converting Map to List

AI models sometimes output `{id1: data1, id2: data2}` instead of `[{id: id1, ...}, {id: id2, ...}]`:

```dart
List<Map<String, dynamic>> ensureList(dynamic components) {
  if (components is List) {
    return components.cast<Map<String, dynamic>>();
  }
  
  if (components is Map) {
    return components.entries.map((entry) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      item['id'] ??= entry.key.toString();
      return item;
    }).toList();
  }
  
  // Single item - wrap in list
  if (components is Map<String, dynamic>) {
    return [components];
  }
  
  throw FormatException('Cannot convert ${components.runtimeType} to List');
}
```

### Extracting Components from Generic UI

When AI generates generic UI (Card, Button, Text) instead of your catalog items:

```dart
Map<String, dynamic>? extractCatalogComponent(Map<String, dynamic> genericUI) {
  final componentType = genericUI['componentType']?.toString().toLowerCase();
  
  // Look for catalog items in the generic structure
  if (componentType == 'card' || componentType == 'column') {
    final children = genericUI['children'] as List?;
    if (children != null) {
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          // Recursively search children
          final found = extractCatalogComponent(child);
          if (found != null) return found;
          
          // Check if this child has useful data
          final text = child['content'] ?? child['text'];
          if (text != null) {
            // Try to infer intent from content
            return _inferComponentFromContent(text.toString());
          }
        }
      }
    }
  }
  
  return null;
}

Map<String, dynamic>? _inferComponentFromContent(String content) {
  final lower = content.toLowerCase();
  
  // Looks like a reminder
  if (lower.contains('remind') || 
      lower.contains('tomorrow') || 
      lower.contains('schedule')) {
    return {
      'component': {
        'createReminder': {
          'title': content,
        },
      },
    };
  }
  
  return null;
}
```

---

## Strategy 4: Graceful Degradation

When all else fails, degrade gracefully rather than crashing.

### The Degradation Hierarchy

```dart
Widget renderAIResponse(FunctionCall call) {
  try {
    // Level 1: Try full rendering
    return _renderComponent(call);
  } catch (e1) {
    debugPrint('Full render failed: $e1');
    
    try {
      // Level 2: Try simplified rendering
      return _renderSimplified(call);
    } catch (e2) {
      debugPrint('Simplified render failed: $e2');
      
      try {
        // Level 3: Show raw data
        return _renderRawData(call);
      } catch (e3) {
        debugPrint('Raw render failed: $e3');
        
        // Level 4: Show error message
        return _renderError(call, e1);
      }
    }
  }
}

Widget _renderSimplified(FunctionCall call) {
  // Extract key information and show a basic card
  final args = call.args;
  
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            call.name.replaceAll('_', ' ').toTitleCase(),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ...args.entries.map((e) => Text('${e.key}: ${e.value}')),
        ],
      ),
    ),
  );
}

Widget _renderRawData(FunctionCall call) {
  return ExpansionTile(
    title: Text('AI Response (Debug)'),
    children: [
      Padding(
        padding: EdgeInsets.all(8),
        child: SelectableText(
          JsonEncoder.withIndent('  ').convert(call.args),
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    ],
  );
}

Widget _renderError(FunctionCall call, dynamic error) {
  return Card(
    color: Colors.red.shade50,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(height: 8),
          Text('Could not display AI response'),
          TextButton(
            onPressed: () => _reportError(call, error),
            child: Text('Report Issue'),
          ),
        ],
      ),
    ),
  );
}
```

### User-Friendly Error Messages

```dart
String getUserFriendlyError(dynamic error) {
  final errorStr = error.toString().toLowerCase();
  
  if (errorStr.contains('quota') || errorStr.contains('rate')) {
    return 'The AI is busy right now. Please try again in a moment.';
  }
  
  if (errorStr.contains('network') || errorStr.contains('connection')) {
    return 'Check your internet connection and try again.';
  }
  
  if (errorStr.contains('timeout')) {
    return 'The request took too long. Please try a simpler question.';
  }
  
  if (errorStr.contains('malformed') || errorStr.contains('parse')) {
    return 'The AI response was unclear. Please try rephrasing your request.';
  }
  
  // Don't expose internal errors
  return 'Something went wrong. Please try again.';
}
```

---

## Strategy 5: Retry with Guidance

Sometimes the best fix is asking the AI to try again with more specific instructions.

### Automatic Retry with Feedback

```dart
class SmartContentGenerator {
  int _retryCount = 0;
  static const int _maxRetries = 2;

  Future<ContentGeneratorResponse> generate(String prompt) async {
    try {
      final response = await _innerGenerate(prompt);
      _retryCount = 0; // Reset on success
      return response;
    } catch (e) {
      if (_retryCount < _maxRetries && _isRetryable(e)) {
        _retryCount++;
        
        // Add guidance based on the error
        final guidance = _getRetryGuidance(e);
        final enhancedPrompt = '$prompt\n\n[System: $guidance]';
        
        debugPrint('Retrying with guidance: $guidance');
        return generate(enhancedPrompt);
      }
      
      rethrow;
    }
  }

  bool _isRetryable(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    // Don't retry quota errors
    if (errorStr.contains('quota')) return false;
    
    // Don't retry authentication errors
    if (errorStr.contains('auth') || errorStr.contains('key')) return false;
    
    // Retry malformed responses
    if (errorStr.contains('malformed')) return true;
    
    // Retry parsing errors
    if (errorStr.contains('parse') || errorStr.contains('format')) return true;
    
    return false;
  }

  String _getRetryGuidance(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('malformed_function_call')) {
      return 'Please use ONLY the exact tool names provided: '
          'createReminder, showAnimal, logFeeding, createInviteCode. '
          'Do not use generic components like Card or Button.';
    }
    
    if (errorStr.contains('missing') && errorStr.contains('title')) {
      return 'The title field is required. Please include a title in your response.';
    }
    
    if (errorStr.contains('components')) {
      return 'The components field must be a list/array, not an object.';
    }
    
    return 'Please format your response according to the provided schema.';
  }
}
```

---

## Real-World Implementation: The Fix Pipeline

Here's the complete error-handling pipeline from our farm management app:

```dart
class RobustGeminiContentGenerator extends GeminiContentGenerator {
  @override
  Future<ContentGeneratorResponse> processResponse(
    GenerateContentResponse response,
  ) async {
    // Check for finish reason issues
    if (response.candidates?.isEmpty ?? true) {
      throw AIResponseException('No response generated');
    }

    final candidate = response.candidates!.first;
    
    // Handle blocked responses
    if (candidate.finishReason == FinishReason.safety) {
      throw AIResponseException(
        'Response blocked for safety reasons',
        isRetryable: false,
      );
    }

    // Handle malformed function calls
    if (candidate.finishReason?.name == 'MALFORMED_FUNCTION_CALL') {
      debugPrint('Malformed function call, requesting text-only response');
      return _requestTextOnly();
    }

    // Process function calls with fixes
    for (final part in candidate.content?.parts ?? []) {
      if (part is FunctionCall) {
        return _processToolCallWithFixes(part);
      }
    }

    return super.processResponse(response);
  }

  Future<ContentGeneratorResponse> _processToolCallWithFixes(
    FunctionCall call,
  ) async {
    var toolName = call.name;
    var safeArgs = Map<String, dynamic>.from(call.args);

    debugPrint('Processing tool call: $toolName');
    debugPrint('Original args: ${jsonEncode(safeArgs)}');

    // === FIX PIPELINE ===

    // Fix 0: Handle direct component calls
    safeArgs = _fixDirectComponentCall(toolName, safeArgs);
    if (safeArgs.containsKey('_fixedToolName')) {
      toolName = safeArgs.remove('_fixedToolName') as String;
    }

    // Fix 1: Normalize keys
    safeArgs = _normalizeKeys(safeArgs);

    // Fix 2: Map synonyms
    safeArgs = _mapFieldSynonyms(safeArgs);

    // Fix 3: Ensure components is a list
    if (safeArgs.containsKey('components')) {
      safeArgs['components'] = _ensureList(safeArgs['components']);
    }

    // Fix 4: Ensure component wrapper exists
    if (safeArgs['components'] is List) {
      safeArgs['components'] = _fixComponentWrappers(
        safeArgs['components'] as List,
      );
    }

    // Fix 5: Extract catalog items from generic UI
    if (safeArgs['components'] is List) {
      safeArgs['components'] = _extractCatalogItems(
        safeArgs['components'] as List,
      );
    }

    // Fix 6: Ensure surfaceId exists
    safeArgs['surfaceId'] ??= 'surface_${DateTime.now().microsecondsSinceEpoch}';

    // Fix 7: Ensure each component has an id
    if (safeArgs['components'] is List) {
      var index = 0;
      safeArgs['components'] = (safeArgs['components'] as List).map((item) {
        if (item is Map && !item.containsKey('id')) {
          item['id'] = 'comp_${index++}_${DateTime.now().microsecondsSinceEpoch}';
        }
        return item;
      }).toList();
    }

    debugPrint('Fixed args: ${jsonEncode(safeArgs)}');

    return super.processToolCall(FunctionCall(toolName, safeArgs));
  }

  Map<String, dynamic> _fixDirectComponentCall(
    String toolName,
    Map<String, dynamic> args,
  ) {
    final knownComponents = {
      'createreminder': 'createReminder',
      'create_reminder': 'createReminder',
      'showanimal': 'showAnimal',
      'show_animal': 'showAnimal',
      'logfeeding': 'logFeeding',
      'log_feeding': 'logFeeding',
      'createinvitecode': 'createInviteCode',
      'create_invite_code': 'createInviteCode',
    };

    final normalizedName = toolName.toLowerCase();
    final componentName = knownComponents[normalizedName];

    if (componentName != null) {
      return {
        '_fixedToolName': 'render_farm',
        'surfaceId': 'surface_${DateTime.now().microsecondsSinceEpoch}',
        'components': [
          {
            'id': 'comp_${DateTime.now().microsecondsSinceEpoch}',
            'component': {
              componentName: Map<String, dynamic>.from(args),
            },
          },
        ],
      };
    }

    return args;
  }

  Map<String, dynamic> _normalizeKeys(Map<String, dynamic> input) {
    return input.map((key, value) {
      var normalizedKey = key;
      
      // snake_case to camelCase
      if (key.contains('_')) {
        final parts = key.split('_');
        normalizedKey = parts.first +
            parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
      }
      
      // PascalCase to camelCase
      if (normalizedKey.isNotEmpty && 
          normalizedKey[0] == normalizedKey[0].toUpperCase()) {
        normalizedKey = normalizedKey[0].toLowerCase() + 
            normalizedKey.substring(1);
      }

      final normalizedValue = value is Map<String, dynamic>
          ? _normalizeKeys(value)
          : value;

      return MapEntry(normalizedKey, normalizedValue);
    });
  }

  static const _fieldSynonyms = {
    'urgency': 'priority',
    'importance': 'priority',
    'deadline': 'dueDate',
    'date': 'dueDate',
    'when': 'dueDate',
    'name': 'title',
    'subject': 'title',
    'details': 'description',
    'notes': 'description',
  };

  Map<String, dynamic> _mapFieldSynonyms(Map<String, dynamic> input) {
    return input.map((key, value) {
      final mappedKey = _fieldSynonyms[key.toLowerCase()] ?? key;
      final mappedValue = value is Map<String, dynamic>
          ? _mapFieldSynonyms(value)
          : value;
      return MapEntry(mappedKey, mappedValue);
    });
  }

  List _ensureList(dynamic components) {
    if (components is List) return components;
    
    if (components is Map) {
      return components.entries.map((e) {
        final item = Map<String, dynamic>.from(e.value as Map);
        item['id'] ??= e.key.toString();
        return item;
      }).toList();
    }
    
    return [components];
  }

  List _fixComponentWrappers(List components) {
    final catalogComponents = [
      'createReminder',
      'showAnimal', 
      'logFeeding',
      'createInviteCode',
    ];

    return components.map((item) {
      if (item is! Map) return item;
      
      final itemMap = Map<String, dynamic>.from(item);
      
      // Already has component wrapper
      if (itemMap.containsKey('component')) return itemMap;
      
      // Find catalog component key
      for (final compName in catalogComponents) {
        if (itemMap.containsKey(compName)) {
          return {
            'id': itemMap['id'] ?? 'gen_${DateTime.now().microsecondsSinceEpoch}',
            'component': {
              compName: itemMap[compName],
            },
          };
        }
      }
      
      return itemMap;
    }).toList();
  }

  List _extractCatalogItems(List components) {
    return components.map((item) {
      if (item is! Map) return item;
      
      final itemMap = Map<String, dynamic>.from(item);
      
      // Check for generic UI that needs extraction
      if (itemMap.containsKey('componentType') && 
          !itemMap.containsKey('component')) {
        final extracted = _extractFromGenericUI(itemMap);
        if (extracted != null) return extracted;
      }
      
      return itemMap;
    }).toList();
  }

  Map<String, dynamic>? _extractFromGenericUI(Map<String, dynamic> genericUI) {
    // Try to find useful content in generic UI structure
    final children = genericUI['children'] as List?;
    if (children == null) return null;

    String? title;
    String? description;

    for (final child in children) {
      if (child is Map) {
        final content = child['content'] ?? child['text'];
        if (content != null) {
          if (title == null) {
            title = content.toString();
          } else {
            description = content.toString();
          }
        }
      }
    }

    if (title != null) {
      return {
        'id': genericUI['id'] ?? 'extracted_${DateTime.now().microsecondsSinceEpoch}',
        'component': {
          'createReminder': {
            'title': title,
            if (description != null) 'description': description,
          },
        },
      };
    }

    return null;
  }

  Future<ContentGeneratorResponse> _requestTextOnly() async {
    // Fall back to text-only response
    return ContentGeneratorResponse(
      text: 'I encountered an issue processing that request. '
          'Could you please rephrase it?',
      toolCalls: [],
    );
  }
}
```

---

## Testing Your Error Handling

### Unit Tests for Transformation Functions

```dart
void main() {
  group('normalizeKeys', () {
    test('converts snake_case to camelCase', () {
      final input = {'due_date': '2026-01-30', 'max_uses': 5};
      final result = normalizeKeys(input);
      
      expect(result, {'dueDate': '2026-01-30', 'maxUses': 5});
    });

    test('converts PascalCase to camelCase', () {
      final input = {'Title': 'Test', 'Priority': 'high'};
      final result = normalizeKeys(input);
      
      expect(result, {'title': 'Test', 'priority': 'high'});
    });

    test('handles nested maps', () {
      final input = {
        'outer_key': {
          'inner_key': 'value',
        },
      };
      final result = normalizeKeys(input);
      
      expect(result, {
        'outerKey': {
          'innerKey': 'value',
        },
      });
    });
  });

  group('ensureList', () {
    test('returns list as-is', () {
      final input = [1, 2, 3];
      expect(ensureList(input), [1, 2, 3]);
    });

    test('converts map to list with ids', () {
      final input = {
        'id1': {'value': 1},
        'id2': {'value': 2},
      };
      final result = ensureList(input);
      
      expect(result, [
        {'id': 'id1', 'value': 1},
        {'id': 'id2', 'value': 2},
      ]);
    });

    test('wraps single item in list', () {
      final input = {'single': 'item'};
      expect(ensureList(input), [input]);
    });
  });

  group('mapFieldSynonyms', () {
    test('maps known synonyms', () {
      final input = {'urgency': 'high', 'deadline': '2026-01-30'};
      final result = mapFieldSynonyms(input);
      
      expect(result, {'priority': 'high', 'dueDate': '2026-01-30'});
    });

    test('preserves unknown fields', () {
      final input = {'customField': 'value'};
      final result = mapFieldSynonyms(input);
      
      expect(result, {'customField': 'value'});
    });
  });
}
```

### Integration Tests with Mock AI Responses

```dart
void main() {
  group('RobustGeminiContentGenerator', () {
    late RobustGeminiContentGenerator generator;

    setUp(() {
      generator = RobustGeminiContentGenerator(
        apiKey: 'test-key',
        modelName: 'gemini-test',
        catalogs: [Catalog(id: 'farm', items: farmTools)],
      );
    });

    test('handles direct component call', () async {
      final call = FunctionCall('create_reminder', {
        'title': 'Test Reminder',
        'priority': 'high',
      });

      final result = await generator.processToolCall(call);

      expect(result.toolCalls.first.name, 'render_farm');
      expect(result.toolCalls.first.args['components'], isA<List>());
    });

    test('fixes map components to list', () async {
      final call = FunctionCall('render_farm', {
        'surfaceId': 'test',
        'components': {
          'comp1': {'component': {'createReminder': {'title': 'Test'}}},
        },
      });

      final result = await generator.processToolCall(call);

      expect(result.toolCalls.first.args['components'], isA<List>());
    });

    test('extracts catalog items from generic UI', () async {
      final call = FunctionCall('render_farm', {
        'surfaceId': 'test',
        'components': [
          {
            'id': 'card1',
            'componentType': 'Card',
            'children': [
              {'componentType': 'Text', 'content': 'Feed chickens'},
            ],
          },
        ],
      });

      final result = await generator.processToolCall(call);
      final component = result.toolCalls.first.args['components'][0];

      expect(component['component']['createReminder'], isNotNull);
      expect(component['component']['createReminder']['title'], 'Feed chickens');
    });
  });
}
```

---

## Monitoring and Logging

### Structured Logging

```dart
class AILogger {
  static void logToolCall(FunctionCall call, {String? phase}) {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'phase': phase ?? 'unknown',
      'toolName': call.name,
      'args': call.args,
      'argsSize': jsonEncode(call.args).length,
    };
    
    debugPrint('AI_TOOL_CALL: ${jsonEncode(entry)}');
  }

  static void logFix(String fixName, dynamic before, dynamic after) {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'fix': fixName,
      'beforeType': before.runtimeType.toString(),
      'afterType': after.runtimeType.toString(),
      'changed': before.toString() != after.toString(),
    };
    
    debugPrint('AI_FIX_APPLIED: ${jsonEncode(entry)}');
  }

  static void logError(dynamic error, {FunctionCall? call}) {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'error': error.toString(),
      'errorType': error.runtimeType.toString(),
      'toolName': call?.name,
      'stack': StackTrace.current.toString().split('\n').take(5).join('\n'),
    };
    
    debugPrint('AI_ERROR: ${jsonEncode(entry)}');
  }
}
```

### Analytics Dashboard Metrics

Track these metrics to understand AI behavior:

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| Fix Rate | % of tool calls needing fixes | > 30% |
| Error Rate | % of tool calls failing | > 5% |
| Retry Rate | % of requests needing retry | > 10% |
| Degradation Rate | % falling back to simplified rendering | > 15% |
| Avg Fixes Per Call | Average number of fixes applied | > 3 |

---

## Best Practices Summary

### Do's ✅

1. **Always normalize input** - Handle case, naming, and type variations
2. **Provide meaningful defaults** - Don't fail on missing optional fields
3. **Log extensively** - You can't fix what you can't see
4. **Test with real AI output** - Save problematic responses for regression tests
5. **Degrade gracefully** - Show something rather than nothing
6. **Give users feedback** - Clear error messages, not stack traces
7. **Version your fixes** - Track which fixes are applied over time

### Don'ts ❌

1. **Don't trust AI output blindly** - Always validate
2. **Don't expose internal errors** - Users don't need stack traces
3. **Don't retry infinitely** - Set reasonable limits
4. **Don't ignore edge cases** - They're more common than you think
5. **Don't hardcode fixes** - Make them configurable
6. **Don't skip logging in production** - You'll regret it

---

## Conclusion

Building robust AI integrations is less about preventing errors and more about handling them gracefully. AI models will misbehave. Schemas will be violated. Formats will be wrong. Accept this reality and build systems that:

1. **Expect the unexpected** - Treat schemas as hints, not contracts
2. **Transform aggressively** - Fix what you can automatically
3. **Degrade gracefully** - Always show something useful
4. **Learn continuously** - Log, analyze, improve

The goal isn't perfect AI output — it's perfect user experience despite imperfect AI output.

Your users don't care if the AI returned `{Title: "Feed chickens"}` instead of `{title: "Feed chickens"}`. They care that their reminder was created. Build systems that bridge that gap, and your AI-powered features will feel magical instead of frustrating.

---

## Further Reading

- [Google Generative AI Best Practices](https://ai.google.dev/docs)
- [JSON Schema Validation](https://json-schema.org/understanding-json-schema/)
- [Error Handling Patterns in Dart](https://dart.dev/guides/libraries/futures-error-handling)
- [Structured Logging in Flutter](https://pub.dev/packages/logging)
- [Part 1: Integrating GenUI](./article.md)

---

*This article documents real production challenges and solutions from building a Flutter application with Gemini AI. Every error handler described here exists because we encountered that exact error in the wild.*
