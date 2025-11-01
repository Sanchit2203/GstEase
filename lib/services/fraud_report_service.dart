import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FraudReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit a fraud report for a UPI ID
  static Future<bool> submitFraudReport({
    required String upiId,
    required String reason,
    required String description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final normalizedUpiId = upiId.trim().toLowerCase();
      final now = DateTime.now();
      
      // Reference to the reported UPI IDs collection
      final reportedUpiRef = _firestore
          .collection('reported_upi_ids')
          .doc(normalizedUpiId);

      // Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(reportedUpiRef);
        
        if (docSnapshot.exists) {
          // Check if user has already reported this UPI ID
          final data = docSnapshot.data()!;
          final reporters = List<String>.from(data['reporters'] ?? []);
          
          if (reporters.contains(user.uid)) {
            throw Exception('You have already reported this UPI ID');
          }
          
          // Update existing report
          transaction.update(reportedUpiRef, {
            'report_count': FieldValue.increment(1),
            'last_reported_at': now,
            'reporters': FieldValue.arrayUnion([user.uid]),
          });
        } else {
          // Create new report document
          transaction.set(reportedUpiRef, {
            'upi_id': normalizedUpiId,
            'report_count': 1,
            'first_reported_at': now,
            'last_reported_at': now,
            'reporters': [user.uid],
            'status': 'pending',
          });
        }
        
        // Add individual report details
        final reportRef = reportedUpiRef.collection('reports').doc();
        transaction.set(reportRef, {
          'reporter_uid': user.uid,
          'reporter_email': user.email,
          'reason': reason,
          'description': description,
          'reported_at': now,
        });
      });
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get report information for a UPI ID
  static Future<Map<String, dynamic>?> getUpiIdReportInfo(String upiId) async {
    try {
      final normalizedUpiId = upiId.trim().toLowerCase();
      final docSnapshot = await _firestore
          .collection('reported_upi_ids')
          .doc(normalizedUpiId)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get risk level for a UPI ID based on report count
  static String getRiskLevel(int reportCount) {
    if (reportCount > 10) {
      return 'CRITICAL';
    } else if (reportCount > 5) {
      return 'HIGH';
    } else if (reportCount > 2) {
      return 'MEDIUM';
    } else if (reportCount > 0) {
      return 'LOW';
    } else {
      return 'NONE';
    }
  }

  /// Get risk color for UI display
  static String getRiskColor(int reportCount) {
    if (reportCount > 10) {
      return '#D32F2F'; // Red
    } else if (reportCount > 5) {
      return '#F57C00'; // Orange
    } else if (reportCount > 2) {
      return '#FBC02D'; // Yellow
    } else if (reportCount > 0) {
      return '#689F38'; // Light Green
    } else {
      return '#4CAF50'; // Green
    }
  }

  /// Get user's report history
  static Future<List<Map<String, dynamic>>> getUserReportHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collectionGroup('reports')
          .where('reporter_uid', isEqualTo: user.uid)
          .orderBy('reported_at', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['upi_id'] = doc.reference.parent.parent!.id;
        return data;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get most reported UPI IDs (for admin/moderation purposes)
  static Future<List<Map<String, dynamic>>> getMostReportedUpiIds({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('reported_upi_ids')
          .orderBy('report_count', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if current user has reported a specific UPI ID
  static Future<bool> hasUserReportedUpiId(String upiId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final normalizedUpiId = upiId.trim().toLowerCase();
      final docSnapshot = await _firestore
          .collection('reported_upi_ids')
          .doc(normalizedUpiId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final reporters = List<String>.from(data['reporters'] ?? []);
        return reporters.contains(user.uid);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}