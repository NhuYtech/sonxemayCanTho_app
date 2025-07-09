import 'package:flutter/material.dart';

class ManagerProfile extends StatelessWidget {
  final String fullName;
  const ManagerProfile({super.key, required this.fullName});

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
                      fullName, // ✅ Đổi từ 'Quản lý' thành tên thật
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
                    _buildTile(Icons.feedback, 'Ghi chú và phản hồi', () {}),
                    _buildTile(Icons.lock, 'Đổi mật khẩu', () {}),
                    _buildTile(Icons.logout, 'Đăng xuất', () {
                      // TODO: Đăng xuất
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Navigation bar dưới cùng
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: 3,
      //   type: BottomNavigationBarType.fixed,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
      //     BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Đơn hàng'),
      //     BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'CSKH'),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
      //   ],
      //   onTap: (index) {
      //     // TODO: Điều hướng tương ứng
      //   },
      // ),
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
