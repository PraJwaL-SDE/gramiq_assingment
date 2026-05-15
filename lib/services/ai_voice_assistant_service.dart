// lib/services/ai_voice_assistant_service.dart

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// ═══════════════════════════════════════════════════════════════════
/// AI VOICE ASSISTANT SERVICE
/// ───────────────────────────────────────────────────────────────────
/// Complete pipeline:
///   start() → listen() → understand() → speak() → stop()
///
/// Language: Marathi (mr-IN)
/// AI Model: Gemini 2.0 Flash (via google_generative_ai)
/// STT: speech_to_text (on-device)
/// TTS: flutter_tts (on-device)
/// ═══════════════════════════════════════════════════════════════════

class AiVoiceAssistantService {
  // ──────────────────────────────────────────────────────────────────
  // CONFIGURATION  (replace with your actual keys / settings)
  // ──────────────────────────────────────────────────────────────────

  /// 🔑 Gemini API key from .env file
  static final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Gemini model to use
  static const String _modelId = 'gemini-3-flash-preview';

  /// Speech recognition locale (Marathi – India)
  static const String _sttLocale = 'mr-IN';

  /// TTS language code
  static const String _ttsLanguage = 'mr-IN';

  /// TTS speech rate (0.0 – 1.0)
  static const double _ttsSpeechRate = 0.45;

  /// TTS pitch
  static const double _ttsPitch = 1.05;

  /// TTS volume
  static const double _ttsVolume = 1.0;

  /// Max seconds to wait for speech input before auto-stopping
  static const int _listenTimeoutSeconds = 8;

  // ──────────────────────────────────────────────────────────────────
  // PRIVATE STATE
  // ──────────────────────────────────────────────────────────────────

  static late GenerativeModel _geminiModel;
  static late ChatSession _chatSession;
  static final SpeechToText _stt = SpeechToText();
  static final FlutterTts _tts = FlutterTts();

  static bool _isInitialized = false;
  static bool _isSpeaking = false;
  static bool _isListening = false;

  /// Tracks the full conversation for multi-turn context
  static final List<Map<String, String>> _conversationHistory = [];

  // ──────────────────────────────────────────────────────────────────
  // PUBLIC CALLBACKS  (set these from your UI)
  // ──────────────────────────────────────────────────────────────────

  /// Called every time a partial / final transcription arrives
  static void Function(String partial)? onPartialTranscription;

  /// Called when TTS starts speaking
  static void Function()? onSpeakStart;

  /// Called when TTS finishes speaking
  static void Function()? onSpeakComplete;

  /// Called on any error
  static void Function(String error)? onError;

  // ──────────────────────────────────────────────────────────────────
  // MARATHI SYSTEM PROMPT
  // ──────────────────────────────────────────────────────────────────

  static const String _marathiSystemPrompt = '''
तुम्ही एक बुद्धिमान मराठी आवाज सहाय्यक आहात.

नियम:
1. **फक्त मराठी भाषेत** उत्तर द्या. कधीही इंग्रजी वापरू नका.
2. उत्तरे **संक्षिप्त आणि स्पष्ट** असावीत — आवाज संवादासाठी योग्य.
3. तुम्ही **माहितीपूर्ण, मैत्रीपूर्ण आणि उपयुक्त** आहात.
4. शेती, बाजारभाव, हवामान, आरोग्य, सरकारी योजना यांसारख्या **ग्रामीण विषयांमध्ये** तज्ञ आहात.
5. **प्रश्न विचारा** जेव्हा अधिक माहिती हवी असेल — एका वेळी एकच प्रश्न.
6. बाजारभाव विचारल्यास, शहर/जिल्हा विचारा, मग अंदाजे दर सांगा.
7. उत्तर देताना लांबलचक वाक्ये टाळा. बोलण्यायोग्य, नैसर्गिक मराठी वापरा.
8. क्रमांक, तारखा देशी पद्धतीने सांगा (उदा. "पाच हजार पाचशे रुपये प्रति क्विंटल").
9. संभाषण सुरू करताना: "नमस्कार! मी तुमचा मराठी AI सहाय्यक आहे. मी तुमची कशी मदत करू शकतो?"

उदाहरण संवाद:
वापरकर्ता: "आज गव्हाचा भाव किती आहे?"
सहाय्यक: "तुम्हाला कोणत्या शहरातील भाव हवा आहे?"
वापरकर्ता: "नागपूर"
सहाय्यक: "आज नागपुरात गव्हाचा भाव साधारण पाच हजार पाचशे रुपये प्रति क्विंटल आहे."
''';

  // ──────────────────────────────────────────────────────────────────
  // 1. START — initialise all subsystems
  // ──────────────────────────────────────────────────────────────────

