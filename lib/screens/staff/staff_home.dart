import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart'; // Only if you use it for number formatting
import 'package:sonxemaycantho/screens/order/order_content.dart';
import 'package:sonxemaycantho/widgets/navigation_bar.dart';
import '../profile/profile.dart';
import '../../widgets/header.dart';

class StaffHome extends StatefulWidget {
  final String name;
  const StaffHome({super.key, required this.name});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  // Data for staff dashboard - Renamed for clarity based on desired data
  // Ensure these are ALWAYS initialized with a non-null String
  String _totalImportOrders = 'Đang tải...';
  String _totalExportOrders = 'Đang tải...';
  String _totalStockItems = 'Đang tải...';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize screens immediately with loading states
    _initializeScreens();
    // Then start fetching data
    _fetchDashboardData();
  }

  void _initializeScreens() {
    _screens = [
      _StaffDashboardContent(
        totalImportOrders: _totalImportOrders,
        totalExportOrders: _totalExportOrders,
        totalStockItems: _totalStockItems,
        isLoading: _isLoading,
      ),
      const OrderContent(),
      _buildCustomerService(),
      Profile(name: widget.name, role: 'staff'),
    ];
  }

  // Main function to fetch all dashboard data for staff
  void _fetchDashboardData() async {
    print('🚀 Bắt đầu fetch staff dashboard data...');
    setState(() {
      _isLoading = true; // Set loading to true
      _totalImportOrders = 'Đang tải...'; // Reset values to loading state
      _totalExportOrders = 'Đang tải...';
      _totalStockItems = 'Đang tải...';
      _initializeScreens(); // Update screens to show loading states
    });

    try {
      // Fetch Total Import Orders
      await _fetchTotalImportOrders();

      // Fetch Total Export Orders
      await _fetchTotalExportOrders();

      // Fetch Total Stock Items
      await _fetchTotalStockItems();

      if (mounted) {
        setState(() {
          _isLoading = false; // Data loaded
          _initializeScreens(); // Re-initialize screens with new data
        });
        print('✅ Hoàn thành fetch staff dashboard data');
      }
    } catch (e) {
      print('💥 Error fetching staff dashboard data: $e');
      if (mounted) {
        setState(() {
          _totalImportOrders = 'Lỗi tải dữ liệu';
          _totalExportOrders = 'Lỗi tải dữ liệu';
          _totalStockItems = 'Lỗi tải dữ liệu';
          _isLoading = false;
          _initializeScreens(); // Re-initialize screens to show error states
        });
      }
    }
  }

  // New function to fetch total import orders, similar to manager's stock quantity
  Future<void> _fetchTotalImportOrders() async {
    try {
      print('🔍 Bắt đầu fetch dữ liệu tổng đơn nhập...');
      List<String> possibleCollections = [
        'serviceOrders', // Potential existing repair/service orders
        'orders', // General orders
        'import_orders', // Specific import order collection
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
              print('✅ Tìm thấy $totalImports đơn nhập trong $collectionName');
              break; // Found a relevant collection, no need to check others
            } else {
              // Check if documents within the collection have a 'type' field indicating import
              for (var doc in querySnapshot.docs) {
                var data = doc.data() as Map<String, dynamic>;
                if (data.containsKey('type') &&
                    (data['type'].toString().toLowerCase().contains('import') ||
                        data['type'].toString().toLowerCase().contains(
                          'nhap',
                        ))) {
                  totalImports = querySnapshot.docs.length;
                  foundCollection = true;
                  print(
                    '✅ Tìm thấy $totalImports đơn nhập trong $collectionName (qua type field)',
                  );
                  break; // Found a relevant collection, no need to check others
                }
              }
              if (foundCollection)
                break; // If found within this collection, stop
            }
          }
        } catch (e) {
          print('❌ Lỗi khi truy cập collection $collectionName: $e');
        }
      }

      if (mounted) {
        setState(() {
          _totalImportOrders = '$totalImports đơn';
        });
        print('🎯 Cập nhật UI: Tổng đơn nhập: $_totalImportOrders');
      }
    } catch (e) {
      print('💥 Lỗi khi fetch tổng đơn nhập: $e');
      if (mounted) {
        setState(() {
          _totalImportOrders = 'Lỗi tải';
        });
      }
    }
  }

  // New function to fetch total export orders
  Future<void> _fetchTotalExportOrders() async {
    try {
      print('🔍 Bắt đầu fetch dữ liệu tổng đơn xuất...');
      int totalExports = 0;
      List<String> possibleCollections = [
        'export_orders', // Specific export order collection
        'exportOrders',
        'phieu_xuat',
        'don_xuat',
        'stock_exports',
        'sale_orders', // Sales orders often imply exports
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
              print('✅ Tìm thấy $totalExports đơn xuất trong $collectionName');
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
                  print(
                    '✅ Tìm thấy $totalExports đơn xuất trong $collectionName (qua type field)',
                  );
                  break;
                }
              }
              if (foundCollection) break;
            }
          }
        } catch (e) {
          print('❌ Lỗi khi truy cập collection $collectionName: $e');
        }
      }

      if (mounted) {
        setState(() {
          _totalExportOrders = '$totalExports đơn';
        });
        print('🎯 Cập nhật UI: Tổng đơn xuất: $_totalExportOrders');
      }
    } catch (e) {
      print('💥 Lỗi khi fetch tổng đơn xuất: $e');
      if (mounted) {
        setState(() {
          _totalExportOrders = 'Lỗi tải';
        });
      }
    }
  }

  // New function to fetch total items in stock (sum of quantities from 'parts' or 'products')
  Future<void> _fetchTotalStockItems() async {
    try {
      print('🔍 Bắt đầu fetch dữ liệu tổng tồn kho...');
      int totalItems = 0;
      List<String> possibleCollections = [
        'parts',
        'products',
        'inventory',
      ]; // Common collections for stock

      // Flag to indicate if any stock data was found and processed
      for (String collectionName in possibleCollections) {
        try {
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection(collectionName)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            for (var doc in querySnapshot.docs) {
              var data = doc.data() as Map<String, dynamic>;
              // Try to find a quantity-like field
              int itemQuantity = 0;
              if (data.containsKey('quantity')) {
                itemQuantity = (data['quantity'] as num?)?.toInt() ?? 0;
              } else if (data.containsKey('stock')) {
                itemQuantity = (data['stock'] as num?)?.toInt() ?? 0;
              } else if (data.containsKey('amount')) {
                itemQuantity = (data['amount'] as num?)?.toInt() ?? 0;
              }
              totalItems += itemQuantity;
            }
            // If we found any documents in a collection, consider it found and stop
            // Even if totalItems is 0, it means we checked this collection and it's empty or has no quantity
            // This prevents iterating through unnecessary collections if a primary one is found
            if (querySnapshot.docs.isNotEmpty) {
              print(
                '✅ Tổng số $totalItems mặt hàng tồn kho từ $collectionName',
              );
              break; // Assuming one collection holds the primary stock data
            }
          }
        } catch (e) {
          print(
            '❌ Lỗi khi truy cập collection $collectionName để lấy tồn kho: $e',
          );
        }
      }

      if (mounted) {
        setState(() {
          _totalStockItems = '$totalItems sản phẩm';
        });
        print('🎯 Cập nhật UI: Tổng tồn kho: $_totalStockItems');
      }
    } catch (e) {
      print('💥 Lỗi khi fetch tổng tồn kho: $e');
      if (mounted) {
        setState(() {
          _totalStockItems = 'Lỗi tải';
        });
      }
    }
  }

  void _refreshData() {
    setState(() {
      _isLoading = true;
      _totalImportOrders = 'Đang tải...';
      _totalExportOrders = 'Đang tải...';
      _totalStockItems = 'Đang tải...';
      _initializeScreens(); // Re-initialize screens to show loading state on refresh
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
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildCustomerService() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chăm sóc khách hàng',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tính năng đang được phát triển',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- _StaffDashboardContent Widget (Updated parameters and titles) ---
class _StaffDashboardContent extends StatelessWidget {
  // Ensure these parameters are consistently named and non-null
  final String totalImportOrders;
  final String totalExportOrders;
  final String totalStockItems;
  final bool isLoading;

  const _StaffDashboardContent({
    required this.totalImportOrders,
    required this.totalExportOrders,
    required this.totalStockItems,
    this.isLoading =
        false, // Default to false if not provided, but it's usually provided by parent
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
          'Tổng tồn kho:', // Changed from 'Tổn đơn tồn kho' to 'Tổng tồn kho' for clarity
          totalStockItems,
          Icons.inventory_2,
          const Color(0xFFFFEBEE),
          showLoading: isLoading && totalStockItems == 'Đang tải...',
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
