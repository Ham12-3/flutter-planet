# Smart Trip Planner 🌍✈️

An AI-powered Flutter application that creates personalized travel itineraries through natural language conversations. Users can describe their dream trip and receive detailed, day-by-day plans with activities, dining suggestions, and interactive maps.

## 🚀 Features

### Core Features (MVP)
- **🤖 AI-Powered Planning**: Natural language trip descriptions powered by OpenAI, Gemini, or local Ollama
- **💬 Conversational Interface**: Real-time chat with streaming responses
- **📱 Itinerary Management**: Save, edit, and refine trip plans
- **🗺️ Interactive Maps**: Integrated Google/Apple Maps with location coordinates
- **📴 Offline Access**: Local storage with Isar database for offline viewing
- **📊 Token Tracking**: Cost-aware AI usage with debug overlay
- **🔍 Real-time Search**: Web search integration for live information

### Advanced Features
- **🎤 Voice Input**: Speech-to-text for hands-free planning
- **🔊 Audio Playback**: Text-to-speech for itinerary narration
- **🌤️ Weather Integration**: Real-time weather data for destinations
- **💱 Currency Exchange**: Live exchange rates and cost estimates
- **🎯 Smart Recommendations**: Location-based suggestions with walking distances

## 🏗️ Architecture

### Clean Architecture Structure
```
lib/
├── core/                 # Shared utilities and constants
│   ├── constants/       # App-wide constants
│   ├── utils/          # Utility classes (theme, router)
│   └── errors/         # Error handling
├── data/                # Data layer
│   ├── datasources/    # API and local data sources
│   ├── models/         # Data models with JSON serialization
│   └── repositories/   # Repository implementations
├── domain/              # Business logic layer
│   ├── entities/       # Core business objects
│   ├── repositories/   # Abstract repository contracts
│   └── usecases/       # Business use cases
├── presentation/        # UI layer
│   ├── pages/          # Screen widgets
│   ├── widgets/        # Reusable UI components
│   ├── providers/      # Riverpod state management
│   └── utils/          # UI-specific utilities
└── services/           # External services (AI, Maps, Database)
```

### Technology Stack

**Frontend:**
- Flutter 3.13+ with Material 3 Design
- Riverpod 2.4+ for state management
- Go Router for navigation
- Isar for local database storage

**AI Integration:**
- OpenAI GPT-4/GPT-3.5-turbo
- Google Gemini API
- Local Ollama support
- Function calling for structured responses

**External Services:**
- Google Maps / Apple Maps
- OpenWeather API
- Web search APIs
- Speech recognition & synthesis

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK 3.13.0 or higher
- Dart SDK 3.1.0 or higher
- Android Studio / VS Code with Flutter extensions
- Node.js 18+ (for Firebase Functions, optional)

### 1. Clone and Install
```bash
git clone https://github.com/yourusername/smart_trip_planner_flutter.git
cd smart_trip_planner_flutter

# Install Flutter dependencies
flutter pub get

# Generate code (JSON serialization, Riverpod, etc.)
flutter packages pub run build_runner build
```

### 2. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your API keys
nano .env
```

Required API keys:
- `OPENAI_API_KEY`: OpenAI API key for GPT models
- `GOOGLE_AI_API_KEY`: Google AI Studio API key for Gemini

Optional API keys:
- `OPENWEATHER_API_KEY`: Weather data
- `CURRENCY_API_KEY`: Exchange rates

### 3. Firebase Setup (Optional)
For cloud-based AI agent:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init functions

# Configure FlutterFire
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Local AI Setup (Optional)
For local Ollama integration:
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull a model
ollama pull llama2
ollama serve
```

