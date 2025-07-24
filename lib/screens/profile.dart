import 'package:flutter/material.dart';
import 'package:sonxemaycantho/services/auth.dart'; // Import AuthService
import 'package:sonxemaycantho/screens/role.dart'; // Import RoleSelection
import 'package:sonxemaycantho/widgets/profile_header.dart'; // Import ProfileHeader mới

class CommonProfile extends StatelessWidget {
  final String name;
  final String role;

  const CommonProfile({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the scaffold background to white
      body: SafeArea(
        child: Stack(
          // Use Stack to allow overlapping widgets
          children: [
            Column(
              children: [
                // Sử dụng ProfileHeader widget mới thay vì Container cũ
                ProfileHeader(name: name, role: role),

                // Khoảng trắng bên dưới phần màu đỏ (để lấp đầy không gian còn lại)
                Expanded(child: Container(color: Colors.white)),
              ],
            ),

            // Phần Card chứa form, nằm đè lên (overlapped)
            Positioned(
              // Adjust this 'top' value to control how much it overlaps.
              // A smaller value moves it higher, increasing overlap.
              top:
                  100, // Giá trị này có thể cần điều chỉnh để phù hợp với ProfileHeader mới
              left: 16,
              right: 16,
              child: Card(
                color:
                    Colors.grey.shade100, // Light grey for the form background
                elevation: 4, // Shadow for the card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    15,
                  ), // Rounded corners for the card
                ),
                margin: EdgeInsets
                    .zero, // Remove default card margin to let Positioned control spacing
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                  ), // Padding inside the card around the ListView
                  child: ListView(
                    physics:
                        const NeverScrollableScrollPhysics(), // Prevent scrolling if content fits
                    shrinkWrap: true, // Make ListView only take up needed space
                    children: [
                      _buildTile(Icons.person, 'Xem thông tin', () {
                        // TODO: Navigate to View Profile screen
                        print('Xem thông tin tapped!');
                      }),
                      _buildTile(Icons.edit, 'Chỉnh sửa thông tin', () {
                        // TODO: Navigate to Edit Profile screen
                        print('Chỉnh sửa thông tin tapped!');
                      }),
                      if (role !=
                          'customer') // chỉ employee/manager mới có ghi chú
                        _buildTile(Icons.feedback, 'Ghi chú và phản hồi', () {
                          // TODO: Navigate to Feedback screen
                          print('Ghi chú và phản hồi tapped!');
                        }),
                      _buildTile(Icons.lock, 'Đổi mật khẩu', () {
                        // TODO: Navigate to Change Password screen
                        print('Đổi mật khẩu tapped!');
                      }),
                      _buildTile(Icons.logout, 'Đăng xuất', () {
                        _showLogoutDialog(context);
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build a tile for the profile options.
  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 16,
      ), // Horizontal margin for tiles within the card
      child: Material(
        color: const Color(0xFFB3E5FC), // Light blue for tile background
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: Colors.black),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a confirmation dialog for logging out.
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
              // Thực hiện đăng xuất
              await AuthService().signOut();
              if (context.mounted) {
                // Điều hướng về màn hình chọn vai trò và xóa tất cả các route trước đó
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
