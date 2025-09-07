import 'dart:math';
import 'dart:collection';

class POI {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final double rating;
  final int priceLevel; // 1-4 scale
  final Duration estimatedVisitTime;
  final List<String> openHours;
  
  POI({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.rating = 0.0,
    this.priceLevel = 2,
    this.estimatedVisitTime = const Duration(hours: 2),
    this.openHours = const [],
  });
  
  /// Calculate straight-line distance to another POI in meters
  double distanceTo(POI other) {
    return _haversineDistance(latitude, longitude, other.latitude, other.longitude);
  }
  
  /// Calculate walking time to another POI in minutes
  int walkingTimeTo(POI other) {
    final distanceMeters = distanceTo(other);
    const walkingSpeedMps = 1.4; // Average walking speed: 1.4 m/s
    return (distanceMeters / walkingSpeedMps / 60).ceil(); // Convert to minutes
  }
}

class PathNode {
  final POI poi;
  final double gCost; // Actual cost from start
  final double hCost; // Heuristic cost to goal
  final PathNode? parent;
  
  PathNode({
    required this.poi,
    required this.gCost,
    required this.hCost,
    this.parent,
  });
  
  double get fCost => gCost + hCost; // Total estimated cost
}

class PathfindingService {
  static const double _walkingSpeedKmh = 5.0; // Average walking speed
  static const int _maxWalkingMinutes = 30; // Maximum walking time between POIs
  
  /// Re-rank POIs using A* pathfinding to optimize walking routes
  Future<List<POI>> reRankPOIsByWalkingDistance({
    required List<POI> pois,
    required POI startLocation,
    POI? endLocation,
    int maxPoisPerDay = 6,
    Duration availableTime = const Duration(hours: 8),
  }) async {
    if (pois.isEmpty) return [];
    
    try {
      // Group POIs by proximity clusters
      final clusters = _clusterPOIsByProximity(pois);
      
      // Find optimal route through clusters
      final optimizedRoute = await _findOptimalRoute(
        clusters: clusters,
        startLocation: startLocation,
        endLocation: endLocation,
        maxPois: maxPoisPerDay,
        availableTime: availableTime,
      );
      
      return optimizedRoute;
    } catch (e) {
      print('Error in POI re-ranking: \$e');
      return _fallbackRanking(pois, startLocation);
    }
  }
  
  /// Cluster POIs by geographical proximity
  List<List<POI>> _clusterPOIsByProximity(List<POI> pois) {
    final clusters = <List<POI>>[];
    final visited = <POI>{};
    const maxClusterRadius = 1000; // 1km radius for clusters
    
    for (final poi in pois) {
      if (visited.contains(poi)) continue;
      
      final cluster = <POI>[poi];
      visited.add(poi);
      
      // Find nearby POIs to form a cluster
      for (final other in pois) {
        if (visited.contains(other)) continue;
        
        if (poi.distanceTo(other) <= maxClusterRadius) {
          cluster.add(other);
          visited.add(other);
        }
      }
      
      clusters.add(cluster);
    }
    
    return clusters;
  }
  
  /// Find optimal route using A* algorithm principles
  Future<List<POI>> _findOptimalRoute({
    required List<List<POI>> clusters,
    required POI startLocation,
    POI? endLocation,
    required int maxPois,
    required Duration availableTime,
  }) async {
    final selectedPois = <POI>[];
    final remainingTime = availableTime.inMinutes;
    var currentLocation = startLocation;
    var timeUsed = 0;
    
    // Priority queue for POIs based on score
    final poiQueue = PriorityQueue<POI>((a, b) => 
        _calculatePOIScore(b, currentLocation).compareTo(_calculatePOIScore(a, currentLocation)));
    
    // Add all POIs to queue
    for (final cluster in clusters) {
      for (final poi in cluster) {
        poiQueue.add(poi);
      }
    }
    
    while (selectedPois.length < maxPois && 
           timeUsed < remainingTime && 
           poiQueue.isNotEmpty) {
      
      final bestPoi = _findBestNextPOI(
        available: poiQueue.toList(),
        currentLocation: currentLocation,
        remainingTime: remainingTime - timeUsed,
        endLocation: endLocation,
        selectedPois: selectedPois,
      );
      
      if (bestPoi == null) break;
      
      // Add POI to route
      selectedPois.add(bestPoi);
      
      // Update time and location
      final walkingTime = currentLocation.walkingTimeTo(bestPoi);
      timeUsed += walkingTime + bestPoi.estimatedVisitTime.inMinutes;
      currentLocation = bestPoi;
      
      // Remove from queue
      poiQueue.remove(bestPoi);
      
      // Remove nearby POIs that are too close (avoid clustering)
      poiQueue.removeWhere((poi) => bestPoi.distanceTo(poi) < 200);
    }
    
    return selectedPois;
  }
  
