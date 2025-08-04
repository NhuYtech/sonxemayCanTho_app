// lib/screens/customer/customer_order_entry.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/service_order.dart';

class CustomerEntry extends StatefulWidget {
  const CustomerEntry({super.key});

  @override
  State<CustomerEntry> createState() => _CustomerEntryState();
}

class _CustomerEntryState extends State<CustomerEntry> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _generalNoteController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    _loadUserStoreName(); // Thêm hàm tải tên cửa hàng
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

  Future<void> _loadUserStoreName() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _storeNameController.text =
              userDoc.data()?['storeName'] ?? 'Không rõ';
        });
      }
    }
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

    // Kiểm tra xem có ít nhất một đơn hàng với số lượng > 0 hay không
    if (_orderItems.where((item) => item.quantity > 0).isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vui lòng thêm ít nhất một sản phẩm với số lượng > 0',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newOrderRef = await _firestore.collection('serviceOrders').add({
        'storeName': _storeNameController.text,
        'note': _generalNoteController.text,
        'createDate': FieldValue.serverTimestamp(),
        'status': 'Đã nhận',
      });

      for (var item in _orderItems.where((item) => item.quantity > 0)) {
        await newOrderRef.collection('items').add({
          'carModel': item.carModel,
          'color': item.color,
          'quantity': item.quantity,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đơn hàng đã được tạo thành công!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tạo đơn hàng: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tạo Đơn Hàng',
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
                    TextFormField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên cửa hàng',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // Cửa hàng không được thay đổi tên
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _generalNoteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú chung (nếu có)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Chi tiết đơn hàng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC1473B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: _orderItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Card(
                            elevation: 2,
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
                                        'Sản phẩm ${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_orderItems.length > 1)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeOrderItem(index),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Dòng xe',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: item.carModel,
                                    items: _carModels.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          item.carModel = newValue;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue: item.quantity.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Số lượng',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final quantity = int.tryParse(value) ?? 0;
                                      item.quantity = quantity;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    initialValue: item.color,
                                    decoration: const InputDecoration(
                                      labelText: 'Màu sắc',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      item.color = value;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _addOrderItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm sản phẩm'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC1473B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: const BorderSide(color: Color(0xFFC1473B)),
                        ),
                      ),
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
                          'Gửi Đơn Hàng',
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
