// lib/screens/customer/customer_home.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/header.dart';
import '../profile/profile.dart';
import '../../services/chat_service.dart';
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
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    // Khởi tạo các màn hình
    _pages = [
      _buildHomeTab(),
      CustomerChatScreen(customerName: widget.name),
      Profile(name: widget.name, role: 'customer'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: _chatService.getTotalUnreadCountStream(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat),
                    if (unreadCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Tin nhắn',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Chào mừng
          _buildWelcomeBanner(),
          const SizedBox(height: 24),

          // Tình trạng đơn hàng gần nhất
          _buildSectionTitle('Đơn hàng gần nhất'),
          const SizedBox(height: 8),
          _buildRecentOrderCard(),
          const SizedBox(height: 24),

          // Hành động nhanh
          _buildSectionTitle('Hành động nhanh'),
          const SizedBox(height: 8),
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Thông báo & Khuyến mãi (Ví dụ)
          _buildSectionTitle('Ưu đãi dành cho bạn'),
          const SizedBox(height: 8),
          _buildPromotionCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC1473B),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chào mừng quay trở lại!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chúng tôi luôn sẵn lòng phục vụ bạn.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildRecentOrderCard() {
    // Đây là ví dụ, bạn có thể fetch dữ liệu thật từ Firestore
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn hàng #123456',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Chip(
                  label: Text(
                    'Đang sơn',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              value: 0.5, // Giả lập 50% tiến độ
              backgroundColor: Colors.grey,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tiến độ: 50% hoàn thành',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Chuyển đến màn hình chi tiết đơn hàng
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC1473B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 40),
              ),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Xem chi tiết'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton('Tạo đơn mới', Icons.add_shopping_cart, () {
            // TODO: Chuyển đến màn hình tạo đơn hàng
          }),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton('Liên hệ', Icons.chat_bubble_outline, () {
            // TODO: Chuyển đến màn hình chat
            setState(() {
              _selectedIndex = 1;
            });
          }),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: const Color(0xFFC1473B)),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.lightBlueAccent),
      ),
      child: const Row(
        children: [
          Icon(Icons.star, color: Colors.blueAccent, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giảm giá đặc biệt!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Giảm 10% cho đơn hàng tiếp theo. Áp dụng đến cuối tháng!',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
