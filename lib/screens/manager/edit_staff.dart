import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditStaff extends StatefulWidget {
  final Map<String, dynamic> staff;

  const EditStaff({super.key, required this.staff});

  @override
  State<EditStaff> createState() => _EditStaffState();
}

class _EditStaffState extends State<EditStaff> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailAliasController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.staff['fullName'] ?? '',
    );
    _emailAliasController = TextEditingController(
      text: widget.staff['emailAlias'] ?? widget.staff['email'] ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: widget.staff['phoneNumber'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.staff['address'] ?? '',
    );
    // _isActive = widget.staff['isActive'] ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailAliasController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Hàm lưu dữ liệu đã chỉnh sửa lên Firestore
  Future<void> _saveStaffChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final staffUid = widget.staff['uid'] as String?;
        if (staffUid == null) {
          _showError('Không tìm thấy UID nhân viên.');
          return;
        }

        final updatedData = {
          'fullName': _fullNameController.text,
          'emailAlias': _emailAliasController.text,
          'phoneNumber': _phoneNumberController.text,
          'address': _addressController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('accounts').doc(staffUid).update(updatedData);

        if (mounted) {
          _showSuccessPopup();
        }
      } catch (e) {
        _showError('Lỗi khi cập nhật thông tin: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  // Hàm hiển thị pop-up thông báo thành công
  void _showSuccessPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thành công !🎉', textAlign: TextAlign.center),
          content: const Text('Thông tin nhân viên đã được cập nhật.'),
          actions: <Widget>[
            Center(
              child: TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng pop-up
                  Navigator.of(context).pop(true); // Trở về màn hình trước
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa Nhân viên',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC1473B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      widget.staff['avatarURL'] != null &&
                          widget.staff['avatarURL'].toString().isNotEmpty
                      ? NetworkImage(widget.staff['avatarURL'])
                      : null,
                  child:
                      (widget.staff['avatarURL'] == null ||
                          widget.staff['avatarURL'].toString().isEmpty)
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailAliasController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveStaffChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC1473B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Cập nhật',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
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
