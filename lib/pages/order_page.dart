import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/controllers/order_controller.dart';
import 'package:gogas_delivery_app/model/order.dart';
import 'package:gogas_delivery_app/services/common_services.dart';
import 'package:gogas_delivery_app/tiles/product.dart';
import 'package:gogas_delivery_app/widgets/buttons.dart';

import '../dialogs/total_user_dialog.dart';

class OrderPage extends StatelessWidget {
  final OrderEditorController _orderEditorController = Get.find();

  OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        if (!_orderEditorController.canSave.value) {
          return true;
        }

        bool? b = await Get.dialog<bool>(Dialog(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Container(
                color: Colors.white,
                width: 470,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 60,
                      alignment: Alignment.center,
                      color: Theme.of(context).colorScheme.primary,
                      child: Text("Ordine non salvato",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            Icon(
                              FontAwesomeIcons.triangleExclamation,
                              color: Colors.red,
                              size: 50,
                            ),
                            SizedBox(width: 15),
                            Flexible(
                                child: Text(
                                    "Alcune modifiche all'ordine non sono state salvate e verranno perse."))
                          ]),
                          const SizedBox(height: 25),
                          Row(
                            children: [
                              ElevatedButton(
                                  onPressed: () => Get.back(result: false),
                                  child: Text("Torna all'ordine")),
                              SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white),
                                  onPressed: () => Get.back(result: true),
                                  child: Text("Ignora le modifiche")),
                              SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.tertiary,
                                      foregroundColor: Colors.white),
                                  onPressed: () async {
                                    await _orderEditorController.save();
                                    Get.back(result: true);
                                  },
                                  child: Text("Salva"))
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ))));

        return b ?? false;
      },
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Obx(() {
            if (_orderEditorController.loadingOrder.value) {
              return const Center(child: Text("loading..."));
            }

            if (_orderEditorController.currentOrder == null) {
              return const SizedBox();
            }

            return _buildView();
          }),
          Positioned(top: 3, child: ViewModeButton())
        ],
      ),
    );
  }

  Widget _buildView() {
    final OrderEntry orderEntry = _orderEditorController.currentOrderEntry!;
    final Order order = _orderEditorController.currentOrder!;

    Widget body =
        (_orderEditorController.viewMode.value == OrderViewMode.product)
            ? ByProductView(order: order, orderEntry: orderEntry)
            : ByUserView(order: order, orderEntry: orderEntry);

    List<Widget> actions = _orderEditorController.viewMode.value ==
            OrderViewMode.product
        ? [
            UploadButton(),
            SaveButton(),
            PackageOnlyButton(),
            SearchButton(
              searchFunction: ({String? searchText}) =>
                  _orderEditorController.filterProducts(searchText: searchText),
              tooltip: "Cerca i prodotti",
            ),
          ]
        : [
            SearchButton(
              searchFunction: ({String? searchText}) =>
                  _orderEditorController.filterUsers(searchText: searchText),
              tooltip: "Cerca i gasisti",
            ),
          ];

    return ViewContainer(
        actions: actions,
        body: body,
        orderName: order.name,
        viewMode: _orderEditorController.viewMode.value);
  }
}

class ByProductView extends StatelessWidget {
  final OrderEditorController _orderEditorController = Get.find();

  final Order order;
  final OrderEntry orderEntry;

  ByProductView({
    super.key,
    required this.order,
    required this.orderEntry,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Wrap(
                      runSpacing: 10,
                      children: [
                        OrderInfo(
                          icon: Icon(FontAwesomeIcons.truck, size: 22),
                          label: "Data Consegna",
                          value: orderEntry.formattedDeliveryDate,
                        ),
                        OrderInfo(
                          icon: Icon(FontAwesomeIcons.users, size: 22),
                          label: "Totale ordinanti",
                          value: order.totalUsers.length.toString(),
                          button: IconButton(
                            tooltip: "Vedi lista ordinanti",
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Get.dialog(TotalUserDialog(
                              users: order.sortedTotalUsers,
                            )),
                            icon: Icon(FontAwesomeIcons.eye),
                            color: colorScheme.tertiary,
                          ),
                        ),
                        OrderInfo(
                          icon: Icon(FontAwesomeIcons.download, size: 24),
                          label: "Scaricato da Go!Gas",
                          value: DateFormatter.formatTimeAgo(
                              orderEntry.downloadTs),
                        ),
                        OrderInfo(
                          icon: Icon(FontAwesomeIcons.pencil, size: 24),
                          label: "Ultima modifica",
                          value: DateFormatter.formatTimeAgo(
                              orderEntry.lastEditTs),
                        ),
                        OrderInfo(
                          icon: Icon(FontAwesomeIcons.upload, size: 24),
                          label: "Inviato a Go!Gas",
                          value: DateFormatter.formatTimeAgo(
                              orderEntry.lastPushTs),
                        ),
                      ],
                    ),
                  )),
              Expanded(
                  flex: 2,
                  child: Container(
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide()),
                      ),
                      child: Obx(() => ListView.builder(
                          itemCount: _orderEditorController
                              .filteredProducts.value.length,
                          itemBuilder: (context, index) {
                            return ProductTile(
                              product: _orderEditorController
                                  .filteredProducts.value[index],
                              users: order.users,
                            );
                          }))))
            ],
          ),
        ),
      ],
    );
  }
}

