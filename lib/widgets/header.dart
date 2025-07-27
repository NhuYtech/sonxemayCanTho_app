// lib/widgets/header.dart
import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  // THÊM implements PreferredSizeWidget
  final String name;
  final Color backgroundColor;

  const Header({
    super.key,
    required this.name,
    this.backgroundColor = const Color(0xFFC1473B),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Không cần width: double.infinity nữa khi dùng trong AppBar
      // vì AppBar đã tự động tràn viền ngang rồi.
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Điều chỉnh padding cho phù hợp với AppBar
      decoration: BoxDecoration(
        color: backgroundColor,
        // BỎ borderRadius nếu bạn muốn nó tràn viền hoàn toàn như AppBar
        // và không có góc bo tròn ở dưới.
        // Nếu muốn vẫn có bo tròn nhưng tràn viền, xem ghi chú bên dưới.
        // borderRadius: const BorderRadius.only(
        //   bottomLeft: Radius.circular(30),
        //   bottomRight: Radius.circular(30),
        // ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        // Sử dụng SafeArea để tránh thanh trạng thái
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/logo/logo1.png'),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Xin chào,\n$name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.notifications, color: Colors.yellow, size: 28),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    print('Clear search tapped!');
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              onChanged: (value) {
                print('Search query: $value');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(160.0);
}
