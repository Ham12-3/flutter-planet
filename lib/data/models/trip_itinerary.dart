import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'trip_itinerary.freezed.dart';
part 'trip_itinerary.g.dart';

@freezed
@Collection()
class TripItinerary with _$TripItinerary {
  const factory TripItinerary({
    @Id() int? id,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required List<DayPlan> days,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<ChatMessage> chatHistory,
    @Default(0) int totalTokensUsed,
    @Default(0.0) double estimatedCost,
  }) = _TripItinerary;

  factory TripItinerary.fromJson(Map<String, dynamic> json) =>
      _$TripItineraryFromJson(json);
}

@freezed
@Embedded()
class DayPlan with _$DayPlan {
  const factory DayPlan({
    required String date,
    required String summary,
    required List<ItineraryItem> items,
  }) = _DayPlan;

  factory DayPlan.fromJson(Map<String, dynamic> json) =>
      _$DayPlanFromJson(json);
}

@freezed
@Embedded()
class ItineraryItem with _$ItineraryItem {
  const factory ItineraryItem({
    required String time,
    required String activity,
    required String location,
    String? description,
    String? mapUrl,
    List<String>? tags,
  }) = _ItineraryItem;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) =>
      _$ItineraryItemFromJson(json);
}

@freezed
@Embedded()
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    required bool isUser,
    required DateTime timestamp,
    int? tokenCount,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}