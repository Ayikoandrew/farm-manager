// ignore_for_file: unused_field, unused_local_variable

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as google_ai;
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;

class GeminiContentGeneratorPractice implements ContentGenerator {
  late final google_ai.GenerativeModel _chatModel;
  late final google_ai.ChatSession _chatSession;

  final _a2uiController = StreamController<A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<ContentGeneratorError>.broadcast();
  final _isProcessing = ValueNotifier<bool>(false);

  GeminiContentGeneratorPractice({
    required String apikey,
    required String modelName,
    required List<Catalog> catalogs,
    String? additionalSystemPrompt,
    bool disableTools = false,
  }) {
    List<google_ai.Tool>? modelTools;
    String fullPrompt;

    if (!disableTools && catalogs.isNotEmpty) {
      final tools = catalogs.map((c) {
        final toolName = 'render_${c.catalogId}';
        final decl = catalogToFunctionDeclaration(
          c,
          toolName,
          'Generates UI for ${c.catalogId}',
        );

        final jsbSchema = decl.parameters as jsb.Schema;

        final geminiSchema = decl.parameters == null
            ? null
            : _convertSchema(jsbSchema);
      });
    }
  }
  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiController.stream;

  @override
  void dispose() {}

  @override
  Stream<ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<String> get textResponseStream => throw UnimplementedError();

  static google_ai.Schema _convertSchema(jsb.Schema input) {
    try {
      return _convertSchemaImpl(input);
    } catch (e, stack) {
      debugPrint("Schema Conversion Failed for input: $input");
      debugPrint("Error: $e");
      debugPrint("Stack: $stack");
      return google_ai.Schema.object(properties: {}, nullable: true);
    }
  }

  static google_ai.Schema _convertSchemaImpl(jsb.Schema input) {
    final typeRaw = input.type;
    return input as google_ai.Schema;
  }
}
