# Smart Trip Planner - Architecture Documentation

## 🏗️ System Overview

The Smart Trip Planner follows a **Clean Architecture** pattern with clear separation of concerns across three main layers:

1. **Presentation Layer**: UI components, state management, and user interactions
2. **Domain Layer**: Business logic, entities, and use cases
3. **Data Layer**: API calls, local storage, and data models

```mermaid
graph TB
    subgraph "Presentation Layer"
        UI[UI Widgets]
        Providers[Riverpod Providers]
        Pages[Pages/Screens]
    end
    
    subgraph "Domain Layer"
        Entities[Entities]
        UseCases[Use Cases]
        RepoInterfaces[Repository Interfaces]
    end
    
    subgraph "Data Layer"
        Repositories[Repository Implementations]
        DataSources[Data Sources]
        Models[Data Models]
        
        subgraph "External Services"
            OpenAI[OpenAI API]
            Gemini[Google Gemini]
            Ollama[Local Ollama]
            Maps[Maps API]
            Weather[Weather API]
            DB[(Isar Database)]
        end
    end
    
    UI --> Providers
    Pages --> Providers
    Providers --> UseCases
    UseCases --> RepoInterfaces
    RepoInterfaces --> Repositories
    Repositories --> DataSources
    DataSources --> OpenAI
    DataSources --> Gemini
    DataSources --> Ollama
    DataSources --> Maps
    DataSources --> Weather
    DataSources --> DB
    
    Models --> Entities
```

## 📱 Application Flow

### User Journey & Data Flow

```mermaid
sequenceDiagram
    participant User
    participant ChatUI
    participant ChatProvider
    participant AIUseCase
    participant AIRepository
    participant OpenAIService
    participant Database
    
    User->>ChatUI: Enter trip description
    ChatUI->>ChatProvider: Send message
    ChatProvider->>AIUseCase: Generate itinerary
    AIUseCase->>AIRepository: Request AI response
    AIRepository->>OpenAIService: API call with context
    OpenAIService-->>AIRepository: Streaming JSON response
    AIRepository-->>AIUseCase: Validated itinerary
    AIUseCase-->>ChatProvider: Update state
    ChatProvider-->>ChatUI: Render streaming response
    ChatUI-->>User: Display itinerary
    
    ChatProvider->>Database: Save itinerary
    Database-->>ChatProvider: Confirm saved
```

## 🧩 Component Architecture

### 1. Presentation Layer

**State Management (Riverpod)**
```dart
// Provider hierarchy
AppProvider
├── ThemeProvider
├── RouterProvider
├── ChatProvider
├── ItineraryProvider
└── SettingsProvider
```

**Screen Structure**
```
presentation/
├── pages/
│   ├── splash_page.dart          # App initialization
│   ├── home_page.dart            # Main dashboard
│   ├── chat_page.dart            # AI conversation
│   └── itinerary_details_page.dart # Trip details
├── widgets/
│   ├── chat/                     # Chat-specific widgets
│   ├── itinerary/               # Itinerary components
│   └── common/                  # Reusable widgets
└── providers/
    ├── chat_provider.dart        # Chat state management
    ├── itinerary_provider.dart   # Trip data management
    └── ai_provider.dart          # AI service coordination
```

### 2. Domain Layer

**Core Entities**
```dart
// Business objects (pure Dart classes)
class TripItinerary {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<DayPlan> days;
}

class DayPlan {
  final String date;
  final String summary;
  final List<ItineraryItem> items;
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
}
```

**Use Cases**
```dart
// Business logic encapsulation
class GenerateItineraryUseCase {
  Future<TripItinerary> execute(String userPrompt, TripItinerary? existing);
}

class SaveItineraryUseCase {
  Future<void> execute(TripItinerary itinerary);
}

class RefineItineraryUseCase {
  Future<TripItinerary> execute(String refinementPrompt, TripItinerary current);
}
```

### 3. Data Layer

**Repository Pattern**
```dart
abstract class ItineraryRepository {
  Future<List<TripItinerary>> getAllItineraries();
  Future<TripItinerary?> getItinerary(String id);
  Future<void> saveItinerary(TripItinerary itinerary);
  Future<void> deleteItinerary(String id);
}

abstract class AIRepository {
  Stream<String> generateItinerary(String prompt, Map<String, dynamic> context);
  Future<bool> validateResponse(String jsonResponse);
}
```

## 🤖 AI Agent Architecture

### LLM Integration Strategy

