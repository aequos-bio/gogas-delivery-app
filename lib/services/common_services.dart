import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gogas_delivery_app/model/order.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:toastification/toastification.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class NotificationService extends GetxService {
  SnackbarController? _snackbarController;

  void showError(String message,
      {Duration? duration = const Duration(seconds: 1)}) {
    String sanitizedMessage = message == '' ? 'Errore generico' : message;

    _snackbarController = Get.rawSnackbar(
        message: sanitizedMessage,
        backgroundColor: Colors.red,
        animationDuration: Duration(milliseconds: 300),
        duration: duration);
  }

  void showInfo(String message,
      {Duration? duration = const Duration(seconds: 2)}) {
    _snackbarController = Get.rawSnackbar(
        message: message,
        animationDuration: Duration(milliseconds: 300),
        duration: duration);
  }

  void hideNotification() {
    if (SnackbarController.isSnackbarBeingShown) {
      _snackbarController?.close();
    }
  }

  void showToast(String message) {
    toastification.show(
        context: NavigationService.navigatorKey.currentContext!,
        title: Text(message),
        autoCloseDuration: const Duration(seconds: 2),
        type: ToastificationType.info,
        style: ToastificationStyle.minimal,
        alignment: Alignment.topCenter,
        closeButtonShowType: CloseButtonShowType.none,
        showProgressBar: false,
        closeOnClick: false);
  }

  void vibrate() {
    if (_isVibrationSupported) {
      Vibrate.feedback(FeedbackType.medium);
    }
  }

  bool get _isVibrationSupported {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}

class StorageService {
  late Directory _documentDirectory;
  RxList<OrderEntry> catalog = RxList.empty();

  Future<void> init() async {
    _documentDirectory = await getApplicationDocumentsDirectory();
    var firstPath = "${_documentDirectory.path}/orders";
    await Directory(firstPath).create(recursive: true);

    catalog.value = readCatalog();
  }

  List<OrderEntry> readCatalog() {
    GetStorage box = GetStorage();
    String? catalogJson = box.read("ORDER_CATALOG");

    if (catalogJson == null) {
      return [];
    }

    return List<OrderEntry>.from(
        jsonDecode(catalogJson).map((item) => OrderEntry.fromJson(item)));
  }

  Future<void> store(OrderEntry orderEntry, Order order) async {
    catalog.add(orderEntry);
    await _save(orderEntry, order);
  }

  Future<void> save(OrderEntry orderEntry, Order order) async {
    await _save(orderEntry, order);
    catalog.refresh();
  }

  Future<void> _save(OrderEntry orderEntry, Order order) async {
    String orderPath = buildOrderPath(orderEntry.id);
    File orderFile = File(orderPath);
    await orderFile.writeAsString(order.toJson());

    GetStorage box = GetStorage();
    await box.write("ORDER_CATALOG", json.encode(catalog));
  }

  Future<void> delete(OrderEntry orderEntry) async {
    catalog.remove(orderEntry);

    String orderPath = buildOrderPath(orderEntry.id);
    File orderFile = File(orderPath);
    await orderFile.delete();

    GetStorage box = GetStorage();
    await box.write("ORDER_CATALOG", json.encode(catalog));
  }

  Future<Order> load(String orderId) async {
    String orderPath = buildOrderPath(orderId);
    File orderFile = File(orderPath);
    String fileContent = await orderFile.readAsString();
    return Order.fromJson(fileContent);
  }

  String buildOrderPath(String orderId) {
    return "${_documentDirectory.path}/orders/$orderId.smj";
  }
}

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static String formatTimeAgo(DateTime? timestamp) {
    if (timestamp == null) {
      return "-";
    }

    return timeago.format(timestamp);
  }

  static String formatDeliveryDate(DateTime deliveryDate) {
    return _dateFormat.format(deliveryDate);
  }

  static DateTime parseDeliveryDate(String deliveryDate) {
    return _dateFormat.parse(deliveryDate);
  }
}

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
