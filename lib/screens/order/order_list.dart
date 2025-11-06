// lib/screens/order/order_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../models/service_order.dart'; // Import ServiceOrder model
import 'order_entry.dart'; // Import màn hình OrderEntry để thêm mới
import 'edit_order.dart'; // Import màn hình EditOrder để chỉnh sửa

class OrderList extends StatefulWidget {
  const OrderList({super.key});

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hiển thị chi tiết của một đơn nhập trong một hộp thoại.
  void _showOrderDetail(ServiceOrder order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chi Tiết Đơn Nhập'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Mã đơn hàng', order.id!),
                _buildDetailRow(
                  'Ngày gửi',
                  DateFormat('dd/MM/yyyy HH:mm').format(order.createDate),
                ),
                _buildDetailRow('Cửa hàng', order.storeName),
                _buildDetailRow('Trạng thái', order.status),
                _buildDetailRow('Ghi chú chung', order.note ?? 'Không có'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  /// Điều hướng đến màn hình EditOrder để chỉnh sửa đơn hàng đã chọn.
  void _editOrder(ServiceOrder order) {
    // Kiểm tra nếu đơn hàng đã gửi thì không được chỉnh sửa nữa
    if (order.status == 'Đã gửi') {
      _showAlertDialog(
        title: 'Không thể chỉnh sửa',
        content: 'Đơn hàng đã được gửi đi, không thể chỉnh sửa nữa.',
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          // Chuyển đối tượng ServiceOrder sang màn hình EditOrder
          builder: (context) => EditOrder(serviceOrder: order),
        ),
      );
    }
  }

  /// Hàm phụ trợ để hiển thị hộp thoại thông báo.
  void _showAlertDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // A helper method to build a detail row with a label and value.
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách đơn nhập',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('serviceOrders')
            .orderBy('createDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có đơn hàng nào được nhập.'));
          }

          // Convert QuerySnapshot to a list of ServiceOrder objects
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
                case 'Đã gửi': // Trạng thái mới
                  statusColor = Colors.deepPurple;
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
                    // Hiển thị chi tiết đơn hàng khi nhấn vào card
                    _showOrderDetail(order);
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
                        if (order.note != null && order.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Ghi chú chung: ${order.note}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _showOrderDetail(order);
                                },
                                child: const Text(
                                  'Xem chi tiết',
                                  style: TextStyle(
                                    color: Color(0xFFC1473B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  // Kiểm tra trước khi chỉnh sửa
                                  _editOrder(order);
                                },
                                child: const Text(
                                  'Chỉnh sửa',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Điều hướng đến màn hình OrderEntry để thêm mới đơn hàng
          Navigator.push(
            context,
            MaterialPageRoute(
              // Truyền null cho orderToEdit để báo hiệu là thêm mới
              builder: (context) => const OrderEntry(orderToEdit: null),
            ),
          );
        },
        backgroundColor: const Color(0xFFC1473B),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