### 5. Run the Application
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Web (experimental)
flutter run -d chrome
```

## 🧪 Testing

### Run Tests
```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Integration tests
flutter test integration_test/
```

### Test Coverage Target
- **Minimum**: 60% overall coverage
- **Business Logic**: 80%+ coverage for domain layer
- **UI Components**: Widget tests for critical flows
- **Integration**: End-to-end user journey tests

### Mock Strategy
- HTTP responses using `http_mock_adapter`
- AI responses with predefined JSON fixtures
- Database operations with in-memory Isar instances
- Location services with fake GPS coordinates

## 📊 AI Agent Architecture

### Request Flow
1. **User Input** → Chat interface captures natural language
2. **Context Building** → Previous itinerary + chat history assembled
3. **AI Processing** → LLM generates structured JSON response
4. **Validation** → Schema validation ensures proper format
5. **Streaming Update** → UI updates with real-time streaming
6. **Persistence** → Final itinerary saved to local database

### JSON Schema (Spec A)
```json
{
  "title": "Kyoto 5-Day Solo Trip",
  "startDate": "2025-04-10",
  "endDate": "2025-04-15",
  "days": [
    {
      "date": "2025-04-10",
      "summary": "Fushimi Inari & Gion",
      "items": [
        {
          "time": "09:00",
          "activity": "Climb Fushimi Inari Shrine",
          "location": "34.9671,135.7727",
          "description": "Famous shrine with thousands of red torii gates",
          "tags": ["shrine", "hiking", "cultural"]
        }
      ]
    }
  ]
}
```

### Function Calling Tools
- **Web Search**: Real-time information gathering
- **Weather API**: Current conditions and forecasts
- **Currency API**: Exchange rates and cost calculations
- **Maps API**: Location validation and routing

## 🔧 Development Workflow

### Code Generation
```bash
# Watch for changes and auto-generate
flutter packages pub run build_runner watch

# One-time generation
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Code Quality
```bash
# Linting
flutter analyze

# Formatting
dart format lib/ test/

# Import sorting
flutter pub run import_sorter:main
```

### Git Workflow
```bash
# Feature branch
git checkout -b feature/user-authentication

# Conventional commits
git commit -m "feat: add voice input support"
git commit -m "fix: resolve streaming chat lag"
git commit -m "docs: update API documentation"
```

## 🚀 Deployment

### Mobile Apps
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Web Deployment
```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Cloud Functions
```bash
cd functions
npm run build
firebase deploy --only functions
```

## 📈 Performance & Cost Optimization

### Token Usage Tracking
- Request/response token counts logged
- Cost estimation displayed in debug overlay
- Usage analytics for optimization

### Caching Strategy
- Itinerary responses cached locally
- Web search results cached for 1 hour
- Weather data cached for 30 minutes
- Maps queries cached by location

### Memory Management
- Proper disposal of controllers and streams
- Image caching with size limits
- Database connection pooling
- Background task optimization

## 🎯 User Stories Implementation

| ID | Story | Status | Acceptance Criteria |
|----|-------|--------|-------------------|
| S-1 | Create trip via chat | ✅ Implemented | Natural language → structured JSON itinerary |
| S-2 | Refine itinerary | ✅ Implemented | Follow-up messages modify existing plans |
| S-3 | Save & revisit | ✅ Implemented | Local persistence with Isar database |
| S-4 | Offline view | ✅ Implemented | Cached trips accessible without network |
| S-5 | Basic metrics | ✅ Implemented | Token usage tracking and cost display |
| S-6 | Web search | 🚧 In Progress | Real-time information integration |

## 🔍 Token Cost Analysis

Based on testing with various trip types:

| Trip Type | Avg Tokens | Est. Cost (GPT-4) | Est. Cost (GPT-3.5) |
|-----------|------------|------------------|-------------------|
| Weekend City Trip | 800-1200 | $0.02-0.04 | $0.002-0.004 |
| Week-long Adventure | 1500-2500 | $0.05-0.08 | $0.005-0.008 |
| Multi-city Tour | 2000-3500 | $0.08-0.12 | $0.008-0.012 |
| Custom Refinements | 300-800 | $0.01-0.02 | $0.001-0.002 |

*Costs based on current OpenAI pricing as of January 2025*

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Follow coding standards in `CLAUDE.md`
4. Write tests for new functionality
5. Submit pull request with detailed description

### Code Standards
- Follow Flutter/Dart style guide
- Maintain 60%+ test coverage
- Use conventional commit messages
- Update documentation for API changes

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- 📧 Email: support@smarttripplanner.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/smart_trip_planner_flutter/issues)
- 📖 Documentation: [Wiki](https://github.com/yourusername/smart_trip_planner_flutter/wiki)

## 🎬 Demo

🎥 **Demo Video**: [Smart Trip Planner in Action](https://youtu.be/your-demo-video)

### Screenshots
- 🏠 Home screen with recent trips
- 💬 AI chat interface with streaming
- 📋 Detailed itinerary view with maps
- ⚙️ Settings and token usage overlay

---

**Built with ❤️ by [Your Name] using Flutter & AI**