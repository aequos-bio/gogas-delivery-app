// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/controllers/product_controller.dart';
import 'package:gogas_delivery_app/dialogs/product_dialog.dart';
import 'package:gogas_delivery_app/model/order.dart';
import 'package:gogas_delivery_app/services/common_services.dart';
import 'package:gogas_delivery_app/services/settings_service.dart';
import 'package:gogas_delivery_app/tiles/order_item.dart';
import 'package:gogas_delivery_app/widgets/buttons.dart';
import 'package:gogas_delivery_app/widgets/num_pad.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class ProductPage extends StatefulWidget {
  final ProductController _controller;
  final UndoRedoService _undoRedoService;

  ProductPage({
    Key? key,
    required product,
    required users,
  })  : _controller = ProductController(product, users),
        _undoRedoService = UndoRedoService(),
        super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final SettingsService _settingsService = Get.find();
  final NotificationService _notificationService = Get.find();

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  int prevUserIndex = 0;

  @override
  void initState() {
    widget._controller.selectedUserIndex.listen((position) {
      var lastVisibleIndex =
          itemPositionsListener.itemPositions.value.last.index;

      if (prevUserIndex < position &&
          (position == lastVisibleIndex || position == lastVisibleIndex - 1)) {
        itemScrollController.scrollTo(
            index: min(widget._controller.sortedOrderItems.length, position),
            duration: const Duration(milliseconds: 200));
      }

      var firstVisibleIndex =
          itemPositionsListener.itemPositions.value.first.index;

      if (prevUserIndex > position &&
          position > 0 &&
          position == firstVisibleIndex) {
        itemScrollController.scrollTo(
            index: max(
                0,
                position -
                    itemPositionsListener.itemPositions.value.length +
                    2),
            duration: const Duration(milliseconds: 200));
      }

      prevUserIndex = position;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp): IncrementIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown): DecrementIntent(),
        SingleActivator(LogicalKeyboardKey.escape): CancelIntent(),
        SingleActivator(LogicalKeyboardKey.space): CopyIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          IncrementIntent: CallbackAction<IncrementIntent>(
            onInvoke: (IncrementIntent intent) =>
                widget._controller.event('prev'),
          ),
          DecrementIntent: CallbackAction<DecrementIntent>(
            onInvoke: (DecrementIntent intent) =>
                widget._controller.event('next'),
          ),
          CancelIntent: CallbackAction<CancelIntent>(
              onInvoke: (CancelIntent intent) =>
                  widget._controller.event('cancel')),
          CopyIntent: CallbackAction<CopyIntent>(
              onInvoke: (CopyIntent intent) =>
                  widget._controller.event('copy')),
          UndoIntent: CallbackAction<UndoIntent>(
              onInvoke: (UndoIntent intent) => _performUndo()),
          RedoIntent: CallbackAction<RedoIntent>(
              onInvoke: (RedoIntent intent) => _performRedo()),
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            buildHeader(colorScheme),
            Expanded(
              child: Row(
                children: [
                  buildUsersPanel(colorScheme),
                  buildInfoPanel(colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container buildInfoPanel(ColorScheme colorScheme) {
    return Container(
        padding: EdgeInsets.only(bottom: 2, top: 5, left: 5, right: 5),
        constraints: BoxConstraints(minWidth: 540, maxWidth: 550),
        color: Color.fromARGB(255, 218, 218, 218),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Container(child: _buildProductInfo(context)),
                  Container(child: _buildCoverageInfo(context)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: NumPad(
                        buttonSize: 82,
                        buttonColor: colorScheme.primary,
                        iconColor: colorScheme.secondary,
                        onPress: (char) {
                          _notificationService.vibrate();
                          widget._controller.event('pressed', payload: char);
                        },
                        delete: () => widget._controller.event('delete')),
                  ),
                  Obx(() => Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ActionButton(
                                  icon: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6.0),
                                        child: Icon(FontAwesomeIcons.truck,
                                            size: 34,
                                            color: Color.fromARGB(
                                                255, 219, 219, 219)),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
                                        child: Icon(
                                          FontAwesomeIcons.slash,
                                          size: 50,
                                        ),
                                      ),
                                    ],
                                  ),
                                  tooltip: "Azzera il peso consegnato",
                                  onPressed: () =>
                                      widget._controller.event('zero'),
                                  height: 75,
                                  disabled: widget
                                          ._controller.selectedUserIndex.value <
                                      0),
                              SizedBox(
                                height: 10,
                              ),
                              ActionButton(
                                  icon: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Icon(
                                      FontAwesomeIcons.copy,
                                      size: 46,
                                    ),
                                  ),
                                  tooltip: "Conferma il peso originale",
                                  onPressed: () =>
                                      widget._controller.event('copy'),
                                  height: 75,
                                  disabled: widget
                                          ._controller.selectedUserIndex.value <
                                      0),
                              SizedBox(
                                height: 10,
                              ),
                              ActionButton.icon(
                                  icon: Icons.close,
                                  tooltip: "Cancella il peso consegnato",
                                  onPressed: () =>
                                      widget._controller.event('reset'),
                                  height: 75,
                                  disabled: widget
                                          ._controller.selectedUserIndex.value <
                                      0),
                              SizedBox(
                                height: 10,
                              ),
                              ActionButton.icon(
                                  primary: true,
                                  icon: Icons.check,
                                  tooltip: "Conferma il peso consegnato",
                                  onPressed: () =>
                                      widget._controller.event('submit'),
                                  height: 140,
                                  disabled: widget
                                          ._controller.selectedUserIndex.value <
                                      0)
                            ]),
                      )),
                ],
              ),
            ]));
  }

  Card _buildProductInfo(BuildContext context) {
    return Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Obx(() => Container(
              color: widget._controller.productCompleted.value
                  ? Color.fromARGB(255, 224, 248, 225)
                  : Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Obx(() => _getCompletedIcon(
                          widget._controller.productCompleted.value)),
                      SizedBox(
                        width: 6,
                      ),
                      Obx(
                        () => Text(
                            widget._controller.productCompleted.value
                                ? "Prodotto\ncompletato"
                                : "Prodotto\nnon completato",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: widget._controller.productCompleted.value
                                    ? Colors.green
                                    : Colors.grey)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Obx(() => Icon(
                            FontAwesomeIcons.userLarge,
                            color: widget._controller.productCompleted.value
                                ? Colors.green
                                : Colors.grey,
                            size: 45,
                          )),
                      SizedBox(
                        width: 10,
                      ),
                      Obx(() => buildLinear(
                          widget._controller.completedUsers.value,
                          widget._controller.product.orderingUsers,
                          context))
                    ],
                  ),
                ],
              ),
            )));
  }

  Icon _getCompletedIcon(bool completed) {
    if (completed) {
      return const Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.green,
        size: 60,
      );
    }

    return const Icon(
      Icons.check_circle_outline_rounded,
      color: Colors.grey,
      size: 60,
    );
  }

  Card _buildCoverageInfo(BuildContext context) {
    return Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Container(
          color: Colors.white,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Obx(() =>
                  buildCircular(widget._controller.coverage.value, context)),
            ),
            SizedBox(
              width: 30,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Indicator(
                        icon: Icon(
                          FontAwesomeIcons.boxOpen,
                          size: 16,
                        ),
                        label: "N. colli",
                        value: NumberFormatter.format(
                            widget._controller.product.orderedBoxes),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Indicator(
                        icon: Icon(
                          FontAwesomeIcons.scaleBalanced,
                          size: 16,
                        ),
                        label: "Peso reale",
                        value:
                            "${NumberFormatter.format(widget._controller.product.actualTotalWeight)} ${widget._controller.product.um}",
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Indicator(
                        icon: Icon(
                          FontAwesomeIcons.scaleBalanced,
                          size: 16,
                        ),
                        label: "Peso collo",
                        value:
                            "${NumberFormatter.format(widget._controller.product.boxWeight)} ${widget._controller.product.um}",
                      ),
                      const SizedBox(width: 10),
                      Obx(() => Indicator(
                            icon: Icon(
                              FontAwesomeIcons.truckRampBox,
                              size: 16,
                            ),
                            label: "Rimanenze",
                            value:
                                "${NumberFormatter.format(widget._controller.remainingWeight.value)} ${widget._controller.product.um}",
                          )),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 20,
            ),
          ]),
        )
        //]),
        );
  }

  Expanded buildUsersPanel(ColorScheme colorScheme) {
    return Expanded(
        child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide()),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  title: Text(
                    "Ordinanti",
                    style: TextStyle(fontSize: 20),
                  ),
                  tileColor: Colors.grey,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 6.0, right: 5.0),
                    child: Obx(() => badges.Badge(
                        position: badges.BadgePosition.bottomEnd(
                            end: -10, bottom: -14),
                        badgeContent: Text(
                          widget._controller.sortedOrderItems.length.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        child: Icon(
                          FontAwesomeIcons.userLarge,
                          size: 34,
                        ))),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: "Aggiungi gasista",
                        child: InkWell(
                          child: Icon(
                            FontAwesomeIcons.userPlus,
                            size: 34,
                          ),
                          onTap: () => Get.dialog(AddUserDialog(
                            users: widget._controller.notOrderingUsers,
                            onConfirm: (userId) =>
                                widget._controller.addUser(userId),
                          )),
                        ),
                      ),
                      SizedBox(width: 30),
                      Tooltip(
                        message: "Modifica ordinamento gasisti",
                        child: InkWell(
                          child: Obx(() => SortIcon(
                                sortSettings:
                                    _settingsService.userSortingSettings.value,
                              )),
                          onTap: () => Get.dialog(SortDialog()),
                        ),
                      ),
                      SizedBox(width: 30),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() => ScrollablePositionedList.builder(
                      itemScrollController: itemScrollController,
                      itemPositionsListener: itemPositionsListener,
                      itemCount: widget._controller.sortedOrderItems.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            if (widget._controller.noSelection) {
                              widget._controller.selectionChanged(index);
                              return;
                            }
                            widget._controller
                                .event('selection', payload: "$index");
                          },
                          child: Obx(() => OrderItemTile(
                                key: ValueKey(_settingsService
                                    .userSortingSettings.value.key),
                                orderItem:
                                    widget._controller.sortedOrderItems[index],
                                um: widget._controller.product.um,
                                user: widget._controller.getUser(index),
                                selected: widget
                                        ._controller.selectedUserIndex.value ==
                                    index,
                                controller: widget._controller,
                                undoRedoService: widget._undoRedoService,
                              )),
                        );
                      })),
                ),
              ],
            )));
  }

  Container buildHeader(ColorScheme colorScheme) {
    return Container(
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide()),
            color: colorScheme.primary.withAlpha(100)),
        child: ListTile(
          title: Text(
            widget._controller.product.name,
            style: TextStyle(fontSize: 20),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: "Annulla l'ultima modifica effettuata",
                child: Obx(() => ElevatedButton(
                    onPressed: widget._undoRedoService.canUndo.value
                        ? _performUndo
                        : null,
                    child: Icon(Icons.undo))),
              ),
              SizedBox(
                width: 5,
              ),
              Tooltip(
                message: "Ripristina l'ultima modifica annullata",
                child: Obx(() => ElevatedButton(
                    onPressed: widget._undoRedoService.canRedo.value
                        ? _performRedo
                        : null,
                    child: Icon(Icons.redo))),
              ),
              SizedBox(
                width: 15,
              ),
              Tooltip(
                message: "Azzera tutte le quantità",
                child: ElevatedButton(
                    onPressed: () => _cancelProduct(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(FontAwesomeIcons.truck,
                            size: 18,
                            color: Color.fromARGB(255, 219, 219, 219)),
                        Icon(
                          FontAwesomeIcons.slash,
                          size: 22,
                        ),
                      ],
                    )),
              ),
              SizedBox(
                width: 5,
              ),
              Tooltip(
                message: "Conferma tutte le quantità originali",
                child: ElevatedButton(
                  onPressed: () => _copyQuantities(),
                  child: Icon(FontAwesomeIcons.copy, size: 20),
                ),
              ),
              SizedBox(
                width: 15,
              ),
              SaveButton(),
            ],
          ),
        ));
  }

  void _performRedo() {
    EditEvent? editEvent = widget._undoRedoService.redo();

    if (editEvent != null) {
      widget._controller.redo(editEvent);
    }
  }

  void _performUndo() {
    EditEvent? editEvent = widget._undoRedoService.undo();

    if (editEvent != null) {
      widget._controller.undo(editEvent);
    }
  }

  void _cancelProduct() {
    Get.dialog(OperationConfirmDialog(
        width: 260,
        title: "Azzeramento prodotto",
        body: "Tutte le quantità verranno azzerate. Continuare?",
        onConfirm: () =>
            widget._controller.cancelProduct(widget._undoRedoService)));
  }

  void _copyQuantities() {
    Get.dialog(OperationConfirmDialog(
        width: 260,
        title: "Conferma quantità originali",
        body:
            "Tutte le quantità originali verranno confermate come consegnate. Continuare?",
        onConfirm: () => widget._controller
            .copyOriginalQuantities(widget._undoRedoService)));
  }
}

