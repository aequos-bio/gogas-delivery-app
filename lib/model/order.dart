// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:gogas_delivery_app/services/common_services.dart';
import 'package:intl/intl.dart';

class Order {
  final String id;
  final String name;
  final DateTime deliveryDate;
  final List<User> users;
  final List<Product> products;

  Order(
      {required this.id,
      required this.name,
      required this.deliveryDate,
      required this.users,
      required this.products});

  Set<String> get totalUsers {
    return products.expand((p) => p.orderItems.map((o) => o.userId)).toSet();
  }

  List<User> get totalUsersFull {
    return users.where((element) => totalUsers.contains(element.id)).toList();
  }

  String get formattedDeliveryDate {
    return DateFormatter.formatDeliveryDate(deliveryDate);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orderId': id,
      'orderType': name,
      'deliveryDate': DateFormatter.formatDeliveryDate(deliveryDate),
      'users': users.map((u) => u.toMap()).toList(),
      'products': products.map((p) => p.toMap()).toList()
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['orderId'] as String,
      name: map['orderType'] as String,
      deliveryDate:
          DateFormatter.parseDeliveryDate(map['deliveryDate'] as String),
      users: map['users'].map<User>((u) => User.fromMap(u)).toList(),
      products:
          map['products'].map<Product>((p) => Product.fromMap(p)).toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Order.fromJson(String source) =>
      Order.fromMap(json.decode(source) as Map<String, dynamic>);
}

class User {
  final String id;
  final int position;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;

  User(
      {required this.id,
      required this.position,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.phone});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idUtente': id,
      'position': position,
      'nome': firstName,
      'cognome': lastName,
      'email': email,
      'telefono': phone,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['idUtente'] as String,
      position: map['position'] as int,
      firstName: map['nome'] as String,
      lastName: map['cognome'] as String,
      email: map['email'] as String?,
      phone: map['telefono'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);
}

class Product {
  final String id;
  final String name;
  final String um;
  final double price;
  final List<OrderItem> orderItems;

  double orderedBoxes;
  double boxWeight;
  double actualTotalWeight;
  bool completed;

  Product(
      {required this.id,
      required this.name,
      required this.um,
      required this.price,
      required this.orderedBoxes,
      required this.boxWeight,
      required this.completed,
      required this.orderItems,
      required double? actualTotalWeight})
      : actualTotalWeight = actualTotalWeight ?? orderedBoxes * boxWeight;

  int get orderingUsers {
    return orderItems.length;
  }

  int get completedUsers {
    return orderItems.where((item) => item.finalDeliveredQty != null).length;
  }

  double get totalDeliveredWeight {
    return orderItems
        .map((e) => e.finalDeliveredQty ?? 0.0)
        .reduce((value, element) => value + element);
  }

  double get coverage {
    if (actualTotalWeight == 0) {
      return 0.0;
    }

    return totalDeliveredWeight / actualTotalWeight;
  }

  double get remainingWeight {
    return actualTotalWeight - totalDeliveredWeight;
  }

  bool get inProgress {
    if (completed) {
      return false;
    }

    return orderItems.any((item) => item.finalDeliveredQty != null);
  }

