import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Phương thức `createUser` đã được loại bỏ vì logic này được xử lý trong AuthService._checkAndSetUserRole
  // khi người dùng đăng ký hoặc đăng nhập lần đầu.

  /// Lấy thông tin user từ Firestore dựa trên UID.
  /// Trả về [DocumentSnapshot] chứa dữ liệu user.
  Future<DocumentSnapshot> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      print('Error getting user data for UID $uid: $e');
      rethrow; // Ném lại lỗi để caller xử lý
    }
  }

  /// Lấy vai trò (role) của người dùng hiện tại đã đăng nhập.
  /// Trả về vai trò dưới dạng String, mặc định là 'customer' nếu không tìm thấy hoặc có lỗi.
  Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('No user is currently signed in. Defaulting role to "customer".');
      return 'customer'; // Mặc định là customer nếu không có người dùng đăng nhập
    }

    try {
      final userData = await getUserData(user.uid);
      if (userData.exists && userData.data() != null) {
        final data = userData.data() as Map<String, dynamic>;
        return data['role'] as String? ??
            'customer'; // Lấy role, nếu null thì mặc định là 'customer'
      } else {
        print(
          'User document for ${user.uid} does not exist. Defaulting role to "customer".',
        );
        return 'customer'; // Mặc định là customer nếu document không tồn tại
      }
    } catch (e) {
      print('Error getting current user role: $e');
      return 'customer'; // Mặc định là customer nếu có lỗi trong quá trình lấy dữ liệu
    }
  }

  /// Cập nhật vai trò (role) của một user trong Firestore.
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
      print('User $uid role updated to $newRole');
    } catch (e) {
      print('Error updating user $uid role to $newRole: $e');
      rethrow;
    }
  }

  /// Cập nhật thông tin profile của user trong Firestore và Firebase Authentication.
  /// [displayName] và [phoneNumber] là tùy chọn.
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
  }) async {
    final Map<String, dynamic> updates = {};

    if (displayName != null) {
      updates['displayName'] = displayName;
      // Cập nhật displayName trong Firebase Authentication
      try {
        await _auth.currentUser?.updateDisplayName(displayName);
        print('Firebase Auth displayName updated for $uid');
      } catch (e) {
        print('Error updating Firebase Auth displayName for $uid: $e');
        // Vẫn tiếp tục cập nhật Firestore dù Auth update có lỗi
      }
    }

    if (phoneNumber != null) {
      updates['phoneNumber'] = phoneNumber;
    }

    if (updates.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(uid).update(updates);
        print('Firestore profile updated for $uid: $updates');
      } catch (e) {
        print('Error updating Firestore profile for $uid: $e');
        rethrow;
      }
    } else {
      print('No updates provided for user $uid profile.');
    }
  }
}
