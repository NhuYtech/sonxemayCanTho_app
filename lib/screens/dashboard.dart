// lib/screens/dashboard.dart
import 'package:flutter/material.dart';
import 'package:sonxemaycantho/screens/manager/staff_list.dart';

class Dashboard extends StatelessWidget {
  final String revenue;
  final String totalOrders;
  final String stockQuantity;
  final String damagedItems;
  final String customerCount;
  final String staffCount;
  final String totalStockOrders; // Thêm tham số mới
  final bool isLoading;

  const Dashboard({
    super.key,
    required this.revenue,
    required this.totalOrders,
    required this.stockQuantity,
    required this.damagedItems,
    required this.customerCount,
    required this.staffCount,
    required this.totalStockOrders,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        _buildStatCard(
          'Tổng đơn nhập:',
          stockQuantity,
          Icons.warehouse,
          const Color(0xFFFFFDE7),
        ),
        _buildStatCard(
          'Tổng đơn xuất:',
          totalOrders,
          Icons.shopping_cart,
          const Color(0xFFE8F5E9),
        ),
        _buildStatCard(
          'Tổng tồn kho:',
          totalStockOrders,
          Icons.inventory_2,
          const Color(0xFFFFEBEE),
        ),
        _buildStatCard(
          'Danh sách nhân viên:',
          staffCount,
          Icons.groups,
          const Color.fromARGB(255, 236, 220, 211),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const StaffList()));
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted
              ? Border.all(color: Colors.blue, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
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
                  Row(
                    children: [
                      if (isLoading && title.contains('đơn nhập'))
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Expanded(
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
