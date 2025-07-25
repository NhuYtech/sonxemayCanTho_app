import 'package:flutter/material.dart';
import 'package:sonxemaycantho/screens/login_Internal_User.dart';
import 'login.dart';

class RoleSelection extends StatelessWidget {
  const RoleSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1473B),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo/logo1.png', width: 180),
            const SizedBox(height: 20),
            const Text(
              'Xin chào,\nSơn Xe Máy Cần Thơ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vui lòng chọn tuỳ chọn để tiếp tục',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 30),

            _buildRoleButton(context, 'Quản lý'),
            _buildRoleButton(context, 'Nhân viên'),
            _buildRoleButton(context, 'Khách hàng'),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          if (role == 'Khách hàng') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            );
          } else if (role == 'Nhân viên') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginInternalUser()),
            );
          } else if (role == 'Quản lý') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginInternalUser()),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, color: Colors.black),
            const SizedBox(width: 10),
            Text(
              role,
              style: const TextStyle(color: Colors.black, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
