import 'package:flutter/material.dart';
import '../customer/customer_home.dart';
import '../manager/manager_home.dart';
import '../staff/staff_home.dart';
import 'register.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Login extends StatefulWidget {
  final String role;

  const Login({super.key, required this.role});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thông báo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _navigateToHome(String role, String fullName) {
    Widget destination;

    switch (role.toLowerCase()) {
      case 'quản lý':
      case 'manager':
        destination = ManagerHome(name: fullName);
        break;
      case 'nhân viên':
      case 'staff':
        destination = StaffHome(name: fullName);
        break;
      case 'khách hàng':
      case 'customer':
      default:
        destination = CustomerHome(name: fullName);
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  String _convertRoleToEnglish(String vietnameseRole) {
    switch (vietnameseRole.toLowerCase()) {
      case 'quản lý':
        return 'manager';
      case 'nhân viên':
        return 'staff';
      case 'khách hàng':
        return 'customer';
      default:
        return 'customer';
    }
  }

  String _convertRoleToVietnamese(String englishRole) {
    switch (englishRole.toLowerCase()) {
      case 'manager':
        return 'Quản lý';
      case 'staff':
        return 'Nhân viên';
      case 'customer':
        return 'Khách hàng';
      default:
        return 'Khách hàng';
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (result != null) {
        final String fullName = result['fullName'] ?? 'Người dùng';
        final String uid = result['uid'];
        final String email = result['email'];

        // Kiểm tra user trong Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        String selectedRoleEnglish = _convertRoleToEnglish(widget.role);

        if (doc.exists) {
          // ✅ USER ĐÃ TỒN TẠI - KIỂM TRA ROLE THỰC TẾ
          final userData = doc.data() as Map<String, dynamic>;
          String actualRole = userData['role'] ?? 'customer';
          bool isActive = userData['isActive'] ?? true;

          // Kiểm tra tài khoản có bị vô hiệu hóa không
          if (!isActive) {
            _showErrorDialog(
              'Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ quản trị viên.',
            );
            return;
          }

          // ⚠️ KIỂM TRA ROLE CÓ KHỚP KHÔNG
          if (actualRole.toLowerCase() != selectedRoleEnglish.toLowerCase()) {
            _showErrorDialog(
              'Tài khoản của bạn là "${_convertRoleToVietnamese(actualRole)}", không phải "${widget.role}".\n\n'
              'Vui lòng chọn đúng vai trò của bạn để đăng nhập.',
            );
            return;
          }

          // ✅ ROLE KHỚP - CHO PHÉP ĐĂNG NHẬP
          _navigateToHome(actualRole, fullName);
        } else {
          // ✅ USER MỚI - CHỈ CHO PHÉP TẠO TÀI KHOẢN CUSTOMER
          if (selectedRoleEnglish != 'customer') {
            _showErrorDialog(
              'Tài khoản ${widget.role} phải được tạo bởi quản trị viên.\n\n'
              'Nếu bạn là khách hàng mới, vui lòng chọn "Khách hàng" để đăng ký.',
            );
            return;
          }

          // Tạo tài khoản customer mới
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'fullName': fullName,
            'emailAlias': email,
            'role': 'customer',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });

          _navigateToHome('customer', fullName);
        }
      } else {
        _showErrorDialog('Đăng nhập Google không thành công hoặc đã bị hủy.');
      }
    } catch (e) {
      _showErrorDialog('Đăng nhập Google thất bại: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1473B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo/logo1.png', width: 150),
                const SizedBox(height: 20),
                const Text(
                  'Sơn Xe Máy Cần Thơ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),

                // Hiển thị role được chọn
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    // ignore: deprecated_member_use
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoleIcon(widget.role),
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đăng nhập với vai trò: ${widget.role}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Nút Đăng nhập bằng Google
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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
                    _isLoading ? 'Đang đăng nhập...' : 'Đăng nhập bằng Google',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Chỉ hiển thị đăng ký cho khách hàng
                if (widget.role.toLowerCase() == 'khách hàng') ...[
                  const Text(
                    'Nếu bạn chưa có tài khoản khách hàng\nVui lòng Đăng ký để tiếp tục',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Register()),
                      );
                    },
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Nếu bạn chưa có tài khoản \nVui lòng liên hệ quản trị viên',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],

                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Quay lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'quản lý':
        return Icons.admin_panel_settings;
      case 'nhân viên':
        return Icons.work;
      case 'khách hàng':
        return Icons.person;
      default:
        return Icons.person;
    }
  }
}