  /// Initialises Gemini, STT, and TTS.
  /// Must be called once before any other method.
  static Future<void> start() async {
    if (_isInitialized) {
      dev.log('[AVA] Already initialised — skipping start()');
      return;
    }

    dev.log('[AVA] ▶ start()');

    try {
      await Future.wait([
        _initGemini(),
        _initStt(),
        _initTts(),
      ]);

      _isInitialized = true;
      dev.log('[AVA] ✅ All subsystems ready');

      // Greet the user in Marathi on first launch
      final greeting = await understand('', '');
      await speak(greeting);
    } catch (e, st) {
      dev.log('[AVA] ❌ start() failed: $e', stackTrace: st);
      onError?.call('सुरू करताना त्रुटी: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 2. LISTEN — capture speech and return transcribed Marathi text
  // ──────────────────────────────────────────────────────────────────

  /// Starts the microphone and returns the final Marathi transcription.
  /// Returns empty string on timeout or silence.
  static Future<String> listen() async {
    _assertInitialised('listen');

    if (_isListening) {
      dev.log('[AVA] Already listening — ignoring duplicate call');
      return '';
    }
    if (_isSpeaking) await _waitForSpeakToFinish();

    dev.log('[AVA] 🎙 listen() — locale: $_sttLocale');

    final completer = Completer<String>();
    final buffer = StringBuffer();

    _isListening = true;

    final available = await _stt.initialize(
      onError: (error) {
        dev.log('[AVA] STT error: ${error.errorMsg}');
        _isListening = false;
        if (!completer.isCompleted) completer.complete(buffer.toString().trim());
      },
      onStatus: (status) {
        dev.log('[AVA] STT status: $status');
        if ((status == 'done' || status == 'notListening') &&
            !completer.isCompleted) {
          _isListening = false;
          completer.complete(buffer.toString().trim());
        }
      },
    );

    if (!available) {
      _isListening = false;
      onError?.call('मायक्रोफोन उपलब्ध नाही');
      return '';
    }

    await _stt.listen(
      localeId: _sttLocale,
      listenFor: Duration(seconds: _listenTimeoutSeconds),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      onResult: (result) {
        final text = result.recognizedWords;
        buffer.clear();
        buffer.write(text);
        onPartialTranscription?.call(text);

        if (result.finalResult && !completer.isCompleted) {
          _isListening = false;
          _stt.stop();
          completer.complete(text.trim());
        }
      },
    );

    // Safety timeout
    Future.delayed(Duration(seconds: _listenTimeoutSeconds + 2), () {
      if (!completer.isCompleted) {
        _isListening = false;
        _stt.stop();
        completer.complete(buffer.toString().trim());
      }
    });

    final result = await completer.future;
    dev.log('[AVA] 🎤 Transcribed: "$result"');
    return result;
  }

  // ──────────────────────────────────────────────────────────────────
  // 3. UNDERSTAND — send text to Gemini and get Marathi response
  // ──────────────────────────────────────────────────────────────────

  /// Sends [text] to Gemini with conversation [context] and returns
  /// the Marathi AI response.
  ///
  /// [text]    — user's transcribed speech (can be empty for greeting)
  /// [context] — optional extra context string (e.g. location, date)
  static Future<String> understand(String text, String context) async {
    _assertInitialised('understand');

    dev.log('[AVA] 🧠 understand() — input: "$text"');

    try {
      // Build the message
      final userMessage = _buildUserMessage(text, context);

      // Store in local history
      if (text.isNotEmpty) {
        _conversationHistory.add({'role': 'user', 'content': text});
      }

      // Send to Gemini chat session (maintains turn history automatically)
      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
      );

      final aiText = response.text?.trim() ?? '';

      if (aiText.isEmpty) {
        const fallback = 'मला समजले नाही, कृपया पुन्हा सांगा.';
        dev.log('[AVA] ⚠️ Empty Gemini response — using fallback');
        return fallback;
      }

      _conversationHistory.add({'role': 'assistant', 'content': aiText});
      dev.log('[AVA] 💬 Gemini response: "$aiText"');
      return aiText;
    } on GenerativeAIException catch (e) {
      dev.log('[AVA] ❌ Gemini error: $e');
      onError?.call('AI त्रुटी: ${e.message}');
      return 'माफ करा, काही तांत्रिक अडचण आली आहे.';
    } catch (e) {
      dev.log('[AVA] ❌ understand() error: $e');
      onError?.call('समजण्यात त्रुटी: $e');
      return 'माफ करा, काही चूक झाली.';
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 4. SPEAK — convert Marathi text to speech
  // ──────────────────────────────────────────────────────────────────

  /// Speaks [text] aloud in Marathi using TTS.
  static Future<void> speak(String text) async {
    _assertInitialised('speak');

    if (text.trim().isEmpty) return;

    dev.log('[AVA] 🔊 speak(): "$text"');

    // Stop any ongoing speech first
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }

    _isSpeaking = true;
    onSpeakStart?.call();

    final completer = Completer<void>();

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onSpeakComplete?.call();
      if (!completer.isCompleted) completer.complete();
    });

    _tts.setErrorHandler((message) {
      dev.log('[AVA] TTS error: $message');
      _isSpeaking = false;
      onError?.call('TTS त्रुटी: $message');
      if (!completer.isCompleted) completer.complete();
    });

    await _tts.speak(text);
    await completer.future;
  }

  // ──────────────────────────────────────────────────────────────────
  // 5. STOP — graceful shutdown
  // ──────────────────────────────────────────────────────────────────

  /// Stops listening and speaking, and resets state.
  static Future<void> stop() async {
    dev.log('[AVA] ⏹ stop()');

    if (_isListening) {
      await _stt.stop();
      _isListening = false;
    }

    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }

    _isInitialized = false;
    _conversationHistory.clear();
    dev.log('[AVA] ✅ Stopped and cleaned up');
  }

