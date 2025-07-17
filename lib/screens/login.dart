import 'package:flutter/material.dart';
import 'manager_home.dart';
import 'staff_home.dart';
import 'customer_home.dart';
import 'register.dart';
import '../service/api_login.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final name = nameController.text.trim();
      final phone = phoneNumberController.text.trim();
      final password = passwordController.text.trim();

      final result = await ApiService.login(phone, password);

      if (result['status'] == 200) {
        final data = result['data'];
        final role = data['role'];

        if (role == 'manager') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ManagerHome(name: name)),
          );
        } else if (role == 'staff') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StaffHome(name: name)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => CustomerHome(name: name)),
          );
        }
      } else {
        _showErrorDialog(
          result['data']['message'] ?? "Sai tài khoản hoặc mật khẩu",
        );
      }
    } catch (e) {
      _showErrorDialog("Lỗi kết nối máy chủ.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1473B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Center(child: Image.asset('assets/logo/logo1.png', width: 150)),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Sơn xe máy\nCần Thơ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      validator: _validateName,
                      decoration: _inputDecoration('Nhập họ và tên').copyWith(
                        labelText: 'Họ và tên',
                        labelStyle: const TextStyle(color: Colors.black),
                      ),
                      keyboardType: TextInputType.text,
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: phoneNumberController,
                      validator: _validatePhone,
                      decoration: _inputDecoration('Nhập số điện thoại')
                          .copyWith(
                            labelText: 'Số điện thoại',
                            labelStyle: const TextStyle(color: Colors.black),
                          ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      decoration: _inputDecoration('Nhập mật khẩu').copyWith(
                        labelText: 'Mật khẩu',
                        labelStyle: const TextStyle(color: Colors.black),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(() {
                            _obscurePassword = !_obscurePassword;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Đăng nhập',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.white, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('hoặc', style: TextStyle(color: Colors.white)),
                  ),
                  Expanded(child: Divider(color: Colors.white, thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Nếu bạn chưa có tài khoản\nVui lòng Đăng ký để tiếp tục',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
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
                    decoration: TextDecoration.underline,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final phoneRegex = RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.length < 2) {
      return 'Họ và tên phải từ 2 ký tự trở lên';
    }
    return null;
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
