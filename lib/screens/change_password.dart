// lib/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:sonxemaycantho/services/auth.dart'; // Ensure this import is correct
import 'package:firebase_auth/firebase_auth.dart'; // Import if using Firebase Auth exceptions

class ChangePasswordScreen extends StatefulWidget {
  final String role; // Thêm tham số role

  const ChangePasswordScreen({super.key, required this.role});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      // Check if new password and confirm new password match
      if (_newPasswordController.text != _confirmNewPasswordController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mật khẩu mới và xác nhận mật khẩu không khớp.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await AuthService().updateUserPassword(
          _currentPasswordController.text,
          _newPasswordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mật khẩu của bạn đã được thay đổi thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Go back after success
        }
      } on FirebaseAuthException catch (e) {
        // Catch Firebase specific exceptions
        if (mounted) {
          String errorMessage;
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            errorMessage = 'Mật khẩu hiện tại không đúng.';
          } else if (e.code == 'requires-recent-login') {
            errorMessage =
                'Vui lòng đăng nhập lại để thay đổi mật khẩu (phiên đăng nhập đã hết hạn).';
          } else if (e.code == 'weak-password') {
            errorMessage = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
          } else if (e.code == 'user-not-found') {
            // Should not happen if user is logged in
            errorMessage = 'Không tìm thấy người dùng. Vui lòng đăng nhập lại.';
          } else {
            errorMessage = 'Lỗi khi đổi mật khẩu: ${e.message}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        // Catch any other general exceptions
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã xảy ra lỗi: ${e.toString().split(':').last.trim()}',
              ), // Generic error message
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra nếu không phải manager thì hiển thị thông báo
    if (widget.role != 'manager') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đổi mật khẩu'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(
          child: Text(
            'Bạn không có quyền thay đổi mật khẩu.\nVui lòng liên hệ quản trị viên.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // Nếu là manager thì hiển thị form đổi mật khẩu
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Để thay đổi mật khẩu, vui lòng nhập mật khẩu hiện tại và mật khẩu mới của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 30),

                const Text(
                  'Mật khẩu hiện tại',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFC1473B),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu hiện tại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Mật khẩu mới',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Tối thiểu 8 ký tự',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFC1473B),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Xác nhận mật khẩu mới',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmNewPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFFC1473B),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu mới';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFC1473B),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC1473B),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Đổi mật khẩu',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
