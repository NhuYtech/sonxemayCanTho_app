import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1473B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo
              Image.asset('assets/logo/logo1.png', width: 200),
              const SizedBox(height: 40),

              // Title
              const Text(
                'Chào mừng đến với\nSơn Xe Máy Cần Thơ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Đăng ký tài khoản để trải nghiệm dịch vụ tốt nhất',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 60),

              // Google Sign In Button
              _buildGoogleSignInButton(),

              const Spacer(),

              // Back button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Quay lại',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: const Size(double.infinity, 50),
      ),
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.red,
              ),
            )
          : Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://developers.google.com/identity/images/g-logo.png',
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
      label: Text(
        _isLoading ? 'Đang đăng ký...' : 'Đăng ký bằng Google',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Đăng xuất tài khoản Google hiện tại (nếu có) để cho phép chọn tài khoản
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // Check if this is a new user or existing user
        final bool isNewUser =
            userCredential.additionalUserInfo?.isNewUser ?? false;

        // Save or update user data to Firestore
        await _saveUserToFirestore(user, isNewUser);

        if (isNewUser) {
          _showDialog(
            "Đăng ký thành công!",
            "Chào mừng ${user.displayName ?? 'bạn'} đến với Sơn Xe Máy Cần Thơ!",
            isSuccess: true,
          );
        } else {
          _showDialog(
            "Đăng nhập thành công!",
            "Chào mừng bạn quay lại!",
            isSuccess: true,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Đăng ký thất bại!";
      String details = "";

      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = "Tài khoản đã tồn tại";
          details = "Email này đã được đăng ký bằng phương thức khác.";
          break;
        case 'invalid-credential':
          message = "Thông tin xác thực không hợp lệ";
          details = "Vui lòng thử lại.";
          break;
        case 'operation-not-allowed':
          message = "Đăng nhập Google chưa được kích hoạt";
          details = "Vui lòng liên hệ quản trị viên.";
          break;
        case 'user-disabled':
          message = "Tài khoản đã bị khóa";
          details = "Vui lòng liên hệ hỗ trợ.";
          break;
        default:
          details = e.message ?? "Vui lòng thử lại sau.";
      }

      _showDialog(message, details);
    } catch (error) {
      print('Error during Google Sign In: $error');
      _showDialog(
        "Lỗi kết nối",
        "Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.",
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserToFirestore(User user, bool isNewUser) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      if (isNewUser) {
        // New user - create document
        await userDoc.set({
          'uid': user.uid,
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'phone': '', // User có thể cập nhật sau
          'photoURL': user.photoURL ?? '',
          'role': 'customer', // Mặc định là customer
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'loginMethod': 'google',
        });
      } else {
        // Existing user - update last login time
        await userDoc.update({'lastLoginAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
    }
  }

  void _showDialog(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSuccess ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (isSuccess) {
                Navigator.pop(context); // Go back to previous screen
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: isSuccess
                  ? Colors.green
                  : const Color(0xFFC1473B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "OK",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
