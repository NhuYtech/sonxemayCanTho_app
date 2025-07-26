import 'package:flutter/material.dart';

class ManagerDashboardContent extends StatelessWidget {
  final String revenue;
  final String totalOrders;
  final String stockQuantity;
  final String damagedItems;
  final String customerCount;
  final String staffCount;

  const ManagerDashboardContent({
    super.key,
    required this.revenue,
    required this.totalOrders,
    required this.stockQuantity,
    required this.damagedItems,
    required this.customerCount,
    required this.staffCount,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildStatCard(
            'Doanh thu:',
            revenue,
            Icons.bar_chart,
            const Color(0xFFE3F2FD),
          ),
          _buildStatCard(
            'Tổng đơn hàng:',
            totalOrders,
            Icons.shopping_cart,
            const Color(0xFFE8F5E9),
          ),
          _buildStatCard(
            'Hàng tồn kho:',
            stockQuantity,
            Icons.warehouse,
            const Color(0xFFFFFDE7),
          ),
          _buildStatCard(
            'Hàng hư hỏng:',
            damagedItems,
            Icons.broken_image,
            const Color(0xFFFFEBEE),
          ),
          _buildStatCard(
            'Tổng khách hàng:',
            customerCount,
            Icons.people,
            const Color(0xFFF3E5F5),
          ),
          _buildStatCard(
            'Danh sách nhân viên:',
            staffCount,
            Icons.groups,
            const Color.fromARGB(255, 236, 220, 211),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
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
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
