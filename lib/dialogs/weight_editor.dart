import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/controllers/order_controller.dart';
import 'package:gogas_delivery_app/model/order.dart';
import 'package:gogas_delivery_app/services/common_services.dart';

class WeightEditorDialog extends StatefulWidget {
  final Product product;

  const WeightEditorDialog({super.key, required this.product});

  @override
  State<WeightEditorDialog> createState() => _WeightEditorDialogState();
}

class _WeightEditorDialogState extends State<WeightEditorDialog> {
  final NotificationService _notificationService = Get.find();
  final OrderEditorController _orderEditorController = Get.find();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController boxesController = TextEditingController();
  final TextEditingController boxWeightController = TextEditingController();
  final TextEditingController actualWeightController = TextEditingController();

  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();

    boxesController.text = NumberFormatter.format(widget.product.orderedBoxes);
    boxWeightController.text = NumberFormatter.format(widget.product.boxWeight);
    actualWeightController.text =
        NumberFormatter.format(widget.product.actualTotalWeight);
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      backgroundColor: Colors.white,
      child: Material(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                  child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(10),
                      color: colorScheme.primary,
                      child: const Text(
                        "Modifica peso",
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      )),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(widget.product.name, style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      NumericTextField(
                          icon: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Icon(
                              FontAwesomeIcons.boxOpen,
                              color: colorScheme.tertiary,
                              size: 30,
                            ),
                          ),
                          label: 'Numero di colli',
                          controller: boxesController,
                          onChange: (val) => _refreshSubmit()),
                      const SizedBox(height: 10),
                      NumericTextField(
                          icon: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          FontAwesomeIcons.weightHanging,
                                          color: colorScheme.tertiary,
                                          size: 18,
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.only(top: 6.0),
                                          child: Text(
                                            "KG",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10),
                                          ),
                                        ),
                                      ]),
                                ),
                                Icon(
                                  FontAwesomeIcons.boxOpen,
                                  color: colorScheme.tertiary,
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                          label: 'Peso collo',
                          controller: boxWeightController,
                          onChange: (val) => _refreshSubmit()),
                      const SizedBox(height: 10),
                      NumericTextField(
                          icon: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Icon(
                              FontAwesomeIcons.scaleBalanced,
                              color: colorScheme.tertiary,
                              size: 30,
                            ),
                          ),
                          label: 'Peso reale',
                          controller: actualWeightController,
                          onChange: (val) => _refreshSubmit()),
                      const SizedBox(height: 50),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                                onPressed: () => Get.back(),
                                child: const Text("Annulla")),
                          ),
                          Expanded(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.tertiary,
                                    foregroundColor: Colors.white),
                                onPressed: _canSubmit ? _submit : null,
                                child: const Text('Conferma')),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshSubmit() {
    setState(() {
      _canSubmit = boxesController.text.isNotEmpty &&
          boxWeightController.text.isNotEmpty &&
          actualWeightController.text.isNotEmpty;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    double orderedBoxes = NumberFormatter.parseQuantity(boxesController.text);
    double boxWeight = NumberFormatter.parseQuantity(boxWeightController.text);
    double actualTotalWeight =
        NumberFormatter.parseQuantity(actualWeightController.text);

    bool distributionPerformed = _orderEditorController.productWeightsChanged(
        orderedBoxes, boxWeight, actualTotalWeight, widget.product);

    String distributionPerformedMessage =
        distributionPerformed ? " e pesi ridistribuiti sugli ordinanti" : "";

    Get.back();

    _notificationService.showInfo(
        "Peso prodotto aggiornato con successo$distributionPerformedMessage");
  }
}

class NumericTextField extends StatefulWidget {
  final Widget icon;
  final String label;
  final TextEditingController controller;
  final Function(String val) onChange;

  const NumericTextField(
      {super.key,
      required this.label,
      required this.controller,
      required this.onChange,
      required this.icon});

  @override
  State<NumericTextField> createState() => _NumericTextFieldState();
}

class _NumericTextFieldState extends State<NumericTextField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
        decoration: InputDecoration(
          border: const UnderlineInputBorder(),
          icon: widget.icon,
          labelText: widget.label,
        ),
        controller: widget.controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\,?\d{0,3}')),
          FilteringTextInputFormatter.deny('.', replacementString: ','),
        ],
        validator: (value) => (value == null || value.isEmpty)
            ? 'Inserire un valore numerico'
            : null,
        onChanged: widget.onChange);
  }
}
