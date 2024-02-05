import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/controllers/order_controller.dart';
import 'package:gogas_delivery_app/model/order.dart';
import 'package:gogas_delivery_app/services/api_service.dart';
import 'package:gogas_delivery_app/tiles/order.dart';
import 'package:grouped_list/grouped_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: LocalOrderList()),
        Expanded(child: OnlineOrderListTab())
      ],
    );
  }
}

class LocalOrderList extends StatelessWidget {
  final OrderController _orderController = Get.find();

  LocalOrderList({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      margin: EdgeInsets.all(15),
      surfaceTintColor: Colors.white,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(children: [
        Container(
            decoration:
                const BoxDecoration(border: Border(bottom: BorderSide())),
            child: ListTile(
                tileColor: Theme.of(context).colorScheme.primary.withAlpha(100),
                title: Text(
                  "Ordini scaricati",
                  style: TextStyle(fontSize: 24),
                ))),
        Expanded(
          child: Obx(() {
            if (_orderController.localOrders.isEmpty) {
              return Center(child: Text("Nessun ordine scaricato da Go!Gas"));
            }

            return GroupedListView<OrderEntry, String>(
              elements: _orderController.localOrders.value,
              groupBy: (element) =>
                  element.deliveryDate.millisecondsSinceEpoch.toString(),
              groupHeaderBuilder: (OrderEntry order) =>
                  DateHeader(formattedDate: order.formattedDeliveryDate),
              itemBuilder: (context, order) => OrderTile(order: order),
              itemComparator: (order1, order2) =>
                  order1.name.compareTo(order2.name) * -1,
              order: GroupedListOrder.DESC,
            );
          }),
        ),
      ]),
    );
  }
}

class OnlineOrderListTab extends StatelessWidget {
  OnlineOrderListTab({super.key});

  final ApiService _apiService = Get.find();
  final OrderController _orderController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      margin: EdgeInsets.all(15),
      surfaceTintColor: Colors.white,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(children: [
        Container(
            decoration:
                const BoxDecoration(border: Border(bottom: BorderSide())),
            child: ListTile(
                title: const Text(
                  "Ordini su Go!Gas",
                  style: TextStyle(fontSize: 24),
                ),
                tileColor: Theme.of(context).colorScheme.primary.withAlpha(100),
                trailing: Obx(() => AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: Container(
                      key: ValueKey(_orderController.searchOrdersStatus.value),
                      child: _orderController.searchOrdersStatus.value ==
                              ConnectionStatus.progress
                          ? Container(
                              height: 44,
                              width: 44,
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ))
                          : Container(
                              child: IconButton(
                                  iconSize: 28,
                                  onPressed: _apiService.authenticated.value
                                      ? () => _orderController.loadOrders()
                                      : null,
                                  icon: const Icon(
                                      FontAwesomeIcons.arrowsRotate)),
                            ),
                    ))))),
        Expanded(
          child: buildBody(),
        ),
      ]),
    );
  }

  Obx buildBody() {
    return Obx(() {
      if (!_apiService.authenticated.value) {
        return const Center(
            child:
                Text("Effettua la login per consultare gli ordini su Go!Gas"));
      }

      if (_orderController.searchOrdersStatus.value == ConnectionStatus.none) {
        return const Center(
            child: Text("Aggiorna per vedere gli ordini su Go!Gas"));
      }

      return OnlineOrderList(orders: _orderController.remoteOrders.value);
    });
  }
}

class OnlineOrderList extends StatelessWidget {
  const OnlineOrderList({
    super.key,
    required this.orders,
  });

  final List<RemoteOrderEntry> orders;

  @override
  Widget build(BuildContext context) {
    return GroupedListView<RemoteOrderEntry, String>(
      elements: orders,
      groupBy: (element) =>
          element.orderEntry.deliveryDate.millisecondsSinceEpoch.toString(),
      groupHeaderBuilder: (RemoteOrderEntry entry) =>
          DateHeader(formattedDate: entry.orderEntry.formattedDeliveryDate),
      itemBuilder: (context, order) => OrderEntryTile(order: order),
      itemComparator: (entry1, entry2) =>
          entry1.orderEntry.name.compareTo(entry2.orderEntry.name) * -1,
      order: GroupedListOrder.DESC,
    );
  }
}

class DateHeader extends StatelessWidget {
  final String formattedDate;

  const DateHeader({super.key, required this.formattedDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
      color: const Color.fromARGB(255, 218, 218, 218),
      child: Text(
        formattedDate,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
