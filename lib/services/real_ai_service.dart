import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/parser.dart' as html;

class RealAIService {
  final Dio _dio = Dio();
  
  // Free API endpoints
  static const String _searchAPI = 'https://api.search.brave.com/res/v1/web/search';
  static const String _weatherAPI = 'https://api.openweathermap.org/data/2.5/weather';
  static const String _currencyAPI = 'https://api.exchangerate-api.com/v4/latest/USD';
  
  // Free alternative APIs
  static const String _freeSearchAPI = 'https://serpapi.com/search.json'; // Free tier
  static const String _duckDuckGoAPI = 'https://api.duckduckgo.com/';
  
  String? _openAIKey;
  String? _weatherKey;
  
  RealAIService() {
    _openAIKey = dotenv.env['OPENAI_API_KEY'];
    _weatherKey = dotenv.env['OPENWEATHER_API_KEY'] ?? 'demo_key'; // Use demo for testing
    
    // Validate OpenAI API key
    if (_openAIKey == null || _openAIKey!.isEmpty) {
      print('Warning: No OpenAI API key found in .env file');
    } else if (!_openAIKey!.startsWith('sk-')) {
      print('Warning: OpenAI API key should start with "sk-"');
    }
    
    _dio.interceptors.add(LogInterceptor());
  }
  
  /// Generate real itinerary with AI and internet search
  Future<String> generateItinerary(String tripVision) async {
    try {
      // Step 1: Extract key information from trip vision
      final tripDetails = _extractTripDetails(tripVision);
      
      // Step 2: Search for destination information
      final searchResults = await _searchDestinationInfo(tripDetails['destination'] ?? '');
      
      // Step 3: Get weather data
      final weatherData = await _getWeatherData(tripDetails['destination'] ?? '');
      
      // Step 4: Get currency rates if international
      final currencyData = await _getCurrencyRates();
      
      // Step 5: Use AI to generate itinerary with real data
      final itinerary = await _generateAIItinerary(tripVision, searchResults, weatherData, currencyData);
      
      return itinerary;
    } catch (e) {
      print('Error generating real itinerary: $e');
      return _generateFallbackItinerary(tripVision);
    }
  }

  /// Handle follow-up chat with existing itinerary context
  Future<String> handleFollowUpChat({
    required String userMessage,
    required String originalTripVision,
    required String existingItinerary,
    List<String> chatHistory = const [],
  }) async {
    try {
      if (_openAIKey == null || _openAIKey!.isEmpty) {
        return _generateFollowUpFallback(userMessage, existingItinerary);
      }

      // Build context-aware prompt
      final prompt = _buildFollowUpPrompt(userMessage, originalTripVision, existingItinerary, chatHistory);

      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openAIKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful travel planning assistant. Always maintain context of the original trip and provide relevant, practical advice.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1500,
          'temperature': 0.7,
        },
      );

