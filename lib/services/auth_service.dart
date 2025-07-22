import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 🔄 Lắng nghe thay đổi đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 🔐 Đăng ký bằng email & password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.updateDisplayName(displayName);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'Mật khẩu quá yếu';
      } else if (e.code == 'email-already-in-use') {
        throw 'Email này đã được sử dụng';
      } else if (e.code == 'invalid-email') {
        throw 'Email không hợp lệ';
      }
      throw e.message ?? 'Đã có lỗi xảy ra';
    }
  }

  // 🔑 Đăng nhập bằng email & password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'Không tìm thấy tài khoản với email này';
      } else if (e.code == 'wrong-password') {
        throw 'Sai mật khẩu';
      } else if (e.code == 'invalid-email') {
        throw 'Email không hợp lệ';
      } else if (e.code == 'user-disabled') {
        throw 'Tài khoản đã bị vô hiệu hóa';
      }
      throw e.message ?? 'Đã có lỗi xảy ra';
    }
  }

  // 🚪 Đăng xuất (bao gồm cả Google nếu có)
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut(); // Đăng xuất khỏi tài khoản Google luôn
  }

  // 👤 Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // 🔑 Đổi mật khẩu
  Future<void> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'Mật khẩu mới quá yếu';
      }
      throw e.message ?? 'Đã có lỗi xảy ra khi đổi mật khẩu';
    }
  }

  // 📧 Quên mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'Không tìm thấy tài khoản với email này';
      }
      throw e.message ?? 'Đã có lỗi xảy ra';
    }
  }

  // ✅ Đăng nhập với Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User huỷ đăng nhập

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Đăng nhập Google thất bại';
    } catch (e) {
      throw 'Đăng nhập Google thất bại: $e';
    }
  }
}
