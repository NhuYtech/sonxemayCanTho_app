import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;

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
              // Logo
              Center(child: Image.asset('assets/logo/logo1.png', width: 150)),
              const SizedBox(height: 20),

              // Tên app
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

              // Họ và tên
              const Text('Họ và tên:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 5),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Nhập họ tên',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Mật khẩu
              const Text('Mật khẩu:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 5),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Nhập mật khẩu',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Nút Đăng nhập
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text;
                  final password = passwordController.text;

                  if (name.isEmpty || password.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('LỖI'),
                        content: const Text('Vui lòng nhập đầy đủ thông tin.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Đóng'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    print('Đăng nhập với: $name - $password');
                    // TODO: chuyển sang màn chính tuỳ vai trò
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
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
                  // TODO: điều hướng tới màn đăng ký
                },
                child: const Text(
                  'Đăng ký',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Color.fromARGB(255, 0, 0, 0),
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
}
