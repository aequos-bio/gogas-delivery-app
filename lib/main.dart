import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gogas_delivery_app/controllers/order_controller.dart';
import 'package:gogas_delivery_app/dialogs/settings_editor.dart';
import 'package:gogas_delivery_app/pages/home_page.dart';
import 'package:gogas_delivery_app/pages/product_page.dart';
import 'package:gogas_delivery_app/services/api_service.dart';
import 'package:gogas_delivery_app/services/common_services.dart';
import 'package:gogas_delivery_app/services/settings_service.dart';
import 'package:gogas_delivery_app/widgets/buttons.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'pages/order_page.dart';

// GoRouter configuration
final List<GetPage> orderRouter = [
  GetPage(
      name: '/home',
      page: () {
        return MyHomePage(title: 'Go!Gas - Smistamento', body: HomePage());
      },
      transition: Transition.topLevel,
      binding: GlobalBindings()),
  GetPage(
    name: '/order',
    page: () {
      return MyHomePage(title: 'Go!Gas - Smistamento', body: OrderPage());
    },
    transition: Transition.leftToRight,
    binding: GlobalBindings(),
  ),
  GetPage(
    name: '/product',
    page: () {
      return MyHomePage(
          title: 'Go!Gas - Smistamento',
          body: ProductPage(
              product: Get.arguments['product'],
              users: Get.arguments['users']));
    },
    transition: Transition.leftToRight,
    binding: GlobalBindings(),
  )
];

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderController>(() => OrderController());
    Get.lazyPut<OrderEditorController>(() => OrderEditorController());
  }
}

void main() async {
  await GetStorage.init();

  timeago.setLocaleMessages('it', timeago.ItMessages());
  timeago.setDefaultLocale('it');

  SettingsService settingsService = SettingsService();
  settingsService.init();
  Get.put<SettingsService>(settingsService, permanent: true);

  Get.put<ApiService>(ApiService(), permanent: true);
  Get.put<NotificationService>(NotificationService(), permanent: true);

  StorageService storageService = StorageService();
  await storageService.init();
  Get.put<StorageService>(storageService, permanent: true);

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Go!Gas - Smistamento',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 150, 176, 67),
              secondary: Color.fromARGB(255, 145, 94, 59),
              tertiary: Color(0xFF65810F)),
          appBarTheme: const AppBarTheme(
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                  inherit: true,
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold))),
      initialRoute: '/home',
      getPages: orderRouter,
      navigatorKey: NavigationService.navigatorKey,
      builder: (context, child) => Overlay(
        initialEntries: [
          if (child != null) ...[
            OverlayEntry(
              builder: (context) => child,
            ),
          ],
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () => Get.dialog(const SettingsEditorDialog()),
              icon: const Icon(
                FontAwesomeIcons.gear,
                size: 30,
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: LoginButton(),
          ),
        ],
      ),
      body: widget.body,
    );
  }
}
