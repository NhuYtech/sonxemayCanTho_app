import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/service_order.dart' as order;
import '../../models/service_order_item.dart' as item;

class CustomerEdit extends StatefulWidget {
  final order.ServiceOrder serviceOrder;

  const CustomerEdit({super.key, required this.serviceOrder});

  @override
  State<CustomerEdit> createState() => _CustomerEditState();
}

class _CustomerEditState extends State<CustomerEdit> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _generalNoteController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<item.ServiceOrderItem> _orderItems = [];
  bool _isLoading = false;
  late String _selectedStatus;

  static const List<String> _carModels = [
    'Vision',
    'Future 125',
    'Scoopy',
    'Exciter',
    'Wave Alpha',
    'Sirius',
    'Vario',
    'SH Mode',
  ];

  static const List<String> _orderStatuses = [
    'Đã nhận',
    'Đang sơn',
    'Đã sơn xong',
    'Đã gửi', // Thêm trạng thái 'Đã gửi' vào đây
  ];

  @override
  void initState() {
    super.initState();
    _storeNameController.text = widget.serviceOrder.storeName;
    _generalNoteController.text = widget.serviceOrder.note ?? '';

    // Đảm bảo giá trị của DropdownButtonFormField là hợp lệ
    // Nếu trạng thái từ database không tồn tại trong danh sách, gán giá trị mặc định.
    if (_orderStatuses.contains(widget.serviceOrder.status)) {
      _selectedStatus = widget.serviceOrder.status;
    } else {
      _selectedStatus =
          _orderStatuses.first; // Hoặc gán một giá trị mặc định khác
    }

    _fetchOrderItems();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _generalNoteController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đã nhận':
        return Colors.blue;
      case 'Đang sơn':
        return Colors.orange;
      case 'Đã sơn xong':
        return Colors.green;
      case 'Đã gửi':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _fetchOrderItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('serviceOrderItems')
          .where('serviceOrderId', isEqualTo: widget.serviceOrder.id)
          .where(
            'storeName',
            isEqualTo: widget.serviceOrder.storeName,
          ) // Lọc theo storeName
          .get();

      if (mounted) {
        setState(() {
          _orderItems = snapshot.docs.map((doc) {
            return item.ServiceOrderItem.fromMap(doc.data(), doc.id);
          }).toList();
        });
      }
    } catch (e) {
      print('Lỗi khi tải chi tiết đơn hàng: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addOrderItem() {
    setState(() {
      _orderItems.add(
        item.ServiceOrderItem(
          serviceOrderId: widget.serviceOrder.id!,
          carModel: _carModels.first,
          quantity: 0,
          color: '',
        ),
      );
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  Future<void> _updateOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final updatedOrder = order.ServiceOrder(
        id: widget.serviceOrder.id,
        storeName: _storeNameController.text.trim(),
        createDate: widget.serviceOrder.createDate,
        note: _generalNoteController.text.trim().isEmpty
            ? null
            : _generalNoteController.text.trim(),
        status: _selectedStatus,
      );

      await _firestore
          .collection('orders')
          .doc(widget.serviceOrder.id)
          .update(updatedOrder.toMap());

      for (var orderItem in _orderItems) {
        if (orderItem.id == null) {
          await _firestore
              .collection('serviceOrderItems')
              .add(orderItem.toMap());
        } else {
          await _firestore
              .collection('serviceOrderItems')
              .doc(orderItem.id)
              .update(orderItem.toMap());
        }
      }

      if (mounted) {
        _showConfirmationDialog(
          title: 'Cập nhật đơn hàng thành công!',
          content: 'Đơn hàng của bạn đã được cập nhật.',
          isSuccess: true,
        );
      }
    } catch (e) {
      print('Lỗi khi cập nhật đơn hàng: $e');
      if (mounted) {
        _showConfirmationDialog(
          title: 'Lỗi!',
          content:
              'Đã xảy ra lỗi khi cập nhật đơn hàng. Vui lòng thử lại. Lỗi: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                if (isSuccess) Navigator.of(context).pop();
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
          'Chỉnh sửa Đơn Nhập',
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
                      key: const Key('store_name_field'), // Thêm key
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
                      key: const Key('general_note_field'), // Thêm key
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái đơn hàng',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(
                          Icons.assignment_turned_in,
                          color: _getStatusColor(_selectedStatus),
                        ),
                      ),
                      items: _orderStatuses.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 16,
                                color: _getStatusColor(status),
                              ),
                              const SizedBox(width: 8),
                              Text(status),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatus = newValue!;
                        });
                      },
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
                        item.ServiceOrderItem orderItem = entry.value;
                        return Padding(
                          key: Key(
                            orderItem.id ?? 'order_item_${index}',
                          ), // Thêm key cho Padding
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Xe #${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
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
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    key: Key(
                                      'car_model_${orderItem.id ?? index}',
                                    ), // Thêm key
                                    value: orderItem.carModel,
                                    decoration: const InputDecoration(
                                      labelText: 'Dòng xe',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _carModels.map((String model) {
                                      return DropdownMenuItem<String>(
                                        value: model,
                                        child: Text(model),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        orderItem.carModel = newValue!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    key: Key(
                                      'quantity_${orderItem.id ?? index}',
                                    ), // Thêm key
                                    initialValue: orderItem.quantity.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Số lượng',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {
                                        orderItem.quantity =
                                            int.tryParse(value) ?? 0;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null ||
                                          value.isEmpty ||
                                          int.tryParse(value) == null ||
                                          int.tryParse(value)! <= 0) {
                                        return 'Số lượng phải là số nguyên dương';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    key: Key(
                                      'color_${orderItem.id ?? index}',
                                    ), // Thêm key
                                    initialValue: orderItem.color,
                                    decoration: const InputDecoration(
                                      labelText: 'Màu sắc',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        orderItem.color = value;
                                      });
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
                        onPressed: _updateOrder,
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
                          'Cập nhật Đơn Hàng',
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
