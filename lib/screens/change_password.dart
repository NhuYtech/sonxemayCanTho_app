// lib/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:sonxemaycantho/screens/usermapping.dart'; // Đảm bảo file này tồn tại
import 'package:sonxemaycantho/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Vẫn cần để bắt FirebaseAuthException

class ChangePasswordScreen extends StatefulWidget {
  final String role; // Stores the role parameter

  const ChangePasswordScreen({super.key, required this.role}); // Constructor

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Controllers for current, new, and confirm new password fields
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService(); // Initialize AuthService

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    // Call _testMapping when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testMapping();
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  // Handles the password change process
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    // Check if new password and confirmation match
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      _showSnackBar(
        'Mật khẩu mới và xác nhận mật khẩu không khớp.',
        Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call updateUserPassword with NAMED ARGUMENTS as defined in AuthService
      await _authService.updateUserPassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (mounted) {
        _showSnackBar(
          'Mật khẩu của bạn đã được thay đổi thành công!',
          Colors.green,
        );
        // Clear fields after successful password change
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
        // Optionally pop the screen after successful change to return to the previous screen
        // Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      // Catch specific Firebase Auth errors
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'wrong-password':
          case 'invalid-credential':
            errorMessage = 'Mật khẩu hiện tại không đúng.';
            break;
          case 'requires-recent-login':
            errorMessage =
                'Vui lòng đăng nhập lại để thay đổi mật khẩu (phiên đăng nhập đã hết hạn).';
            break;
          case 'weak-password':
            errorMessage = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
            break;
          case 'user-not-found':
            errorMessage = 'Không tìm thấy người dùng. Vui lòng đăng nhập lại.';
            break;
          case 'too-many-requests':
            errorMessage = 'Quá nhiều lần thử. Vui lòng thử lại sau.';
            break;
          default:
            errorMessage = 'Lỗi khi đổi mật khẩu: ${e.message}';
        }
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      // Catch other errors (e.g., from Firestore or general AuthService errors)
      if (mounted) {
        // Try to get error message from Exception
        String errorMessage = e.toString().contains('Exception:')
            ? e.toString().split(':').last.trim()
            : e.toString();
        _showSnackBar('Đã xảy ra lỗi: $errorMessage', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Utility function to show a SnackBar
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Reusable widget to create password input fields
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: toggleVisibility,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFC1473B), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: validator,
        ),
      ],
    );
  }

  // _testMapping method (re-added as per previous user code)
  Future<void> _testMapping() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Assuming UserMapping.getUserMapping is a method to check mapping
        // You need to ensure UserMapping class and this method exist and work correctly
        // Example: await UserMapping.getUserMapping(currentUser.uid); // Replace with actual check logic
        _showSnackBar('✅ Mapping hoạt động tốt!', Colors.green);
      } else {
        _showSnackBar('❌ Không tìm thấy user đăng nhập.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Không tìm thấy mapping: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
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

                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Mật khẩu hiện tại',
                  obscureText: !_showCurrentPassword,
                  toggleVisibility: () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu hiện tại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'Mật khẩu mới',
                  hintText: 'Tối thiểu 6 ký tự',
                  obscureText: !_showNewPassword,
                  toggleVisibility: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu mới';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    if (value == _currentPasswordController.text) {
                      return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildPasswordField(
                  controller: _confirmNewPasswordController,
                  label: 'Xác nhận mật khẩu mới',
                  obscureText: !_showConfirmPassword,
                  toggleVisibility: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
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

                const SizedBox(height: 20),

                // Security tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Lời khuyên bảo mật:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Sử dụng mật khẩu mạnh với ít nhất 8 ký tự\n'
                        '• Kết hợp chữ hoa, chữ thường, số và ký tự đặc biệt\n'
                        '• Không sử dụng thông tin cá nhân dễ đoán\n'
                        '• Thay đổi mật khẩu định kỳ',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Debug button to create mapping (retained as per previous user code)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Placeholder for UserMapping.createUserMapping
                      // You need to ensure UserMapping class and this method exist
                      // or replace with your actual mapping creation logic.
                      // Example: await UserMapping.createUserMapping(username: 'admin01', accountId: 'admin01');
                      _showSnackBar(
                        '✅ Đã tạo mapping thành công (Debug)!',
                        Colors.green,
                      );
                      // Retest mapping after creation
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _testMapping();
                      });
                    } catch (e) {
                      _showSnackBar(
                        '❌ Lỗi tạo mapping (Debug): $e',
                        Colors.red,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Debug: Tạo User Mapping',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
