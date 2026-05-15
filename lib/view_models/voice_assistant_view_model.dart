import 'dart:async';
import 'package:flutter/material.dart';
import '../models/voice_assistant_models.dart';
import '../services/ai_voice_assistant_service.dart';
import 'base_view_model.dart';

class VoiceAssistantViewModel extends BaseViewModel {
  AssistantState _state = AssistantState.idle;
  String _partialTranscript = '';
  String _errorMessage = '';
  final List<ConversationMessage> _messages = [];

  bool _sessionActive = false;
  StreamSubscription<void>? _sessionSub;

  AssistantState get state => _state;
  String get partialTranscript => _partialTranscript;
  String get errorMessage => _errorMessage;
  List<ConversationMessage> get messages => List.unmodifiable(_messages);
  bool get sessionActive => _sessionActive;

  bool get isListening => _state == AssistantState.listening;
  bool get isSpeaking => _state == AssistantState.speaking;
  bool get isThinking => _state == AssistantState.thinking;
  bool get isBusy =>
      _state == AssistantState.listening ||
      _state == AssistantState.thinking ||
      _state == AssistantState.speaking;

  void _setupCallbacks() {
    AiVoiceAssistantService.onPartialTranscription = (text) {
      _partialTranscript = text;
      notifyListeners();
    };

    AiVoiceAssistantService.onSpeakStart = () {
      _setState(AssistantState.speaking);
    };

    AiVoiceAssistantService.onSpeakComplete = () {
      _partialTranscript = '';
      _setState(AssistantState.idle);
    };

    AiVoiceAssistantService.onError = (err) {
      _errorMessage = err;
      _setState(AssistantState.error);
    };
  }

  Future<void> startSession() async {
    if (_sessionActive) return;

    _setState(AssistantState.starting);
    _setupCallbacks();

    try {
      await AiVoiceAssistantService.start();
      _sessionActive = true;

      final greeting = AiVoiceAssistantService.conversationHistory.lastWhere(
        (m) => m['role'] == 'assistant',
        orElse: () => {},
      )['content'];

      if (greeting != null && greeting.isNotEmpty) {
        _addMessage(greeting, isUser: false);
      }
    } catch (e) {
      _errorMessage = 'सुरू करता आले नाही: $e';
      _setState(AssistantState.error);
    }
  }

  Future<void> runTurn() async {
    if (!_sessionActive || isBusy) return;

    _partialTranscript = '';
    _setState(AssistantState.listening);

    try {
      final userSpeech = await AiVoiceAssistantService.listen();

      if (userSpeech.isEmpty) {
        _setState(AssistantState.idle);
        return;
      }

      _addMessage(userSpeech, isUser: true);
      _partialTranscript = '';
      _setState(AssistantState.thinking);

      final aiReply = await AiVoiceAssistantService.understand(userSpeech, '');
      _addMessage(aiReply, isUser: false);

      await AiVoiceAssistantService.speak(aiReply);
    } catch (e) {
      _errorMessage = 'त्रुटी: $e';
      _setState(AssistantState.error);
    }
  }

  Future<void> stopSession() async {
    await AiVoiceAssistantService.stop();
    _sessionActive = false;
    _sessionSub?.cancel();
    _setState(AssistantState.idle);
  }

  void clearConversation() {
    AiVoiceAssistantService.clearHistory();
    _messages.clear();
    notifyListeners();
  }

  void _addMessage(String text, {required bool isUser}) {
    _messages.add(
      ConversationMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void _setState(AssistantState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    AiVoiceAssistantService.stop();
    super.dispose();
  }
}
