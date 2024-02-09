import 'dart:async';

import 'package:get/get.dart';
import 'package:gogas_delivery_app/model/order.dart';
import 'package:gogas_delivery_app/services/api_service.dart';
import 'package:gogas_delivery_app/services/common_services.dart';
import 'package:gogas_delivery_app/services/settings_service.dart';

class OrderController {
  final ApiService _apiService = Get.find();
  final NotificationService _notificationService = Get.find();
  final StorageService _storageService = Get.find();

  RxList<RemoteOrderEntry> remoteOrders = RxList.empty();
  Rx<ConnectionStatus> searchOrdersStatus = ConnectionStatus.none.obs;
  RxString downloadingOrder = ''.obs;
  RxBool localChanged = false.obs;

  OrderController() {
    _apiService.authenticated.stream.listen((authenticated) {
      if (!authenticated) {
        remoteOrders.clear();
        searchOrdersStatus.value = ConnectionStatus.none;
      }
    });
  }

  RxList<OrderEntry> get localOrders {
    return _storageService.catalog;
  }

  void loadOrders() {
    searchOrdersStatus.value = ConnectionStatus.progress;

    _apiService.searchOrders(0, {
      "status": [1],
      "deliveryDateFrom": DateFormatter.formatDeliveryDate(
          DateTime.now().subtract(const Duration(days: 180)))
    }).then((response) {
      if (response.error) {
        _notificationService
            .showError(response.errorMessage ?? 'Errore generico');
        return;
      }

      List<OrderEntry> responseOrders = response.body ?? [];
      _updateRemoteOrders(responseOrders);

      searchOrdersStatus.value = ConnectionStatus.completed;
    });
  }

  void download(OrderEntry orderEntry) async {
    try {
      downloadingOrder.value = orderEntry.id;

      var response = await _apiService.downloadOrder(orderEntry.id);

      if (response.error) {
        _notificationService
            .showError(response.errorMessage ?? 'Errore generico');
        return;
      }

      orderEntry.downloadTs = DateTime.now();

      await _storageService.store(orderEntry, response.body!);
      _updateRemoteOrders(remoteOrders.map((o) => o.orderEntry).toList());
      _notificationService.showInfo('Ordine salvato con successo');
    } finally {
      downloadingOrder.value = '';
    }
  }

  void delete(OrderEntry orderEntry) async {
    _storageService.delete(orderEntry).then((v) {
      _updateRemoteOrders(remoteOrders.map((o) => o.orderEntry).toList());
      _notificationService.showInfo('Ordine eliminato con successo');
    });
  }

  void _updateRemoteOrders(List<OrderEntry> responseOrders) {
    Set<String> localOrderIds = localOrders.map((o) => o.id).toSet();

    remoteOrders.value = responseOrders
        .map((o) => RemoteOrderEntry(
            orderEntry: o, downloaded: localOrderIds.contains(o.id)))
        .toList();
  }
}

class OrderEditorController {
  final ApiService _apiService = Get.find();
  final StorageService _storageService = Get.find();
  final SettingsService _settingsService = Get.find();
  final NotificationService _notificationService = Get.find();

  OrderEditorController() {
    _settingsService.showEmptyProducts.stream
        .listen((event) => filterProducts());
  }

  OrderEntry? _currentOrderEntry;
  Order? _currentOrder;
  final RxList<Product> _filteredProducts = RxList.empty();
  final RxList<User> _filteredUsers = RxList.empty();
  RxBool viewPackageProductsOnly = false.obs;

  RxBool loadingOrder = false.obs;
  Rx<ConnectionStatus> uploadingOrder = ConnectionStatus.none.obs;
  String? uploadError;
  Rx<OrderViewMode> viewMode = OrderViewMode.product.obs;
  RxBool canSave = false.obs;

  DateTime? _autoSaveLastEditTs;
  Timer? _autoSaveTimer;

  OrderEntry? get currentOrderEntry {
    return _currentOrderEntry;
  }

  Order? get currentOrder {
    return _currentOrder;
  }

  RxList<Product> get filteredProducts {
    return _filteredProducts;
  }

  RxList<User> get filteredUsers {
    return _filteredUsers;
  }

  List<Product> filteredByUser(String userId) {
    if (_currentOrder == null) {
      return [];
    }

    return _currentOrder!.products
        .where((p) => p.orderItems.any((item) => item.userId == userId))
        .toList();
  }

  void updateViewPackageProductsOnly(bool enabled) {
    viewPackageProductsOnly.value = enabled;
    filterProducts();
  }

  void toggleViewMode() {
    if (viewMode.value == OrderViewMode.product) {
      viewMode.value = OrderViewMode.user;
    } else {
      viewMode.value = OrderViewMode.product;
    }
  }

