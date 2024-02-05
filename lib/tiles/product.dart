// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/dialogs/weight_editor.dart';

import 'package:gogas_delivery_app/model/order.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final List<User> users;

  const ProductTile({
    Key? key,
    required this.product,
    required this.users,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: _getTileColor(),
        border: const Border(
            bottom: BorderSide(color: Color.fromARGB(255, 218, 218, 218))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
        title: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 2,
            children: [
              Container(
                constraints: BoxConstraints(minWidth: 400),
                child: Text(
                  product.name,
                  style: TextStyle(
                      fontSize: 20,
                      color: product.isEmpty() ? Colors.grey : Colors.black),
                ),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Card(
                    child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          ProductTileStats(
                              icon: FontAwesomeIcons.users,
                              label: "Ordinanti",
                              value: product.orderingUsers.toString(),
                              color: _getIconsColor(colorScheme)),
                        ]))),
                Card(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        ProductTileStats(
                            icon: FontAwesomeIcons.boxOpen,
                            label: "Colli ricevuti",
                            value: product.orderedBoxes.toString(),
                            color: _getIconsColor(colorScheme)),
                        const SizedBox(width: 25.0),
                        ProductTileStats(
                            icon: FontAwesomeIcons.scaleBalanced,
                            label: "Peso collo",
                            value:
                                "${NumberFormatter.format(product.actualTotalWeight)} ${product.um}",
                            color: _getIconsColor(colorScheme)),
                        const SizedBox(width: 10.0),
                        Container(
                          height: 30,
                          color: _getIconsColor(colorScheme),
                          child: Tooltip(
                            message: "Modifica il peso del prodotto",
                            child: IconButton(
                              icon: Icon(FontAwesomeIcons.pencil),
                              iconSize: 14,
                              onPressed: () => Get.dialog(
                                  WeightEditorDialog(product: product)),
                              color: Colors.white,
                            ),
                          ),
                        )
                      ]),
                    )),
                Card(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      ProductTileStats(
                          icon: FontAwesomeIcons.chartPie,
                          label: "Copertura",
                          value: NumberFormatter.formatPercentage(
                              product.coverage),
                          color: _getIconsColor(colorScheme)),
                      const SizedBox(width: 25.0),
                      ProductTileStats(
                          icon: FontAwesomeIcons.truckRampBox,
                          label: "Rimanenze",
                          value:
                              NumberFormatter.format(product.remainingWeight),
                          color: _getIconsColor(colorScheme)),
                    ]),
                  ),
                ),
              ]),
            ]),
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: getIcon(),
        ),
        trailing: product.isEmpty()
            ? null
            : IconButton(
                tooltip: "Smista il prodotto",
                iconSize: 40,
                color: _getIconsColor(colorScheme),
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => Get.toNamed("/product",
                    arguments: {"product": product, "users": users}),
              ),
      ),
    );
  }

  Widget getIcon() {
    if (product.completed) {
      return const Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.green,
        size: 50,
      );
    }

    if (product.inProgress) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Icon(
          FontAwesomeIcons.pencil,
          color: Color.fromARGB(255, 179, 112, 11),
          size: 32,
        ),
      );
    }
    return const Icon(
      Icons.check_circle_outline_rounded,
      color: Color.fromARGB(255, 219, 219, 219),
      size: 50,
    );
  }

  Color? _getTileColor() {
    if (product.completed) {
      return const Color.fromARGB(255, 224, 248, 225);
    }

    if (product.inProgress) {
      return const Color.fromARGB(255, 250, 238, 220);
    }

    return null;
  }

  Color _getIconsColor(ColorScheme colorScheme) {
    if (product.inProgress) {
      return const Color.fromARGB(255, 179, 112, 11);
    }

    if (product.isEmpty()) {
      return Color.fromARGB(255, 199, 199, 199);
    }

    return colorScheme.tertiary;
  }
}

class ProductTileStats extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const ProductTileStats(
      {super.key,
      required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(children: [
        Tooltip(
          message: label,
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
        )
      ]),
    );
  }
}

class ProductByUserTile extends StatelessWidget {
  final Product product;
  final String userId;
  final bool altColor;

  const ProductByUserTile({
    Key? key,
    required this.product,
    required this.userId,
    required this.altColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    OrderItem orderItem =
        product.orderItems.where((item) => item.userId == userId).first;

    return Container(
      decoration: BoxDecoration(
        //color: _getTileColor(),
        border: const Border(
            bottom: BorderSide(color: Color.fromARGB(255, 218, 218, 218))),
      ),
      child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
          tileColor: altColor ? Color.fromARGB(255, 231, 231, 231) : null,
          title: Text(product.name,
              style: TextStyle(
                  fontSize: 20,
                  color: _getColor(orderItem),
                  decoration: orderItem.finalDeliveredQty == 0
                      ? TextDecoration.lineThrough
                      : null)),
          trailing: formatQuantity(orderItem)),
    );
  }

  Color _getColor(OrderItem orderItem) {
    if (orderItem.finalDeliveredQty == null) {
      return Colors.red;
    }

    if (orderItem.finalDeliveredQty == 0) {
      return Colors.grey;
    }

    return Colors.black;
  }

  Widget formatQuantity(OrderItem orderItem) {
    if (orderItem.finalDeliveredQty == null) {
      return Tooltip(
          message: "Prodotto non ancora smistato",
          child: Icon(
            FontAwesomeIcons.triangleExclamation,
            color: Colors.red,
            size: 28,
          ));
    }

    TextStyle style = TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: _getColor(orderItem),
        decoration: orderItem.finalDeliveredQty == 0
            ? TextDecoration.lineThrough
            : null);

    if (orderItem.finalDeliveredQty! > 0 &&
        orderItem.finalDeliveredQty! % product.boxWeight == 0) {
      int boxes = orderItem.finalDeliveredQty! ~/ product.boxWeight;
      String plural = boxes > 1 ? "e" : "a";
      return Text(
        "$boxes cass$plural",
        style: style,
      );
    }

    return Text(
      "${NumberFormatter.formatQuantity(orderItem.finalDeliveredQty)} ${product.um}",
      style: style,
    );
  }
}
