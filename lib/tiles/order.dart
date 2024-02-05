import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/controllers/order_controller.dart';
import 'package:gogas_delivery_app/dialogs/product_dialog.dart';
import 'package:gogas_delivery_app/model/order.dart';
import 'package:gogas_delivery_app/services/common_services.dart';

class OrderTile extends StatelessWidget {
  final OrderController _orderController = Get.find();
  final OrderEditorController _orderEditorController = Get.find();
  final OrderEntry order;

  OrderTile({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color.fromARGB(255, 218, 218, 218))),
      ),
      child: ListTile(
        title: Text(
          order.name,
          style: const TextStyle(fontSize: 20),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Wrap(spacing: 20, children: [
            OrderTileStats(
                tooltip: "Scaricato da gogas",
                icon: FontAwesomeIcons.download,
                timestamp: order.downloadTs),
            OrderTileStats(
                tooltip: "Ultima modifica",
                icon: FontAwesomeIcons.pencil,
                timestamp: order.lastEditTs),
            OrderTileStats(
                tooltip: "Inviato a gogas",
                icon: FontAwesomeIcons.upload,
                timestamp: order.lastPushTs),
          ]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: "Apri l'ordine per lo smistamento",
              iconSize: 36,
              color: colorScheme.tertiary,
              icon: const Icon(FontAwesomeIcons.folderOpen),
              onPressed: () {
                _orderEditorController.loadOrder(order);
                Get.toNamed('/order')
                    ?.then((value) => _orderEditorController.unloadOrder());
              },
            ),
            const SizedBox(
              width: 15,
            ),
            IconButton(
              tooltip: "Elimina l'ordine",
              iconSize: 36,
              color: colorScheme.tertiary,
              icon: const Icon(FontAwesomeIcons.trashCan),
              onPressed: () => Get.dialog(OperationConfirmDialog(
                width: 400,
                title: "Eliminazione ordine",
                body: "L'ordine verrà eliminato sul dispositivo locale. "
                    "Eventuali modifiche non inviate a Go!Gas verranno perse, "
                    "continuare?",
                onConfirm: () => _orderController.delete(order),
              )),
            )
          ],
        ),
      ),
    );
  }
}

class OrderEntryTile extends StatelessWidget {
  final OrderController _orderController = Get.find();
  final RemoteOrderEntry order;

  OrderEntryTile({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color.fromARGB(255, 218, 218, 218))),
        ),
        child: ListTile(
          title: Text(
            order.orderEntry.name,
            style: const TextStyle(fontSize: 20),
          ),
          trailing: Obx(
            () => AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: _orderController.downloadingOrder.value ==
                      order.orderEntry.id
                  ? Container(
                      key: ValueKey("${order.orderEntry.id}-progress"),
                      height: 48,
                      width: 48,
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                        color: colorScheme.tertiary,
                        strokeWidth: 5,
                      ),
                    )
                  : Container(
                      child: IconButton(
                        key: ValueKey("${order.orderEntry.id}-none"),
                        tooltip: order.downloaded
                            ? "Ordine già scaricato per lo smistamento"
                            : "Scarica l'ordine per lo smistamento",
                        iconSize: 32,
                        color: order.downloaded
                            ? Colors.grey
                            : colorScheme.tertiary,
                        icon: const Icon(FontAwesomeIcons.download),
                        onPressed: order.downloaded
                            ? null
                            : () => _orderController.download(order.orderEntry),
                      ),
                    ),
            ),
          ),
        ));
  }
}

class OrderTileStats extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final DateTime? timestamp;

  const OrderTileStats(
      {super.key,
      required this.timestamp,
      required this.icon,
      required this.tooltip});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            size: 18,
            color: colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          DateFormatter.formatTimeAgo(timestamp),
          style: const TextStyle(fontSize: 12),
        )
      ]),
    );
  }
}
