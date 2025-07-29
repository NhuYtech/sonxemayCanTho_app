import 'package:flutter/material.dart';
import 'package:sonxemaycantho/screens/export_order.dart';
import 'package:sonxemaycantho/screens/order_entry.dart';

class OrderContent extends StatelessWidget {
  const OrderContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: const Text(
              'Chức năng',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xFF3F51B5),
                letterSpacing: 0.5,
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildFunctionTile(
                  context,
                  icon: Icons.download,
                  text: 'Đơn nhập',
                  color: Colors.lightBlue.shade50,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderEntry(),
                      ),
                    );
                    print('Đơn nhập tapped!');
                  },
                ),
                _buildFunctionTile(
                  context,
                  icon: Icons.upload,
                  text: 'Đơn xuất',
                  color: Colors.green.shade50,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportOrder(),
                      ),
                    );
                    print('Đơn xuất tapped!');
                  },
                ),
                _buildFunctionTile(
                  context,
                  icon: Icons.inventory_2,
                  text: 'Đơn tồn kho',
                  color: Colors.orange.shade50,
                  onTap: () {
                    // TODO: Navigator.push to StockOrder
                    print('Đơn tồn kho tapped!');
                  },
                ),
                // _buildFunctionTile(
                //   context,
                //   icon: Icons.broken_image_outlined,
                //   text: 'Đơn bị hư hỏng',
                //   color: Colors.red.shade50, // Keep tile background color
                //   onTap: () {
                //     // TODO: Navigator.push to BrokenOrder
                //     print('Đơn bị hư hỏng tapped!');
                //   },
                // ),
                const SizedBox(height: 20),
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
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1.5,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 20.0,
            ),
            child: Row(
              children: [
                Icon(icon, size: 30, color: Colors.black87),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 22,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
