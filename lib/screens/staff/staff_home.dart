import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sonxemaycantho/screens/order/order_content.dart';
import '../profile/profile.dart';

class StaffHome extends StatefulWidget {
  final String name;
  const StaffHome({super.key, required this.name});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  String _totalImportOrders = 'Đang tải...';
  String _totalExportOrders = 'Đang tải...';
  String _totalStockOrders = 'Đang tải...';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _fetchDashboardData();
  }

  void _initializeScreens() {
    _screens = [
      _StaffDashboardContent(
        totalImportOrders: _totalImportOrders,
        totalExportOrders: _totalExportOrders,
        totalStockOrders: _totalStockOrders,
        isLoading: _isLoading,
      ),
      const OrderContent(),
      Profile(name: widget.name, role: 'staff'),
    ];
  }

  void _fetchDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _totalImportOrders = 'Đang tải...';
      _totalExportOrders = 'Đang tải...';
      _totalStockOrders = 'Đang tải...';
    });

    try {
      await Future.wait([
        _fetchImportOrders(),
        _fetchExportOrders(),
        _fetchStockOrders(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _initializeScreens();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalImportOrders = 'Lỗi tải dữ liệu';
          _totalExportOrders = 'Lỗi tải dữ liệu';
          _totalStockOrders = 'Lỗi tải dữ liệu';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchImportOrders() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('serviceOrders')
          .get();
      if (mounted) {
        setState(() {
          _totalImportOrders = '${snapshot.docs.length} đơn nhập';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalImportOrders = 'Lỗi tải';
        });
      }
    }
  }

  Future<void> _fetchExportOrders() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('exportOrders')
          .get();
      if (mounted) {
        setState(() {
          _totalExportOrders = '${snapshot.docs.length} đơn xuất';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalExportOrders = 'Lỗi tải';
        });
      }
    }
  }

  Future<void> _fetchStockOrders() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('inventory')
          .get();
      if (mounted) {
        setState(() {
          _totalStockOrders = '${snapshot.docs.length} sản phẩm';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalStockOrders = 'Lỗi tải';
        });
      }
    }
  }

  void _refreshData() {
    _fetchDashboardData();
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào,',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        widget.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.black,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: _selectedIndex == 0 ? 'Trang chủ' : '',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.list),
          label: _selectedIndex == 1 ? 'Đơn hàng' : '',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: _selectedIndex == 2 ? 'Cá nhân' : '',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 160.0,
        // Đặt automaticallyImplyLeading thành false để loại bỏ mũi tên quay lại.
        automaticallyImplyLeading: false,
        flexibleSpace: _buildHeader(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}

// Các class còn lại vẫn giữ nguyên
// --- _StaffDashboardContent Widget ---
class _StaffDashboardContent extends StatelessWidget {
  final String totalImportOrders;
  final String totalExportOrders;
  final String totalStockOrders;
  final bool isLoading;

  const _StaffDashboardContent({
    required this.totalImportOrders,
    required this.totalExportOrders,
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
          totalImportOrders,
          Icons.download,
          const Color(0xFFE3F2FD),
          showLoading: isLoading && totalImportOrders == 'Đang tải...',
        ),
        _buildStatCard(
          'Tổng đơn xuất:',
          totalExportOrders,
          Icons.upload,
          const Color(0xFFFFFDE7),
          showLoading: isLoading && totalExportOrders == 'Đang tải...',
        ),
        _buildStatCard(
          'Tổng tồn kho:',
          totalStockOrders,
          Icons.inventory_2,
          const Color(0xFFFFEBEE),
          showLoading: isLoading && totalStockOrders == 'Đang tải...',
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
    bool showLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted ? Border.all(color: Colors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withValues(alpha: 0.2),
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
                    if (showLoading)
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
    );
  }
}
