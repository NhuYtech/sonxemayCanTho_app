class ServiceOrderItem {
  String? id;
  String serviceOrderId;
  String carModel;
  int quantity;
  String color;

  ServiceOrderItem({
    this.id,
    required this.serviceOrderId,
    required this.carModel,
    required this.quantity,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'serviceOrderId': serviceOrderId,
      'carModel': carModel,
      'quantity': quantity,
      'color': color,
    };
  }

  static ServiceOrderItem fromMap(Map<String, dynamic> map, String id) {
    return ServiceOrderItem(
      id: id,
      serviceOrderId: map['serviceOrderId'],
      carModel: map['carModel'],
      quantity: map['quantity'],
      color: map['color'],
    );
  }
}
