import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sonxemaycantho/screens/chat.dart';
import 'package:sonxemaycantho/widgets/navigation_bar.dart';
import '../profile.dart'; // CommonProfile
import '../order.dart'; // ManagerOrder (giả định)
import 'customer_support/chat_list.dart'; // Đã thay đổi import này để trỏ đến ChatListScreen
import '../../widgets/header.dart'; // Header
import '../../widgets/navigation_bar.dart'; // Import BottomNavBar mới
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
  String _revenue = 'Đang tải...'; // Changed to loading state
  String _totalOrders = 'Đang tải...'; // Changed to loading state
  String _stockQuantity = 'Đang tải...'; // Changed default value
  String _damagedItems = 'Đang tải...'; // Changed to loading state
  String _customerCount = 'Đang tải...'; // Changed to loading state
  String _staffCount = 'Đang tải...'; // Changed to loading state

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
      ChatList(managerName: widget.name),
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
        _revenue = 'Lỗi tải dữ liệu: $e';
        _totalOrders = 'Lỗi tải dữ liệu: $e';
        _damagedItems = 'Lỗi tải dữ liệu: $e';
        _customerCount = 'Lỗi tải dữ liệu: $e';
        _staffCount = 'Lỗi tải dữ liệu: $e';
        _isLoading = false;
        _initializeScreens();
      });
    }
  }

  Future<void> _fetchStockQuantity() async {
    try {
      print('🔍 Bắt đầu fetch dữ liệu đơn nhập...');

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
            var firstDoc = querySnapshot.docs.first;
            print('📄 Document đầu tiên: ${firstDoc.id}');

            try {
              var data = firstDoc.data() as Map<String, dynamic>;
              print('🔑 Các fields: ${data.keys.toList()}');
              print('💾 Sample data: $data');

              if (collectionName == 'serviceOrders') {
                totalImportOrders = querySnapshot.docs.length;
                foundCollection = collectionName;
                found = true;
                print(
                  '✅ Tìm thấy $totalImportOrders đơn nhập trong $collectionName',
                );
                break;
              }

              bool isImportOrder = false;

              if (collectionName.toLowerCase().contains('import') ||
                  collectionName.toLowerCase().contains('nhap')) {
                isImportOrder = true;
                totalImportOrders = querySnapshot.docs.length;
              } else if (data.containsKey('type')) {
                if (data['type'].toString().toLowerCase().contains('import') ||
                    data['type'].toString().toLowerCase().contains('nhap')) {
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

      // Fetch total export orders from 'exportOrders' collection
      try {
        QuerySnapshot exportOrdersSnapshot = await FirebaseFirestore.instance
            .collection('exportOrders')
            .get();
        print('✅ Tìm thấy ${exportOrdersSnapshot.docs.length} đơn xuất');

        setState(() {
          _totalOrders = '${exportOrdersSnapshot.docs.length} đơn xuất';
        });
      } catch (e) {
        print('❌ Lỗi khi lấy export orders: $e');
        setState(() {
          _totalOrders = 'Lỗi tải';
        });
      }

      // Fetch revenue from 'exportOrders'
      try {
        QuerySnapshot exportOrdersSnapshot = await FirebaseFirestore.instance
            .collection('exportOrders')
            .get();
        double totalRevenue = 0;
        for (var doc in exportOrdersSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          // Giả định mỗi đơn xuất có 'quantity' và 'pricePerItem'
          // Hoặc bạn có thể có một trường 'totalAmount' trực tiếp trong exportOrders
          int quantity = (data['quantity'] as num?)?.toInt() ?? 0;
          // Để tính doanh thu thực tế, bạn cần giá của sản phẩm.
          // Ví dụ: lấy giá từ serviceOrder hoặc có một trường giá trực tiếp.
          // Hiện tại, giả định một giá cố định cho mỗi đơn vị nếu không có trường giá.
          // Hoặc nếu có trường 'totalAmount' trong exportOrders, hãy dùng nó.
          double itemPrice =
              100000; // GIÁ TRỊ GIẢ ĐỊNH: Cần thay bằng giá thực tế từ Firebase

          // Nếu có trường 'totalAmount' trong exportOrders, hãy sử dụng nó
          // Ví dụ: double orderTotal = (data['totalAmount'] as num?)?.toDouble() ?? 0;
          // totalRevenue += orderTotal;

          totalRevenue += (quantity * itemPrice); // Tính toán dựa trên giả định
        }

        setState(() {
          // Định dạng số tiền
          final formatter = NumberFormat(
            '#,##0',
            'vi_VN',
          ); // Định dạng tiền Việt Nam
          _revenue = '${formatter.format(totalRevenue)} VND';
          print('🎯 Cập nhật UI: Doanh thu: $_revenue');
        });
      } catch (e) {
        print('❌ Lỗi khi tính doanh thu từ export orders: $e');
        setState(() {
          _revenue = 'Lỗi tải';
        });
      }

      // Fetch damaged items count
      try {
        QuerySnapshot damagedItemsSnapshot = await FirebaseFirestore.instance
            .collection('damagedItems') // Thử collection 'damagedItems'
            .get();
        int count = damagedItemsSnapshot.docs.length;
        if (count == 0) {
          // Fallback: Check 'products' or 'inventory' collection for 'damaged' status
          QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
              .collection('products') // Hoặc 'inventory'
              .where(
                'status',
                isEqualTo: 'damaged',
              ) // Giả định có trường 'status'
              .get();
          count = productsSnapshot.docs.length;
        }
        setState(() {
          _damagedItems = '$count sản phẩm';
          print('🎯 Cập nhật UI: Hàng hư hỏng: $_damagedItems');
        });
      } catch (e) {
        print('❌ Lỗi khi lấy hàng hư hỏng: $e');
        setState(() {
          _damagedItems = 'Lỗi tải';
        });
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
        // Try with 'users' collection as fallback
        try {
          QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .get();
          setState(() {
            _customerCount = '${usersSnapshot.docs.length} người dùng';
          });
        } catch (e2) {
          print('❌ Lỗi khi lấy users: $e2');
          setState(() {
            _customerCount = 'Lỗi tải';
          });
        }
      }

      // Fetch staff count
      try {
        QuerySnapshot staffSnapshot = await FirebaseFirestore.instance
            .collection(
              'users',
            ) // Giả định nhân viên nằm trong collection 'users'
            .where('role', isEqualTo: 'staff') // Lọc theo vai trò 'staff'
            .get();
        // Bạn có thể thêm các vai trò khác nếu có, ví dụ: .where(FieldPath.documentId, whereIn: ['staff', 'manager'])
        setState(() {
          _staffCount = '${staffSnapshot.docs.length} nhân viên';
          print('🎯 Cập nhật UI: Danh sách nhân viên: $_staffCount');
        });
      } catch (e) {
        print('❌ Lỗi khi lấy danh sách nhân viên: $e');
        setState(() {
          _staffCount = 'Lỗi tải';
        });
      }

      print('✅ Hoàn thành fetch dữ liệu khác');
    } catch (e) {
      print('💥 Error fetching other data: $e');
      // Keep default values or set to error
    }
  }

  // Method to refresh data manually
  void _refreshData() {
    setState(() {
      _isLoading = true;
      _revenue = 'Đang tải...';
      _totalOrders = 'Đang tải...';
      _stockQuantity = 'Đang tải...';
      _damagedItems = 'Đang tải...';
      _customerCount = 'Đang tải...';
      _staffCount = 'Đang tải...';
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
      bottomNavigationBar: BottomNavBar(
        // Sử dụng BottomNavBar mới
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
