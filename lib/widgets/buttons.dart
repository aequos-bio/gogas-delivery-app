import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/controllers/order_controller.dart';
import 'package:gogas_delivery_app/dialogs/login.dart';
import 'package:gogas_delivery_app/dialogs/order_upload.dart';
import 'package:gogas_delivery_app/services/api_service.dart';
import 'package:gogas_delivery_app/services/common_services.dart';

class SaveButton extends StatelessWidget {
  final OrderEditorController _orderEditorController = Get.find();

  SaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Salva le modifiche effettuate",
      child: Obx(() => ElevatedButton(
          onPressed: _orderEditorController.canSave.value
              ? _orderEditorController.save
              : null,
          child: const Icon(FontAwesomeIcons.floppyDisk))),
    );
  }
}

class ViewModeButton extends StatelessWidget {
  final OrderEditorController _orderEditorController = Get.find();

  ViewModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = context.theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Obx(
        () => AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: Row(
              key: ValueKey(_orderEditorController.viewMode.value.toString()),
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTab(colorScheme, "Visualizza ordini per prodotto",
                    FontAwesomeIcons.boxesPacking, OrderViewMode.product),
                _buildTab(colorScheme, "Visualizza ordini per utente",
                    FontAwesomeIcons.userLarge, OrderViewMode.user),
              ],
            )),
      ),
    );
  }

  Tooltip _buildTab(ColorScheme colorScheme, String tooltip, IconData icon,
      OrderViewMode viewMode) {
    bool selected = _orderEditorController.viewMode.value == viewMode;

    return Tooltip(
      message: "Visualizza ordini per utente",
      child: InkWell(
          onTap: selected ? null : _orderEditorController.toggleViewMode,
          child: Container(
              color: selected ? colorScheme.primary : null,
              padding: EdgeInsets.symmetric(vertical: 7, horizontal: 30),
              child: Icon(
                icon,
                color: selected ? Colors.white : colorScheme.primary,
              ))),
    );
  }
}

class UploadButton extends StatelessWidget {
  final OrderEditorController _orderEditorController = Get.find();
  final ApiService _apiService = Get.find();

  UploadButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Invia i pesi a Go!Gas",
      child: Obx(() => ElevatedButton(
          onPressed: _apiService.authenticated.value
              ? () {
                  _orderEditorController.initOrderUpload();
                  Get.dialog(OrderUploadDialog(), barrierDismissible: false);
                }
              : () => Get.defaultDialog(
                  title: "Autenticazione richiesta",
                  textCancel: "Chiudi",
                  contentPadding: EdgeInsets.all(20),
                  content: const Row(children: [
                    Icon(
                      FontAwesomeIcons.triangleExclamation,
                      color: Colors.red,
                      size: 40,
                    ),
                    SizedBox(width: 20),
                    Flexible(
                        child: Text(
                            "E' necessario effettuare il login per poter\ninviare i pesi a Go!Gas"))
                  ])),
          child: const Icon(FontAwesomeIcons.upload))),
    );
  }
}

class PackageOnlyButton extends StatelessWidget {
  final OrderEditorController _orderEditorController = Get.find();

  PackageOnlyButton({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
        message: "Mostra solo prodotti da consegnare a pezzi",
        child: Obx(
          () => Card(
              margin: EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 6),
                    child: Icon(
                      FontAwesomeIcons.boxesStacked,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    width: 50,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: CupertinoSwitch(
                          value: _orderEditorController
                              .viewPackageProductsOnly.value,
                          onChanged: (value) => _orderEditorController
                              .updateViewPackageProductsOnly(value),
                          activeColor: colorScheme.primary),
                    ),
                  ),
                ],
              )),
        ));
  }
}

class SearchButton extends StatefulWidget {
  final String tooltip;
  final void Function({String? searchText}) searchFunction;

  const SearchButton(
      {super.key, required this.tooltip, required this.searchFunction});

  @override
  State<SearchButton> createState() => _SearchButtonState();
}

class _SearchButtonState extends State<SearchButton> {
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = context.theme.colorScheme;

    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation, axis: Axis.horizontal, child: child),
        child: _buildButton(colorScheme));
  }

  Widget _buildButton(ColorScheme colorScheme) {
    if (!_searching) {
      return Tooltip(
        key: const ValueKey("close"),
        message: widget.tooltip,
        child: ElevatedButton(
            onPressed: () => setState(() {
                  _searching = true;
                }),
            child: const Icon(FontAwesomeIcons.magnifyingGlass)),
      );
    }

    return Container(
      key: const ValueKey("open"),
      width: 220,
      height: 32,
      child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {
                String? searchText = value.length > 3 ? value : null;
                widget.searchFunction(searchText: searchText);
              }),
          decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              alignLabelWithHint: true,
              hintText: widget.tooltip,
              filled: true,
              fillColor: Colors.white,
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
                borderRadius: BorderRadius.circular(15),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
                borderRadius: BorderRadius.circular(15),
              ),
              suffixIcon: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() {
                        _searching = false;
                        _searchController.text = '';
                        widget.searchFunction();
                      }),
                  icon: const Icon(FontAwesomeIcons.xmark)),
              prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass),
              prefixIconColor: colorScheme.primary)),
    );
  }
}

class LoginButton extends StatelessWidget {
  final ApiService _apiService = Get.find();
  final NotificationService _notificationService = Get.find();

  LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool authenticated = _apiService.authenticated.value;
      String userCompleteName = _apiService.userCompleteName ?? '';

      return Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        elevation: 0,
        child: AnimatedContainer(
          padding: EdgeInsets.symmetric(horizontal: authenticated ? 6 : 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          height: authenticated ? 36 : 42,
          constraints: BoxConstraints(maxWidth: authenticated ? 200 : 60),
          color: authenticated
              ? Colors.white
              : Theme.of(context).colorScheme.primary,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                  icon: Icon(
                    FontAwesomeIcons.userLarge,
                    color: authenticated
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                  ),
                  iconSize: authenticated ? 20 : 28,
                  itemBuilder: (context) => _buildMenu(authenticated)),
              Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: Container(
                  key: ValueKey("auth:$authenticated"),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: authenticated
                        ? Text(userCompleteName)
                        : const SizedBox(width: 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<PopupMenuEntry<String>> _buildMenu(bool authenticated) {
    if (authenticated) {
      return [
        PopupMenuItem<String>(
          value: 'logout',
          child: const Text('Logout'),
          onTap: () {
            _apiService.logout();
            _notificationService.showInfo("Logout effettuato con successo");
          },
        )
      ];
    }

    return [
      PopupMenuItem<String>(
        value: 'login',
        child: const Text('Accedi a Go!Gas'),
        onTap: () => Get.dialog(const LoginDialog(), barrierDismissible: false),
      )
    ];
  }
}
