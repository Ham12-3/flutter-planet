import 'dart:convert';
import 'dart:math';
import 'package:isar/isar.dart';
import 'package:vector_math/vector_math.dart' as vm;

part 'vector_storage_service.g.dart';

@collection
class VectorCache {
  Id id = Isar.autoIncrement;
  
  @Index()
  String key;
  
  String content;
  List<double> embedding;
  DateTime createdAt;
  DateTime lastAccessed;
  
  @Index()
  String category; // 'destination', 'activity', 'restaurant', etc.
  
  double relevanceScore;
  
  VectorCache({
    required this.key,
    required this.content,
    required this.embedding,
    required this.category,
    this.relevanceScore = 0.0,
  }) : createdAt = DateTime.now(),
       lastAccessed = DateTime.now();
}

class VectorStorageService {
  static const int _embeddingDimensions = 384; // Use smaller model for speed
  static const int _maxCacheSize = 1000;
  static const Duration _cacheExpiry = Duration(days: 7);
  
  late Isar _isar;
  final Random _random = Random();
  
  Future<void> initialize() async {
    // This would be initialized with the main app's Isar instance
    // For now, we'll simulate vector operations
  }
  
  /// Cache site/destination description with vector embedding
  Future<void> cacheSiteDescription(
    String destination, 
    String description, 
    {String category = 'destination'}
  ) async {
    try {
      final embedding = await _generateEmbedding(description);
      final vectorCache = VectorCache(
        key: _generateKey(destination, category),
        content: description,
        embedding: embedding,
        category: category,
      );
      
      // In real implementation, save to Isar
      await _saveToCache(vectorCache);
      
      // Clean old cache entries
      await _cleanExpiredCache();
    } catch (e) {
      print('Error caching site description: \$e');
    }
  }
  
  /// Fast retrieval of cached descriptions for similar destinations
  Future<List<String>> getCachedDescriptions(
    String query, 
    {String category = 'destination', int limit = 5}
  ) async {
    try {
      final queryEmbedding = await _generateEmbedding(query);
      final cachedItems = await _getCachedItems(category);
      
      // Calculate similarity scores
      final similarities = <MapEntry<double, VectorCache>>[];
      
      for (final item in cachedItems) {
        final similarity = _cosineSimilarity(queryEmbedding, item.embedding);
        similarities.add(MapEntry(similarity, item));
        
        // Update last accessed
        item.lastAccessed = DateTime.now();
      }
      
      // Sort by similarity and return top results
      similarities.sort((a, b) => b.key.compareTo(a.key));
      
      return similarities
          .take(limit)
          .where((entry) => entry.key > 0.7) // Only high similarity
          .map((entry) => entry.value.content)
          .toList();
    } catch (e) {
      print('Error retrieving cached descriptions: \$e');
      return [];
    }
  }
  
  /// Generate semantic embedding for text (simplified version)
  Future<List<double>> _generateEmbedding(String text) async {
    // In a real implementation, you would use:
    // - OpenAI embeddings API
    // - Local model like SentenceTransformers
    // - Hugging Face transformers.js
    
    // For now, create a hash-based embedding simulation
    final embedding = List<double>.filled(_embeddingDimensions, 0.0);
    final hash = text.toLowerCase().hashCode;
    
    // Create pseudo-semantic embedding based on text features
    final words = text.toLowerCase().split(' ');
    
    for (int i = 0; i < _embeddingDimensions; i++) {
      double value = 0.0;
      
      // Factor in word count and hash
      value += (words.length * 0.1) * sin(hash + i);
      
      // Factor in specific travel-related keywords
      if (words.any((word) => _isLocationKeyword(word))) {
        value += 0.3 * cos(hash + i);
      }
      
      if (words.any((word) => _isActivityKeyword(word))) {
        value += 0.2 * sin(hash - i);
      }
      
      // Normalize to [-1, 1]
      embedding[i] = value.clamp(-1.0, 1.0);
    }
    
    return _normalizeVector(embedding);
  }
  
  bool _isLocationKeyword(String word) {
    const locationWords = {
      'city', 'town', 'village', 'capital', 'downtown', 'district',
      'beach', 'mountain', 'river', 'lake', 'island', 'park',
      'museum', 'gallery', 'cathedral', 'temple', 'palace'
    };
    return locationWords.contains(word);
  }
  
  bool _isActivityKeyword(String word) {
    const activityWords = {
      'visit', 'explore', 'walk', 'hike', 'swim', 'eat', 'dine',
      'tour', 'see', 'experience', 'enjoy', 'relax', 'adventure',
      'shopping', 'cultural', 'historical', 'scenic', 'romantic'
    };
    return activityWords.contains(word);
  }
  
  /// Calculate cosine similarity between two vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0.0 || normB == 0.0) return 0.0;
    
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
  
  /// Normalize vector to unit length
  List<double> _normalizeVector(List<double> vector) {
    double norm = 0.0;
    for (final value in vector) {
      norm += value * value;
    }
    
    if (norm == 0.0) return vector;
    
    norm = sqrt(norm);
    return vector.map((value) => value / norm).toList();
  }
  
  String _generateKey(String destination, String category) {
    return '${category}_${destination.toLowerCase().replaceAll(' ', '_')}';
  }
  
  /// Save to cache (simulated - would use Isar in real implementation)
  Future<void> _saveToCache(VectorCache item) async {
    // In real implementation:
    // await _isar.writeTxn(() async {
    //   await _isar.vectorCaches.put(item);
    // });
    
    print('Cached: \${item.key} in \${item.category}');
  }
  
  /// Get cached items by category
  Future<List<VectorCache>> _getCachedItems(String category) async {
    // In real implementation:
    // return await _isar.vectorCaches
    //     .where()
    //     .categoryEqualTo(category)
    //     .findAll();
    
    // Return empty for simulation
    return [];
  }
  
  /// Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    final cutoffDate = DateTime.now().subtract(_cacheExpiry);
    
    // In real implementation:
    // await _isar.writeTxn(() async {
    //   await _isar.vectorCaches
    //       .where()
    //       .lastAccessedLessThan(cutoffDate)
    //       .deleteAll();
    // });
    
    // Also clean by size if over limit
    // final count = await _isar.vectorCaches.count();
    // if (count > _maxCacheSize) {
    //   final oldestItems = await _isar.vectorCaches
    //       .where()
    //       .sortByLastAccessed()
    //       .limit(count - _maxCacheSize + 100)
    //       .findAll();
    //   
    //   await _isar.writeTxn(() async {
    //     for (final item in oldestItems) {
    //       await _isar.vectorCaches.delete(item.id);
    //     }
    //   });
    // }
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    // In real implementation, return actual stats
    return {
      'totalItems': 0,
      'categories': <String, int>{},
      'lastCleaned': DateTime.now(),
      'hitRate': 0.0,
    };
  }
}