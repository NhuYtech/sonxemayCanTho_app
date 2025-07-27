// lib/screens/order_entry_screen.dart
import 'package:flutter/material.dart';
// For date formatting
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sonxemaycantho/models/service_order.dart'; // Import ServiceOrder and ServiceOrderItem models

class OrderEntry extends StatefulWidget {
  // Renamed from OrderEntry to OrderEntry for consistency
  const OrderEntry({super.key});

  @override
  State<OrderEntry> createState() => _OrderEntryState();
}

class _OrderEntryState extends State<OrderEntry> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _generalNoteController = TextEditingController();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List to hold ServiceOrderItems for the current order being entered
  List<ServiceOrderItem> _orderItems = [];

  // State to manage loading indicator
  bool _isLoading = false;

  // List of available car models for the dropdown
  final List<String> _carModels = [
    'Vision',
    'Future 125',
    'Scoopy',
    'Exciter',
    'Wave Alpha',
    'Sirius',
    'Vario',
    'SH Mode',
  ];

  // List of available colors for the dropdown
  // final List<String> _carColors = [
  //   'Đỏ',
  //   'Xanh',
  //   'Trắng',
  //   'Đen',
  //   'Bạc',
  //   'Vàng',
  //   'Cam',
  //   'Hồng',
  //   'Nâu',
  //   'Xám Titan',
  //   'Khác',
  // ];

  @override
  void initState() {
    super.initState();
    // Initialize with one empty item for convenience, quantity now defaults to 0, and default color
    _orderItems.add(
      ServiceOrderItem(
        carModel: _carModels.first,
        quantity: 0,
        color: '', // Default color
      ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _generalNoteController.dispose();
    super.dispose();
  }

  // Function to add a new ServiceOrderItem row to the form
  void _addOrderItem() {
    setState(() {
      _orderItems.add(
        ServiceOrderItem(
          carModel: _carModels.first,
          quantity: 0,
          color: '', // Default color for new item
        ),
      );
    });
  }

  // Function to remove a ServiceOrderItem row from the form
  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  // Function to handle form submission
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is not valid
    }

    _formKey.currentState!.save(); // Save all form fields

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // 1. Create the ServiceOrder object
      final newOrder = ServiceOrder(
        storeName: _storeNameController.text.trim(),
        createDate: DateTime.now(),
        note: _generalNoteController.text.trim().isEmpty
            ? null
            : _generalNoteController.text.trim(),
        status: 'Chưa kiểm', // Default status for new orders
      );

      // 2. Add the ServiceOrder to Firestore
      // Using .add() for auto-generated ID
      DocumentReference orderRef = await _firestore
          .collection('serviceOrders')
          .add(newOrder.toMap());
      newOrder.id = orderRef.id; // Get the auto-generated ID

      // 3. Add each ServiceOrderItem to Firestore, linking to the parent order
      for (var item in _orderItems) {
        item.serviceOrderId = newOrder.id; // Link item to the new order's ID
        await _firestore.collection('serviceOrderItems').add(item.toMap());
      }

      // Show success confirmation dialog
      _showConfirmationDialog(
        title: 'Tạo đơn hàng thành công!',
        content: 'Đơn hàng của bạn đã được ghi nhận vào hệ thống.',
        isSuccess: true,
      );

      // Optionally clear the form or navigate away after successful submission
      _storeNameController.clear();
      _generalNoteController.clear();
      setState(() {
        _orderItems = [
          ServiceOrderItem(
            carModel: _carModels.first,
            quantity: 0,
            color: '', // Reset items, quantity to 0, default color
          ),
        ];
      });
    } catch (e) {
      print('Lỗi khi tạo đơn hàng: $e');
      // Show error dialog
      _showConfirmationDialog(
        title: 'Lỗi!',
        content: 'Đã xảy ra lỗi khi tạo đơn hàng. Vui lòng thử lại. Lỗi: $e',
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tạo Đơn Nhập',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // General Order Information
                    Text(
                      'Thông tin đơn hàng',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC1473B),
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeNameController,
                      decoration: InputDecoration(
                        labelText: 'Tên cửa hàng',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.store),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên cửa hàng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _generalNoteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú chung (nếu có)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.note_alt),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // List of Car Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chi tiết xe gửi',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC1473B),
                              ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addOrderItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm xe'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC1473B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Use Column to dynamically add/remove widgets
                    Column(
                      children: _orderItems.asMap().entries.map((entry) {
                        int index = entry.key;
                        ServiceOrderItem item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Card(
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Xe #${index + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey[700],
                                            ),
                                      ),
                                      if (_orderItems.length >
                                          1) // Allow removing if more than one item
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeOrderItem(index),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: item.carModel,
                                    decoration: InputDecoration(
                                      labelText: 'Loại xe',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(Icons.motorcycle),
                                    ),
                                    items: _carModels.map((String model) {
                                      return DropdownMenuItem<String>(
                                        value: model,
                                        child: Text(model),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        item.carModel = newValue!;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng chọn loại xe';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue:
                                        item.color, // Display current color
                                    decoration: InputDecoration(
                                      labelText: 'Màu sắc',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(Icons.color_lens),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập màu sắc';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      item.color =
                                          value!; // Save the entered color
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue: item.quantity.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Số lượng',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(Icons.numbers),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Vui lòng nhập số lượng';
                                      }
                                      if (int.tryParse(value) == null ||
                                          int.parse(value) <= 0) {
                                        return 'Số lượng phải lớn hơn 0';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      item.quantity = int.parse(value!);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue: item.note,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      labelText: 'Ghi chú riêng (nếu có)',
                                      alignLabelWithHint: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(Icons.edit_note),
                                    ),
                                    onSaved: (value) {
                                      item.note = value!.isEmpty ? null : value;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitOrder,
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
                        child: const Text(
                          'Tạo Đơn Hàng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
