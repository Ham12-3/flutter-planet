import 'dart:convert';

class ItineraryModel {
  final String title;
  final String startDate;
  final String endDate;
  final List<DayModel> days;

  ItineraryModel({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  factory ItineraryModel.fromJson(Map<String, dynamic> json) {
    return ItineraryModel(
      title: json['title'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      days: (json['days'] as List<dynamic>?)
          ?.map((day) => DayModel.fromJson(day))
          .toList() ?? [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ItineraryModel.fromJsonString(String jsonString) {
    return ItineraryModel.fromJson(jsonDecode(jsonString));
  }
}

class DayModel {
  final String date;
  final String summary;
  final List<ActivityModel> items;

  DayModel({
    required this.date,
    required this.summary,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'summary': summary,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      date: json['date'] ?? '',
      summary: json['summary'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ActivityModel.fromJson(item))
          .toList() ?? [],
    );
  }
}

class ActivityModel {
  final String time;
  final String activity;
  final String? location; // Optional coordinates "lat,lng"
  final String? notes; // Optional additional notes

  ActivityModel({
    required this.time,
    required this.activity,
    this.location,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'time': time,
      'activity': activity,
    };
    if (location != null) json['location'] = location!;
    if (notes != null) json['notes'] = notes!;
    return json;
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      time: json['time'] ?? '',
      activity: json['activity'] ?? '',
      location: json['location'],
      notes: json['notes'],
    );
  }
}