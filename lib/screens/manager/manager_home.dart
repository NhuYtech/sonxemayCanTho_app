import 'package:flutter/material.dart';
import '../profile.dart'; // CommonProfile
import '../customer/order.dart'; // ManagerOrder (giả định)
import '../customer/customer_support.dart'; // ManagerCustomerSupport (giả định)
import '../../widgets/header.dart'; // Header
import 'dashboard.dart'; // ManagerDashboardContent

class ManagerHome extends StatefulWidget {
  final String name;
  const ManagerHome({super.key, required this.name});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  String _revenue = '120,000,000 VND';
  String _totalOrders = '530';
  String _stockQuantity = '1,250 sản phẩm';
  String _damagedItems = '15 sản phẩm';
  String _customerCount = '870 khách hàng';
  String _staffCount = '20 nhân viên';

  @override
  void initState() {
    super.initState();
    _screens = [
      // Bây giờ dashboard chỉ cần nội dung, không cần Header riêng
      ManagerDashboardContent(
        revenue: _revenue,
        totalOrders: _totalOrders,
        stockQuantity: _stockQuantity,
        damagedItems: _damagedItems,
        customerCount: _customerCount,
        staffCount: _staffCount,
      ),
      ManagerOrder(name: widget.name),
      ManagerCustomerSupport(name: widget.name),
      // CommonProfile giờ cũng sẽ không cần Header riêng nếu bạn muốn nó dùng AppBar chung
      // Hoặc Profile sẽ có AppBar riêng của nó nếu bạn muốn thiết kế khác
      Profile(name: widget.name, role: 'manager'),
    ];

    _fetchDashboardData();
  }

  void _fetchDashboardData() async {
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
      backgroundColor: Colors.white,
      // ĐẶT HEADER LÀM APPBAR CHO SCAFFOLD CHÍNH
      appBar: Header(name: widget.name), // Đây là nơi Header sẽ tràn viền
      // body chỉ chứa các màn hình đã được định nghĩa ở trên
      // Mỗi màn hình con KHÔNG nên có AppBar/Header riêng nếu bạn muốn Header chung này.
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
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'CSKH'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}