class ViewContainer extends StatelessWidget {
  final String orderName;
  final List<Widget> actions;
  final Widget body;
  final OrderViewMode viewMode;

  const ViewContainer(
      {super.key,
      required this.actions,
      required this.body,
      required this.orderName,
      required this.viewMode});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide())),
          child: ListTile(
            contentPadding: EdgeInsets.only(left: 16, right: 12),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderName,
                  style: TextStyle(fontSize: 24),
                )
              ],
            ),
            tileColor: Theme.of(context).colorScheme.primary.withAlpha(100),
            trailing: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: SizedBox(
                  width: 700,
                  key: ValueKey(viewMode),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    children: actions,
                  ),
                )),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween(
                    begin: Offset(1.0, 0.0),
                    end: Offset(0.0, 0.0),
                  ).animate(animation),
                  child: child),
              child: Container(key: ValueKey(viewMode), child: body)),
        ),
      ],
    );
  }
}

class ByUserView extends StatefulWidget {
  const ByUserView({
    super.key,
    required this.order,
    required this.orderEntry,
  });

  final Order order;
  final OrderEntry orderEntry;

  @override
  State<ByUserView> createState() => _ByUserViewState();
}

class _ByUserViewState extends State<ByUserView> {
  final OrderEditorController _orderEditorController = Get.find();

  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 1,
                  child: Obx(() => ListView.builder(
                      itemCount: _orderEditorController.filteredUsers.length,
                      itemBuilder: (context, index) {
                        User user =
                            _orderEditorController.filteredUsers.value[index];

                        bool selected = user.id == _selectedUserId;

                        return InkWell(
                          onTap: () => setState(() {
                            _selectedUserId = user.id;
                          }),
                          child: Container(
                              decoration: BoxDecoration(
                                color: selected
                                    ? Color.fromARGB(255, 218, 218, 218)
                                    : Colors.white,
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color.fromARGB(
                                            255, 218, 218, 218))),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(6.0),
                                title: Text(
                                  "${user.firstName} ${user.lastName}",
                                  style: TextStyle(fontSize: 18),
                                ),
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  child: Text("${user.position}",
                                      style: TextStyle(
                                          fontSize: 28,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w200)),
                                ),
                              )),
                        );
                      }))),
              Expanded(
                  flex: 2,
                  child: Container(
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide()),
                      ),
                      child: _buildUserOrdersList()))
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserOrdersList() {
    if (_selectedUserId == null) {
      return const Center(
        child: Text("Seleziona un gasista per vedere i prodotto ordinati"),
      );
    }

    List<Product> productsByUser =
        _orderEditorController.filteredByUser(_selectedUserId!);

    return ListView.builder(
        itemCount: productsByUser.length,
        itemBuilder: (context, index) {
          return ProductByUserTile(
              product: productsByUser[index],
              userId: _selectedUserId!,
              altColor: index % 2 ==
                  0 //_selectedProductId == productsByUser[index].id,
              );
        });
  }
}

class OrderInfo extends StatelessWidget {
  final Icon icon;
  final String label;
  final String value;
  final Widget? button;

  const OrderInfo(
      {super.key,
      required this.label,
      required this.value,
      required this.icon,
      this.button});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            height: 40,
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 218, 218, 218),
                border: Border.all(color: Color.fromARGB(255, 218, 218, 218))),
            padding: EdgeInsets.only(top: 2, bottom: 2, left: 15, right: 12),
            alignment: Alignment.center,
            child: icon),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 218, 218, 218),
                border: Border.all(color: Color.fromARGB(255, 218, 218, 218))),
            padding: EdgeInsets.all(2),
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color.fromARGB(255, 218, 218, 218))),
            padding: EdgeInsets.all(2),
            alignment: Alignment.center,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Positioned(right: 0, child: button ?? SizedBox())
              ],
            ),
          ),
        ),
      ],
    );
  }
}
