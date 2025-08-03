// lib/screens/customer/customer_home.dart
import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../profile/profile.dart';

class CustomerHome extends StatefulWidget {
  final String name;
  const CustomerHome({super.key, required this.name});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  String _customerOrdersCount = '12 đơn hàng';
  String _pendingSupportTickets = '3 yêu cầu';
  String _loyaltyPoints = '5,000 điểm';

  @override
  void initState() {
    super.initState();

    _pages = [
      _buildHomeTab(),
      const Center(child: Text('📦 Danh sách đơn hàng')),
      const Center(child: Text('💬 Tin nhắn')),
      Profile(name: widget.name, role: 'customer'),
    ];

    _fetchCustomerDashboardData();
  }

  void _fetchCustomerDashboardData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _customerOrdersCount = '15 đơn hàng';
      _pendingSupportTickets = '1 yêu cầu';
      _loyaltyPoints = '5,250 điểm';
    });
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
          'Tổng đơn hàng của bạn:',
          _customerOrdersCount,
          Icons.shopping_bag,
          const Color(0xFFE3F2FD),
        ),
        _buildStatCard(
          'Yêu cầu hỗ trợ đang chờ:',
          _pendingSupportTickets,
          Icons.support_agent,
          const Color(0xFFFFFDE7),
        ),
        _buildStatCard(
          'Điểm tích lũy:',
          _loyaltyPoints,
          Icons.star,
          const Color(0xFFE8F5E9),
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