class SortIcon extends StatelessWidget {
  final UserSortingSettings sortSettings;

  const SortIcon({
    super.key,
    required this.sortSettings,
  });

  @override
  Widget build(BuildContext context) {
    return badges.Badge(
        position: badges.BadgePosition.bottomEnd(end: end, bottom: bottom),
        badgeContent: badge,
        badgeStyle: badges.BadgeStyle(badgeColor: Colors.transparent),
        child: Icon(
          icon,
          size: 32,
        ));
  }

  IconData get icon {
    if (sortSettings.direction == 'asc') {
      return FontAwesomeIcons.arrowDownShortWide;
    }

    return FontAwesomeIcons.arrowDownWideShort;
  }

  double get bottom {
    if (sortSettings.direction == 'asc') {
      return 10;
    }

    if (sortSettings.field == 'weight') {
      return -8;
    }

    return -10;
  }

  double get end {
    if (sortSettings.field == 'weight') {
      return -24;
    }

    return -32;
  }

  Widget get badge {
    switch (sortSettings.field) {
      case 'position':
        return Text(
          "123",
          style: TextStyle(fontWeight: FontWeight.bold),
        );

      case 'name':
      case 'surname':
        return Text(
          "abc",
          style: TextStyle(fontWeight: FontWeight.bold),
        );

      case 'weight':
        return Icon(
          FontAwesomeIcons.scaleBalanced,
          size: 16,
        );

      default:
        return SizedBox();
    }
  }
}

