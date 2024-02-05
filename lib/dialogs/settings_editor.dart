import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/services/common_services.dart';
import 'package:gogas_delivery_app/services/settings_service.dart';
import 'package:gogas_delivery_app/widgets/forms.dart';

class SettingsEditorDialog extends StatefulWidget {
  const SettingsEditorDialog({super.key});

  @override
  State<SettingsEditorDialog> createState() => _SettingsEditorDialogState();
}

class _SettingsEditorDialogState extends State<SettingsEditorDialog> {
  final NotificationService _notificationService = Get.find();
  final SettingsService _settingsService = Get.find();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController autoSavePeriodController =
      TextEditingController();

  late bool _automaticDistribution;
  late bool _showEmptyProducts;
  late String _sortingField;
  late String _sortingDirection;
  late bool _autoSaveEnabled;
  late int _autoSavePeriodMinutes;

  @override
  void initState() {
    super.initState();

    _automaticDistribution = _settingsService.automaticDistribution.value;
    _showEmptyProducts = _settingsService.showEmptyProducts.value;
    _sortingField = _settingsService.userSortingSettings.value.field;
    _sortingDirection = _settingsService.userSortingSettings.value.direction;
    _autoSaveEnabled = _settingsService.autoSaveEnabled;
    _autoSavePeriodMinutes = _settingsService.autoSavePeriodMinutes;

    autoSavePeriodController.text = _autoSavePeriodMinutes.toString();
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
          constraints: const BoxConstraints(maxWidth: 480),
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
                        "Impostazioni",
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      )),
                ),
              ]),
              SizedBox(
                height: 5,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CupertinoSwitch(
                              value: _automaticDistribution,
                              onChanged: (value) => setState(
                                  () => _automaticDistribution = value),
                              activeColor: colorScheme.primary),
                          SizedBox(
                            width: 10,
                          ),
                          _buildLabel("Distribuzione automatica delle quantità",
                              _automaticDistribution),
                          SizedBox(
                            width: 10,
                          ),
                          Tooltip(
                            textAlign: TextAlign.center,
                            message:
                                "Abilitando questa opzione i pesi da distribuire ai gasisti\n"
                                "verranno ricalcolati proporzionalmente ad ogni modifica\n"
                                "del peso reale del prodotto",
                            child: Icon(
                              FontAwesomeIcons.circleInfo,
                              size: 24,
                              color: _automaticDistribution
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CupertinoSwitch(
                              value: _showEmptyProducts,
                              onChanged: (value) =>
                                  setState(() => _showEmptyProducts = value),
                              activeColor: colorScheme.primary),
                          SizedBox(
                            width: 10,
                          ),
                          _buildLabel(
                              "Mostra prodotti annullati", _showEmptyProducts),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CupertinoSwitch(
                              value: _autoSaveEnabled,
                              onChanged: (value) =>
                                  setState(() => _autoSaveEnabled = value),
                              activeColor: colorScheme.primary),
                          SizedBox(
                            width: 10,
                          ),
                          _buildLabel("Salvataggio automatico attivo ogni",
                              _autoSaveEnabled),
                          SizedBox(
                            width: 4,
                          ),
                          SizedBox(
                            width: 50,
                            height: 30,
                            child: TextFormField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.only(
                                  bottom: 5,
                                ),
                                errorStyle: const TextStyle(fontSize: 0),
                              ),
                              textAlign: TextAlign.center,
                              controller: autoSavePeriodController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+'))
                              ],
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Non valido'
                                      : null,
                              onChanged: (value) {
                                if (value != '') {
                                  _autoSavePeriodMinutes = int.parse(value);
                                }
                              },
                              enabled: _autoSaveEnabled,
                            ),
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          _buildLabel("minuti", _autoSaveEnabled),
                        ],
                      ),
                      const SizedBox(height: 40),
                      SortingForm(
                          initialField: _sortingField,
                          initialDirection: _sortingDirection,
                          onChange: (selectedField, selectedDirection) {
                            _sortingField = selectedField;
                            _sortingDirection = selectedDirection;
                          }),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          SizedBox(width: 20),
                          Expanded(
                            child: ElevatedButton(
                                onPressed: () => Get.back(),
                                child: const Text("Annulla")),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.tertiary,
                                    foregroundColor: Colors.white),
                                onPressed: _submit,
                                child: const Text('Conferma')),
                          ),
                          SizedBox(width: 20),
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

  Text _buildLabel(String text, bool enabled) {
    return Text(
      text,
      style: TextStyle(color: enabled ? Colors.black : Colors.grey),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _settingsService.changeSettings(
        _automaticDistribution,
        _showEmptyProducts,
        _sortingField,
        _sortingDirection,
        _autoSaveEnabled,
        _autoSavePeriodMinutes);

    Get.back();
    _notificationService.showInfo("Impostazioni aggiornate con successo");
  }
}
