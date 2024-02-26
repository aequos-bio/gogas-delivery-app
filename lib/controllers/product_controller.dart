import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:gogas_delivery_app/controllers/order_controller.dart';
import 'package:gogas_delivery_app/model/order.dart';
import 'package:gogas_delivery_app/services/common_services.dart';
import 'package:gogas_delivery_app/services/settings_service.dart';

class ProductController {
  final SettingsService _settingsService = Get.find();
  final OrderEditorController _orderEditorController = Get.find();
  final NotificationService _notificationService = Get.find();

  final Product product;
  final List<User> users;
  final RxList<OrderItem> sortedOrderItems;
  final RxInt selectedUserIndex = RxInt(-1);
  final List<EditEvent> editEvents = [];
  final RxDouble coverage = RxDouble(0.0);
  final RxDouble remainingWeight = RxDouble(0.0);
  final RxInt completedUsers = RxInt(0);
  final RxBool productCompleted = RxBool(false);

  final StreamController<ProductPageEvent> eventStream =
      StreamController<ProductPageEvent>.broadcast();

  ProductController(this.product, this.users)
      : sortedOrderItems = RxList.from(product.orderItems) {
    sortOrderItems(_settingsService.userSortingSettings.value);

    _settingsService.userSortingSettings.listen((sortingSettings) {
      sortOrderItems(sortingSettings);
    });

    _updateStats();
  }

  void sortOrderItems(UserSortingSettings sortingSettings) {
    String? selectedUserId = selectedUserIndex >= 0
        ? sortedOrderItems[selectedUserIndex.value].userId
        : null;

    String sortingField = sortingSettings.field;

    sortedOrderItems.sort((o1, o2) {
      int result = 0;

      if (sortingField == 'position') {
        result = _find(o1.userId).position.compareTo(_find(o2.userId).position);
      } else if (sortingField == 'surname') {
        result = _find(o1.userId).lastName.compareTo(_find(o2.userId).lastName);
      } else if (sortingField == 'name') {
        result =
            _find(o1.userId).firstName.compareTo(_find(o2.userId).firstName);
      } else if (sortingField == 'weight') {
        result = o1.originalDeliveredQty.compareTo(o2.originalDeliveredQty);
      }

      if (sortingSettings.direction == 'desc') {
        result = result * -1;
      }

      return result;
    });

    if (selectedUserId != null) {
      _forceSelection(selectedUserId);
    }
  }

  void _forceSelection(String selectedUserId) {
    selectedUserIndex.value =
        sortedOrderItems.indexWhere((item) => item.userId == selectedUserId);
  }

  User _find(String userId) {
    return users.firstWhere((user) => userId == user.id);
  }

  User getUser(int index) {
    String userId = sortedOrderItems[index].userId;
    return _find(userId);
  }

  List<User> get notOrderingUsers {
    List<User> notOrderingUsers = users
        .where(
            (element) => !sortedOrderItems.any((o) => o.userId == element.id))
        .toList();

    notOrderingUsers.sort((u1, u2) => u1.lastName.compareTo(u2.lastName));
    return notOrderingUsers;
  }

  void addUser(String userId) {
    OrderItem orderItem = OrderItem(
        userId: userId,
        requestedQty: 0,
        originalDeliveredQty: 0,
        changed: false,
        finalDeliveredQty: null);

    sortedOrderItems.add(orderItem);
    product.orderItems.add(orderItem);
  }

  void event(String type, {String? payload}) {
    eventStream.add(ProductPageEvent(type: type, payload: payload));
  }

  StreamSubscription<ProductPageEvent> listenEvents(
      void Function(ProductPageEvent) onData) {
    return eventStream.stream.listen(onData);
  }

  void cancelProduct(UndoRedoService undoRedoService) {
    _setAllQuantities(undoRedoService, value: 0);
  }

  void copyOriginalQuantities(UndoRedoService undoRedoService) {
    _setAllQuantities(undoRedoService);
  }

