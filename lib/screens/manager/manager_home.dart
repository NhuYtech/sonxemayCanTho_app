// lib/screens/manager/manager_home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sonxemaycantho/screens/chat/chat_list.dart';
import 'package:sonxemaycantho/widgets/navigation_bar.dart';
import '../profile/profile.dart';
import '../order/order.dart';
import '../../widgets/header.dart';
import '../dashboard.dart';

class ManagerHome extends StatefulWidget {
  final String name;
  const ManagerHome({super.key, required this.name});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  String _totalOrders = 'Đang tải...';
  String _stockQuantity = 'Đang tải...';
  String _damagedItems = 'Đang tải...';
  String _customerCount = 'Đang tải...';
  String _staffCount = 'Đang tải...';
  String _totalStockOrders = 'Đang tải...'; // Thêm biến cho đơn tồn kho

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _fetchDashboardData();
  }

  void _initializeScreens() {
    _screens = [
      Dashboard(
        revenue: 'Không hiển thị',
        totalOrders: _totalOrders,
        stockQuantity: _stockQuantity,
        damagedItems: _damagedItems,
        customerCount: _customerCount,
        staffCount: _staffCount,
        totalStockOrders:
            _totalStockOrders, // Thêm dữ liệu tồn kho vào Dashboard
        isLoading: _isLoading,
      ),
      ManagerOrder(name: widget.name),
      ChatList(managerName: widget.name),
      Profile(name: widget.name, role: 'manager'),
    ];
  }

  void _fetchDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _totalOrders = 'Đang tải...';
      _stockQuantity = 'Đang tải...';
      _damagedItems = 'Đang tải...';
      _customerCount = 'Đang tải...';
      _staffCount = 'Đang tải...';
      _totalStockOrders = 'Đang tải...'; // Cập nhật lại trạng thái
      _initializeScreens();
    });

    try {
      await Future.wait([
        _fetchStockQuantity(),
        _fetchOtherData(),
        _fetchTotalStockOrders(), // Gọi hàm lấy dữ liệu tồn kho
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _screens[0] = Dashboard(
            revenue: 'Không hiển thị',
            totalOrders: _totalOrders,
            stockQuantity: _stockQuantity,
            damagedItems: _damagedItems,
            customerCount: _customerCount,
            staffCount: _staffCount,
            totalStockOrders: _totalStockOrders, // Cập nhật lại Dashboard
            isLoading: _isLoading,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        print('💥 Lỗi khi tải dữ liệu dashboard: $e');
        setState(() {
          _stockQuantity = 'Lỗi tải dữ liệu';
          _totalOrders = 'Lỗi tải dữ liệu';
          _damagedItems = 'Lỗi tải dữ liệu';
          _customerCount = 'Lỗi tải dữ liệu';
          _staffCount = 'Lỗi tải dữ liệu';
          _totalStockOrders = 'Lỗi tải dữ liệu'; // Cập nhật trạng thái lỗi
          _isLoading = false;
          _screens[0] = Dashboard(
            revenue: 'Lỗi tải dữ liệu',
            totalOrders: _totalOrders,
            stockQuantity: _stockQuantity,
            damagedItems: _damagedItems,
            customerCount: _customerCount,
            staffCount: _staffCount,
            totalStockOrders: _totalStockOrders, // Cập nhật trạng thái lỗi
            isLoading: _isLoading,
          );
        });
      }
    }
  }

  // Lấy số lượng đơn nhập kho từ các collection có thể có
  Future<void> _fetchStockQuantity() async {
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

      int totalImportOrders = 0;
      bool found = false;

      for (String collectionName in possibleCollections) {
        try {
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection(collectionName)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            totalImportOrders = querySnapshot.docs.length;
            found = true;
            break;
          }
        } catch (e) {
          // Bỏ qua lỗi và thử collection khác
        }
      }

      if (mounted) {
        setState(() {
          _stockQuantity = found ? '$totalImportOrders đơn nhập' : '0 đơn nhập';
        });
      }
    } catch (e) {
      if (mounted) {
        print('💥 Lỗi khi lấy số lượng đơn nhập kho: $e');
        setState(() {
          _stockQuantity = 'Lỗi tải';
        });
      }
    }
  }

  // Lấy các dữ liệu khác bao gồm đơn xuất, sản phẩm hỏng, khách hàng và nhân viên
  Future<void> _fetchOtherData() async {
    try {
      QuerySnapshot exportOrdersSnapshot = await FirebaseFirestore.instance
          .collection('exportOrders')
          .get();
      if (mounted) {
        setState(() {
          _totalOrders = '${exportOrdersSnapshot.docs.length} đơn xuất';
        });
      }
      QuerySnapshot damagedItemsSnapshot = await FirebaseFirestore.instance
          .collection('damagedItems')
          .get();
      int damagedCount = damagedItemsSnapshot.docs.length;
      if (damagedCount == 0) {
        QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('status', isEqualTo: 'damaged')
            .get();
        damagedCount = productsSnapshot.docs.length;
      }
      if (mounted) {
        setState(() {
          _damagedItems = '$damagedCount sản phẩm';
        });
      }
      QuerySnapshot customersSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();
      if (mounted) {
        setState(() {
          _customerCount = '${customersSnapshot.docs.length} khách hàng';
        });
      }
      QuerySnapshot staffSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .get();
      if (mounted) {
        setState(() {
          _staffCount = '${staffSnapshot.docs.length} nhân viên';
        });
      }
    } catch (e) {
      print('💥 Lỗi khi lấy dữ liệu khác: $e');
      if (mounted) {
        setState(() {
          _totalOrders = 'Lỗi tải';
          _damagedItems = 'Lỗi tải';
          _customerCount = 'Lỗi tải';
          _staffCount = 'Lỗi tải';
        });
      }
    }
  }

  // Phương thức mới để lấy tổng đơn tồn kho từ serviceOrders
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
    _fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Header(name: widget.name),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: _screens[_selectedIndex],
      ),
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
}
