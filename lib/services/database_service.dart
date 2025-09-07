import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/trip_itinerary.dart';

class DatabaseService {
  static Isar? _isar;
  
  static Isar get instance {
    if (_isar == null) {
      throw Exception('Database not initialized. Call DatabaseService.initialize() first.');
    }
    return _isar!;
  }
  
  static Future<void> initialize() async {
    if (_isar != null) return;
    
    final dir = await getApplicationDocumentsDirectory();
    
    _isar = await Isar.open(
      [TripItinerarySchema],
      directory: dir.path,
      name: 'smart_trip_planner',
    );
  }
  
  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
  
  // Trip Itinerary CRUD operations
  static Future<int> saveItinerary(TripItinerary itinerary) async {
    return await instance.writeTxn(() async {
      return await instance.tripItinerarys.put(itinerary);
    });
  }
  
  static Future<List<TripItinerary>> getAllItineraries() async {
    return await instance.tripItinerarys
        .where()
        .sortByCreatedAtDesc()
        .findAll();
  }
  
  static Future<TripItinerary?> getItinerary(int id) async {
    return await instance.tripItinerarys.get(id);
  }
  
  static Future<bool> deleteItinerary(int id) async {
    return await instance.writeTxn(() async {
      return await instance.tripItinerarys.delete(id);
    });
  }
  
  static Future<void> clearAllData() async {
    await instance.writeTxn(() async {
      await instance.tripItinerarys.clear();
    });
  }
}