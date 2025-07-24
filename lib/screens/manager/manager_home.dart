import 'package:flutter/material.dart';
import '../profile.dart';
import '../customer/order.dart';
import '../customer/customer_support.dart';
import '../../widgets/header.dart';
import 'dashboard.dart';

class ManagerHome extends StatefulWidget {
  final String name;
  const ManagerHome({super.key, required this.name});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  int _selectedIndex = 0; // Index của tab được chọn trong BottomNavigationBar

  late List<Widget> _screens; // Danh sách các màn hình tương ứng với mỗi tab

  // Dữ liệu giả định cho các thẻ thống kê.
  // Trong ứng dụng thực tế, bạn sẽ fetch dữ liệu này từ API hoặc database.
  String _revenue = '120,000,000 VND';
  String _totalOrders = '530';
  String _stockQuantity = '1,250 sản phẩm';
  String _damagedItems = '15 sản phẩm';
  String _customerCount = '870 khách hàng';

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách các màn hình khi widget được tạo
    _screens = [
      _buildDashboard(), // Tab "Trang chủ"
      ManagerOrder(name: widget.name), // Tab "Đơn hàng"
      ManagerCustomerSupport(name: widget.name), // Tab "CSKH"
      CommonProfile(name: widget.name, role: 'manager'), // Tab "Cá nhân"
    ];

    // Bạn có thể thêm logic fetch dữ liệu ở đây
    _fetchDashboardData();
  }

  /// Phương thức giả định để fetch dữ liệu cho dashboard.
  /// Trong thực tế, bạn sẽ gọi API hoặc database ở đây.
  void _fetchDashboardData() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _revenue = '125,500,000 VND';
      _totalOrders = '550';
      _stockQuantity = '1,200 sản phẩm';
      _damagedItems = '12 sản phẩm';
      _customerCount = '880 khách hàng';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Màu nền của Scaffold
      body:
          _screens[_selectedIndex], // Hiển thị màn hình tương ứng với tab được chọn
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Tab hiện tại được chọn
        selectedItemColor: Colors.red, // Màu của icon và label khi được chọn
        unselectedItemColor:
            Colors.black, // Màu của icon và label khi không được chọn
        onTap: (index) {
          setState(() {
            _selectedIndex =
                index; // Cập nhật index của tab khi người dùng chạm vào
          });
        },
        items: const [
          // Các item trong BottomNavigationBar
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'CSKH'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }

  /// Xây dựng màn hình dashboard chính.
  /// Bao gồm Header và danh sách các thẻ thống kê.
  Widget _buildDashboard() {
    return SafeArea(
      child: Column(
        children: [
          // Header widget
          Header(name: widget.name),

          // Dashboard content
          ManagerDashboardContent(
            revenue: _revenue,
            totalOrders: _totalOrders,
            stockQuantity: _stockQuantity,
            damagedItems: _damagedItems,
            customerCount: _customerCount,
          ),
        ],
      ),
    );
  }
}
