// lib/screens/customer/customer_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/service_order.dart';

class CustomerOrderList extends StatefulWidget {
  const CustomerOrderList({super.key});

  @override
  State<CustomerOrderList> createState() => _CustomerOrderListState();
}

class _CustomerOrderListState extends State<CustomerOrderList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userStoreName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStoreName();
  }

  Future<void> _loadUserStoreName() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userStoreName = userDoc.data()?['storeName'];
          _isLoading = false;
        });
        // Dòng này để bạn kiểm tra trong console xem tên cửa hàng đã được lấy chưa
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Phương thức xác nhận đã nhận hàng
  void _confirmReceived(BuildContext context, ServiceOrder order) async {
    try {
      await FirebaseFirestore.instance
          .collection('serviceOrders')
          .doc(order.id)
          .update({'status': 'Đã nhận'});
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận nhận hàng thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xác nhận: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đơn hàng của bạn',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userStoreName == null
          ? const Center(child: Text('Không tìm thấy tên cửa hàng của bạn.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('serviceOrders')
                  .where(
                    'storeName',
                    isEqualTo: _userStoreName,
                  ) // DÒNG LỌC ĐƠN HÀNG QUAN TRỌNG
                  .orderBy('createDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bạn chưa có đơn hàng nào.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final orders = snapshot.data!.docs.map((doc) {
                  return ServiceOrder.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                return Column(
                  children: [
                    // Thống kê tổng số đơn hàng
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.list_alt,
                                color: Color(0xFFC1473B),
                                size: 30,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Tổng số đơn hàng: ${orders.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC1473B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Danh sách đơn hàng chi tiết
                    Expanded(
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          Color statusColor;
                          switch (order.status) {
                            case 'Đã nhận':
                              statusColor = Colors.orange;
                              break;
                            case 'Đang sơn':
                              statusColor = Colors.blue;
                              break;
                            case 'Đã sơn xong':
                              statusColor = Colors.green;
                              break;
                            case 'Đã gửi':
                              statusColor = Colors.purple;
                              break;
                            default:
                              statusColor = Colors.grey;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                'Đơn hàng: ${order.storeName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(order.createDate)}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Text('Trạng thái: '),
                                      Text(
                                        order.status,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: order.status == 'Đã sơn xong'
                                  ? ElevatedButton(
                                      onPressed: () =>
                                          _confirmReceived(context, order),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Đã nhận hàng'),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
