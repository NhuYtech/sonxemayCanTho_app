import 'package:flutter/material.dart';
import '../common_profile.dart';
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
      _buildDashboard(), // Trang chủ
      const CreateRepairOrderScreen(), // Tạo đơn sửa chữa
      CommonProfile(name: widget.name, role: 'staff'), // Trang cá nhân
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Tạo đơn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
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
