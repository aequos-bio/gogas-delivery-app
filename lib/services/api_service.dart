import 'dart:developer';
import 'dart:io';
import 'package:gogas_delivery_app/model/order.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ApiService extends GetConnect with CacheManager {
  static const String _gogasPrefix = '/gogas';
  static const String _apiPrefix = '$_gogasPrefix/api';

  String? _baseUrl;
  String? _jwtToken;
  String? _userCompleteName;
  RxBool authenticated = false.obs;

  ApiService() {
    _getBaseUrl().then((value) => _baseUrl = value);
  }

  Future<ApiResult<List<OrderEntry>>> searchOrders(
      int pageNumber, Map<String, dynamic> filter) async {
    filter['pagination'] = {'pageNumber': pageNumber, 'pageSize': 20};

    return await _post("$_apiPrefix/order/manage/list", filter,
        decoder: (list) => List<OrderEntry>.from(
            list.map((item) => OrderEntry.fromMap(item))));
  }

  Future<ApiResult<Order>> downloadOrder(String orderId) async {
    return await _get("$_apiPrefix/delivery/$orderId",
        decoder: (data) => Order.fromMap(data));
  }

  Future<ApiResult<String>> uploadOrder(String orderId, Order order) async {
    return await _post("$_apiPrefix/delivery/$orderId", order.toMap(),
        query: {"skipEmptyQuantities": "true"}, decoder: (body) {
      return body.toString();
    });
  }

  Future<String?> login(
      String hostName, String username, String password) async {
    try {
      var response = await post("https://$hostName$_gogasPrefix/authenticate",
              '{"username": "$username", "password": "$password"}',
              headers: {HttpHeaders.contentTypeHeader: 'application/json'})
          .withMinDuration();

      if (response.status.connectionError) {
        return "Server non raggiungibile, verificare l'indirizzo inserito e la connessione a internet ${response.status.code}";
      }

      if (response.statusCode == 401) {
        return 'Utente non valido o password errata';
      }

      if (response.statusCode != 200) {
        return 'Errore: ${response.bodyString}';
      }

      var token = response.body['data'];
      _jwtToken = token;
      _baseUrl = "https://$hostName";

      await saveHost(hostName);
      await saveUsername(username);
      await _setUserContext(token);

      authenticated.value = true;

      return null;
    } catch (e) {
      log(e.toString());
      return e.toString();
    }
  }

  Future<void> _setUserContext(String jwtToken) async {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(jwtToken);
    _userCompleteName =
        decodedToken['firstname'] + " " + decodedToken['lastname'];
  }

  void logout() {
    authenticated.value = false;
    _jwtToken = null;
    _userCompleteName = null;
  }

  Future<ApiResult<T>> _get<T>(
    String url, {
    Map<String, dynamic>? query,
    required Decoder<T> decoder,
  }) async {
    String completeUrl = "$_baseUrl$url";

    Response response = await super
        .get(completeUrl,
            headers: {HttpHeaders.authorizationHeader: 'Bearer $_jwtToken'},
            query: query)
        .withMinDuration();

    return parseResponse<T>(response, decoder);
  }

  Future<ApiResult<T>> _post<T>(
    String url,
    dynamic body, {
    Map<String, dynamic>? query,
    required Decoder<T> decoder,
    Progress? uploadProgress,
  }) async {
    String completeUrl = "$_baseUrl$url";

    Response response = await super
        .post(
          completeUrl,
          body,
          headers: {HttpHeaders.authorizationHeader: 'Bearer $_jwtToken'},
          query: query,
          uploadProgress: uploadProgress,
        )
        .withMinDuration();

    return parseResponse<T>(response, decoder);
  }

  ApiResult<T> parseResponse<T>(Response response, Decoder<T> decoder) {
    if (response.status.connectionError) {
      return ApiResult.error(
          errorMessage:
              "Server non raggiungibile, verificare l'indirizzo inserito e la connessione a internet",
          statusCode: 0);
    }

    if (response.status.hasError) {
      return ApiResult.error(
          errorMessage: response.statusText,
          statusCode: response.statusCode ?? 0);
    }

    if (response.unauthorized) {
      Get.defaultDialog(
          title: "Sessione scaduta",
          content: Text("Effettuare nuovamente la login"),
          onConfirm: () {
            logout();
          });

      return ApiResult.error(
          errorMessage: "Utente non autorizzato",
          statusCode: response.statusCode ?? 0);
    }

    return ApiResult.ok(body: decoder(response.body));
  }

  Future<String?> _getBaseUrl() async {
    String? host = await getHost();

    if (host == null) {
      return null;
    }

    return 'https://$host';
  }

  String? get userCompleteName {
    return _userCompleteName;
  }
}

class ApiResult<T> {
  final T? body;
  final String? errorMessage;
  final bool error;
  final int statusCode;

  ApiResult.ok({required this.body})
      : error = false,
        errorMessage = null,
        statusCode = 200;

  ApiResult.error({required this.errorMessage, required this.statusCode})
      : error = true,
        body = null;
}

mixin CacheManager {
  Future<bool> saveHost(String? baseUrl) async {
    return await save(CacheManagerKey.HOST.toString(), baseUrl);
  }

  Future<bool> saveUsername(String? username) async {
    return await save(CacheManagerKey.USERNAME.toString(), username);
  }

  Future<bool> save(String key, String? value) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: key, value: value);
    return true;
  }

  Future<String?> getHost() async {
    return await getValue(CacheManagerKey.HOST.toString());
  }

  Future<String?> getUsername() async {
    return await getValue(CacheManagerKey.USERNAME.toString());
  }

  Future<String?> getValue(String key) async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: key);
  }

  Future<void> deleteValue(String key) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: key);
  }
}

enum CacheManagerKey { HOST, USERNAME }

extension FutureExtensions<T> on Future<T> {
  Future<T> withMinDuration({
    Duration duration = const Duration(milliseconds: 1000),
  }) async {
    final delayFuture = Future<void>.delayed(duration);
    await Future.wait([this, delayFuture]);
    return this;
  }
}