  void _setAllQuantities(UndoRedoService undoRedoService, {double? value}) {
    for (OrderItem item in sortedOrderItems) {
      undoRedoService.addEvent(EditEvent(item.userId,
          valueBefore: item.finalDeliveredQty,
          valueAfter: value ?? item.originalDeliveredQty));

      item.finalDeliveredQty = value ?? item.originalDeliveredQty;
      item.changed = true;

      eventStream.add(ProductPageEvent(type: 'undo', payload: item.userId));
    }

    sortedOrderItems.refresh();
    quantityChanged();
  }

  void quantityChanged() {
    _updateProductCompleted();
    _updateStats();
    _orderEditorController.quantityChanged();
  }

  void _updateProductCompleted() {
    bool oldProductCompletedStatus = product.completed;
    bool newProductCompletedStatus =
        product.orderItems.every((element) => element.changed);

    if (oldProductCompletedStatus == newProductCompletedStatus) {
      return;
    }

    product.completed = newProductCompletedStatus;

    if (product.completed) {
      _notificationService.showInfo(
          "Prodotto contrassegnato come completato, tutti i pesi sono stati assegnati");
    } else {
      _notificationService.showInfo(
          "Prodotto contrassegnato come NON completato, alcuni pesi sono stati rimossi");
    }
  }

  void _updateStats() {
    coverage.value = product.coverage;
    remainingWeight.value = product.remainingWeight;
    completedUsers.value = product.completedUsers;
    productCompleted.value = product.completed;
  }

  void quantitySubmitted() {
    if (selectedUserIndex.value + 1 > product.orderingUsers - 1) {
      selectedUserIndex.value = -1;
    } else {
      selectedUserIndex.value =
          min(product.orderingUsers - 1, selectedUserIndex.value + 1);
    }
  }

  void stepDone(int step) {
    if (step > 0) {
      selectedUserIndex.value =
          min(product.orderingUsers - 1, selectedUserIndex.value + step);
    } else {
      selectedUserIndex.value = max(0, selectedUserIndex.value + step);
    }
  }

  void selectionChanged(int index) {
    selectedUserIndex.value = index;
  }

  bool get noSelection {
    return selectedUserIndex.value < 0;
  }

  void undo(EditEvent editEvent) {
    _performUndoRedo(editEvent.userId, editEvent.valueBefore);
  }

  void redo(EditEvent editEvent) {
    _performUndoRedo(editEvent.userId, editEvent.valueAfter);
  }

  void _performUndoRedo(String userId, double? value) {
    OrderItem first =
        sortedOrderItems.where((item) => item.userId == userId).first;

    first.finalDeliveredQty = value;
    first.changed = value != null;

    sortedOrderItems.refresh();
    eventStream.add(ProductPageEvent(type: 'undo', payload: userId));
    _forceSelection(userId);
    quantityChanged();
  }
}

class EditEvent {
  final String userId;
  final double? valueBefore;
  final double? valueAfter;

  EditEvent(this.userId, {this.valueBefore, this.valueAfter});

  @override
  String toString() {
    return 'USER: $userId, BEFORE: $valueBefore, AFTER: $valueAfter';
  }
}

class ProductPageEvent {
  final String type;
  final String? payload;

  ProductPageEvent({required this.type, this.payload});
}

class UndoRedoService {
  final List<EditEvent> _editEvents = [];
  final RxBool canUndo = false.obs;
  final RxBool canRedo = false.obs;

  int _eventIndex = -1;

  void addEvent(EditEvent event) {
    if (_eventIndex < _editEvents.length) {
      _editEvents.removeRange(_eventIndex + 1, _editEvents.length);
    }

    _editEvents.add(event);
    _updateIndex(1);
  }

  void _updateIndex(int step) {
    _eventIndex += step;

    canUndo.value = _eventIndex >= 0;
    canRedo.value = _eventIndex < _editEvents.length - 1;
  }

  EditEvent? undo() {
    if (!canUndo.value) {
      return null;
    }

    EditEvent editEvent = _editEvents[_eventIndex];
    _updateIndex(-1);
    return editEvent;
  }

  EditEvent? redo() {
    if (!canRedo.value) {
      return null;
    }

    _updateIndex(1);
    return _editEvents[_eventIndex];
  }
}
