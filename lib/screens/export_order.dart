// lib/screens/manager/export_order.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
          .get();
      setState(() {
        _serviceOrders = snapshot.docs;
      });
      print('📋 Đã load ${_serviceOrders.length} service orders');
    } catch (e) {
      print('❌ Lỗi load service orders: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExportDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFC1473B),
            colorScheme: const ColorScheme.light(primary: Color(0xFFC1473B)),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedExportDate) {
      setState(() {
        _selectedExportDate = picked;
      });
    }
  }

  Future<bool> _validateServiceOrder(String serviceOrderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('serviceOrders')
          .doc(serviceOrderId)
          .get();
      return doc.exists;
    } catch (e) {
      print('❌ Lỗi validate service order: $e');
      return false;
    }
  }

  Future<void> _addExportOrder() async {
    if (_customerStoreNameController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty ||
        _selectedExportDate == null ||
        _serviceOrderIdController.text.trim().isEmpty ||
        _createdByController.text.trim().isEmpty) {
      _showSnackBar('❌ Vui lòng điền đầy đủ thông tin.', Colors.red);
      return;
    }

    int? quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showSnackBar(
        '❌ Số lượng phải là số nguyên dương lớn hơn 0.',
        Colors.red,
      );
      return;
    }

    setState(() {
      _isAddingOrder = true;
    });

    try {
      bool serviceOrderExists = await _validateServiceOrder(
        _serviceOrderIdController.text.trim(),
      );
      if (!serviceOrderExists) {
        _showSnackBar('❌ Mã đơn dịch vụ không tồn tại.', Colors.red);
        setState(() {
          _isAddingOrder = false;
        });
        return;
      }

      DocumentReference docRef = await _firestore
          .collection('exportOrders')
          .add({
            'customerStoreName': _customerStoreNameController.text.trim(),
            'exportDate': Timestamp.fromDate(_selectedExportDate!),
            'note': _noteController.text.trim().isEmpty
                ? ''
                : _noteController.text.trim(),
            'quantity': quantity,
            'serviceOrderId': _serviceOrderIdController.text.trim(),
            'createdBy': _createdByController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      print('✅ Đã tạo export order: ${docRef.id}');

      _clearForm();

      _showSnackBar('✅ Đơn xuất đã được thêm thành công!', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      print('❌ Lỗi khi thêm đơn xuất: $e');
      _showSnackBar('❌ Lỗi khi thêm đơn xuất: $e', Colors.red);
    } finally {
      setState(() {
        _isAddingOrder = false;
      });
    }
  }

  void _clearForm() {
    _customerStoreNameController.clear();
    _quantityController.clear();
    _noteController.clear();
    _serviceOrderIdController.clear();
    _createdByController.clear();
    setState(() {
      _selectedExportDate = null;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showServiceOrderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn Đơn Dịch Vụ'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _serviceOrders.isEmpty
                ? const Center(child: Text('Không có đơn dịch vụ nào'))
                : ListView.builder(
                    itemCount: _serviceOrders.length,
                    itemBuilder: (context, index) {
                      var order = _serviceOrders[index];
                      var data = order.data() as Map<String, dynamic>;

                      return ListTile(
                        title: Text('ID: ${order.id}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Khách hàng: ${data['customerName'] ?? 'N/A'}',
                            ),
                            Text('Trạng thái: ${data['status'] ?? 'N/A'}'),
                          ],
                        ),
                        onTap: () {
                          _serviceOrderIdController.text = order.id;
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Thêm Đơn Xuất',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC1473B),
                          ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _customerStoreNameController,
                      decoration: InputDecoration(
                        labelText: 'Tên cửa hàng',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () async {
                        await _selectDate(context);
                        setModalState(() {});
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: _selectedExportDate == null
                                ? 'Chọn ngày xuất'
                                : 'Ngày Xuất: ${DateFormat('dd/MM/yyyy').format(_selectedExportDate!)}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số lượng',
                        hintText: 'Nhập số lượng (>0)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      onChanged: (value) {
                        int? qty = int.tryParse(value);
                        if (qty != null && qty <= 0) {
                          setModalState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú (nếu có)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.note_alt),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _serviceOrderIdController,
                            decoration: InputDecoration(
                              labelText: 'Mã đơn nhập',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.receipt_long),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _showServiceOrderDialog,
                          icon: const Icon(Icons.search),
                          tooltip: 'Chọn từ danh sách',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: _createdByController,
                      decoration: InputDecoration(
                        labelText: 'Người tạo đơn',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _isAddingOrder ? null : _addExportOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC1473B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: _isAddingOrder
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Thêm Đơn Xuất',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Đơn Xuất',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('exportOrders')
            .orderBy('exportDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('❌ Lỗi: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC1473B)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có đơn xuất nào.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;

              String exportDate = 'N/A';
              if (data['exportDate'] is Timestamp) {
                exportDate = DateFormat(
                  'dd/MM/yyyy',
                ).format(data['exportDate'].toDate());
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '🏪 ${data['customerStoreName'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFFC1473B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ngày xuất: $exportDate',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2,
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
                      if (data['note'] != null &&
                          data['note'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.note_alt,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Ghi chú: ${data['note']}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Đơn dịch vụ: ${data['serviceOrderId'] ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
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