  /// Find the best next POI using A* heuristic
  POI? _findBestNextPOI({
    required List<POI> available,
    required POI currentLocation,
    required int remainingTime,
    POI? endLocation,
    required List<POI> selectedPois,
  }) {
    if (available.isEmpty) return null;
    
    POI? bestPoi;
    double bestScore = -1;
    
    for (final poi in available) {
      if (selectedPois.contains(poi)) continue;
      
      final walkingTime = currentLocation.walkingTimeTo(poi);
      final totalTimeNeeded = walkingTime + poi.estimatedVisitTime.inMinutes;
      
      // Skip if not enough time
      if (totalTimeNeeded > remainingTime) continue;
      
      // Calculate A* score
      final score = _calculateAStarScore(
        poi: poi,
        currentLocation: currentLocation,
        endLocation: endLocation,
        remainingTime: remainingTime,
        walkingTime: walkingTime,
      );
      
      if (score > bestScore) {
        bestScore = score;
        bestPoi = poi;
      }
    }
    
    return bestPoi;
  }
  
  /// Calculate A* score combining distance, rating, and heuristics
  double _calculateAStarScore({
    required POI poi,
    required POI currentLocation,
    POI? endLocation,
    required int remainingTime,
    required int walkingTime,
  }) {
    // G cost: actual walking time (inverted for scoring)
    final gScore = 1.0 / (1.0 + walkingTime / 60.0); // Higher score for shorter walks
    
    // H cost: heuristic based on POI quality
    final hScore = _calculatePOIScore(poi, currentLocation);
    
    // Consider distance to end location if specified
    double endLocationBonus = 0.0;
    if (endLocation != null) {
      final distanceToEnd = poi.distanceTo(endLocation);
      endLocationBonus = 1.0 / (1.0 + distanceToEnd / 1000.0); // Bonus for being closer to end
    }
    
    // Time efficiency bonus
    final timeEfficiency = remainingTime / max(1, walkingTime + poi.estimatedVisitTime.inMinutes);
    
    // Combine all factors
    return gScore * 0.3 + hScore * 0.5 + endLocationBonus * 0.1 + timeEfficiency * 0.1;
  }
  
  /// Calculate POI intrinsic score
  double _calculatePOIScore(POI poi, POI currentLocation) {
    // Base score from rating
    double score = poi.rating / 5.0; // Normalize to 0-1
    
    // Category bonuses
    score += _getCategoryBonus(poi.category);
    
    // Price level factor (prefer diverse price ranges)
    score += (5 - poi.priceLevel) * 0.1; // Slight preference for lower cost
    
    // Walking distance penalty
    final walkingMinutes = currentLocation.walkingTimeTo(poi);
    if (walkingMinutes > _maxWalkingMinutes) {
      score *= 0.5; // Heavy penalty for too far
    } else {
      score *= (1.0 - walkingMinutes / (_maxWalkingMinutes * 2.0)); // Linear penalty
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  double _getCategoryBonus(String category) {
    const categoryBonuses = {
      'museum': 0.2,
      'restaurant': 0.15,
      'attraction': 0.25,
      'park': 0.1,
      'shopping': 0.05,
      'entertainment': 0.15,
      'cultural': 0.2,
      'historical': 0.25,
    };
    
    return categoryBonuses[category.toLowerCase()] ?? 0.0;
  }
  
  /// Fallback ranking by simple distance and rating
  List<POI> _fallbackRanking(List<POI> pois, POI startLocation) {
    final scored = pois.map((poi) {
      final distance = startLocation.distanceTo(poi);
      final walkingTime = startLocation.walkingTimeTo(poi);
      
      // Simple score: rating / walking_time_hours
      final score = walkingTime > 0 
          ? poi.rating / (walkingTime / 60.0)
          : poi.rating;
      
      return MapEntry(score, poi);
    }).toList();
    
    scored.sort((a, b) => b.key.compareTo(a.key));
    return scored.map((entry) => entry.value).take(8).toList();
  }
  
  /// Calculate total walking distance for a route
  double calculateTotalWalkingDistance(List<POI> route, POI startLocation) {
    if (route.isEmpty) return 0.0;
    
    double totalDistance = startLocation.distanceTo(route.first);
    
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += route[i].distanceTo(route[i + 1]);
    }
    
    return totalDistance;
  }
  
  /// Calculate total walking time for a route in minutes
  int calculateTotalWalkingTime(List<POI> route, POI startLocation) {
    if (route.isEmpty) return 0;
    
    int totalTime = startLocation.walkingTimeTo(route.first);
    
    for (int i = 0; i < route.length - 1; i++) {
      totalTime += route[i].walkingTimeTo(route[i + 1]);
      totalTime += route[i].estimatedVisitTime.inMinutes;
    }
    
    if (route.isNotEmpty) {
      totalTime += route.last.estimatedVisitTime.inMinutes;
    }
    
    return totalTime;
  }
}

/// Calculate Haversine distance between two points in meters
double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // Earth radius in meters
  
  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);
  
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

double _degreesToRadians(double degrees) {
  return degrees * (pi / 180);
}

/// Simple priority queue implementation
class PriorityQueue<T> {
  final List<T> _items = [];
  final Comparator<T> _comparator;
  
  PriorityQueue(this._comparator);
  
  void add(T item) {
    _items.add(item);
    _items.sort(_comparator);
  }
  
  T? removeFirst() {
    return _items.isNotEmpty ? _items.removeAt(0) : null;
  }
  
  void remove(T item) {
    _items.remove(item);
  }
  
  void removeWhere(bool Function(T) test) {
    _items.removeWhere(test);
  }
  
  List<T> toList() => List.from(_items);
  
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
}