import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiPlantDiseasePredictionService {
  static final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _geminiModel = 'gemini-3-flash-preview';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent';

  static Future<Map<String, dynamic>> predictDisease(
    File image,
    String plantName,
    String state,
    String city,
    DateTime imageDateTime,
    Map<String, dynamic> extraContext,
  ) async {
    print(
      'DEBUG: [AiPlantDiseasePredictionService] Starting predictDisease for plant: $plantName',
    );
    try {
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final mimeType = _detectMimeType(image.path);
      print(
        'DEBUG: [AiPlantDiseasePredictionService] Image encoded. MIME type: $mimeType',
      );

      final prompt = _buildPrompt(
        plantName: plantName,
        state: state,
        city: city,
        imageDateTime: imageDateTime,
        extraContext: extraContext,
      );
      print(
        'DEBUG: [AiPlantDiseasePredictionService] Contextual prompt built.',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Image},
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'topK': 32,
          'topP': 0.95,
          'maxOutputTokens': 2048,
          'responseMimeType': 'application/json',
        },
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        ],
      };

      final uri = Uri.parse('$_baseUrl?key=$_geminiApiKey');
      print(
        'DEBUG: [AiPlantDiseasePredictionService] Sending POST request to Gemini API...',
      );
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));
      print(
        'DEBUG: [AiPlantDiseasePredictionService] Response received. Status code: ${response.statusCode}',
      );
      try {
        final prettyJson = const JsonEncoder.withIndent(
          '  ',
        ).convert(jsonDecode(response.body));
        print(
          'DEBUG: [AiPlantDiseasePredictionService] Raw API Response Body:\n$prettyJson',
        );
      } catch (_) {
        print(
          'DEBUG: [AiPlantDiseasePredictionService] Raw API Response Body: ${response.body}',
        );
      }

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        print(
          'DEBUG: [AiPlantDiseasePredictionService] Gemini API error: ${response.body}',
        );
        return {
          'error':
              'Gemini API error ${response.statusCode}: '
              '${errorBody['error']?['message'] ?? 'Unknown error'}',
        };
      }

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = responseJson['candidates'] as List<dynamic>?;

      if (candidates == null || candidates.isEmpty) {
        return {'error': 'No candidates returned from Gemini API.'};
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;

      if (parts == null || parts.isEmpty) {
        return {'error': 'Empty response content from Gemini API.'};
      }

      if (candidates.isNotEmpty) {
        final finishReason = candidates[0]['finishReason'];
        print(
          'DEBUG: [AiPlantDiseasePredictionService] Finish Reason: $finishReason',
        );
      }

      final rawText = parts[0]['text'] as String? ?? '';

      final result = _parseModelResponse(rawText);
      print(
        'DEBUG: [AiPlantDiseasePredictionService] predictDisease completed successfully.',
      );
      return result;
    } on SocketException {
      print(
        'DEBUG: [AiPlantDiseasePredictionService] SocketException: No internet.',
      );
      return {'error': 'No internet connection. Please check your network.'};
    } on HttpException catch (e) {
      print(
        'DEBUG: [AiPlantDiseasePredictionService] HttpException: ${e.message}',
      );
      return {'error': 'HTTP error: ${e.message}'};
    } on FormatException catch (e) {
      print(
        'DEBUG: [AiPlantDiseasePredictionService] FormatException: ${e.message}',
      );
      return {'error': 'Failed to parse API response: ${e.message}'};
    } catch (e) {
      print('DEBUG: [AiPlantDiseasePredictionService] Unexpected error: $e');
      return {'error': 'Unexpected error: $e'};
    }
  }

  static String _buildPrompt({
    required String plantName,
    required String state,
    required String city,
    required DateTime imageDateTime,
    required Map<String, dynamic> extraContext,
  }) {
    print(
      'DEBUG: [AiPlantDiseasePredictionService] Building prompt for $plantName...',
    );
    final formattedDate =
        '${imageDateTime.year}-${_pad(imageDateTime.month)}-${_pad(imageDateTime.day)} '
        '${_pad(imageDateTime.hour)}:${_pad(imageDateTime.minute)}';

    final contextString = extraContext.entries
        .map((e) => '- **${e.key}**: ${e.value}')
        .join('\n');

    return '''
You are an expert plant pathology and agronomist specializing in Cotton (Gossypium) crops. 
Your primary task is to analyze the provided image specifically for Cotton leaf diseases, pests, and nutrient deficiencies.

## Core Objective
Analyze the image of a Cotton leaf and identify common cotton-specific issues such as:
- Bacterial Blight (Angular Leaf Spot)
- Alternaria Leaf Spot
- Grey Mildew
- Leaf Curl Virus
- Fusarium/Verticillium Wilt
- Pests (Aphids, Jassids, Whitefly, Thrips, Mealybug)
- Nutrient Deficiencies (Nitrogen, Potassium, Magnesium)

## Plant & Environmental Context
- **Crop**: Cotton
- **User Input Plant Name**: $plantName
- **Location**: $city, $state
- **Photo Taken**: $formattedDate
$contextString

## Instructions
1. Focus your diagnosis exclusively on issues affecting Cotton plants.
2. Examine the leaf image carefully for any signs of cotton-specific disease, pest damage, nutrient deficiency, or stress.
3. Use the environmental data (temperature, humidity, location, season) to refine your diagnosis.
4. If the cotton leaf appears healthy, set `disease_name` to "Healthy" and `severity` to "None".
5. Return ONLY a valid JSON object — no markdown, no code fences, no extra text.

## Required JSON Schema
{
  "disease_name": "string — specific cotton disease name or 'Healthy'",
  "confidence": "number 0.0–1.0",
  "severity": "None | Low | Moderate | High | Critical",
  "affected_parts": ["list of affected parts, e.g. 'leaves', 'bolls', 'stem'"],
  "symptoms": ["list of observed symptom descriptions in cotton"],
  "causes": ["list of causal agents, e.g. 'Xanthomonas citri pv. malvacearum'"],
  "treatment": ["ordered list of recommended treatment steps for cotton"],
  "prevention": ["list of prevention measures for future cotton crops"],
  "environmental_risk": "string — assessment of how current temp/humidity/location increases risk for this cotton disease",
  "urgency": "Monitor | Treat Soon | Treat Immediately",
  "additional_notes": "string — any other cotton-specific observations or caveats"
}
''';
  }

  static Map<String, dynamic> _parseModelResponse(String rawText) {
    print(
      'DEBUG: [AiPlantDiseasePredictionService] Parsing model response text (length: ${rawText.length})',
    );
    print(
      'DEBUG: [AiPlantDiseasePredictionService] Raw Text to Parse: $rawText',
    );

    var cleaned = rawText.trim();

    if (cleaned.contains('```')) {
      final match = RegExp(
        r'```(?:json)?\s*([\s\S]*?)\s*```',
      ).firstMatch(cleaned);
      if (match != null) {
        cleaned = match.group(1) ?? cleaned;
      } else {
        cleaned = cleaned.replaceAll(RegExp(r'^```(?:json)?|```$'), '').trim();
      }
    }

    cleaned = cleaned.replaceAllMapped(
      RegExp(r',\s*([\}\]])'),
      (m) => m.group(1)!,
    );

    try {
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      if (parsed['confidence'] is String) {
        parsed['confidence'] = double.tryParse(parsed['confidence']) ?? 0.0;
      }
      print(
        'DEBUG: [AiPlantDiseasePredictionService] JSON parsed successfully.',
      );
      return parsed;
    } catch (e) {
      print('DEBUG: [AiPlantDiseasePredictionService] JSON Parse Error: $e');
      return {'error': 'Model returned invalid JSON.', 'raw_response': rawText};
    }
  }

  static String _detectMimeType(String path) {
    print(
      'DEBUG: [AiPlantDiseasePredictionService] Detecting MIME type for: $path',
    );
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
