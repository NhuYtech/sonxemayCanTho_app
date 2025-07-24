// customer_home.dart
import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../profile.dart'; // Import CommonProfile

class CustomerHome extends StatefulWidget {
  final String name;
  const CustomerHome({super.key, required this.name});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _selectedIndex = 0; // Index của tab được chọn trong BottomNavigationBar

  late final List<Widget>
  _pages; // Danh sách các màn hình tương ứng với mỗi tab

  // Dữ liệu giả định cho các thẻ thống kê trên trang chủ của khách hàng.
  // Trong ứng dụng thực tế, bạn sẽ fetch dữ liệu này từ API hoặc database.
  String _customerOrdersCount = '12 đơn hàng';
  String _pendingSupportTickets = '3 yêu cầu';
  String _loyaltyPoints = '5,000 điểm';

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách các màn hình khi widget được tạo
    _pages = [
      _buildHomeTab(), // Tab "Trang chủ"
      const Center(child: Text('📦 Danh sách đơn hàng')), // Tab "Đơn hàng"
      const Center(child: Text('💬 Tin nhắn')), // Tab "Tin nhắn"
      CommonProfile(name: widget.name, role: 'customer'), // Tab "Tài khoản"
    ];

    // Bạn có thể thêm logic fetch dữ liệu cho dashboard khách hàng ở đây
    _fetchCustomerDashboardData();
  }

  /// Phương thức giả định để fetch dữ liệu cho dashboard của khách hàng.
  /// Trong thực tế, bạn sẽ gọi API hoặc database ở đây.
  void _fetchCustomerDashboardData() async {
    // Simulate a network delay
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
      backgroundColor: Colors.white, // Màu nền của Scaffold
      body:
          _pages[_selectedIndex], // Hiển thị màn hình tương ứng với tab được chọn
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Tab hiện tại được chọn
        onTap: (int index) {
          setState(() {
            _selectedIndex =
                index; // Cập nhật index của tab khi người dùng chạm vào
          });
        },
        selectedItemColor: Colors.red, // Màu của icon và label khi được chọn
        unselectedItemColor:
            Colors.grey, // Màu của icon và label khi không được chọn
        items: const [
          // Các item trong BottomNavigationBar
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }

  /// Xây dựng màn hình tab Trang chủ cho khách hàng.
  /// Bao gồm Header và danh sách các thẻ thông tin.
  Widget _buildHomeTab() {
    return SafeArea(
      child: Column(
        children: [
          // Sử dụng widget Header đã import
          Header(name: widget.name), // Truyền tên người dùng vào Header
          const SizedBox(
            height: 16,
          ), // Khoảng cách giữa Header và nội dung chính
          // Nội dung chính của tab Trang chủ
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ), // Padding cho ListView
              children: [
                // Các thẻ thông tin với dữ liệu động cho khách hàng
                _buildStatCard(
                  'Tổng đơn hàng của bạn:',
                  _customerOrdersCount, // Sử dụng biến dữ liệu giả định
                  Icons.shopping_bag,
                  const Color(0xFFE3F2FD), // Light blue
                ),
                _buildStatCard(
                  'Yêu cầu hỗ trợ đang chờ:',
                  _pendingSupportTickets, // Sử dụng biến dữ liệu giả định
                  Icons.support_agent,
                  const Color(0xFFFFFDE7), // Light yellow
                ),
                _buildStatCard(
                  'Điểm tích lũy:',
                  _loyaltyPoints, // Sử dụng biến dữ liệu giả định
                  Icons.star,
                  const Color(0xFFE8F5E9), // Light green
                ),
                // Bạn có thể thêm các thẻ khác như "Ưu đãi đặc biệt", "Sản phẩm yêu thích" v.v.
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget dùng để tạo một thẻ thông tin với tiêu đề, giá trị, icon và màu nền.
  /// Tương tự như _buildStatCard trong manager.dart nhưng được điều chỉnh cho mục đích khách hàng.
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Khoảng cách dưới mỗi thẻ
      padding: const EdgeInsets.all(16), // Padding bên trong thẻ
      decoration: BoxDecoration(
        color: color, // Màu nền của thẻ
        borderRadius: BorderRadius.circular(12), // Bo tròn góc
        boxShadow: [
          // Thêm bóng đổ nhẹ để thẻ nổi bật hơn
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2), // Vị trí bóng đổ
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black), // Icon của thẻ
          const SizedBox(width: 16), // Khoảng cách giữa icon và nội dung
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Căn chỉnh văn bản sang trái
              children: [
                Text(
                  title, // Tiêu đề của thẻ (ví dụ: "Tổng đơn hàng của bạn:")
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ), // Màu chữ nhạt hơn cho tiêu đề
                ),
                const SizedBox(
                  height: 4,
                ), // Khoảng cách giữa tiêu đề và giá trị
                Text(
                  value, // Giá trị thống kê (ví dụ: "12 đơn hàng")
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ), // In đậm và lớn hơn cho giá trị
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
