import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile.dart'; // CommonProfile
import '../customer/order.dart'; // ManagerOrder (giả định)
import '../customer/customer_support.dart'; // ManagerCustomerSupport (giả định)
import '../../widgets/header.dart'; // Header
import 'dashboard.dart'; // ManagerDashboardContent
import '../../services/firestore.dart'; // Import FirestoreService với đúng tên file

class ManagerHome extends StatefulWidget {
  final String name;
  const ManagerHome({super.key, required this.name});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  // Dashboard data variables
  String _revenue = '120,000,000 VND';
  String _totalOrders = '530';
  String _stockQuantity = 'Đang tải...'; // Changed default value
  String _damagedItems = '15 sản phẩm';
  String _customerCount = '870 khách hàng';
  String _staffCount = '20 nhân viên';

  // Loading state
  bool _isLoading = true;

  // FirestoreService instance
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _fetchDashboardData();
  }

  void _initializeScreens() {
    _screens = [
      ManagerDashboardContent(
        revenue: _revenue,
        totalOrders: _totalOrders,
        stockQuantity: _stockQuantity,
        damagedItems: _damagedItems,
        customerCount: _customerCount,
        staffCount: _staffCount,
        isLoading: _isLoading,
      ),
      ManagerOrder(name: widget.name),
      ManagerCustomerSupport(name: widget.name),
      Profile(name: widget.name, role: 'manager'),
    ];
  }

  void _fetchDashboardData() async {
    try {
      print('🚀 Bắt đầu fetch dashboard data...');

      // Fetch stock/import orders count from Firestore
      print('📦 Bắt đầu fetch stock quantity...');
      await _fetchStockQuantity();
      print('📦 Hoàn thành fetch stock quantity');

      // Fetch other dashboard data
      print('📊 Bắt đầu fetch other data...');
      await _fetchOtherData();
      print('📊 Hoàn thành fetch other data');

      setState(() {
        _isLoading = false;
        _initializeScreens(); // Reinitialize screens with updated data
      });

      print('✅ Hoàn thành fetch dashboard data');
    } catch (e) {
      print('💥 Error fetching dashboard data: $e');
      setState(() {
        _stockQuantity = 'Lỗi tải dữ liệu: $e';
        _isLoading = false;
        _initializeScreens();
      });
    }
  }

  Future<void> _fetchStockQuantity() async {
    try {
      print('🔍 Bắt đầu fetch dữ liệu đơn nhập...');

      // Thử các collection name có thể - thêm serviceOrders vào đầu danh sách
      List<String> possibleCollections = [
        'serviceOrders', // Thêm collection này từ Firebase Console
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
      String foundCollection = '';
      bool found = false;

      for (String collectionName in possibleCollections) {
        try {
          print('📋 Đang kiểm tra collection: $collectionName');

          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection(collectionName)
              .get();

          print(
            '📊 Collection $collectionName có ${querySnapshot.docs.length} documents',
          );

          if (querySnapshot.docs.isNotEmpty) {
            // Debug: in ra thông tin document đầu tiên
            var firstDoc = querySnapshot.docs.first;
            print('📄 Document đầu tiên: ${firstDoc.id}');

            try {
              var data = firstDoc.data() as Map<String, dynamic>;
              print('🔑 Các fields: ${data.keys.toList()}');
              print('💾 Sample data: $data');

              // Với serviceOrders, coi tất cả documents là đơn nhập
              if (collectionName == 'serviceOrders') {
                totalImportOrders = querySnapshot.docs.length;
                foundCollection = collectionName;
                found = true;
                print(
                  '✅ Tìm thấy $totalImportOrders đơn nhập trong $collectionName',
                );
                break;
              }

              // Kiểm tra xem có phải đơn nhập không cho các collection khác
              bool isImportOrder = false;

              // Nếu collection tên chứa import/nhap thì coi như đơn nhập
              if (collectionName.toLowerCase().contains('import') ||
                  collectionName.toLowerCase().contains('nhap')) {
                isImportOrder = true;
                totalImportOrders = querySnapshot.docs.length;
              }
              // Hoặc kiểm tra field type
              else if (data.containsKey('type')) {
                if (data['type'].toString().toLowerCase().contains('import') ||
                    data['type'].toString().toLowerCase().contains('nhap')) {
                  // Đếm số đơn có type = import
                  var importDocs = querySnapshot.docs.where((doc) {
                    var docData = doc.data() as Map<String, dynamic>;
                    return docData['type'].toString().toLowerCase().contains(
                          'import',
                        ) ||
                        docData['type'].toString().toLowerCase().contains(
                          'nhap',
                        );
                  }).toList();
                  totalImportOrders = importDocs.length;
                  isImportOrder = true;
                }
              }

              if (isImportOrder && totalImportOrders > 0) {
                foundCollection = collectionName;
                found = true;
                print(
                  '✅ Tìm thấy $totalImportOrders đơn nhập trong $collectionName',
                );
                break;
              }
            } catch (e) {
              print('❌ Không thể đọc data từ $collectionName: $e');
            }
          }
        } catch (e) {
          print('❌ Lỗi khi truy cập collection $collectionName: $e');
        }
      }

      setState(() {
        if (found && totalImportOrders > 0) {
          _stockQuantity = '$totalImportOrders đơn nhập';
          print('🎯 Cập nhật UI: $_stockQuantity (từ $foundCollection)');
        } else {
          _stockQuantity = '0 đơn nhập (không tìm thấy)';
          print('🎯 Cập nhật UI: $_stockQuantity');
        }
      });
    } catch (e) {
      print('💥 Error: $e');
      setState(() {
        _stockQuantity = 'Lỗi: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchOtherData() async {
    try {
      print('📊 Đang fetch dữ liệu khác...');

      // Fetch total orders using FirestoreService
      try {
        QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .get();
        print('✅ Tìm thấy ${ordersSnapshot.docs.length} đơn hàng');

        setState(() {
          _totalOrders = '${ordersSnapshot.docs.length}';
        });
      } catch (e) {
        print('❌ Lỗi khi lấy orders: $e');
      }

      // Fetch customer count
      try {
        QuerySnapshot customersSnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .get();
        print('✅ Tìm thấy ${customersSnapshot.docs.length} khách hàng');

        setState(() {
          _customerCount = '${customersSnapshot.docs.length} khách hàng';
        });
      } catch (e) {
        print('❌ Lỗi khi lấy customers: $e');
        // Thử với collection users
        try {
          QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .get();
          setState(() {
            _customerCount = '${usersSnapshot.docs.length} người dùng';
          });
        } catch (e2) {
          print('❌ Lỗi khi lấy users: $e2');
        }
      }

      // Simulate other data (replace with actual Firestore calls when you have the collections)
      setState(() {
        _revenue =
            '125,500,000 VND'; // This should come from order calculations
        _damagedItems =
            '12 sản phẩm'; // This might need specific query for damaged products
        _staffCount =
            '20 nhân viên'; // This might come from users collection with role filter
      });

      print('✅ Hoàn thành fetch dữ liệu khác');
    } catch (e) {
      print('💥 Error fetching other data: $e');
      // Keep default values
    }
  }

  // Method to refresh data manually
  void _refreshData() {
    setState(() {
      _isLoading = true;
      _initializeScreens();
    });
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
