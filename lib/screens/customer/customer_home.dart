// lib/screens/customer/customer_home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sonxemaycantho/screens/customer/customer_order.dart';
import '../../widgets/header.dart';
import '../profile/profile.dart';
import 'customer_chat.dart';

class CustomerHome extends StatefulWidget {
  final String name;
  const CustomerHome({super.key, required this.name});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  // Khởi tạo biến đếm đơn hàng với giá trị ban đầu
  String _customerOrdersCount = 'Đang tải...';

  @override
  void initState() {
    super.initState();

    // Khởi tạo các màn hình
    _pages = [
      _buildHomeTab(),
      // Thay thế Center bằng màn hình CustomerOrder
      const CustomerOrder(),
      // Thay thế màn hình Center bằng màn hình chat của khách hàng
      CustomerChatScreen(customerName: widget.name),
      Profile(name: widget.name, role: 'customer'),
    ];

    _fetchCustomerDashboardData();
  }

  // Hàm mới để fetch dữ liệu dashboard cho khách hàng
  void _fetchCustomerDashboardData() async {
    try {
      final QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('serviceOrders')
          .get();
      // Đếm số lượng đơn hàng, có thể thêm logic lọc theo người dùng sau
      final int ordersCount = orderSnapshot.docs.length;
      if (mounted) {
        setState(() {
          _customerOrdersCount = '$ordersCount đơn hàng';
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi fetch dữ liệu đơn hàng: $e');
      if (mounted) {
        setState(() {
          _customerOrdersCount = 'Lỗi tải';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Header(name: widget.name),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _buildStatCard(
          'Tổng đơn hàng:',
          _customerOrdersCount,
          Icons.shopping_bag,
          const Color(0xFFE3F2FD),
        ),
      ],
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
