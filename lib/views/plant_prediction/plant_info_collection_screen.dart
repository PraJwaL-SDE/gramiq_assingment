import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/plant_prediction_view_model.dart';
import 'plant_prediction_details_screen.dart';

class PlantInfoCollectionScreen extends StatefulWidget {
  final File imageFile;

  const PlantInfoCollectionScreen({super.key, required this.imageFile});

  @override
  State<PlantInfoCollectionScreen> createState() => _PlantInfoCollectionScreenState();
}

class _PlantInfoCollectionScreenState extends State<PlantInfoCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  final _tempController = TextEditingController(text: '28');
  final _humidityController = TextEditingController(text: '60');
  final _phController = TextEditingController();
  final _rainfallTimeController = TextEditingController(text: '2 days ago');
  
  String _soilMoisture = 'Medium';
  String _growingPhase = 'Vegetative';
  String _leafAge = 'Mature';
  String _rainfallType = 'Moderate';
  String _season = 'Monsoon';
  String _insectsCount = 'None';

  @override
  void dispose() {
    _tempController.dispose();
    _humidityController.dispose();
    _phController.dispose();
    _rainfallTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlantPredictionViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Environmental Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Basic Environment'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Temp (°C)', _tempController, Icons.thermostat, isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Humidity (%)', _humidityController, Icons.water_drop, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDropdown('Soil Moisture', _soilMoisture, ['Low', 'Medium', 'High', 'Saturated'], (v) => setState(() => _soilMoisture = v!))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdown('Season', _season, ['Summer', 'Monsoon', 'Winter', 'Spring'], (v) => setState(() => _season = v!))),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Plant Context'),
                  const SizedBox(height: 12),
                  _buildDropdown('Growing Phase', _growingPhase, ['Seedling', 'Vegetative', 'Flowering', 'Fruiting'], (v) => setState(() => _growingPhase = v!)),
                  const SizedBox(height: 16),
                  _buildDropdown('Leaf Age', _leafAge, ['Young', 'Mature', 'Old/Senescent'], (v) => setState(() => _leafAge = v!)),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Rainfall & Soil'),
                  const SizedBox(height: 12),
                  _buildTextField('Last Rainfall Time', _rainfallTimeController, Icons.calendar_today),
                  const SizedBox(height: 16),
                  _buildDropdown('Rainfall Type', _rainfallType, ['No Rain', 'Light Drizzle', 'Moderate', 'Heavy'], (v) => setState(() => _rainfallType = v!)),
                  const SizedBox(height: 16),
                  _buildTextField('Soil pH (Optional)', _phController, Icons.science_outlined, isNumber: true, required: false),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Insects/Pests Observed'),
                  const SizedBox(height: 12),
                  _buildInsectToggle(),

                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
          
          // Bottom Submit Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: viewModel.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: viewModel.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ANALYZE PLANT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, bool required = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) return 'Required';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInsectToggle() {
    final options = ['None', 'Few', 'Many'];
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _insectsCount == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _insectsCount = opt),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = Provider.of<PlantPredictionViewModel>(context, listen: false);
    
    final extraContext = {
      "Temperature": "${_tempController.text} °C",
      "Humidity": "${_humidityController.text}%",
      "Soil Moisture": _soilMoisture,
      "Growing Phase": _growingPhase,
      "Leaf Age": _leafAge,
      "Last Rainfall": _rainfallTimeController.text,
      "Rainfall Type": _rainfallType,
      "Soil pH": _phController.text.isEmpty ? "Not provided" : _phController.text,
      "Insects Seen": _insectsCount,
      "Current Season": _season,
    };

    final result = await viewModel.predictWithDetails(context, widget.imageFile, extraContext);
    
    if (result != null && mounted) {
      // Find the last added prediction from history
      final prediction = viewModel.history.first;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PlantPredictionDetailsScreen(prediction: prediction)),
      );
    }
  }
}
