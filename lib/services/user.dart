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
      rethrow; // Ném lại lỗi để caller xử lý
    }
  }

  /// Lấy vai trò (role) của người dùng hiện tại đã đăng nhập.
  /// Trả về vai trò dưới dạng String, mặc định là 'customer' nếu không tìm thấy hoặc có lỗi.
  Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'customer'; // Mặc định là customer nếu không có người dùng đăng nhập
    }

    try {
      final userData = await getUserData(user.uid);
      if (userData.exists && userData.data() != null) {
        final data = userData.data() as Map<String, dynamic>;
        return data['role'] as String? ??
            'customer'; // Lấy role, nếu null thì mặc định là 'customer'
      } else {
        return 'customer'; // Mặc định là customer nếu document không tồn tại
      }
    } catch (e) {
      return 'customer'; // Mặc định là customer nếu có lỗi trong quá trình lấy dữ liệu
    }
  }

  /// Cập nhật vai trò (role) của một user trong Firestore.
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
    } catch (e) {
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
      } catch (e) {
        // Vẫn tiếp tục cập nhật Firestore dù Auth update có lỗi
      }
    }

    if (phoneNumber != null) {
      updates['phoneNumber'] = phoneNumber;
    }

    if (updates.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(uid).update(updates);
      } catch (e) {
        rethrow;
      }
    } else {}
  }

  Future<Map<String, dynamic>?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return doc.data() as Map<String, dynamic>;
      // ignore: empty_catches
    } catch (e) {}
    return null;
  }
}
