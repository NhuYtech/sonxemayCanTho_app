import 'package:flutter/material.dart';
import 'customer/customer_home.dart';
import 'staff/staff_home.dart';
import 'manager/manager_home.dart';
import '../services/account_service.dart';

class LoginStaff extends StatefulWidget {
  const LoginStaff({super.key});

  @override
  State<LoginStaff> createState() => _LoginStaffState();
}

class _LoginStaffState extends State<LoginStaff> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AccountService _accountService = AccountService();

  bool _isLoading = false;

  Future<void> _handleLoginWithAccount() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showErrorDialog('Vui lòng nhập đầy đủ số điện thoại và mật khẩu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await _accountService.login(
        phoneNumber: phone,
        password: password,
      );

      if (userData != null) {
        final role = userData['role'];
        final name = userData['fullName'];

        Widget nextScreen;
        if (role == 'manager') {
          nextScreen = ManagerHome(name: name);
        } else if (role == 'staff') {
          nextScreen = StaffHome(name: name);
        } else {
          nextScreen = CustomerHome(name: name);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      } else {
        _showErrorDialog(
          'Tài khoản không tồn tại, không hoạt động hoặc sai thông tin.',
        );
      }
    } catch (e) {
      _showErrorDialog('Đăng nhập thất bại: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Đóng'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Đăng nhập',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLoginWithAccount,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đăng nhập'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
