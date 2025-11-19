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
    setState(() {
      _isLoading = true;
      _totalImportOrders = 'Đang tải...';
      _totalExportOrders = 'Đang tải...';
      _totalStockOrders = 'Đang tải...';
      _initializeScreens();
    });

    try {
      await _fetchTotalImportOrders();
      await _fetchTotalExportOrders();
      await _fetchTotalStockOrders();

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
          _initializeScreens();
        });
      }
    }
  }

  Future<void> _fetchTotalImportOrders() async {
    try {
      List<String> possibleCollections = [
        'serviceOrders',
        'orders',
        'import_orders',
        'importOrders',
        'phieu_nhap',
        'don_nhap',
        'stock_imports',
        'purchase_orders',
        'imports',
      ];

      int totalImports = 0;
      bool foundCollection = false;

      for (String collectionName in possibleCollections) {
        try {
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection(collectionName)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            if (collectionName.toLowerCase().contains('import') ||
                collectionName.toLowerCase().contains('nhap') ||
                collectionName.toLowerCase().contains('serviceorders')) {
              totalImports = querySnapshot.docs.length;
              foundCollection = true;
              break;
            } else {
              for (var doc in querySnapshot.docs) {
                var data = doc.data() as Map<String, dynamic>;
                if (data.containsKey('type') &&
                    (data['type'].toString().toLowerCase().contains('import') ||
                        data['type'].toString().toLowerCase().contains(
                          'nhap',
                        ))) {
                  totalImports = querySnapshot.docs.length;
                  foundCollection = true;
                  break;
                }
              }
              if (foundCollection) break;
            }
          }
        } catch (e)
        // ignore: empty_catches
        {}
      }

      if (mounted) {
        setState(() {
          _totalImportOrders = '$totalImports đơn';
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

  Future<void> _fetchTotalExportOrders() async {
    try {
      int totalExports = 0;
      List<String> possibleCollections = [
        'export_orders',
        'exportOrders',
        'phieu_xuat',
        'don_xuat',
        'stock_exports',
        'sale_orders',
        'sales',
        'exports',
      ];

      bool foundCollection = false;

      for (String collectionName in possibleCollections) {
        try {
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection(collectionName)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            if (collectionName.toLowerCase().contains('export') ||
                collectionName.toLowerCase().contains('xuat') ||
                collectionName.toLowerCase().contains('sale')) {
              totalExports = querySnapshot.docs.length;
              foundCollection = true;
              break;
            } else {
              for (var doc in querySnapshot.docs) {
                var data = doc.data() as Map<String, dynamic>;
                if (data.containsKey('type') &&
                    (data['type'].toString().toLowerCase().contains('export') ||
                        data['type'].toString().toLowerCase().contains(
                          'xuat',
                        ) ||
                        data['type'].toString().toLowerCase().contains(
                          'sale',
                        ))) {
                  totalExports = querySnapshot.docs.length;
                  foundCollection = true;
                  break;
                }
              }
              if (foundCollection) break;
            }
          }
        } catch (e)
        // ignore: empty_catches
        {}
      }

      if (mounted) {
        setState(() {
          _totalExportOrders = '$totalExports đơn';
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

  Future<void> _fetchTotalStockOrders() async {
    try {
      int totalStockOrders = 0;
      final stockStatuses = ['Đã nhận', 'Đang sơn', 'Đã sơn xong'];

      final QuerySnapshot stockOrdersSnapshot = await FirebaseFirestore.instance
          .collection('serviceOrders')
          .where('status', whereIn: stockStatuses)
          .get();

      totalStockOrders = stockOrdersSnapshot.docs.length;

      if (mounted) {
        setState(() {
          _totalStockOrders = '$totalStockOrders đơn';
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
    setState(() {
      _isLoading = true;
      _totalImportOrders = 'Đang tải...';
      _totalExportOrders = 'Đang tải...';
      _totalStockOrders = 'Đang tải...';
      _initializeScreens();
    });
    _fetchDashboardData();
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFC1473B),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/logo/logo1.png'),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Xin chào,\n${widget.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // const Icon(Icons.notifications, color: Colors.yellow, size: 28),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {},
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              onChanged: (value) {},
            ),
          ],
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