class IncrementIntent extends Intent {
  const IncrementIntent();
}

class DecrementIntent extends Intent {
  const DecrementIntent();
}

class CancelIntent extends Intent {
  const CancelIntent();
}

class CopyIntent extends Intent {
  const CopyIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class Indicator extends StatelessWidget {
  final Icon icon;
  final String label;
  final String value;

  const Indicator(
      {super.key,
      required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 28,
          width: 106,
          decoration: BoxDecoration(
              color: const Color.fromARGB(255, 218, 218, 218),
              border: Border.all(color: Color.fromARGB(255, 218, 218, 218))),
          //padding: const EdgeInsets.all(2),
          alignment: Alignment.center,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: icon,
              ),
              const SizedBox(
                width: 6,
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          height: 28,
          width: 70,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color.fromARGB(255, 218, 218, 218))),
          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          alignment: Alignment.center,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
        )
      ],
    );
  }
}

class VerticalIndicator extends StatelessWidget {
  final String label;
  final String value;

  const VerticalIndicator(
      {super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
              color: Color.fromARGB(255, 218, 218, 218),
              border: Border.all(color: Color.fromARGB(255, 218, 218, 218))),
          padding: EdgeInsets.all(2),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color.fromARGB(255, 218, 218, 218))),
          padding: EdgeInsets.all(2),
          alignment: Alignment.center,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