```mermaid
graph LR
    subgraph "AI Service Layer"
        AICoordinator[AI Coordinator]
        OpenAIAdapter[OpenAI Adapter]
        GeminiAdapter[Gemini Adapter]
        OllamaAdapter[Ollama Adapter]
    end
    
    subgraph "Context Building"
        PromptBuilder[Prompt Builder]
        ContextManager[Context Manager]
        HistoryManager[Chat History]
    end
    
    subgraph "Response Processing"
        StreamProcessor[Stream Processor]
        JSONValidator[JSON Validator]
        SchemaChecker[Schema Checker]
    end
    
    AICoordinator --> OpenAIAdapter
    AICoordinator --> GeminiAdapter
    AICoordinator --> OllamaAdapter
    
    PromptBuilder --> ContextManager
    ContextManager --> HistoryManager
    
    StreamProcessor --> JSONValidator
    JSONValidator --> SchemaChecker
```

### Function Calling Implementation

```dart
// AI Tools/Functions available to LLMs
final tools = [
  {
    "name": "web_search",
    "description": "Search for real-time information about destinations",
    "parameters": {
      "type": "object",
      "properties": {
        "query": {"type": "string"},
        "location": {"type": "string"}
      }
    }
  },
  {
    "name": "get_weather",
    "description": "Get current weather for a location",
    "parameters": {
      "type": "object",
      "properties": {
        "location": {"type": "string"},
        "date": {"type": "string"}
      }
    }
  }
];
```

### Prompt Engineering Strategy

```typescript
// System prompt template
const SYSTEM_PROMPT = `
You are a travel planning expert AI. Generate detailed itineraries in JSON format.

Context:
- User's previous itinerary: {previous_itinerary}
- Chat history: {chat_history}
- Current request: {user_prompt}

Requirements:
1. Always respond with valid JSON matching the schema
2. Include specific times, locations (lat,lng), and descriptions
3. Consider local culture, weather, and practical logistics
4. Use web_search function for real-time information
5. Optimize for the specified trip style (budget, solo, family, etc.)

JSON Schema:
{schema}
`;
```

## 🗄️ Data Architecture

### Local Database (Isar)

```dart
// Database schema with relationships
@Collection()
class TripItinerary {
  Id id = Isar.autoIncrement;
  late String title;
  late DateTime startDate;
  late DateTime endDate;
  
  final days = IsarLinks<DayPlan>(); // One-to-many relationship
  final messages = IsarLinks<ChatMessage>(); // Chat history
}

@Collection()
class DayPlan {
  Id id = Isar.autoIncrement;
  late String date;
  late String summary;
  
  @Backlink(to: 'days')
  final itinerary = IsarLink<TripItinerary>();
  final items = IsarLinks<ItineraryItem>();
}
```

### Caching Strategy

```mermaid
graph TB
    subgraph "Cache Layers"
        MemoryCache[Memory Cache<br/>Runtime data]
        DiskCache[Disk Cache<br/>Persistent storage]
        DatabaseCache[Database Cache<br/>Structured data]
    end
    
    subgraph "Cache Policies"
        TTL[Time-to-Live<br/>Weather: 30min<br/>Search: 1hr]
        LRU[Least Recently Used<br/>Memory management]
        Size[Size Limits<br/>Images: 100MB<br/>Data: 50MB]
    end
    
    MemoryCache --> DiskCache
    DiskCache --> DatabaseCache
    
    TTL --> MemoryCache
    LRU --> MemoryCache
    Size --> DiskCache
```

## 🔌 External Integrations

### API Service Architecture

```dart
// Dio HTTP client configuration
class APIClient {
  static Dio createDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 60),
    ));
    
    dio.interceptors.addAll([
      AuthInterceptor(),      // API key injection
      RetryInterceptor(),     // Auto retry on failure
      CacheInterceptor(),     // Response caching
      LoggingInterceptor(),   // Request/response logging
    ]);
    
    return dio;
  }
}
```

### Service Interfaces

```dart
abstract class WeatherService {
  Future<Weather> getCurrentWeather(double lat, double lng);
  Future<List<Weather>> getForecast(double lat, double lng, int days);
}

abstract class SearchService {
  Future<List<SearchResult>> search(String query, String location);
  Future<List<PlaceInfo>> findNearbyPlaces(double lat, double lng, String type);
}

abstract class MapsService {
  Future<String> generateMapsUrl(double lat, double lng);
  Future<List<Route>> getDirections(LatLng from, LatLng to);
}
```

## 🧪 Testing Architecture

### Test Pyramid Strategy

