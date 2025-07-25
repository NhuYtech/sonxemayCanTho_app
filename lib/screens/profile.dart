import 'package:flutter/material.dart';
import 'package:sonxemaycantho/screens/view_profile.dart';
import 'package:sonxemaycantho/services/auth.dart';
import 'package:sonxemaycantho/screens/role.dart';
import 'package:sonxemaycantho/widgets/header.dart'; // Ensure this import is correct

class CommonProfile extends StatelessWidget {
  final String name;
  final String role; // The role is still needed for the feedback tile condition

  const CommonProfile({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Header(name: name), // Your general Header

              const SizedBox(height: 20), // Spacing below the header

              ListView(
                physics:
                    const NeverScrollableScrollPhysics(), // Still needed for inner ListView
                shrinkWrap: true, // Still needed for inner ListView
                padding: EdgeInsets.zero, // Remove padding from ListView itself
                children: [
                  _buildTile(Icons.person, 'Xem thông tin', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewProfileScreen(),
                      ),
                    );
                  }),
                  if (role != 'customer')
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
              const SizedBox(
                height: 20,
              ), // Optional: Add some padding at the bottom
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to build a tile for the profile options, with styling like OrderContent.
  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
        left: 16,
        right: 16,
      ), // Increased bottom margin, kept horizontal
      decoration: BoxDecoration(
        color: const Color.fromARGB(
          255,
          144,
          220,
          255,
        ), // Keep light blue color
        borderRadius: BorderRadius.circular(
          15,
        ), // Slightly more rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3), // Slightly stronger shadow
            spreadRadius: 1.5, // Increased spread
            blurRadius: 5, // Increased blur
            offset: const Offset(0, 3), // Slightly lower offset
          ),
        ],
      ),
      child: Material(
        // Wrap with Material for InkWell splash effect
        color: Colors
            .transparent, // Make Material transparent to show Container's color
        borderRadius: BorderRadius.circular(
          15,
        ), // Match Container's border radius
        child: InkWell(
          borderRadius: BorderRadius.circular(
            15,
          ), // Match Material's border radius for splash
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 20.0,
            ), // More padding inside the tile
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: Colors.black,
                ), // Larger icon, keep black color
                const SizedBox(width: 20), // More space between icon and text
                Expanded(
                  // Use Expanded to ensure text doesn't overflow
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600, // Slightly bolder than bold
                      fontSize: 18, // Slightly larger font size for title
                      color: Colors.black87, // Keep black87 for text color
                    ),
                  ),
                ),
                // const Icon(
                //   Icons.arrow_forward_ios,
                //   size: 22, // Slightly larger arrow icon
                //   color: Colors.grey, // Keep grey for arrow
                // ),
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
