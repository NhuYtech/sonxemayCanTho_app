// lib/screens/order_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sonxemaycantho/models/service_order.dart';

class OrderEntry extends StatefulWidget {
  final ServiceOrder? orderToEdit; // Thêm parameter để hỗ trợ chỉnh sửa

  const OrderEntry({super.key, this.orderToEdit});

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
  bool _isEditMode = false; // Để theo dõi chế độ chỉnh sửa
  String _selectedStatus = 'Đã nhận'; // Trạng thái được chọn

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

  // Danh sách trạng thái đơn hàng
  final List<String> _orderStatuses = ['Đã nhận', 'Đang sơn', 'Đã sơn xong'];

  @override
  void initState() {
    super.initState();

    // Kiểm tra xem có phải chế độ chỉnh sửa không
    _isEditMode = widget.orderToEdit != null;

    if (_isEditMode) {
      // Chế độ chỉnh sửa - load dữ liệu từ orderToEdit
      _selectedStatus = widget.orderToEdit!.status;
      _loadOrderData();
    } else {
      // Chế độ tạo mới - thêm item mặc định
      _orderItems.add(
        ServiceOrderItem(carModel: _carModels.first, quantity: 0, color: ''),
      );
    }
  }

  // Load dữ liệu từ order để chỉnh sửa
  Future<void> _loadOrderData() async {
    final order = widget.orderToEdit!;
    _storeNameController.text = order.storeName;
    _generalNoteController.text = order.note ?? '';

    // Load order items từ Firestore
    try {
      final QuerySnapshot itemsSnapshot = await _firestore
          .collection('serviceOrderItems')
          .where('serviceOrderId', isEqualTo: order.id)
          .get();

      if (itemsSnapshot.docs.isNotEmpty) {
        setState(() {
          _orderItems = itemsSnapshot.docs.map((doc) {
            return ServiceOrderItem.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
      } else {
        // Nếu không có items, thêm một item mặc định
        setState(() {
          _orderItems.add(
            ServiceOrderItem(
              carModel: _carModels.first,
              quantity: 0,
              color: '',
            ),
          );
        });
      }
    } catch (e) {
      print('Lỗi khi load dữ liệu order items: $e');
      // Thêm item mặc định nếu có lỗi
      setState(() {
        _orderItems.add(
          ServiceOrderItem(carModel: _carModels.first, quantity: 0, color: ''),
        );
      });
    }
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

  // Cập nhật chỉ trạng thái đơn hàng
  Future<void> _updateOrderStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final order = widget.orderToEdit!;

      await _firestore.collection('serviceOrders').doc(order.id).update({
        'status': _selectedStatus,
      });

      _showConfirmationDialog(
        title: 'Cập nhật trạng thái thành công!',
        content: 'Trạng thái đơn hàng đã được cập nhật thành: $_selectedStatus',
        isSuccess: true,
      );
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái: $e');
      _showConfirmationDialog(
        title: 'Lỗi!',
        content: 'Đã xảy ra lỗi khi cập nhật trạng thái. Vui lòng thử lại.',
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      if (_isEditMode) {
        // Chế độ chỉnh sửa
        await _updateOrder();
      } else {
        // Chế độ tạo mới
        await _createOrder();
      }
    } catch (e) {
      print('Lỗi khi ${_isEditMode ? 'cập nhật' : 'tạo'} đơn hàng: $e');
      _showConfirmationDialog(
        title: 'Lỗi!',
        content:
            'Đã xảy ra lỗi khi ${_isEditMode ? 'cập nhật' : 'tạo'} đơn hàng. Vui lòng thử lại. Lỗi: $e',
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createOrder() async {
    final newOrder = ServiceOrder(
      storeName: _storeNameController.text.trim(),
      createDate: DateTime.now(),
      note: _generalNoteController.text.trim().isEmpty
          ? null
          : _generalNoteController.text.trim(),
      status: _selectedStatus,
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
      _selectedStatus = 'Đã nhận';
      _orderItems = [
        ServiceOrderItem(carModel: _carModels.first, quantity: 0, color: ''),
      ];
    });
  }

  Future<void> _updateOrder() async {
    final order = widget.orderToEdit!;

    // Cập nhật thông tin order
    final updatedOrder = ServiceOrder(
      id: order.id,
      storeName: _storeNameController.text.trim(),
      createDate: order.createDate, // Giữ nguyên ngày tạo
      note: _generalNoteController.text.trim().isEmpty
          ? null
          : _generalNoteController.text.trim(),
      status: _selectedStatus, // Cập nhật trạng thái mới
    );

    await _firestore
        .collection('serviceOrders')
        .doc(order.id)
        .update(updatedOrder.toMap());

    // Xóa các order items cũ
    final existingItemsSnapshot = await _firestore
        .collection('serviceOrderItems')
        .where('serviceOrderId', isEqualTo: order.id)
        .get();

    for (var doc in existingItemsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Thêm các order items mới
    for (var item in _orderItems) {
      item.serviceOrderId = order.id;
      await _firestore.collection('serviceOrderItems').add(item.toMap());
    }

    _showConfirmationDialog(
      title: 'Cập nhật đơn hàng thành công!',
      content: 'Thông tin đơn hàng đã được cập nhật.',
      isSuccess: true,
    );
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
                Navigator.of(context).pop(); // Đóng dialog
                if (isSuccess) {
                  Navigator.of(context).pop(); // Quay lại màn hình trước
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Widget hiển thị màu sắc theo trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đã nhận':
        return Colors.blue;
      case 'Đang sơn':
        return Colors.orange;
      case 'Đã sơn xong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Chỉnh sửa đơn nhập' : 'Tạo đơn nhập',
          style: const TextStyle(color: Colors.white),
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

                    // Dropdown chọn trạng thái
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

                    // Hiển thị nút cập nhật trạng thái nếu ở chế độ chỉnh sửa
                    if (_isEditMode) ...[
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _updateOrderStatus,
                          icon: const Icon(Icons.update),
                          label: const Text('Cập Nhật Trạng Thái'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getStatusColor(_selectedStatus),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                        child: Text(
                          _isEditMode ? 'Cập Nhật Đơn Hàng' : 'Tạo Đơn Hàng',
                          style: const TextStyle(
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
