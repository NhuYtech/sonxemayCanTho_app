import 'package:flutter/material.dart';
import 'manager/manager_home.dart';
import 'staff/staff_home.dart';
import 'customer/customer_home.dart';
import 'register.dart';
import '../services/auth_service.dart'; // Đảm bảo import đúng AuthService
// import '../services/user.dart'; // KHÔNG CẦN NỮA

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneNumberController =
      TextEditingController(); // Dùng cho SĐT của NV/QL
  final TextEditingController _passwordController =
      TextEditingController(); // Dùng cho mật khẩu của NV/QL

  bool _isLoading = false; // Dùng chung cho cả hai loại đăng nhập

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  void _navigateToHomeScreen({
    required String userType,
    String? role, // role chỉ có cho staff_manager
    required String fullName,
  }) {
    Widget nextScreen;
    if (userType == 'staff_manager') {
      if (role == 'manager') {
        nextScreen = ManagerHome(name: fullName);
      } else if (role == 'staff') {
        nextScreen = StaffHome(name: fullName);
      } else {
        _showErrorDialog('Vai trò của nhân viên/quản lý không xác định.');
        return;
      }
    } else if (userType == 'customer') {
      nextScreen = CustomerHome(name: fullName);
    } else {
      _showErrorDialog('Loại người dùng không xác định.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  // Xử lý đăng nhập bằng SĐT và Mật khẩu (dành cho Nhân viên/Quản lý)
  Future<void> _handleStaffManagerSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInWithPhoneNumberAndStaticPassword(
        phoneNumber: _phoneNumberController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result != null) {
        final String userType = result['type'];
        final String role = result['role'];
        final String fullName = result['fullName'] ?? 'Người dùng';
        _navigateToHomeScreen(
          userType: userType,
          role: role,
          fullName: fullName,
        );
      } else {
        _showErrorDialog('Đăng nhập nhân viên/quản lý không thành công.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Đăng nhập nhân viên/quản lý thất bại: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Xử lý đăng nhập bằng Google (dành cho Khách hàng)
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (result != null) {
        final String userType = result['type'];
        final String fullName = result['fullName'] ?? 'Người dùng';
        _navigateToHomeScreen(userType: userType, fullName: fullName);
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
                Image.asset('assets/logo/logo1.png', width: 180),
                const SizedBox(height: 30),

                const Text(
                  'Sơn Xe Máy\nCần Thơ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 50),

                // --- Phần đăng nhập cho Nhân viên/Quản lý (SĐT + Mật khẩu) ---
                TextField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone, // Dùng keyboard type phone
                  decoration: InputDecoration(
                    hintText: 'Số điện thoại (Nhân viên/Quản lý)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleStaffManagerSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFC1473B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFC1473B),
                          ),
                        )
                      : const Text(
                          'Đăng nhập (Nhân viên/Quản lý)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                // --- Kết thúc phần đăng nhập SĐT + Mật khẩu ---
                const SizedBox(height: 30),

                const Text(
                  'Hoặc',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),

                // Nút Đăng nhập bằng Google (dành cho Khách hàng)
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
                    _isLoading
                        ? 'Đang đăng nhập...'
                        : 'Đăng nhập bằng Google (Khách hàng)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Theo yêu cầu "nếu không có tài khoản thì không dùng được hệ thống"
                // và "tài khoản của nhân viên là do quản lý cấp",
                // nút Đăng ký này chỉ nên dành cho Khách hàng mới (đăng ký qua Google).
                // Nếu bạn muốn có màn hình đăng ký cho Nhân viên (do quản lý cấp),
                // bạn cần tạo một luồng riêng biệt cho quản lý để tạo tài khoản.
                // Hiện tại, nút "Đăng ký" này sẽ dẫn đến màn hình Register mà bạn đã có.
                // Nếu màn hình Register đó chỉ dành cho khách hàng Google, thì nó phù hợp.
                // Nếu nó có cả đăng ký SĐT, bạn cần cân nhắc lại luồng này.
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

                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
