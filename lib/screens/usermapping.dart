import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserMapping {
  static Future<void> createUserMapping({
    required String username,
    required String accountId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('userMapping')
          .doc(user.uid)
          .set({
            'username': username,
            'accountId': accountId,
            'createdAt': FieldValue.serverTimestamp(),
          });

      print('✅ User mapping created successfully');
      print('UID: ${user.uid}');
      print('Username: $username');
      print('AccountId: $accountId');
    } catch (e) {
      print('❌ Error creating user mapping: $e');
    }
  }

  // Lấy accountId từ UID
  static Future<String?> getAccountId(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('userMapping')
          .doc(uid)
          .get();

      if (doc.exists) {
        return doc.data()?['accountId'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting account ID: $e');
      return null;
    }
  }

  // Debug: Hiển thị UID hiện tại
  static void showCurrentUID() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('=== CURRENT USER INFO ===');
      print('UID: ${user.uid}');
      print('Phone: ${user.phoneNumber}');
      print('========================');
    } else {
      print('No user logged in');
    }
  }
}
