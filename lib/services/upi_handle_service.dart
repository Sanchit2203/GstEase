import 'package:cloud_firestore/cloud_firestore.dart';

class UPIHandleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Handles';

  // Cache for better performance
  static Map<String, List<String>>? _cachedHandles;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(hours: 1);

  /// Get UPI handles from Firestore with caching
  static Future<Map<String, List<String>>> _getUPIHandles() async {
    // Check if cache is valid
    if (_cachedHandles != null && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration) {
      return _cachedHandles!;
    }

    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      
      Map<String, List<String>> handles = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        if (data.containsKey('upi') && data['upi'] is List) {
          handles[doc.id] = List<String>.from(data['upi']);
        }
      }
      
      // Update cache
      _cachedHandles = handles;
      _lastCacheUpdate = DateTime.now();
      
      return handles;
    } catch (e) {
      return {};
    }
  }

  /// Check if UPI ID is from bank or wallet
  /// Returns: 'bank', 'wallet', or 'unknown'
  static Future<String> checkUPIType(String upiId) async {
    if (upiId.isEmpty) return 'unknown';

    try {
      // Extract the handle (part after @)
      String handle = '';
      if (upiId.contains('@')) {
        handle = '@${upiId.split('@').last}';
      } else {
        return 'unknown';
      }

      final handles = await _getUPIHandles();
      
      // Check in bank handles
      if (handles['bank']?.contains(handle) == true) {
        return 'bank';
      }
      
      // Check in wallet handles
      if (handles['wallet']?.contains(handle) == true) {
        return 'wallet';
      }
      
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get all available UPI handles
  static Future<Map<String, List<String>>> getAllHandles() async {
    return await _getUPIHandles();
  }

  /// Clear cache (useful for manual refresh)
  static void clearCache() {
    _cachedHandles = null;
    _lastCacheUpdate = null;
  }

  /// Get suggested UPI handles based on type
  static Future<List<String>> getSuggestedHandles(String type) async {
    final handles = await _getUPIHandles();
    
    if (type.toLowerCase() == 'bank') {
      return handles['bank'] ?? [];
    } else if (type.toLowerCase() == 'wallet') {
      return handles['wallet'] ?? [];
    }
    
    return [];
  }
}