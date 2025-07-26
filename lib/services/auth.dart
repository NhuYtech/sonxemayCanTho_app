// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Khởi tạo Firestore instance

  /// 🔄 Lắng nghe thay đổi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// ✅ Đăng ký bằng email và mật khẩu
  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        // Ghi vai trò mặc định 'manager' hoặc 'staff' khi đăng ký bằng email/password
        await _checkAndSetUserRole(
          user,
          'manager',
        ); // Hoặc 'staff' tùy logic của bạn
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Error registering with email and password: ${e.message}');
      // Bạn có thể ném lại lỗi hoặc trả về null tùy thuộc vào cách bạn muốn xử lý lỗi ở UI.
      // rethrow; // Nếu bạn muốn ném lại lỗi để UI xử lý
      return null;
    }
  }

  /// 🔐 Đăng nhập bằng email và mật khẩu
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        // Kiểm tra và cập nhật vai trò sau khi đăng nhập thành công
        await _checkAndSetUserRole(
          user,
          'manager',
        ); // Vai trò mặc định cho phương thức này
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Error signing in with email and password: ${e.message}');
      // rethrow;
      return null;
    }
  }

  /// 🔐 Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Người dùng hủy đăng nhập

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      if (user != null) {
        // Gán vai trò 'customer' cho người dùng đăng nhập bằng Google
        await _checkAndSetUserRole(user, 'customer');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Error signing in with Google: ${e.message}');
      // rethrow;
      return null;
    } catch (e) {
      print('Unknown error during Google Sign-In: $e');
      // rethrow;
      return null;
    }
  }

  /// 🚪 Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Đổi mật khẩu cho user hiện tại (chỉ dành cho manager)
  Future<void> updateUserPassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Không tìm thấy người dùng đăng nhập');

      // Lấy thông tin user từ Firestore để kiểm tra role
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists)
        throw Exception('Không tìm thấy thông tin người dùng');

      final userData = userDoc.data() as Map<String, dynamic>;
      if (userData['role'] != 'manager') {
        throw Exception('Chỉ quản trị viên mới có quyền đổi mật khẩu');
      }

      // Xác thực lại với mật khẩu hiện tại
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Đổi mật khẩu
      await user.updatePassword(newPassword);
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
  }

  /// 👤 Lấy người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  // --- Hàm hỗ trợ: Kiểm tra và lưu vai trò người dùng vào Firestore ---
  Future<void> _checkAndSetUserRole(User user, String defaultRole) async {
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      // Nếu người dùng chưa có trong Firestore, tạo mới và gán vai trò
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName':
            user.displayName ?? user.email?.split('@')[0] ?? 'Người dùng mới',
        'role': defaultRole,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('New user ${user.uid} created with role: $defaultRole');
    } else {
      // Nếu người dùng đã tồn tại, bạn có thể kiểm tra và cập nhật thông tin nếu cần.
      // Ví dụ: đảm bảo displayName được cập nhật từ Google Sign-In nếu nó thay đổi.
      // Hoặc, nếu vai trò đã được thiết lập, bạn có thể không cần ghi đè.
      // Tuy nhiên, để đơn giản, chúng ta sẽ chỉ in ra log.
      print(
        'User ${user.uid} already exists with role: ${userDoc.get('role')}',
      );
    }
  }
}
