// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gogas_delivery_app/controllers/product_controller.dart';

import 'package:gogas_delivery_app/model/order.dart';

class OrderItemTile extends StatefulWidget {
  final OrderItem orderItem;
  final String um;
  final User user;
  final bool selected;
  final ProductController controller;
  final UndoRedoService undoRedoService;

  const OrderItemTile(
      {Key? key,
      required this.orderItem,
      required this.um,
      required this.user,
      required this.selected,
      required this.controller,
      required this.undoRedoService})
      : super(key: key);

  @override
  State<OrderItemTile> createState() => _OrderItemTileState();
}

class _OrderItemTileState extends State<OrderItemTile> {
  static final RegExp inputValidation = RegExp(r'^\d*\,?\d{0,3}$');

  late StreamSubscription<ProductPageEvent> onEventSub;
  late FocusNode myFocusNode;
  final TextEditingController _quantityController = TextEditingController();
  int caretPosition = 0;

  @override
  void initState() {
    super.initState();

    _quantityController.text =
        NumberFormatter.formatQuantity(widget.orderItem.finalDeliveredQty);

    _quantityController.addListener(() {
      if (_quantityController.selection.isValid) {
        caretPosition = _quantityController.selection.end;
      }
    });

    myFocusNode =
        isPushNotificationSupported ? FirstDisabledFocusNode() : FocusNode();

    myFocusNode.addListener(() {
      if (_quantityController.selection.isValid) {
        caretPosition = _quantityController.selection.end;
      } else {
        _quantityController.selection = TextSelection.collapsed(
            offset: min(caretPosition, _quantityController.text.length));
      }
    });

    onEventSub = widget.controller.listenEvents((ProductPageEvent event) {
      if (event.type == 'undo' && event.payload == widget.orderItem.userId) {
        _quantityController.text =
            NumberFormatter.formatQuantity(widget.orderItem.finalDeliveredQty);
        return;
      }

      if (!widget.selected) {
        return;
      }

      switch (event.type) {
        case 'pressed':
          _onPressed(event.payload);
          break;

        case 'selection':
          _onSelection(event.payload);
          break;

        case 'cancel':
          _cancelEdit();
          break;

        case 'reset':
          _reset('');
          break;

        case 'zero':
          _reset('0');
          break;

        case 'delete':
          _deleteChar();
          break;

        case 'submit':
          _submit(_quantityController.text);
          break;

        case 'copy':
          _submit(NumberFormatter.formatQuantity(
              widget.orderItem.originalDeliveredQty));
          break;

        case 'next':
          _step(_quantityController.text, 1);
          break;

        case 'prev':
          _step(_quantityController.text, -1);
          break;

        default:
      }
    });
  }

  void _onPressed(String? char) {
    if (char == null) {
      return;
    }

    if (!_quantityController.selection.isValid) {
      _quantityController.text = _quantityController.text + char;
      return;
    }

    String beforeCursorPositionAtTEC =
        _quantityController.selection.textBefore(_quantityController.text);
    String afterCursorPositionAtTEC =
        _quantityController.selection.textAfter(_quantityController.text);
    String result = beforeCursorPositionAtTEC + char + afterCursorPositionAtTEC;

    if (inputValidation.hasMatch(result)) {
      if (_quantityController.selection.isValid) {
        caretPosition = _quantityController.selection.end + 1;
      }

      _quantityController.text = result;
    }

    myFocusNode.requestFocus();
  }

  void _onSelection(String? indexAsString) {
    if (indexAsString == null) {
      return;
    }

    int index = int.parse(indexAsString);
    _saveValue(_quantityController.text);
    widget.controller.selectionChanged(index);
  }

  void _cancelEdit() {
    _quantityController.text =
        NumberFormatter.formatQuantity(widget.orderItem.finalDeliveredQty);
  }

  void _reset(String value) {
    _saveValue(value);
    caretPosition = 0;
  }

