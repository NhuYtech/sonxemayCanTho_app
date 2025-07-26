import 'package:flutter/material.dart';
import 'package:sonxemaycantho/screens/view_profile.dart';
import 'package:sonxemaycantho/services/auth.dart';
import 'package:sonxemaycantho/screens/role.dart';
// XÓA DÒNG NÀY: Vì Header đã được cung cấp bởi AppBar của ManagerHome
// import 'package:sonxemaycantho/widgets/header.dart';
import 'package:sonxemaycantho/screens/change_password.dart'; // Import màn hình đổi mật khẩu

class Profile extends StatelessWidget {
  final String name;
  final String role; // The role is still needed for the feedback tile condition

  const Profile({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    // XÓA WIDGET SCAFFOLD NÀY:
    // Màn hình này sẽ được đặt trong body của Scaffold khác (ManagerHome),
    // nên không cần Scaffold riêng để tránh trùng lặp AppBar.
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // XÓA DÒNG NÀY: Header đã có ở ManagerHome
            // Header(name: name),
            const SizedBox(height: 20), // Khoảng cách bên dưới Header (nếu có)

            ListView(
              physics:
                  const NeverScrollableScrollPhysics(), // Vẫn cần cho ListView bên trong
              shrinkWrap: true, // Vẫn cần cho ListView bên trong
              padding: EdgeInsets.zero, // Loại bỏ padding từ chính ListView
              children: [
                _buildTile(Icons.person, 'Xem thông tin', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ViewProfileScreen(),
                    ),
                  );
                }),
                // if (role != 'customer')
                //   _buildTile(Icons.feedback, 'Ghi chú và phản hồi', () {
                //     // TODO: Chuyển đến màn hình Phản hồi
                //     print('Ghi chú và phản hồi tapped!');
                //   }),
                if (role == 'manager') // Chỉ hiển thị cho manager
                  _buildTile(Icons.lock, 'Đổi mật khẩu', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangePasswordScreen(role: role),
                      ),
                    );
                  }),
                _buildTile(Icons.logout, 'Đăng xuất', () {
                  _showLogoutDialog(context);
                }),
              ],
            ),
            const SizedBox(height: 20), // Tùy chọn: Thêm một ít padding ở cuối
          ],
        ),
      ),
    );
  }

  /// Phương thức trợ giúp để xây dựng một ô tùy chọn cho hồ sơ, với kiểu dáng giống OrderContent.
  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
        left: 16,
        right: 16,
      ), // Tăng margin dưới, giữ nguyên margin ngang
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 144, 220, 255), // Giữ màu xanh nhạt
        borderRadius: BorderRadius.circular(15), // Bo tròn góc hơn một chút
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3), // Bóng mạnh hơn một chút
            spreadRadius: 1.5, // Tăng độ lan
            blurRadius: 5, // Tăng độ mờ
            offset: const Offset(0, 3), // Offset thấp hơn một chút
          ),
        ],
      ),
      child: Material(
        // Bọc với Material để có hiệu ứng splash của InkWell
        color: Colors
            .transparent, // Làm cho Material trong suốt để hiển thị màu của Container
        borderRadius: BorderRadius.circular(
          15,
        ), // Khớp với border radius của Container
        child: InkWell(
          borderRadius: BorderRadius.circular(
            15,
          ), // Khớp với border radius của Material cho hiệu ứng splash
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 20.0,
            ), // Nhiều padding hơn bên trong ô
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: Colors.black,
                ), // Icon lớn hơn, giữ màu đen
                const SizedBox(
                  width: 20,
                ), // Khoảng cách lớn hơn giữa icon và văn bản
                Expanded(
                  // Sử dụng Expanded để đảm bảo văn bản không bị tràn
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600, // Hơi đậm hơn bold
                      fontSize:
                          18, // Kích thước font lớn hơn một chút cho tiêu đề
                      color: Colors.black87, // Giữ màu đen87 cho văn bản
                    ),
                  ),
                ),
                // const Icon(
                //   Icons.arrow_forward_ios,
                //   size: 22, // Icon mũi tên lớn hơn một chút
                //   color: Colors.grey, // Giữ màu xám cho mũi tên
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hiển thị hộp thoại xác nhận đăng xuất.
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
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleSelection()),
                  (route) => false,
                );
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