Color _getCoverageColor(double coverage) {
  if (coverage < 0.3) {
    return Colors.red;
  }

  if (coverage < 0.8) {
    return Colors.orange;
  }

  return Colors.green;
}

Widget buildLinear(int done, int total, BuildContext context) {
  double coverage = done / total;

  return Container(
      height: 40,
      width: 140,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Wrap(
            children: [
              Text("Completati: $done/$total", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        SfLinearGauge(
          showLabels: false,
          showTicks: false,
          animateAxis: true,
          animationDuration: 1000,
          barPointers: [
            LinearBarPointer(
                value: (coverage) * 100,
                thickness: 8,
                edgeStyle: LinearEdgeStyle.bothCurve,
                color: _getCoverageColor(coverage),
                animationDuration: 700,
                animationType: LinearAnimationType.easeOutBack)
          ],
        )
      ]));
}

Widget buildCircular(double coverage, BuildContext context) {
  return SizedBox(
      height: 100,
      width: 100,
      child: SfRadialGauge(
        enableLoadingAnimation: true,
        animationDuration: 1200,
        axes: [
          RadialAxis(
              showLabels: false,
              showTicks: false,
              pointers: <GaugePointer>[
                RangePointer(
                    value: coverage * 100,
                    pointerOffset: -3,
                    width: 10,
                    cornerStyle: CornerStyle.bothCurve,
                    color: _getCoverageColor(coverage),
                    animationType: AnimationType.easeOutBack),
              ],
              axisLineStyle: AxisLineStyle(
                thickness: 4,
                cornerStyle: CornerStyle.bothCurve,
              ),
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                    axisValue: 50,
                    verticalAlignment: GaugeAlignment.near,
                    positionFactor: 0.65,
                    widget: SizedBox(
                      height: 80.0,
                      child: Column(
                        children: [
                          Text(
                            '${NumberFormatter.formatPercentage(coverage)}',
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            'Copertura',
                            style: TextStyle(fontSize: 12),
                          )
                        ],
                      ),
                    ))
              ])
        ],
      ));
}
