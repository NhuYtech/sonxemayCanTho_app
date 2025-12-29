import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sonxemaycantho/models/service_order.dart';

class ExportOrder extends StatefulWidget {
  const ExportOrder({super.key});

  @override
  State<ExportOrder> createState() => _ExportOrderState();
}

class _ExportOrderState extends State<ExportOrder> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _customerStoreNameController =
      TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _serviceOrderIdController =
      TextEditingController();
  final TextEditingController _createdByController = TextEditingController();

  DateTime? _selectedExportDate;
  bool _isAddingOrder = false;
  List<DocumentSnapshot> _serviceOrders = [];

  @override
  void initState() {
    super.initState();
    _loadServiceOrders();
  }

  @override
  void dispose() {
    _customerStoreNameController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    _serviceOrderIdController.dispose();
    _createdByController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceOrders() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('serviceOrders')
          .where('status', isEqualTo: 'Đã sơn xong')
          .get();
      setState(() {
        _serviceOrders = snapshot.docs;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching service orders: $e');
      }
    }
  }

  Future<void> _calculateAndFillQuantity(String serviceOrderId) async {
    try {
      QuerySnapshot itemSnapshot = await _firestore
          .collection('serviceOrderItems')
          .where('serviceOrderId', isEqualTo: serviceOrderId)
          .get();

      int totalQuantity = 0;
      for (var doc in itemSnapshot.docs) {
        totalQuantity +=
            (doc.data() as Map<String, dynamic>)['quantity'] as int;
      }
      setState(() {
        _quantityController.text = totalQuantity.toString();
      });
    } catch (e) {
      setState(() {
        _quantityController.text = '0';
      });
    }
  }

  void _showServiceOrderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn đơn đã hoàn thành'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _serviceOrders.isEmpty
                ? const Center(child: Text('Không có đơn nhập đã hoàn thành'))
                : ListView.builder(
                    itemCount: _serviceOrders.length,
                    itemBuilder: (context, index) {
                      var order = _serviceOrders[index];
                      var data = order.data() as Map<String, dynamic>;

                      ServiceOrder selectedOrder = ServiceOrder.fromMap(
                        data,
                        order.id,
                      );

                      return ListTile(
                        title: Text('ID: ${order.id}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cửa hàng: ${data['storeName'] ?? 'N/A'}'),
                            Text(
                              'Ngày nhập: ${DateFormat('dd/MM/yyyy').format((data['createDate'] as Timestamp).toDate())}',
                            ),
                            Text('Trạng thái: ${data['status'] ?? 'N/A'}'),
                          ],
                        ),
                        onTap: () {
                          _serviceOrderIdController.text = order.id;
                          _customerStoreNameController.text =
                              selectedOrder.storeName;
                          _noteController.text = selectedOrder.note ?? '';

                          _calculateAndFillQuantity(order.id);

                          Navigator.pop(context);
                        },
                      );
                    },
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

  void _showAddExportOrderForm() {
    _clearForm();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Thêm Đơn Xuất Mới',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serviceOrderIdController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Mã đơn nhập',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _showServiceOrderDialog,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn một đơn nhập';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customerStoreNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên cửa hàng',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false, // Tên cửa hàng tự động điền
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng xe',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false, // Số lượng tự động điền
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        _selectedExportDate == null
                            ? 'Chọn ngày xuất'
                            : 'Ngày xuất: ${DateFormat('dd/MM/yyyy').format(_selectedExportDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedExportDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          modalSetState(() {
                            // Update the state of the modal
                            _selectedExportDate = pickedDate;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _createdByController,
                      decoration: const InputDecoration(
                        labelText: 'Người tạo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isAddingOrder ? null : _addExportOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC1473B),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Thêm Đơn Xuất'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        _isAddingOrder = false;
      });
    });
  }

  /// Thêm đơn xuất vào Firestore và cập nhật trạng thái đơn nhập gốc.
  Future<void> _addExportOrder() async {
    if (_selectedExportDate == null ||
        _serviceOrderIdController.text.isEmpty ||
        _createdByController.text.isEmpty) {
      _showSnackBar('Vui lòng điền đủ thông tin bắt buộc!', Colors.red);
      return;
    }

    setState(() {
      _isAddingOrder = true;
    });

    try {
      // Kiểm tra xem serviceOrderId có tồn tại không
      final serviceOrderRef = _firestore
          .collection('serviceOrders')
          .doc(_serviceOrderIdController.text);
      final serviceOrderDoc = await serviceOrderRef.get();
      if (!serviceOrderDoc.exists) {
        throw Exception('Mã đơn nhập không tồn tại.');
      }

      final quantity = int.tryParse(_quantityController.text);
      if (quantity == null || quantity <= 0) {
        throw Exception('Số lượng không hợp lệ.');
      }

      await _firestore
          .collection('serviceOrders')
          .doc(_serviceOrderIdController.text.trim())
          .update({'status': 'Đã gửi'});

      _clearForm();
      _showSnackBar('✅ Đơn xuất đã được thêm thành công!', Colors.green);
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Đóng modal bottom sheet
    } catch (e) {
      _showSnackBar('❌ Lỗi khi thêm đơn xuất: $e', Colors.red);
    } finally {
      setState(() {
        _isAddingOrder = false;
      });
    }
  }

  /// Xóa dữ liệu trong các trường của form.
  void _clearForm() {
    _customerStoreNameController.clear();
    _quantityController.clear();
    _noteController.clear();
    _serviceOrderIdController.clear();
    _createdByController.clear();
    _selectedExportDate = null;
  }

  /// Hiển thị thông báo ngắn.
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  /// Hiển thị chi tiết của một đơn xuất trong một hộp thoại.
  void _showExportOrderDetail(DocumentSnapshot exportOrder) {
    final data = exportOrder.data() as Map<String, dynamic>;
    final exportDate = (data['exportDate'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chi tiết đơn xuất'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Mã đơn xuất', exportOrder.id),
                _buildDetailRow(
                  'Ngày xuất',
                  DateFormat('dd/MM/yyyy').format(exportDate),
                ),
                _buildDetailRow('Cửa hàng', data['customerStoreName'] ?? 'N/A'),
                _buildDetailRow('Số lượng', data['quantity'].toString()),
                _buildDetailRow('Đơn dịch vụ', data['serviceOrderId'] ?? 'N/A'),
                _buildDetailRow('Người tạo', data['createdBy'] ?? 'N/A'),
                _buildDetailRow('Ghi chú', data['note'] ?? 'Không có'),
                _buildDetailRow(
                  'Ngày tạo',
                  DateFormat(
                    'dd/MM/yyyy HH:mm:ss',
                  ).format((data['createdAt'] as Timestamp).toDate()),
                ),
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
          'Danh sách đơn xuất',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('exportOrders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return const Center(child: Text('Chưa có đơn xuất nào.'));
          }

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final data = doc.data() as Map<String, dynamic>;
              final exportDate = (data['exportDate'] as Timestamp).toDate();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CẬP NHẬT: Hiển thị mã đơn xuất
                      Text(
                        'Mã đơn xuất: ${doc.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFFC1473B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ngày xuất: ${DateFormat('dd/MM/yyyy').format(exportDate)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color.fromARGB(255, 10, 10, 10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Cửa hàng: ${data['customerStoreName'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.note_alt,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ghi chú: ${data['note'] ?? 'Không có'}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.format_list_numbered,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Số lượng: ${data['quantity'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.link, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Mã đơn nhập: ${data['serviceOrderId'] ?? 'N/A'}',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                decoration: TextDecoration.none,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Người tạo: ${data['createdBy'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () => _showExportOrderDetail(doc),
                          child: const Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              color: Color.fromARGB(255, 71, 200, 216),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExportOrderForm,
        backgroundColor: const Color(0xFFC1473B),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
