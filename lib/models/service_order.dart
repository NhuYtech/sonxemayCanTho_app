// lib/models/service_order.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore's Timestamp

/// Represents a single service order (a batch of cars from a store).
class ServiceOrder {
  String? id; // Nullable for new orders before saving to DB
  final String storeName;
  final DateTime createDate;
  final String? note; // General note for the entire order
  String status; // e.g., 'Chưa kiểm', 'Đã kiểm', 'Hoàn tất'

  ServiceOrder({
    this.id,
    required this.storeName,
    required this.createDate,
    this.note,
    this.status = 'Chưa kiểm', // Default status
  });

  // Factory constructor to create a ServiceOrder from a Map (e.g., from Firestore)
  factory ServiceOrder.fromMap(Map<String, dynamic> data, String id) {
    return ServiceOrder(
      id: id,
      storeName: data['storeName'] as String,
      createDate: (data['createDate'] as Timestamp)
          .toDate(), // Use Firestore Timestamp
      note: data['note'] as String?,
      status: data['status'] as String,
    );
  }

  // Convert ServiceOrder to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'createDate': Timestamp.fromDate(
        createDate,
      ), // Convert DateTime to Firestore Timestamp
      'note': note,
      'status': status,
    };
  }
}

/// Represents a specific car model and quantity within a service order.
class ServiceOrderItem {
  String? id; // Nullable for new items before saving to DB
  String? serviceOrderId; // Link to the parent ServiceOrder
  String carModel;
  int quantity;
  String color; // Added: Color of the car model
  String? note; // Specific note for this car model/quantity

  ServiceOrderItem({
    this.id,
    this.serviceOrderId,
    required this.carModel,
    required this.quantity,
    required this.color, // Added: Color is now required
    this.note,
  });

  // Factory constructor to create a ServiceOrderItem from a Map
  factory ServiceOrderItem.fromMap(Map<String, dynamic> data, String id) {
    return ServiceOrderItem(
      id: id,
      serviceOrderId: data['serviceOrderId'] as String?,
      carModel: data['carModel'] as String,
      quantity: data['quantity'] as int,
      color: data['color'] as String, // Added: Read color from map
      note: data['note'] as String?,
    );
  }

  // Convert ServiceOrderItem to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'serviceOrderId': serviceOrderId,
      'carModel': carModel,
      'quantity': quantity,
      'color': color, // Added: Write color to map
      'note': note,
    };
  }
}
