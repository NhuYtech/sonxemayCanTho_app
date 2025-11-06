class RepairOrder {
  final String? id;
  final String customerName;
  final String phoneNumber;
  final String vehicleType;
  final String description;
  final DateTime createdAt;
  final String status;

  RepairOrder({
    this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.vehicleType,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'vehicleType': vehicleType,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory RepairOrder.fromMap(Map<String, dynamic> map, String id) {
    return RepairOrder(
      id: id,
      customerName: map['customerName'],
      phoneNumber: map['phoneNumber'],
      vehicleType: map['vehicleType'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'],
    );
  }
}
