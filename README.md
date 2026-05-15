# Gramiq Clone - Plant Doctor AI 🌿

A professional Flutter application built with **MVVM Architecture** that leverages **Google Gemini AI** to help farmers diagnose plant diseases and manage their farms efficiently.

## 🚀 Key Features

- **AI Plant Disease Prediction**: Scan plant leaves to get instant AI-powered diagnosis, confidence scores, and treatment recommendations.
- **Marathi AI Voice Assistant**: A specialized voice assistant powered by Gemini AI that speaks and understands Marathi, making technology accessible to local farmers.
- **Farm Management Dashboard**: Track crops, farm finance, and access crop advisory and mandi prices.
- **Historical Logs**: Keep track of previous plant scans and diagnoses.
- **Real-time Connectivity Guard**: Integrated service to handle network interruptions gracefully.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (3.41.6)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **AI Engine**: [Google Generative AI (Gemini)](https://pub.dev/packages/google_generative_ai)
- **Local Persistence**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Environment Config**: [Flutter Dotenv](https://pub.dev/packages/flutter_dotenv)
- **CI/CD**: GitHub Actions (Automated building, testing, and APK generation)

## 🏗️ Architecture (MVVM)

The project follows a clean **Model-View-ViewModel** architecture:
- **Models**: Data entities and business logic structures.
- **ViewModels**: Centralized state management and logic (inheriting from `BaseViewModel`).
- **Views**: UI components and screens, decoupled from business logic.
- **Services**: External integrations (AI, Connectivity, Storage).
- **Widgets**: Reusable UI components.

## 📦 Project Structure

```text
lib/
├── models/         # Data models
├── view_models/    # Business logic & State management
├── views/          # Screen-level UI
├── services/       # External service integrations
├── widgets/        # Reusable UI components
└── utils/          # Theming, colors, and loggers
```

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (>= 3.41.6)
- A Google Gemini API Key (Get it from [Google AI Studio](https://aistudio.google.com/))

### Installation

1. **Clone the repository**:
   ```bash
   git clone git@github.com:PraJwaL-SDE/gramiq_assingment.git
   cd gramiq_clone
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**:
   Create a `.env` file in the root directory:
   ```text
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

## 🤖 CI/CD Workflow

This project includes a fully automated **GitHub Actions** pipeline (`.github/workflows/flutter_ci.yml`):
- **Analyze**: Ensures code quality and follows linting rules.
- **Test**: Runs automated widget and unit tests.
- **Build**: Automatically generates a release APK on every push to `main`.

## 🤝 Contribution

Feel free to fork this project and submit pull requests. For major changes, please open an issue first to discuss what you would like to change.

---
Developed with ❤️ by Prajwal