  bool isEmpty() {
    return orderedBoxes <= 0;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'productId': id,
      'productName': name,
      'unitOfMeasure': um,
      'price': price,
      'orderItems': orderItems.map((x) => x.toMap()).toList(),
      'orderedBoxes': orderedBoxes,
      'boxWeight': boxWeight,
      'actualTotalWeight': actualTotalWeight,
      'completed': completed,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['productId'] as String,
      name: map['productName'] as String,
      um: map['unitOfMeasure'] as String,
      price: NumberFormatter.parseDouble(map['price']),
      orderItems: List<OrderItem>.from(
        (map['orderItems'] as List<dynamic>).map<OrderItem>(
          (x) => OrderItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      orderedBoxes: NumberFormatter.parseDouble(map['orderedBoxes']),
      boxWeight: NumberFormatter.parseDouble(map['boxWeight']),
      actualTotalWeight:
          NumberFormatter.parseNullableDouble(map['actualTotalWeight']),
      completed: map['completed'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Product.fromJson(String source) =>
      Product.fromMap(json.decode(source) as Map<String, dynamic>);
}

class OrderItem {
  final String userId;
  final double requestedQty;
  double originalDeliveredQty;
  double? finalDeliveredQty;
  bool changed;

  OrderItem({
    required this.userId,
    required this.requestedQty,
    required this.originalDeliveredQty,
    required this.finalDeliveredQty,
    required this.changed,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'requestedQty': requestedQty,
      'originalDeliveredQty': originalDeliveredQty,
      'finalDeliveredQty': finalDeliveredQty,
      'changed': changed,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    bool changed = map['changed'] as bool;

    return OrderItem(
      userId: map['userId'] as String,
      requestedQty: NumberFormatter.parseDouble(map['requestedQty']),
      originalDeliveredQty:
          NumberFormatter.parseDouble(map['originalDeliveredQty']),
      finalDeliveredQty: changed
          ? NumberFormatter.parseDouble(map['finalDeliveredQty'])
          : null,
      changed: changed,
    );
  }
}

class OrderEntry {
  final String id;
  final String name;
  final DateTime deliveryDate;
  DateTime? downloadTs;
  DateTime? lastEditTs;
  DateTime? lastPushTs;

  OrderEntry(
      {required this.id,
      required this.name,
      required this.deliveryDate,
      this.downloadTs,
      this.lastEditTs,
      this.lastPushTs});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'tipoordine': name,
      'dataconsegna': formattedDeliveryDate,
      'downloadTs': downloadTs?.millisecondsSinceEpoch,
      'lastEditTs': lastEditTs?.millisecondsSinceEpoch,
      'lastPushTs': lastPushTs?.millisecondsSinceEpoch,
    };
  }

  String get formattedDeliveryDate {
    return DateFormatter.formatDeliveryDate(deliveryDate);
  }

  factory OrderEntry.fromMap(Map<String, dynamic> map) {
    return OrderEntry(
      id: map['id'] as String,
      name: map['tipoordine'] as String,
      deliveryDate:
          DateFormatter.parseDeliveryDate(map['dataconsegna'] as String),
      downloadTs: _fromMillis(map['downloadTs']),
      lastEditTs: _fromMillis(map['lastEditTs']),
      lastPushTs: _fromMillis(map['lastPushTs']),
    );
  }

  static DateTime? _fromMillis(dynamic millis) {
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis as int)
        : null;
  }

  String toJson() => json.encode(toMap());

  factory OrderEntry.fromJson(String source) =>
      OrderEntry.fromMap(json.decode(source) as Map<String, dynamic>);
}

class RemoteOrderEntry {
  final OrderEntry orderEntry;
  final bool downloaded;

  RemoteOrderEntry({required this.orderEntry, required this.downloaded});
}

class NumberFormatter {
  static final NumberFormat genericFormatter =
      NumberFormat.decimalPatternDigits(decimalDigits: 2, locale: 'it_IT');

  static final NumberFormat noDigitsFormatter =
      NumberFormat.decimalPatternDigits(decimalDigits: 0, locale: 'it_IT');

  static final NumberFormat quantityFormatter =
      NumberFormat.decimalPatternDigits(decimalDigits: 3, locale: 'it_IT');

  static final NumberFormat percentageFormatter =
      NumberFormat.percentPattern('it_IT');

  static double parseDouble(dynamic value) {
    return double.parse(value.toString());
  }

  static double? parseNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    return parseDouble(value);
  }

  static double parseQuantity(dynamic value) {
    return quantityFormatter.parse(value.toString()).toDouble();
  }

  static String format(double value) {
    return genericFormatter.format(value);
  }

  static String formatNoDigits(double value) {
    return noDigitsFormatter.format(value);
  }

  static String formatQuantity(double? value) {
    if (value == null) {
      return '';
    }

    return quantityFormatter.format(value);
  }

  static String formatPercentage(double value) {
    return percentageFormatter.format(value);
  }
}
