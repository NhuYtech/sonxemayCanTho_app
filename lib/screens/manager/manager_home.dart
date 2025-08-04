import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  String _revenue = 'Đang tải...';
  String _totalOrders = 'Đang tải...';
  String _stockQuantity = 'Đang tải...';
  String _damagedItems = 'Đang tải...';
  String _customerCount = 'Đang tải...';
  String _staffCount = 'Đang tải...';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _fetchDashboardData();
  }

  // Khởi tạo các màn hình với dữ liệu ban đầu
  // Màn hình Dashboard sẽ được cập nhật dữ liệu khi fetch xong
  void _initializeScreens() {
    _screens = [
      Dashboard(
        revenue: _revenue,
        totalOrders: _totalOrders,
        stockQuantity: _stockQuantity,
        damagedItems: _damagedItems,
        customerCount: _customerCount,
        staffCount: _staffCount,
        isLoading: _isLoading,
      ),
      ManagerOrder(name: widget.name),
      ChatList(managerName: widget.name),
      Profile(name: widget.name, role: 'manager'),
    ];
  }

  // Hàm chính để lấy tất cả dữ liệu từ Firestore và cập nhật UI
  void _fetchDashboardData() async {
    // Ngăn không cho gọi setState nếu widget đã bị hủy
    if (!mounted) return;

    // Hiển thị trạng thái đang tải
    setState(() {
      _isLoading = true;
      _revenue = 'Đang tải...';
      _totalOrders = 'Đang tải...';
      _stockQuantity = 'Đang tải...';
      _damagedItems = 'Đang tải...';
      _customerCount = 'Đang tải...';
      _staffCount = 'Đang tải...';
      _initializeScreens(); // Khởi tạo lại màn hình với dữ liệu "đang tải"
    });

    try {
      // Chạy các tác vụ lấy dữ liệu song song để tối ưu hiệu suất
      await Future.wait([_fetchStockQuantity(), _fetchOtherData()]);

      // Cập nhật giao diện sau khi tất cả dữ liệu đã được lấy
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Cập nhật lại màn hình dashboard với dữ liệu mới
          _screens[0] = Dashboard(
            revenue: _revenue,
            totalOrders: _totalOrders,
            stockQuantity: _stockQuantity,
            damagedItems: _damagedItems,
            customerCount: _customerCount,
            staffCount: _staffCount,
            isLoading: _isLoading,
          );
        });
      }
    } catch (e) {
      // Xử lý lỗi nếu có bất kỳ lỗi nào xảy ra trong quá trình fetch
      if (mounted) {
        print('💥 Error fetching dashboard data: $e');
        setState(() {
          _stockQuantity = 'Lỗi tải dữ liệu';
          _revenue = 'Lỗi tải dữ liệu';
          _totalOrders = 'Lỗi tải dữ liệu';
          _damagedItems = 'Lỗi tải dữ liệu';
          _customerCount = 'Lỗi tải dữ liệu';
          _staffCount = 'Lỗi tải dữ liệu';
          _isLoading = false;
          // Cập nhật màn hình dashboard với thông báo lỗi
          _screens[0] = Dashboard(
            revenue: _revenue,
            totalOrders: _totalOrders,
            stockQuantity: _stockQuantity,
            damagedItems: _damagedItems,
            customerCount: _customerCount,
            staffCount: _staffCount,
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
            break; // Dừng lại sau khi tìm thấy collection đầu tiên có dữ liệu
          }
        } catch (e) {
          // Bỏ qua lỗi và thử collection khác
        }
      }

      if (mounted) {
        setState(() {
          if (found && totalImportOrders > 0) {
            _stockQuantity = '$totalImportOrders đơn nhập';
          } else {
            _stockQuantity = '0 đơn nhập';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        print('💥 Error fetching stock quantity: $e');
        setState(() {
          _stockQuantity = 'Lỗi: ${e.toString()}';
        });
      }
    }
  }

  // Lấy các dữ liệu khác bao gồm doanh thu, đơn xuất, sản phẩm hỏng, khách hàng và nhân viên
  Future<void> _fetchOtherData() async {
    try {
      // 1. Lấy số lượng đơn xuất và tính toán doanh thu
      QuerySnapshot exportOrdersSnapshot = await FirebaseFirestore.instance
          .collection('exportOrders')
          .get();

      if (mounted) {
        setState(() {
          _totalOrders = '${exportOrdersSnapshot.docs.length} đơn xuất';
        });
      }

      double totalRevenue = 0;
      for (var doc in exportOrdersSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        int quantity = (data['quantity'] as num?)?.toInt() ?? 0;
        double itemPrice = 100000; // Giá sản phẩm cố định
        totalRevenue += (quantity * itemPrice);
      }
      if (mounted) {
        setState(() {
          final formatter = NumberFormat('#,##0', 'vi_VN');
          _revenue = '${formatter.format(totalRevenue)} VND';
        });
      }

      // 2. Lấy số lượng sản phẩm hỏng
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

      // 3. Lấy số lượng khách hàng
      try {
        QuerySnapshot customersSnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .get();
        if (mounted) {
          setState(() {
            _customerCount = '${customersSnapshot.docs.length} khách hàng';
          });
        }
      } catch (e) {
        QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .get();
        if (mounted) {
          setState(() {
            _customerCount = '${usersSnapshot.docs.length} người dùng';
          });
        }
      }

      // 4. Lấy số lượng nhân viên bằng cách lọc theo vai trò
      QuerySnapshot staffSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(
            'role',
            isEqualTo: 'staff',
          ) // Lọc những người có vai trò là "staff"
          .get();
      if (mounted) {
        setState(() {
          _staffCount = '${staffSnapshot.docs.length} nhân viên';
        });
      }
    } catch (e) {
      print('💥 Error fetching other data: $e');
      if (mounted) {
        setState(() {
          _totalOrders = 'Lỗi tải';
          _revenue = 'Lỗi tải';
          _damagedItems = 'Lỗi tải';
          _customerCount = 'Lỗi tải';
          _staffCount = 'Lỗi tải';
        });
      }
    }
  }

  // Hàm làm mới dữ liệu
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
