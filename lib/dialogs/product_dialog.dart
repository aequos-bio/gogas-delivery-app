import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/model/order.dart';
import 'package:gogas_delivery_app/services/settings_service.dart';
import 'package:gogas_delivery_app/widgets/forms.dart';

class OperationConfirmDialog extends StatelessWidget {
  OperationConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.onConfirm,
    required this.width,
  });

  final String title;
  final String body;
  final Function onConfirm;
  final double width;

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Dialog(
        child: Container(
            width: width,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28)),
                      color: colorScheme.primary),
                  height: 60,
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  )),
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
                      Flexible(child: Text(body))
                    ]),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                              onPressed: () {
                                Get.back();
                              },
                              child: const Text("Annulla")),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                              onPressed: () {
                                Get.back();
                                onConfirm();
                              },
                              child: const Text('Conferma')),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ])));
  }
}

class SortDialog extends StatefulWidget {
  const SortDialog({super.key});

  @override
  State<SortDialog> createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  final SettingsService _settingsService = Get.find();
  late String sortingField;
  late String sortingDirection;

  @override
  void initState() {
    sortingField = _settingsService.userSortingSettings.value.field;
    sortingDirection = _settingsService.userSortingSettings.value.direction;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Material(
        child: Container(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          width: 500,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 60,
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.primary,
                child: Text("Ordinamento",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white)),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SortingForm(
                    initialField: sortingField,
                    initialDirection: sortingDirection,
                    onChange: (selectedField, selectedDirection) {
                      sortingField = selectedField;
                      sortingDirection = selectedDirection;
                    }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: Text("Annulla")),
                  SizedBox(
                    width: 15,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: Colors.white),
                      onPressed: () {
                        _settingsService.changeSorting(
                            sortingField, sortingDirection);
                        Get.back();
                      },
                      child: Text("Conferma")),
                ],
              ),
              SizedBox(
                height: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddUserDialog extends StatefulWidget {
  final List<User> users;
  final Function(String userId) onConfirm;

  const AddUserDialog(
      {super.key, required this.users, required this.onConfirm});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        width: 370,
        height: 600,
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28)),
                    color: colorScheme.primary),
                height: 60,
                alignment: Alignment.center,
                child: Text(
                  "Aggiungi un gasista",
                  style: TextStyle(fontSize: 24, color: Colors.white),
                )),
            Expanded(
              child: ListView.builder(
                  itemCount: widget.users.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: selectedIndex == index
                            ? Color.fromARGB(255, 224, 248, 225)
                            : Colors.white,
                        border: Border(
                            bottom: BorderSide(
                                color: Color.fromARGB(255, 218, 218, 218))),
                      ),
                      child: ListTile(
                        title: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "${widget.users[index].firstName} ${widget.users[index].lastName}",
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: selectedIndex == index
                              ? Colors.green
                              : Color.fromARGB(255, 218, 218, 218),
                          foregroundColor: Colors.white,
                          child: Text("${widget.users[index].position}",
                              style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w100)),
                        ),
                        onTap: () => setState(() {
                          selectedIndex = index;
                        }),
                      ),
                    );
                  }),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () => Get.back(), child: Text("Annulla")),
                  SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: Colors.white),
                      onPressed: selectedIndex >= 0
                          ? () {
                              widget.onConfirm(widget.users[selectedIndex].id);
                              Get.back();
                            }
                          : null,
                      child: Text("Conferma")),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
