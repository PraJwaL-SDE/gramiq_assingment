import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gramiq_clone/view_models/plant_prediction_view_model.dart';
import 'package:gramiq_clone/view_models/voice_assistant_view_model.dart';
import 'package:provider/provider.dart';
import 'views/splash/splash_screen.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  ConnectivityService().initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VoiceAssistantViewModel()),
        ChangeNotifierProvider(create: (_) => PlantPredictionViewModel()),
      ],
      child: const GramiqCloneApp(),
    ),
  );
}

class GramiqCloneApp extends StatelessWidget {
  const GramiqCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Doctor',
      navigatorKey: ConnectivityService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green.shade700,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const SplashScreen(),
    );
  }
}