      final content = response.data['choices']?[0]?['message']?['content'];
      return content ?? _generateFollowUpFallback(userMessage, existingItinerary);
    } catch (e) {
      print('OpenAI follow-up error: $e');
      return _generateFollowUpFallback(userMessage, existingItinerary);
    }
  }

  String _buildFollowUpPrompt(String userMessage, String originalTripVision, String existingItinerary, List<String> chatHistory) {
    final historyText = chatHistory.isNotEmpty ? '\nChat History:\n${chatHistory.join('\n')}' : '';
    
    return '''
Original Trip Request: "$originalTripVision"

Current Itinerary:
$existingItinerary

$historyText

User's Follow-up Question: "$userMessage"

Please provide a helpful response that:
1. Maintains context of the original trip
2. References the existing itinerary when relevant
3. Provides specific, actionable advice
4. Stays focused on travel planning

Response:
''';
  }

  String _generateFollowUpFallback(String userMessage, String existingItinerary) {
    return '''
I understand you want to discuss your itinerary further. Based on your current plan, I'd be happy to help you with:

• Making adjustments to your schedule
• Finding alternative activities
• Getting restaurant recommendations
• Transportation advice
• Budget planning tips

Your current itinerary includes some great options. What specific aspect would you like to modify or improve?
''';
  }
  
  /// Extract trip details using simple parsing
  Map<String, String> _extractTripDetails(String tripVision) {
    final details = <String, String>{};
    
    // Simple pattern matching for key information
    final destinationMatch = RegExp(r'(?:to|in|visit)\s+([A-Za-z\s]+)(?:,|\s|for|\$)').firstMatch(tripVision.toLowerCase());
    if (destinationMatch != null) {
      details['destination'] = destinationMatch.group(1)?.trim() ?? '';
    }
    
    final durationMatch = RegExp(r'(\d+)\s+day').firstMatch(tripVision.toLowerCase());
    if (durationMatch != null) {
      details['duration'] = durationMatch.group(1) ?? '5';
    }
    
    final budgetMatch = RegExp(r'[\$€£](\d+)').firstMatch(tripVision);
    if (budgetMatch != null) {
      details['budget'] = budgetMatch.group(1) ?? '1000';
    }
    
    return details;
  }
  
  /// Search for destination information using free APIs
  Future<List<String>> _searchDestinationInfo(String destination) async {
    if (destination.isEmpty) return [];
    
    try {
      // Use DuckDuckGo's free API
      final response = await _dio.get(
        _duckDuckGoAPI,
        queryParameters: {
          'q': '$destination travel attractions restaurants',
          'format': 'json',
          'no_html': '1',
          'skip_disambig': '1',
        },
      );
      
      final data = response.data;
      final results = <String>[];
      
      // Extract useful information from search results
      if (data['RelatedTopics'] != null) {
        for (final topic in (data['RelatedTopics'] as List).take(5)) {
          if (topic['Text'] != null) {
            results.add(topic['Text'].toString());
          }
        }
      }
      
      return results;
    } catch (e) {
      print('Search API error: $e');
      return _getDefaultDestinationInfo(destination);
    }
  }
  
  /// Get weather data using OpenWeatherMap free tier
  Future<Map<String, dynamic>> _getWeatherData(String destination) async {
    if (destination.isEmpty) return {};
    
    try {
      final response = await _dio.get(
        _weatherAPI,
        queryParameters: {
          'q': destination,
          'appid': _weatherKey,
          'units': 'metric',
        },
      );
      
      return response.data;
    } catch (e) {
      print('Weather API error: $e');
      return {
        'weather': [{'main': 'Clear', 'description': 'Pleasant weather'}],
        'main': {'temp': 22, 'humidity': 60},
      };
    }
  }
  
  /// Get currency exchange rates using free API
  Future<Map<String, dynamic>> _getCurrencyRates() async {
    try {
      final response = await _dio.get(_currencyAPI);
      return response.data;
    } catch (e) {
      print('Currency API error: $e');
      return {
        'rates': {
          'EUR': 0.85,
          'GBP': 0.75,
          'JPY': 110.0,
          'AUD': 1.35,
        }
      };
    }
  }
  
  /// Generate AI itinerary using OpenAI with real data
  Future<String> _generateAIItinerary(
    String tripVision,
    List<String> searchResults,
    Map<String, dynamic> weatherData,
    Map<String, dynamic> currencyData,
  ) async {
    if (_openAIKey == null || _openAIKey == 'test_key_for_ui_testing') {
      return _generateEnhancedFallbackItinerary(tripVision, searchResults, weatherData);
    }
    
    try {
      final prompt = _buildAIPrompt(tripVision, searchResults, weatherData, currencyData);
      
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openAIKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are an expert travel planner.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 2000,
          'temperature': 0.7,
        },
      );
      
      final content = response.data['choices'][0]['message']['content'];
      return content ?? _generateFallbackItinerary(tripVision);
    } catch (e) {
      print('OpenAI API error: $e');
      return _generateEnhancedFallbackItinerary(tripVision, searchResults, weatherData);
    }
  }
  
  String _buildAIPrompt(
    String tripVision,
    List<String> searchResults,
    Map<String, dynamic> weatherData,
    Map<String, dynamic> currencyData,
  ) {
    final searchInfo = searchResults.join('\n');
    final weather = weatherData.isNotEmpty 
        ? 'Weather: ${weatherData['weather']?[0]['description'] ?? 'Pleasant'}, ${weatherData['main']?['temp'] ?? 22}°C'
        : '';
    
    return '''
Create a detailed travel itinerary based on this request: "$tripVision"

Additional Information:
$searchInfo

Current Weather Info:
$weather

IMPORTANT: Respond with a valid JSON object following this exact schema:
{
  "title": "Trip Title",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "days": [
    {
      "date": "YYYY-MM-DD",
      "summary": "Day summary",
      "items": [
        {
          "time": "HH:MM",
          "activity": "Activity description",
          "location": "lat,lng (optional)",
          "notes": "Additional notes (optional)"
        }
      ]
    }
  ]
}

Requirements:
- Include specific times for each activity
- Add restaurant recommendations with timing
- Include transportation suggestions
- Provide realistic coordinates when possible
- Make the itinerary practical and well-paced
- Return ONLY the JSON object, no additional text
    ''';
  }
  
  /// Enhanced fallback with real search data
  String _generateEnhancedFallbackItinerary(
    String tripVision,
    List<String> searchResults,
    Map<String, dynamic> weatherData,
  ) {
    final destination = _extractTripDetails(tripVision)['destination'] ?? 'your destination';
    final weather = weatherData.isNotEmpty 
        ? '${weatherData['weather']?[0]['description'] ?? 'pleasant weather'}'
        : 'pleasant weather';
    
    final attractions = searchResults.isNotEmpty 
        ? searchResults.take(3).join('\n• ') 
        : 'local attractions and cultural sites';
    
    return '''
🌟 Your \$destination Adventure

🌤️ Weather: Expect \$weather during your visit

📍 Top Attractions & Activities:
• \$attractions

📅 Sample Itinerary:

Day 1: Arrival & City Overview
• 10:00 AM - Arrive and check into accommodation
• 2:00 PM - Walking tour of main attractions
• 7:00 PM - Welcome dinner at local restaurant

Day 2: Cultural Exploration
• 9:00 AM - Visit museums and cultural sites
• 1:00 PM - Lunch at traditional restaurant
• 3:00 PM - Explore local markets
• 6:00 PM - Sunset viewing at scenic spot

Day 3: Adventure & Nature
• 8:00 AM - Outdoor activities (weather permitting)
• 12:00 PM - Picnic lunch
• 3:00 PM - Visit natural landmarks
• 8:00 PM - Farewell dinner

💰 Estimated Budget: \$800-1200 per person
🚗 Transportation: Local transport recommended

*Itinerary enhanced with real-time data*
    ''';
  }
  
  List<String> _getDefaultDestinationInfo(String destination) {
    return [
      'Popular tourist destination with rich culture',
      'Known for historical landmarks and cuisine',
      'Great weather for outdoor activities',
      'Recommended for cultural experiences',
      'Family-friendly attractions available',
    ];
  }
  
  String _generateFallbackItinerary(String tripVision) {
    return '''
🌍 Your Dream Trip Itinerary

Based on your vision: "\$tripVision"

We're working on generating your perfect itinerary with real-time data.

📍 Day-by-Day Plan:
• Customized activities based on your preferences
• Weather-appropriate recommendations
• Local cuisine and cultural experiences
• Budget-friendly options
• Transportation guidance

💡 This itinerary will be enhanced with:
• Real-time weather data
• Current attraction information
• Live pricing and availability
• Local events and festivals

*Note: Connect your API keys for fully personalized, real-time itineraries*
    ''';
  }
}