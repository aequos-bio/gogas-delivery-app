import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SortingForm extends StatefulWidget {
  static const List<SortOption> sortingFieldOptions = [
    SortOption(
        icon: Icon(Icons.abc, size: 34), label: 'Nome gasista', value: 'name'),
    SortOption(
        icon: Icon(Icons.abc, size: 34),
        label: 'Cognome gasista',
        value: 'surname'),
    SortOption(
        icon: Icon(Icons.numbers),
        label: 'Posizione gasista',
        value: 'position'),
    SortOption(
        icon: Icon(FontAwesomeIcons.scaleBalanced, size: 18),
        label: 'Peso richiesto',
        value: 'weight'),
  ];

  static const List<SortOption> sortingDirectionOptions = [
    SortOption(
        icon: Icon(FontAwesomeIcons.arrowUp, size: 18),
        label: 'Crescente',
        value: 'asc'),
    SortOption(
        icon: Icon(FontAwesomeIcons.arrowDown, size: 18),
        label: 'Descrescente',
        value: 'desc')
  ];

  final String initialField;
  final String initialDirection;
  final Function(String selectedField, String selectedDirection) onChange;

  const SortingForm(
      {super.key,
      required this.initialField,
      required this.initialDirection,
      required this.onChange});

  @override
  State<SortingForm> createState() => _SortingFormState();
}

class _SortingFormState extends State<SortingForm> {
  late SortOption seletedField;
  late SortOption selectedDirection;

  @override
  void initState() {
    seletedField = SortingForm.sortingFieldOptions
        .where((option) => option.value == widget.initialField)
        .first;

    selectedDirection = SortingForm.sortingDirectionOptions
        .where((option) => option.value == widget.initialDirection)
        .first;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30, horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Text("Ordina per"),
                      SizedBox(
                        width: 20,
                      ),
                      Expanded(
                          child: Container(
                        child: DropdownSearch<SortOption>(
                            popupProps: PopupProps.menu(
                                fit: FlexFit.loose,
                                itemBuilder: (context, item, isSelected) =>
                                    _buildSelectItem(item, isSelected, true)),
                            dropdownBuilder: (context, selectedItem) =>
                                _buildSelectItem(selectedItem!, false, false),
                            selectedItem: seletedField,
                            items: SortingForm.sortingFieldOptions,
                            onChanged: (selectedOption) => setState(
                                  () {
                                    seletedField = selectedOption!;
                                    widget.onChange(seletedField.value,
                                        selectedDirection.value);
                                  },
                                )),
                      )),
                    ]),
                    SizedBox(
                      height: 10,
                    ),
                    Row(children: [
                      Text("Direzione  "),
                      SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child: DropdownSearch<SortOption>(
                            popupProps: PopupProps.menu(
                                fit: FlexFit.loose,
                                itemBuilder: (context, item, isSelected) =>
                                    _buildSelectItem(item, isSelected, true)),
                            dropdownBuilder: (context, selectedItem) =>
                                _buildSelectItem(selectedItem!, false, false),
                            selectedItem: selectedDirection,
                            items: SortingForm.sortingDirectionOptions,
                            onChanged: (selectedOption) => setState(
                                  () {
                                    selectedDirection = selectedOption!;
                                    widget.onChange(seletedField.value,
                                        selectedDirection.value);
                                  },
                                )),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -10,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: Text(
                    "Ordinamento gasisti",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectItem(
      SortOption sortOption, bool selected, bool isListItem) {
    return Container(
        height: 40,
        padding: isListItem
            ? EdgeInsets.symmetric(vertical: 10, horizontal: 20)
            : EdgeInsets.all(10),
        color: selected ? Colors.grey : null,
        child: Row(children: [
          Container(
              width: 25, alignment: Alignment.center, child: sortOption.icon),
          SizedBox(width: 20),
          Text(
            sortOption.label,
            style: const TextStyle(fontSize: 16),
          )
        ]));
  }
}

class SortOption {
  final Icon icon;
  final String label;
  final String value;

  const SortOption(
      {required this.icon, required this.label, required this.value});
}