  // ──────────────────────────────────────────────────────────────────
  // CONVERSATION LOOP — convenience wrapper
  // ──────────────────────────────────────────────────────────────────

  /// Runs a single full turn:  listen → understand → speak
  /// Returns the AI's response text.
  ///
  /// Use this in a loop to drive the conversation:
  /// ```dart
  /// await AiVoiceAssistantService.start();
  /// while (sessionActive) {
  ///   final reply = await AiVoiceAssistantService.runTurn();
  ///   if (reply.contains('धन्यवाद') || reply.contains('बाय')) break;
  /// }
  /// await AiVoiceAssistantService.stop();
  /// ```
  static Future<String> runTurn({String extraContext = ''}) async {
    _assertInitialised('runTurn');

    final userSpeech = await listen();

    if (userSpeech.isEmpty) {
      const prompt = 'कृपया बोला, मी ऐकत आहे.';
      await speak(prompt);
      return prompt;
    }

    final aiReply = await understand(userSpeech, extraContext);
    await speak(aiReply);
    return aiReply;
  }

  // ──────────────────────────────────────────────────────────────────
  // ACCESSORS
  // ──────────────────────────────────────────────────────────────────

  static bool get isListening => _isListening;
  static bool get isSpeaking => _isSpeaking;
  static bool get isInitialized => _isInitialized;
  static List<Map<String, String>> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Clears conversation history (starts fresh topic)
  static void clearHistory() {
    _conversationHistory.clear();
    // Re-create chat session to reset Gemini turn history
    _chatSession = _geminiModel.startChat(history: [
      Content.text(_marathiSystemPrompt),
    ]);
    dev.log('[AVA] 🗑 History cleared');
  }

  // ──────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ──────────────────────────────────────────────────────────────────

  static Future<void> _initGemini() async {
    dev.log('[AVA] Initialising Gemini...');

    _geminiModel = GenerativeModel(
      model: _modelId,
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 512, // Keep responses short for voice
        stopSequences: [],
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(
            HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(
            HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
      systemInstruction: Content.text(_marathiSystemPrompt),
    );

    // Start a multi-turn chat session
    _chatSession = _geminiModel.startChat();
    dev.log('[AVA] ✅ Gemini ready ($_modelId)');
  }

  static Future<void> _initStt() async {
    dev.log('[AVA] Initialising STT...');
    // Actual initialisation happens on first listen() call.
    // Just verify the plugin is available.
    final available = await _stt.initialize(debugLogging: kDebugMode);
    dev.log('[AVA] ✅ STT available: $available');
  }

  static Future<void> _initTts() async {
    dev.log('[AVA] Initialising TTS...');

    await _tts.setLanguage(_ttsLanguage);
    await _tts.setSpeechRate(_ttsSpeechRate);
    await _tts.setPitch(_ttsPitch);
    await _tts.setVolume(_ttsVolume);

    // Try to select a Marathi engine if available
    final engines = await _tts.getEngines;
    dev.log('[AVA] TTS engines: $engines');

    final voices = await _tts.getVoices;
    dev.log('[AVA] Available voices count: ${(voices as List).length}');

    // Select a Marathi voice if available
    final marathiVoice = (voices as List<dynamic>).firstWhere(
      (v) =>
          (v['locale'] as String?)?.startsWith('mr') == true ||
          (v['name'] as String?)?.toLowerCase().contains('mar') == true,
      orElse: () => null,
    );

    if (marathiVoice != null) {
      await _tts.setVoice({
        'name': marathiVoice['name'],
        'locale': marathiVoice['locale'],
      });
      dev.log('[AVA] ✅ Marathi voice selected: ${marathiVoice['name']}');
    } else {
      dev.log('[AVA] ⚠️ No Marathi voice found — using default');
    }

    dev.log('[AVA] ✅ TTS ready');
  }

  /// Builds the message string sent to Gemini.
  static String _buildUserMessage(String text, String context) {
    if (text.isEmpty) {
      // Greeting turn
      return 'नमस्कार करा आणि सुरुवात करा.';
    }

    final buffer = StringBuffer(text);

    if (context.isNotEmpty) {
      buffer.write('\n\n[अतिरिक्त माहिती: $context]');
    }

    // Append today's date so AI can answer "today" questions
    final now = DateTime.now();
    buffer.write(
        '\n[आज: ${now.day}/${now.month}/${now.year}, वेळ: ${now.hour}:${now.minute.toString().padLeft(2, '0')}]');

    return buffer.toString();
  }

  static void _assertInitialised(String method) {
    if (!_isInitialized) {
      throw StateError(
          '[AVA] $method() called before start(). Call start() first.');
    }
  }

  static Future<void> _waitForSpeakToFinish() async {
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}