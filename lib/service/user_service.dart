import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tạo document user mới trong Firestore
  Future<void> createUser({
    required String uid,
    required String email,
    required String displayName,
    String role = 'customer', // Mặc định là customer
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Lấy thông tin user từ Firestore
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Lấy role của user hiện tại
  Future<String> getCurrentUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await getUserData(user.uid);
        if (userData.exists) {
          return userData.get('role') as String;
        }
      }
      return 'customer'; // Mặc định là customer nếu không tìm thấy
    } catch (e) {
      print('Lỗi khi lấy role: $e');
      return 'customer';
    }
  }

  // Cập nhật role của user
  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
  }

  // Cập nhật thông tin user
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
  }) async {
    final Map<String, dynamic> updates = {};

    if (displayName != null) {
      updates['displayName'] = displayName;
      // Cập nhật displayName trong Authentication
      await _auth.currentUser?.updateDisplayName(displayName);
    }

    if (phoneNumber != null) {
      updates['phoneNumber'] = phoneNumber;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }
}