  Future<void> loadOrder(OrderEntry orderEntry) async {
    loadingOrder.value = true;

    _currentOrderEntry = orderEntry;
    _currentOrder = await _storageService.load(orderEntry.id);
    filterProducts();
    filterUsers();

    _autoSaveLastEditTs = orderEntry.lastEditTs;
    _autoSaveTimer = Timer.periodic(
        Duration(minutes: _settingsService.autoSavePeriodMinutes), _autoSave);

    loadingOrder.value = false;
  }

  Future<void> unloadOrder() async {
    _currentOrderEntry = null;
    _currentOrder = null;
    _filteredProducts.clear();
    _filteredUsers.clear();

    _autoSaveLastEditTs = null;
    _autoSaveTimer?.cancel();
    canSave.value = false;

    viewMode.value = OrderViewMode.product;
  }

  bool productWeightsChanged(double orderedBoxes, double boxWeight,
      double actualTotalWeight, Product product) {
    bool quantitiesDistributed =
        _distributeQuantitiesForProduct(product, actualTotalWeight);

    product.orderedBoxes = orderedBoxes;
    product.boxWeight = boxWeight;
    product.actualTotalWeight = actualTotalWeight;

    quantityChanged();

    return quantitiesDistributed;
  }

  bool _distributeQuantitiesForProduct(Product product, double newTotalWeight) {
    if (!_settingsService.automaticDistribution.value) {
      return false;
    }

    if (product.actualTotalWeight == newTotalWeight) {
      return false;
    }

    double ratio = newTotalWeight / product.actualTotalWeight;

    for (final OrderItem item in product.orderItems) {
      item.originalDeliveredQty *= ratio;
    }

    return true;
  }

  void quantityChanged() {
    _currentOrderEntry!.lastEditTs = DateTime.now();
    canSave.value = true;
    loadingOrder.refresh();
  }

  Future<void> _autoSave(timer) async {
    if (!_settingsService.autoSaveEnabled) {
      return;
    }

    if (_currentOrderEntry == null || _currentOrderEntry?.lastEditTs == null) {
      return;
    }

    if (_autoSaveLastEditTs != null &&
        _autoSaveLastEditTs!.compareTo(_currentOrderEntry!.lastEditTs!) >= 0) {
      return;
    }

    await _save("Salvataggio automatico completato");
  }

  Future<void> save() async {
    await _save("Salvataggio completato");
  }

  Future<void> _save(String message) async {
    await _storageService.save(_currentOrderEntry!, _currentOrder!);
    _autoSaveLastEditTs = _currentOrderEntry!.lastEditTs;
    canSave.value = false;
    _notificationService.showToast(message);
  }

  void filterProducts({String? searchText}) {
    String? lowerCaseSearchText = searchText?.toLowerCase();
    _filteredProducts.value = (_currentOrder?.products ?? [])
        .where((product) => _filterProduct(product, lowerCaseSearchText))
        .toList();
  }

  bool _filterProduct(Product product, String? searchText) {
    if (viewPackageProductsOnly.value && product.um.toLowerCase() == 'kg') {
      return false;
    }

    if (!_settingsService.showEmptyProducts.value && product.isEmpty()) {
      return false;
    }

    if (searchText != null &&
        !product.name.toLowerCase().contains(searchText)) {
      return false;
    }

    return true;
  }

  void filterUsers({String? searchText}) {
    String? lowerCaseSearchText = searchText?.toLowerCase();
    _filteredUsers.value = List<User>.from(currentOrder?.sortedTotalUsers ?? [])
        .where((user) => _filterUser(user, lowerCaseSearchText))
        .toList();
  }

  bool _filterUser(User user, String? searchText) {
    if (searchText == null) {
      return true;
    }

    return user.firstName.toLowerCase().contains(searchText) ||
        user.lastName.toLowerCase().contains(searchText);
  }

  void uploadOrder() async {
    try {
      uploadingOrder.value = ConnectionStatus.progress;
      await save();
      ApiResult<String> response =
          await _apiService.uploadOrder(currentOrderEntry!.id, currentOrder!);

      if (!response.error) {
        uploadError = null;
        return;
      }

      if (response.statusCode == 404) {
        uploadError = 'Ordine non esistente su Go!Gas';
        return;
      }

      uploadError = 'Errore: ${response.errorMessage}';
    } catch (error) {
      uploadError = error.toString();
    } finally {
      uploadingOrder.value = ConnectionStatus.completed;
    }
  }

  void initOrderUpload() {
    uploadingOrder.value = ConnectionStatus.none;
    uploadError = null;
  }
}

enum ConnectionStatus { none, progress, completed }

enum OrderViewMode { product, user }