```mermaid
graph TB
    subgraph "Test Levels"
        E2E[Integration Tests<br/>10%<br/>Full user journeys]
        Widget[Widget Tests<br/>30%<br/>UI components]
        Unit[Unit Tests<br/>60%<br/>Business logic]
    end
    
    subgraph "Test Categories"
        Business[Business Logic<br/>Use cases, entities]
        Data[Data Layer<br/>Repositories, APIs]
        UI[UI Components<br/>Widgets, screens]
        Integration[End-to-End<br/>Complete flows]
    end
    
    E2E --> Integration
    Widget --> UI
    Unit --> Business
    Unit --> Data
```

### Mock Strategy

```dart
// Mock implementations for testing
class MockAIRepository implements AIRepository {
  @override
  Stream<String> generateItinerary(String prompt, Map<String, dynamic> context) {
    return Stream.fromIterable([
      '{"title": "Test Trip",',
      ' "days": [{"date": "2025-01-01",',
      ' "items": []}]}'
    ]).interval(Duration(milliseconds: 100));
  }
}
```

## 📊 Performance Considerations

### Memory Management

```dart
// Proper resource disposal
class ChatController extends StateNotifier<ChatState> {
  late StreamSubscription _aiResponseSubscription;
  late Timer _autosaveTimer;
  
  @override
  void dispose() {
    _aiResponseSubscription.cancel();
    _autosaveTimer.cancel();
    super.dispose();
  }
}
```

### Optimization Strategies

1. **Lazy Loading**: Load trip details only when accessed
2. **Image Caching**: Cache location images with size limits
3. **Background Processing**: Use isolates for heavy computations
4. **Memory Pools**: Reuse objects where possible
5. **Widget Optimization**: Use const constructors and keys

### Streaming Implementation

```dart
// Efficient streaming for real-time chat
class AIStreamProcessor {
  Stream<ItineraryUpdate> processAIStream(Stream<String> rawStream) async* {
    String buffer = '';
    
    await for (final chunk in rawStream) {
      buffer += chunk;
      
      // Try to parse complete JSON objects
      final updates = _extractCompleteObjects(buffer);
      for (final update in updates) {
        yield ItineraryUpdate.fromJson(update);
      }
    }
  }
}
```

## 🔒 Security Considerations

### API Key Management

```dart
// Secure API key handling
class SecurityConfig {
  static String getAPIKey(String service) {
    // Keys stored in secure storage or environment
    return dotenv.env['${service.toUpperCase()}_API_KEY'] ?? '';
  }
  
  static Map<String, String> getHeaders(String service) {
    return {
      'Authorization': 'Bearer ${getAPIKey(service)}',
      'Content-Type': 'application/json',
      'User-Agent': 'SmartTripPlanner/1.0',
    };
  }
}
```

### Data Privacy

- Local storage only (no cloud sync of personal data)
- API calls use minimal required data
- Chat history stored encrypted locally
- Location data never persisted without consent
- Token usage tracking anonymized

## 🚀 Deployment Architecture

### Build Pipeline

```yaml
# CI/CD Pipeline (GitHub Actions)
name: Build and Deploy
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test --coverage
      - run: flutter analyze
  
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - run: flutter build apk --release
      - run: flutter build appbundle --release
      - run: flutter build web --release
```

### Monitoring & Analytics

```dart
// Performance monitoring
class PerformanceTracker {
  static void trackAIRequest(String model, int tokens, Duration latency) {
    // Track AI usage metrics
  }
  
  static void trackUserJourney(String screen, Duration timeSpent) {
    // Track user engagement
  }
  
  static void trackError(String error, Map<String, dynamic> context) {
    // Track and report errors
  }
}
```

## 📈 Scalability Considerations

### Future Enhancements

1. **Multi-language Support**: i18n integration
2. **Collaborative Planning**: Multi-user trip editing
3. **Advanced AI Features**: Image recognition, voice commands
4. **Social Features**: Trip sharing, reviews
5. **Enterprise Features**: Team planning, expense tracking

### Architecture Evolution

```mermaid
graph LR
    subgraph "Current (MVP)"
        MVP[Single User<br/>Local Storage<br/>Basic AI]
    end
    
    subgraph "Phase 2"
        P2[Multi-user<br/>Cloud Sync<br/>Advanced AI]
    end
    
    subgraph "Phase 3"
        P3[Enterprise<br/>Analytics<br/>Integrations]
    end
    
    MVP --> P2
    P2 --> P3
```

This architecture provides a solid foundation for the Smart Trip Planner while maintaining flexibility for future enhancements and scalability requirements.