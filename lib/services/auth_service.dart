import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔄 Lắng nghe trạng thái đăng nhập
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

      // 🔄 Thêm user vào Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': displayName,
        'phone': '',
        'photoURL': '',
        'role': 'customer',
        'loginMethod': 'email',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') throw 'Mật khẩu quá yếu';
      if (e.code == 'email-already-in-use') throw 'Email đã được sử dụng';
      if (e.code == 'invalid-email') throw 'Email không hợp lệ';
      throw e.message ?? 'Đã có lỗi xảy ra';
    }
  }

  // 🔑 Đăng nhập bằng email & password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔄 Cập nhật thời gian đăng nhập gần nhất
      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {'lastLoginAt': FieldValue.serverTimestamp()},
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found')
        throw 'Không tìm thấy tài khoản với email này';
      if (e.code == 'wrong-password') throw 'Sai mật khẩu';
      if (e.code == 'invalid-email') throw 'Email không hợp lệ';
      if (e.code == 'user-disabled') throw 'Tài khoản đã bị vô hiệu hóa';
      throw e.message ?? 'Đã có lỗi xảy ra';
    }
  }

  // ✅ Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Người dùng huỷ

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final user = userCredential.user!;
      final userDoc = _firestore.collection('users').doc(user.uid);

      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // 🔄 Tạo user mới trong Firestore nếu chưa có
        await userDoc.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? '',
          'phone': user.phoneNumber ?? '',
          'photoURL': user.photoURL ?? '',
          'role': 'customer',
          'loginMethod': 'google',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 🔄 Nếu đã có, chỉ cập nhật thời gian login
        await userDoc.update({'lastLoginAt': FieldValue.serverTimestamp()});
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Đăng nhập Google thất bại';
    } catch (e) {
      throw 'Đăng nhập Google thất bại: $e';
    }
  }

  // 🚪 Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut(); // Đăng xuất khỏi Google luôn
  }

  // 👤 Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // 🔒 Đổi mật khẩu
  Future<void> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') throw 'Mật khẩu mới quá yếu';
      throw e.message ?? 'Đã có lỗi xảy ra khi đổi mật khẩu';
    }
  }

  // 📧 Quên mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found')
        throw 'Không tìm thấy tài khoản với email này';
      throw e.message ?? 'Đã có lỗi xảy ra';
    }
  }
}
