import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../plant_prediction/plant_diseases_prediction_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'AI Plant Diagnosis',
      description: 'Instantly identify plant diseases with our advanced AI scanning technology.',
      image: 'assets/onboarding_1.png',
      accentColor: Colors.greenAccent,
    ),
    OnboardingData(
      title: 'Expert Insights',
      description: 'Get detailed reports on severity, symptoms, and professional treatment steps.',
      image: 'assets/onboarding_2.png',
      accentColor: Colors.lightGreenAccent,
    ),
    OnboardingData(
      title: 'Voice Assistant',
      description: 'Manage your crops hands-free with our intelligent agricultural voice assistant.',
      image: 'assets/onboarding_3.png',
      accentColor: Colors.cyanAccent,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PlantDiseasesPredictionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2310), // Matching splash screen deep green
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _pages[_currentPage].accentColor.withOpacity(0.05),
                    const Color(0xFF0D2310),
                  ],
                ),
              ),
            ),
          ),
          
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPageContent(data: _pages[index]);
            },
          ),
          
          // Navigation Controls
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                          ? _pages[_currentPage].accentColor 
                          : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                // Button
                _currentPage == _pages.length - 1
                  ? ElevatedButton(
                      onPressed: _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'GET STARTED',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    )
                  : IconButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: _pages[_currentPage].accentColor,
                        size: 24,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageContent extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPageContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image with Glassmorphism shadow
          Container(
            height: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: data.accentColor.withOpacity(0.1),
                  blurRadius: 50,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                data.image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;
  final Color accentColor;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.accentColor,
  });
}
