import 'package:flutter/material.dart';
import 'package:sonxemaycantho/widgets/navigation_bar.dart';
import '../profile.dart';
import 'create_repair_order.dart';

class StaffHome extends StatefulWidget {
  final String name;
  const StaffHome({super.key, required this.name});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildDashboard(),
      const CreateRepairOrderScreen(),
      _buildCustomerService(), // Thêm màn hình CSKH
      Profile(name: widget.name, role: 'staff'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDashboard() {
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
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/logo/logo1.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Xin chào,\n${widget.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const Icon(Icons.notifications, color: Colors.yellow),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Nội dung
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatCard(
                  'Tổng đơn hàng:',
                  Icons.shopping_cart,
                  Colors.green,
                ),
                _buildStatCard('Hàng tồn kho:', Icons.warehouse, Colors.orange),
                _buildStatCard(
                  'Hàng hư hỏng:',
                  Icons.broken_image,
                  Colors.pink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerService() {
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
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/logo/logo1.png'),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Chăm sóc khách hàng',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const Icon(Icons.chat, color: Colors.yellow),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Nội dung CSKH
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chăm sóc khách hàng',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tính năng đang được phát triển',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
