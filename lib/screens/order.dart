import 'package:flutter/material.dart';

class ManagerOrder extends StatelessWidget {
  final String name;
  const ManagerOrder({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 222, 96, 85),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage('assets/logo/logo1.png'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Xin chào,\n$name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const Icon(Icons.notifications, color: Colors.yellow),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: const Icon(Icons.close),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tiêu đề
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chức năng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.lightBlue,
                ),
              ),
            ),
          ),

          // Danh sách chức năng
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFunctionTile(
                  context,
                  icon: Icons.download,
                  text: 'Đơn nhập',
                  onTap: () {
                    // TODO: Navigator.push to ImportOrder
                  },
                ),
                _buildFunctionTile(
                  context,
                  icon: Icons.upload,
                  text: 'Đơn xuất',
                  onTap: () {
                    // TODO: Navigator.push to ExportOrder
                  },
                ),
                _buildFunctionTile(
                  context,
                  icon: Icons.inventory_2,
                  text: 'Đơn tồn kho',
                  onTap: () {
                    // TODO: Navigator.push to StockOrder
                  },
                ),
                _buildFunctionTile(
                  context,
                  icon: Icons.broken_image_outlined,
                  text: 'Đơn bị hư hỏng',
                  onTap: () {
                    // TODO: Navigator.push to BrokenOrder
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionTile(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 28, color: Colors.blue),
        title: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Itim',
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