  void _deleteChar() {
    if (!_quantityController.selection.isValid) {
      if (_quantityController.text.length > 0) {
        _quantityController.text = _quantityController.text
            .substring(0, _quantityController.text.length - 1);
      }

      return;
    }

    if (_quantityController.selection.end == 0) {
      return;
    }

    String beforeCursorPositionAtTEC =
        _quantityController.selection.textBefore(_quantityController.text);
    String afterCursorPositionAtTEC =
        _quantityController.selection.textAfter(_quantityController.text);
    String result = beforeCursorPositionAtTEC.substring(
            0, beforeCursorPositionAtTEC.length - 1) +
        afterCursorPositionAtTEC;

    caretPosition = _quantityController.selection.end - 1;

    _quantityController.text = result;

    myFocusNode.requestFocus();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    onEventSub.cancel();
    _quantityController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selected) {
      myFocusNode.requestFocus();

      _quantityController.selection = TextSelection.collapsed(
          offset: min(caretPosition, _quantityController.text.length));
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.selected
            ? Color.fromARGB(255, 218, 218, 218)
            : widget.orderItem.changed
                ? Color.fromARGB(255, 224, 248, 225)
                : null,
        border: Border(
            bottom: BorderSide(color: Color.fromARGB(255, 218, 218, 218)),
            right: BorderSide(color: Color.fromARGB(255, 218, 218, 218))),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 12),
        title: Text(
          "${widget.user.firstName} ${widget.user.lastName}",
          style: const TextStyle(fontSize: 20),
        ),
        subtitle: Wrap(children: [
          OrderItemTileStats(
              label: "Qta ordinata",
              value:
                  "${NumberFormatter.formatQuantity(widget.orderItem.requestedQty)} "
                  "${widget.controller.product.um}"),
        ]),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: widget.orderItem.changed
              ? Colors.green
              : widget.selected
                  ? Colors.grey
                  : Color.fromARGB(255, 218, 218, 218),
          foregroundColor: Colors.white,
          child: Text("${widget.user.position}",
              style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w200)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buldFullBoxesIcon(),
                SizedBox(
                  width: 3,
                ),
                Text(
                    NumberFormatter.formatQuantity(
                        widget.orderItem.originalDeliveredQty),
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Icon(Icons.arrow_forward),
                ),
                Container(
                  constraints: BoxConstraints(minWidth: 90, maxHeight: 48),
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      color: Colors.white),
                  child: SizedBox(
                    width: 90,
                    height: 35,
                    child: widget.selected ? textField : disabledTextField,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: widget.orderItem.changed
                            ? Colors.green
                            : widget.selected
                                ? Colors.grey
                                : Color.fromARGB(255, 218, 218, 218)),
                    color: widget.orderItem.changed
                        ? Colors.green
                        : widget.selected
                            ? Colors.grey
                            : Color.fromARGB(255, 218, 218, 218),
                  ),
                  child: Text(
                    widget.um,
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w100),
                  ),
                )
              ],
            ),
            SizedBox(width: 20),
            _getIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buldFullBoxesIcon() {
    if (widget.orderItem.originalDeliveredQty == 0) {
      return const SizedBox();
    }

    if (widget.orderItem.originalDeliveredQty %
            widget.controller.product.boxWeight >
        0) {
      return const SizedBox();
    }

    int boxes = widget.orderItem.originalDeliveredQty ~/
        widget.controller.product.boxWeight;

    String plural = boxes > 1 ? 'e' : 'a';

    return Tooltip(
      message: "$boxes cass$plural inter$plural",
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 3.0, right: 4),
          child: SizedBox(
              width: 56,
              child: Stack(
                children: [
                  Icon(
                    FontAwesomeIcons.boxOpen,
                    color: widget.orderItem.changed
                        ? Colors.green
                        : widget.selected
                            ? Colors.grey
                            : Color.fromARGB(255, 218, 218, 218),
                    size: 44,
                  ),
                  Center(
                      child: Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: Text("$boxes",
                        style: TextStyle(
                            fontSize: 20,
                            //fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ))
                ],
              )),
        ),
      ),
    );
  }

  TextFormField get textField {
    return TextFormField(
      style: TextStyle(fontSize: 24),
      textAlign: TextAlign.center,
      controller: _quantityController,
      focusNode: myFocusNode,
      keyboardType:
          TextInputType.none, //TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.deny('.', replacementString: ','),
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d{0,3}'))
      ],
      decoration: const InputDecoration(
        border: InputBorder.none,
      ),
      onFieldSubmitted: _submit,
    );
  }

  Widget get disabledTextField {
    return Container(
      child: Text(_quantityController.text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400)),
    );
  }

  void _submit(String value) {
    _saveValue(value);
    widget.controller.quantitySubmitted();
  }

  void _step(String value, int step) {
    _saveValue(value);
    widget.controller.stepDone(step);
  }

  void _saveValue(String value) {
    double? parsedQuantity = _parseQuantity(value);

    if (parsedQuantity == widget.orderItem.finalDeliveredQty) {
      return;
    }

    _addUndoEvent(parsedQuantity);

    widget.orderItem.finalDeliveredQty = parsedQuantity;
    widget.orderItem.changed = parsedQuantity != null;

    widget.controller.quantityChanged();

    _quantityController.text = NumberFormatter.formatQuantity(parsedQuantity);
  }

  void _addUndoEvent(double? parsedQuantity) {
    if (parsedQuantity == widget.orderItem.finalDeliveredQty) {
      //no undo action if the value is the same
      return;
    }

    widget.undoRedoService.addEvent(EditEvent(widget.orderItem.userId,
        valueBefore: widget.orderItem.finalDeliveredQty,
        valueAfter: parsedQuantity));
  }

  double? _parseQuantity(String textValue) {
    if (textValue == '') {
      return null;
    }

    return NumberFormatter.parseQuantity(textValue);
  }

  Icon _getIcon() {
    if (widget.selected) {
      return Icon(
        Icons.edit,
        color: Colors.grey,
        size: 40,
      );
    }

    if (widget.orderItem.changed) {
      return Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.green,
        size: 40,
      );
    }

    return Icon(
      Icons.check_circle_outline_rounded,
      color: Color.fromARGB(255, 218, 218, 218),
      size: 40,
    );
  }
}

class OrderItemTileStats extends StatelessWidget {
  final String label;
  final String value;

  const OrderItemTileStats(
      {super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text("$label: ", style: TextStyle(fontSize: 12)),
        Text(
          value,
          style: TextStyle(fontSize: 12),
        )
      ]),
    );
  }
}

class FirstDisabledFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() {
    return false;
  }
}

bool get isPushNotificationSupported {
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
