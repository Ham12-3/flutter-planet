// Simplified models for testing without code generation

class SimpleTripItinerary {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<SimpleDayPlan> days;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  SimpleTripItinerary({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
  });
}

class SimpleDayPlan {
  final String date;
  final String summary;
  final List<SimpleItineraryItem> items;
  
  SimpleDayPlan({
    required this.date,
    required this.summary,
    required this.items,
  });
}

class SimpleItineraryItem {
  final String time;
  final String activity;
  final String location;
  final String? description;
  final List<String>? tags;
  
  SimpleItineraryItem({
    required this.time,
    required this.activity,
    required this.location,
    this.description,
    this.tags,
  });
}

class SimpleChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final int? tokenCount;
  
  SimpleChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.tokenCount,
  });
}