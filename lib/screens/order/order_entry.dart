// lib/screens/order_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sonxemaycantho/models/service_order.dart';

class OrderEntry extends StatefulWidget {
  const OrderEntry({super.key});

  @override
  State<OrderEntry> createState() => _OrderEntryState();
}

class _OrderEntryState extends State<OrderEntry> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _generalNoteController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ServiceOrderItem> _orderItems = [];

  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _orderItems.add(
      ServiceOrderItem(carModel: _carModels.first, quantity: 0, color: ''),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _generalNoteController.dispose();
    super.dispose();
  }

  void _addOrderItem() {
    setState(() {
      _orderItems.add(
        ServiceOrderItem(carModel: _carModels.first, quantity: 0, color: ''),
      );
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final newOrder = ServiceOrder(
        storeName: _storeNameController.text.trim(),
        createDate: DateTime.now(),
        note: _generalNoteController.text.trim().isEmpty
            ? null
            : _generalNoteController.text.trim(),
        status: 'Chưa kiểm',
      );

      DocumentReference orderRef = await _firestore
          .collection('serviceOrders')
          .add(newOrder.toMap());
      newOrder.id = orderRef.id;

      for (var item in _orderItems) {
        item.serviceOrderId = newOrder.id;
        await _firestore.collection('serviceOrderItems').add(item.toMap());
      }

      _showConfirmationDialog(
        title: 'Tạo đơn hàng thành công!',
        content: 'Đơn hàng của bạn đã được ghi nhận vào hệ thống.',
        isSuccess: true,
      );

      _storeNameController.clear();
      _generalNoteController.clear();
      setState(() {
        _orderItems = [
          ServiceOrderItem(carModel: _carModels.first, quantity: 0, color: ''),
        ];
      });
    } catch (e) {
      print('Lỗi khi tạo đơn hàng: $e');
      _showConfirmationDialog(
        title: 'Lỗi!',
        content: 'Đã xảy ra lỗi khi tạo đơn hàng. Vui lòng thử lại. Lỗi: $e',
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
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
                Navigator.of(context).pop();
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
                                      if (_orderItems.length > 1)
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
                                    initialValue: item.color,
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
                                      item.color = value!;
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
