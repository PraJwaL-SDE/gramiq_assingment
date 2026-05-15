import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gramiq_clone/models/plant_prediction_model.dart';
import 'package:gramiq_clone/widgets/history_card.dart';
import 'package:provider/provider.dart';
import '../../view_models/plant_prediction_view_model.dart';
import 'plant_prediction_details_screen.dart';
import 'plant_info_collection_screen.dart';
import 'image_guidelines_view.dart';
import '../voice_assistant/voice_assistant_screen.dart';

class PlantDiseasesPredictionScreen extends StatelessWidget {
  const PlantDiseasesPredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlantPredictionViewModel(),
      child: Consumer<PlantPredictionViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            appBar: AppBar(
              title: const Text('Plant Doctor'),
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: Column(
              children: [
                // Header / Scan Button Area
                _buildHeader(context, viewModel),
                
                // History List
                Expanded(
                  child: viewModel.isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _buildHistoryList(context, viewModel),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VoiceAssistantScreen()),
                );
              },
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/images/voice.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlantPredictionViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology_outlined, size: 60, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'Identify Plant Diseases',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a photo of your plant to get AI-powered diagnosis and treatment recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: viewModel.isLoading ? null : () async {
              final file = await viewModel.pickImage();
              if (file != null && context.mounted) {
                // Show guidelines before proceeding
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageGuidelinesView(
                      imageFile: file,
                      onContinue: () {
                        Navigator.pop(context); // Go back from guidelines
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlantInfoCollectionScreen(imageFile: file),
                          ),
                        ).then((_) {
                          // Refresh history when returning from prediction
                          viewModel.loadHistory();
                        });
                      },
                      onRetake: () async {
                        Navigator.pop(context); // Go back to main screen
                      },
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('SCAN PLANT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, PlantPredictionViewModel viewModel) {
    if (viewModel.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No scan history yet', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Recent Scans',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: viewModel.history.length,
            itemBuilder: (context, index) {
              final item = viewModel.history[index];
              return HistoryCard(
                item: item,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlantPredictionDetailsScreen(prediction: item)),
                ),
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Scan'),
                        content: const Text('Are you sure you want to delete this scan from your history?'),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () {
                              viewModel.deleteFromHistory(index);
                              Navigator.pop(context);
                            },
                            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}