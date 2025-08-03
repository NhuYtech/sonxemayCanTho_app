// lib/screens/inventory/stock_order.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/service_order.dart';

class StockOrder extends StatefulWidget {
  const StockOrder({super.key});

  @override
  State<StockOrder> createState() => _StockOrderState();
}

class _StockOrderState extends State<StockOrder> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách đơn tồn kho',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('serviceOrders')
            .where('status', whereIn: ['Đã nhận', 'Đang sơn', 'Đã sơn xong'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Không có đơn hàng tồn kho nào.'));
          }

          final List<ServiceOrder> orders = snapshot.data!.docs.map((doc) {
            return ServiceOrder.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              // Xác định màu sắc cho trạng thái
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
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    // Hành động khi nhấn vào card, ví dụ xem chi tiết đơn hàng
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cửa hàng: ${order.storeName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC1473B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ngày gửi: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createDate)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Trạng thái: ${order.status}',
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
