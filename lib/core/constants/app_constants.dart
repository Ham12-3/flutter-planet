class AppConstants {
  static const String appName = 'Itinera AI';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com';
  
  // Local AI (Ollama)
  static const String ollamaBaseUrl = 'http://localhost:11434';
  static const String ollamaModel = 'llama2';
  
  // Database Configuration
  static const String databaseName = 'smart_trip_planner.isar';
  static const int databaseVersion = 1;
  
  // Chat Configuration
  static const int maxChatHistory = 50;
  static const int maxTokensPerRequest = 4000;
  static const int streamingDelay = 50; // milliseconds
  
  // Map Configuration
  static const double defaultZoom = 15.0;
  static const double defaultLat = 35.0116;
  static const double defaultLng = 135.7681; // Kyoto, Japan
  
  // Error Messages
  static const String networkError = 'No internet connection';
  static const String aiServiceError = 'AI service temporarily unavailable';
  static const String invalidItineraryError = 'Invalid itinerary format';
  static const String databaseError = 'Local storage error';
  
  // Feature Flags
  static const bool enableVoiceInput = true;
  static const bool enableOfflineMode = true;
  static const bool enableDebugOverlay = true;
  static const bool enableWebSearch = true;
}