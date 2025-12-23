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
      print('Submitting fraud report for UPI ID: $upiId');
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated');
        throw Exception('User not authenticated');
      }

      print('Current user: ${user.uid} (${user.email})');
      
      final normalizedUpiId = upiId.trim().toLowerCase();
      print('Normalized UPI ID: $normalizedUpiId');
      
      final now = DateTime.now();
      
      // Reference to the reported UPI IDs collection
      final reportedUpiRef = _firestore
          .collection('reported_upi_ids')
          .doc(normalizedUpiId);

      print('Starting transaction...');
      
      // Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(reportedUpiRef);
        
        if (docSnapshot.exists) {
          print('Document exists, updating...');
          // Check if user has already reported this UPI ID
          final data = docSnapshot.data()!;
          final reporters = List<String>.from(data['reporters'] ?? []);
          
          if (reporters.contains(user.uid)) {
            print('User has already reported this UPI ID');
            throw Exception('You have already reported this UPI ID');
          }
          
          // Update existing report
          transaction.update(reportedUpiRef, {
            'report_count': FieldValue.increment(1),
            'last_reported_at': now,
            'reporters': FieldValue.arrayUnion([user.uid]),
          });
        } else {
          print('Creating new report document...');
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
        print('Adding individual report with ID: ${reportRef.id}');
        transaction.set(reportRef, {
          'reporter_uid': user.uid,
          'reporter_email': user.email,
          'reason': reason,
          'description': description,
          'reported_at': now,
        });
      });
      
      print('Report submitted successfully');
      return true;
    } catch (e) {
      print('Error submitting fraud report: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Get report information for a UPI ID
  static Future<Map<String, dynamic>?> getUpiIdReportInfo(String upiId) async {
    try {
      print('Fetching report info for UPI ID: $upiId');
      final normalizedUpiId = upiId.trim().toLowerCase();
      print('Normalized UPI ID: $normalizedUpiId');
      
      final docSnapshot = await _firestore
          .collection('reported_upi_ids')
          .doc(normalizedUpiId)
          .get();

      print('Document exists: ${docSnapshot.exists}');
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        print('Report data: $data');
        return data;
      }
      print('No reports found for this UPI ID');
      return null;
    } catch (e) {
      print('Error fetching UPI report info: $e');
      print('Stack trace: ${StackTrace.current}');
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
      print('Fetching user report history...');
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated');
        throw Exception('User not authenticated');
      }

      print('User UID: ${user.uid}');
      
      final querySnapshot = await _firestore
          .collectionGroup('reports')
          .where('reporter_uid', isEqualTo: user.uid)
          .orderBy('reported_at', descending: true)
          .limit(50)
          .get();

      print('Found ${querySnapshot.docs.length} reports');
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['upi_id'] = doc.reference.parent.parent!.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching user report history: $e');
      print('Stack trace: ${StackTrace.current}');
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