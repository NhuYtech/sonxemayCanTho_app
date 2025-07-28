// lib/screens/manager/export_order.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class ExportOrder extends StatefulWidget {
  const ExportOrder({super.key});

  @override
  State<ExportOrder> createState() => _ExportOrderState();
}

class _ExportOrderState extends State<ExportOrder> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for the form fields
  final TextEditingController _customerStoreNameController =
      TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _serviceOrderIdController =
      TextEditingController();
  DateTime? _selectedExportDate;
  final TextEditingController _createdByController =
      TextEditingController(); // For demo purposes, replace with actual user ID

  bool _isAddingOrder = false; // To show loading indicator on add button

  @override
  void dispose() {
    _customerStoreNameController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    _serviceOrderIdController.dispose();
    _createdByController.dispose();
    super.dispose();
  }

  // Function to pick a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExportDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFFC1473B), // Header background color
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC1473B),
            ), // Selected day color
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

  // Function to add a new export order to Firestore
  Future<void> _addExportOrder() async {
    if (_customerStoreNameController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _selectedExportDate == null ||
        _serviceOrderIdController.text.isEmpty ||
        _createdByController.text.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin.', Colors.red);
      return;
    }

    setState(() {
      _isAddingOrder = true;
    });

    try {
      await _firestore.collection('exportOrders').add({
        'customerStoreName': _customerStoreNameController.text.trim(),
        'exportDate': Timestamp.fromDate(_selectedExportDate!),
        'note': _noteController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
        'serviceOrderId': _serviceOrderIdController.text.trim(),
        'createdBy': _createdByController.text
            .trim(), // In a real app, this would come from FirebaseAuth.currentUser.uid
      });

      // Clear form fields
      _customerStoreNameController.clear();
      _quantityController.clear();
      _noteController.clear();
      _serviceOrderIdController.clear();
      _createdByController.clear();
      setState(() {
        _selectedExportDate = null;
      });

      _showSnackBar('Đơn xuất đã được thêm thành công!', Colors.green);
      Navigator.pop(context); // Close the dialog/bottom sheet
    } catch (e) {
      _showSnackBar('Lỗi khi thêm đơn xuất: $e', Colors.red);
    } finally {
      setState(() {
        _isAddingOrder = false;
      });
    }
  }

  // Function to show a SnackBar message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // Function to show the add export order form
  void _showAddExportOrderForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height
      builder: (context) {
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
                  'Thêm Đơn Xuất Mới',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(
                      0xFFC1473B,
                    ), // Matching OrderEntry title color
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _customerStoreNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên Khách Hàng/Cửa Hàng',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                    ),
                    prefixIcon: const Icon(Icons.store), // Icon
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: _selectedExportDate == null
                            ? 'Chọn Ngày Xuất'
                            : 'Ngày Xuất: ${DateFormat('dd/MM/yyyy').format(_selectedExportDate!)}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // Rounded corners
                        ),
                        prefixIcon: const Icon(Icons.calendar_today), // Icon
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số Lượng',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                    ),
                    prefixIcon: const Icon(Icons.numbers), // Icon
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Ghi Chú',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                    ),
                    prefixIcon: const Icon(Icons.note_alt), // Icon
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _serviceOrderIdController,
                  decoration: InputDecoration(
                    labelText: 'ID Đơn Dịch Vụ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                    ),
                    prefixIcon: const Icon(Icons.receipt_long), // Icon
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _createdByController,
                  decoration: InputDecoration(
                    labelText: 'Người Tạo (ID)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                    ),
                    prefixIcon: const Icon(Icons.person), // Icon
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isAddingOrder ? null : _addExportOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFC1473B,
                    ), // Matching OrderEntry button color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded button
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Đơn Xuất',
          style: TextStyle(
            color: Colors.white,
          ), // Matching OrderEntry title color
        ),
        backgroundColor: const Color(
          0xFFC1473B,
        ), // Matching OrderEntry app bar color
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Matching OrderEntry icon color
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('exportOrders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có đơn xuất nào.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0), // Consistent padding
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;

              // Format exportDate
              String exportDate = 'N/A';
              if (data['exportDate'] is Timestamp) {
                exportDate = DateFormat(
                  'dd/MM/yyyy',
                ).format(data['exportDate'].toDate());
              }

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 16.0,
                ), // Consistent margin
                elevation: 3, // Matching OrderEntry card elevation
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    15,
                  ), // Matching OrderEntry card radius
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cửa hàng: ${data['customerStoreName'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(
                            0xFFC1473B,
                          ), // Matching OrderEntry title color
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ngày xuất: $exportDate',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Số lượng: ${data['quantity'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Ghi chú: ${data['note'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'ID Đơn dịch vụ: ${data['serviceOrderId'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Người tạo: ${data['createdBy'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
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
        backgroundColor: const Color(
          0xFFC1473B,
        ), // Matching OrderEntry button color
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
