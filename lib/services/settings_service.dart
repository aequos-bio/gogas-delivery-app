// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsService {
  static const List<String> sortingFieldOptions = [
    'name',
    'surname',
    'position',
    'weight'
  ];

  static const Map<String, Icon> sortingFieldIcons = {
    'name': Icon(
      Icons.abc,
      size: 30,
    ),
    'surname': Icon(Icons.abc, size: 30),
    'position': Icon(Icons.numbers),
    'weight': Icon(FontAwesomeIcons.scaleBalanced, size: 16),
  };

  static const Map<String, String> sortingFieldLabels = {
    'name': 'Nome gasista',
    'surname': 'Cognome gasista',
    'position': 'Posizione gasista',
    'weight': 'Peso richiesto',
  };

  static const List<String> sortingDirectionOptions = ['asc', 'desc'];

  static const Map<String, Icon> sortingDirectionIcons = {
    'asc': Icon(
      FontAwesomeIcons.arrowUp,
      size: 16,
    ),
    'desc': Icon(
      FontAwesomeIcons.arrowDown,
      size: 16,
    ),
  };

  static const Map<String, String> sortingDirectionLabels = {
    'asc': 'Crescente',
    'desc': 'Decrescente',
  };

  late Rx<UserSortingSettings> userSortingSettings;
  late RxBool automaticDistribution;
  late RxBool showEmptyProducts;
  late bool autoSaveEnabled;
  late int autoSavePeriodMinutes;

  void init() {
    GetStorage box = GetStorage();

    String? userSortingAsString = box.read("USER_SORTING");
    userSortingSettings = (userSortingAsString != null
            ? UserSortingSettings.fromJson(userSortingAsString)
            : UserSortingSettings.empty())
        .obs;

    automaticDistribution =
        (box.read<bool?>("AUTOMATIC_DISTRIBUTION") ?? false).obs;
    showEmptyProducts = (box.read<bool?>("SHOW_EMPTY_PRODUCTS") ?? false).obs;
    autoSaveEnabled = box.read<bool?>("AUTO_SAVE_ENABLED") ?? true;
    autoSavePeriodMinutes = box.read<int?>("AUTO_SAVE_PERIOD") ?? 5;
  }

  void changeSorting(String sortingField, String sortingDirection) {
    _changeSorting(sortingField, sortingDirection);
    _save();
  }

  void _changeSorting(String sortingField, String sortingDirection) {
    userSortingSettings.update((settings) {
      settings?.field = sortingField;
      settings?.direction = sortingDirection;
    });
  }

  void changeSettings(
      bool automaticDistribution,
      bool showEmptyProducts,
      String sortingField,
      String sortingDirection,
      bool autoSaveEnabled,
      int autoSavePeriodMinutes) {
    _changeSorting(sortingField, sortingDirection);

    this.automaticDistribution.value = automaticDistribution;
    this.showEmptyProducts.value = showEmptyProducts;
    this.autoSaveEnabled = autoSaveEnabled;
    this.autoSavePeriodMinutes = autoSavePeriodMinutes;

    _save();
  }

  Future<void> _save() async {
    GetStorage box = GetStorage();
    await box.write("USER_SORTING", userSortingSettings.value.toJson());
    await box.write("AUTOMATIC_DISTRIBUTION", automaticDistribution.value);
    await box.write("SHOW_EMPTY_PRODUCTS", showEmptyProducts.value);
    await box.write("AUTO_SAVE_ENABLED", autoSaveEnabled);
    await box.write("AUTO_SAVE_PERIOD", autoSavePeriodMinutes);
  }
}

class UserSortingSettings {
  String field;
  String direction;

  UserSortingSettings({
    required this.field,
    required this.direction,
  });

  String get key {
    return "$field-$direction";
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'field': field,
      'direction': direction,
    };
  }

  factory UserSortingSettings.fromMap(Map<String, dynamic> map) {
    return UserSortingSettings(
      field: map['field'] as String,
      direction: map['direction'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserSortingSettings.fromJson(String source) =>
      UserSortingSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  factory UserSortingSettings.empty() =>
      UserSortingSettings(field: 'position', direction: 'asc');
}

class Settings {
  UserSortingSettings userSorting;
  bool automaticDistributionEnabled;

  Settings({
    required this.userSorting,
    required this.automaticDistributionEnabled,
  });
}
