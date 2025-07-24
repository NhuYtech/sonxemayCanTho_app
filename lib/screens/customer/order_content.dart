import 'package:flutter/material.dart';

class OrderContent extends StatelessWidget {
  const OrderContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề "Chức năng"
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: const Text(
              'Chức năng',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.lightBlue,
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
                    print('Đơn nhập tapped!');
                  },
                ),
                _buildFunctionTile(
                  context,
                  icon: Icons.upload,
                  text: 'Đơn xuất',
                  onTap: () {
                    // TODO: Navigator.push to ExportOrder
                    print('Đơn xuất tapped!');
                  },
                ),
                _buildFunctionTile(
                  context,
                  icon: Icons.inventory_2,
                  text: 'Đơn tồn kho',
                  onTap: () {
                    // TODO: Navigator.push to StockOrder
                    print('Đơn tồn kho tapped!');
                  },
                ),
                _buildFunctionTile(
                  context,
                  icon: Icons.broken_image_outlined,
                  text: 'Đơn bị hư hỏng',
                  onTap: () {
                    // TODO: Navigator.push to BrokenOrder
                    print('Đơn bị hư hỏng tapped!');
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, size: 28, color: Colors.blue.shade700),
        title: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 20,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
