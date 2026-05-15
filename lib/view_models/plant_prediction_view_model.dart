import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_prediction_model.dart';
import '../services/ai_plant_disease_prediction_service.dart';
import 'base_view_model.dart';

class PlantPredictionViewModel extends BaseViewModel {
  final List<PlantPrediction> _history = [];
  List<PlantPrediction> get history => List.unmodifiable(_history);

  final ImagePicker _picker = ImagePicker();

  PlantPredictionViewModel() {
    loadHistory();
  }

  Future<void> loadHistory() async {
    setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('plant_prediction_history');
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      _history.clear();
      _history.addAll(
        decoded.map((item) => PlantPrediction.fromJson(item)).toList(),
      );
      _history.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    }
    setLoading(false);
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String historyJson = jsonEncode(
      _history.map((item) => item.toJson()).toList(),
    );
    await prefs.setString('plant_prediction_history', historyJson);
  }

  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    return File(image.path);
  }

  Future<Map<String, dynamic>?> predictWithDetails(
    BuildContext context,
    File imageFile,
    Map<String, dynamic> extraContext,
  ) async {
    setLoading(true);
    try {
      final result = await AiPlantDiseasePredictionService.predictDisease(
        imageFile,
        "Cotton Leaf",
        "Maharashtra",
        "Nagpur",
        DateTime.now(),
        extraContext,
      );

      if (result.containsKey('error')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['error'])));
        return null;
      }

      final prediction = PlantPrediction(
        diseaseName: result['disease_name'] ?? 'Unknown',
        confidence: (result['confidence'] ?? 0.0).toDouble(),
        severity: result['severity'] ?? 'Moderate',
        symptoms: List<String>.from(result['symptoms'] ?? []),
        treatment: List<String>.from(result['treatment'] ?? []),
        imagePath: imageFile.path,
        dateTime: DateTime.now(),
      );

      _history.insert(0, prediction);
      await saveHistory();
      notifyListeners();

      return result;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      return null;
    } finally {
      setLoading(false);
    }
  }

  // Deprecated: keeping for compatibility but screens should use separate steps
  Future<Map<String, dynamic>?> pickAndPredict(BuildContext context) async {
    final file = await pickImage();
    if (file == null) return null;
    return predictWithDetails(context, file, {
      "Temperature": "28.5 °C",
      "Humidity": "65.0%",
    });
  }

  void deleteFromHistory(int index) async {
    _history.removeAt(index);
    await saveHistory();
    notifyListeners();
  }
}
