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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildStatCard(
            context,
            'Tổng đơn nhập',
            stockQuantity,
            Icons.warehouse_rounded,
            const LinearGradient(
              colors: [Color(0xFFFFF9C4), Color(0xFFFFF59D)],
            ),
            Icons.trending_up,
          ),
          _buildStatCard(
            context,
            'Tổng đơn xuất',
            totalOrders,
            Icons.shopping_cart_rounded,
            const LinearGradient(
              colors: [Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
            ),
            Icons.local_shipping_rounded,
          ),
          _buildStatCard(
            context,
            'Tổng tồn kho',
            totalStockOrders,
            Icons.inventory_2_rounded,
            const LinearGradient(
              colors: [Color(0xFFFFCDD2), Color(0xFFEF9A9A)],
            ),
            Icons.storage_rounded,
          ),
          _buildStatCard(
            context,
            'Danh sách nhân viên',
            staffCount,
            Icons.groups_rounded,
            const LinearGradient(
              colors: [Color(0xFFD7CCC8), Color(0xFFBCAAA4)],
            ),
            Icons.arrow_forward_ios_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const StaffList()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Gradient gradient,
    IconData trailingIcon, {
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              border: isHighlighted
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 32, color: Colors.black87),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (isLoading && title.contains('đơn nhập'))
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black87,
                              ),
                            )
                          else
                            Expanded(
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(trailingIcon, color: Colors.black45, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
