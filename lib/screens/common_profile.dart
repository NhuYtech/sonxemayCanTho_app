import 'package:flutter/material.dart';
import 'role_selection.dart';

class CommonProfile extends StatelessWidget {
  final String name;
  final String role;

  const CommonProfile({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1473B),
      body: SafeArea(
        child: Column(
          children: [
            // Phần trên có logo + tên vai trò + chuông
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFC1473B),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage('assets/logo/logo1.png'),
                    radius: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const Icon(Icons.notifications, color: Colors.yellow),
                ],
              ),
            ),

            // Danh sách chức năng
            Expanded(
              child: Container(
                color: Colors.grey.shade200,
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    _buildTile(Icons.person, 'Xem thông tin', () {}),
                    _buildTile(Icons.edit, 'Chỉnh sửa thông tin', () {}),
                    if (role !=
                        'customer') // ✅ chỉ staff/manager mới có ghi chú
                      _buildTile(Icons.feedback, 'Ghi chú và phản hồi', () {}),
                    _buildTile(Icons.lock, 'Đổi mật khẩu', () {}),
                    _buildTile(Icons.logout, 'Đăng xuất', () {
                      _showLogoutDialog(context);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: const Color(0xFFD34C45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận đăng xuất'),
      content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const RoleSelection()),
              (route) => false,
            );
          },
          child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
