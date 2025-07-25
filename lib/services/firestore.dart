import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Thêm dữ liệu
  Future<void> addData({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).add(data);
    } catch (e) {
      print('Lỗi khi thêm dữ liệu: $e');
      rethrow;
    }
  }

  // Cập nhật dữ liệu
  Future<void> updateData({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Lỗi khi cập nhật dữ liệu: $e');
      rethrow;
    }
  }

  // Lấy dữ liệu
  Stream<QuerySnapshot> getDataStream(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  // Lấy một document cụ thể
  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      print('Lỗi khi lấy document: $e');
      rethrow;
    }
  }

  // Xóa dữ liệu
  Future<void> deleteData({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Lỗi khi xóa dữ liệu: $e');
      rethrow;
    }
  }

  // Tìm kiếm dữ liệu
  Future<QuerySnapshot> searchData({
    required String collection,
    required String field,
    required dynamic value,
  }) async {
    try {
      return await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get();
    } catch (e) {
      print('Lỗi khi tìm kiếm dữ liệu: $e');
      rethrow;
    }
  }
}
