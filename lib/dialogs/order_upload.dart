import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/controllers/order_controller.dart';

class OrderUploadDialog extends StatelessWidget {
  final OrderEditorController _orderEditorController = Get.find();

  OrderUploadDialog({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        backgroundColor: Colors.white,
        child: Container(
            constraints: const BoxConstraints(maxHeight: 300, maxWidth: 400),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(10),
                      color: colorScheme.primary,
                      child: const Text(
                        "Invio a Go!Gas",
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      )),
                ),
              ]),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                      child: Obx(
                    () => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildBody(
                            _orderEditorController.uploadingOrder.value,
                            colorScheme)),
                  )),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Obx(() => _buildButtons(
                  _orderEditorController.uploadingOrder.value, colorScheme)),
              SizedBox(
                height: 15,
              ),
            ])));
  }

  Widget _buildBody(ConnectionStatus uploadStatus, ColorScheme colorScheme) {
    switch (uploadStatus) {
      case ConnectionStatus.progress:
        return Column(
          key: ValueKey<ConnectionStatus>(uploadStatus),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                color: colorScheme.tertiary,
                strokeWidth: 6,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text("Invio in corso...")
          ],
        );

      case ConnectionStatus.completed:
        bool error = _orderEditorController.uploadError != null;
        return Column(
          key: ValueKey<ConnectionStatus>(uploadStatus),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error ? FontAwesomeIcons.xmark : FontAwesomeIcons.check,
              color: error ? Colors.red : colorScheme.tertiary,
              size: 60,
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              error
                  ? "Invio non riuscito:\n${_orderEditorController.uploadError}"
                  : "Pesi aggiornati con successo",
              textAlign: TextAlign.center,
            )
          ],
        );

      case ConnectionStatus.none:
      default:
        return Column(
          key: ValueKey<ConnectionStatus>(uploadStatus),
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              "L'ordine verrà salvato e inviato a Go!Gas "
              "per l'aggiornamento dei pesi. Continuare?",
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 5,
            ),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
                child: Row(children: [
                  Icon(
                    FontAwesomeIcons.triangleExclamation,
                    color: Colors.red,
                    size: 50,
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Flexible(
                      child: RichText(
                    text: TextSpan(
                      children: [
                        _span("I "),
                        _span("pesi non inseriti", bold: true),
                        _span(
                            " (lasciati vuoti) non andranno ad annullare quelli originali."),
                        const TextSpan(
                            text: "\n\n", style: TextStyle(fontSize: 6)),
                        _span("Per "),
                        _span("azzerare la quantità", bold: true),
                        _span(" consegnata occcorre inserire il valore "),
                        _span("zero", bold: true),
                        _span(" come peso."),
                      ],
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ))
                ]),
              ),
            ),
            SizedBox(
              height: 10,
            ),
          ],
        );
    }
  }

  TextSpan _span(String text, {bool bold = false}) {
    return TextSpan(
      text: text,
      style: TextStyle(
          color: Colors.black, fontWeight: bold ? FontWeight.bold : null),
    );
  }

  Widget _buildButtons(ConnectionStatus uploadStatus, ColorScheme colorScheme) {
    switch (uploadStatus) {
      case ConnectionStatus.progress:
        return SizedBox(
          height: 30,
        );

      case ConnectionStatus.completed:
        return ElevatedButton(
            onPressed: () => Get.back(), child: const Text("Chiudi"));

      case ConnectionStatus.none:
      default:
        return Row(
          children: [
            SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                  onPressed: () => Get.back(), child: const Text("Annulla")),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.tertiary,
                      foregroundColor: Colors.white),
                  onPressed: _orderEditorController.uploadOrder,
                  child: const Text('Conferma')),
            ),
            SizedBox(width: 20),
          ],
        );
    }
  }
}
