import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class AccountService {
  final CollectionReference _accountCollection = FirebaseFirestore.instance
      .collection('accounts');

  // 🔐 Đăng ký tài khoản nhân viên
  Future<void> registerUser({
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    await _accountCollection.add({
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'password': hashedPassword,
      'role': 'staff',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔐 Đăng nhập
  Future<Map<String, dynamic>?> login({
    required String phoneNumber,
    required String password,
  }) async {
    final query = await _accountCollection
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final user = doc.data() as Map<String, dynamic>;

    // 👉 Kiểm tra trạng thái hoạt động
    if (user['isActive'] == false) return null;

    // 👉 Kiểm tra mật khẩu
    final hashedPassword = user['password'];
    final isMatch = BCrypt.checkpw(password, hashedPassword);
    if (!isMatch) return null;

    // 👉 Trả về user kèm ID
    return {'id': doc.id, ...user};
  }

  Future<Map<String, dynamic>?> getAccountById(String uid) async {
    try {
      final doc = await _accountCollection.doc(uid).get();
      if (doc.exists) return doc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error getting account by UID $uid: $e');
    }
    return null;
  }
}
