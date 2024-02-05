import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:gogas_delivery_app/services/api_service.dart';
import 'package:gogas_delivery_app/services/common_services.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final ApiService _apiService = Get.find();
  final NotificationService _notificationService = Get.find();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController urlController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _canSubmit = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _apiService.getHost().then((value) => urlController.text = value ?? '');

    _apiService
        .getUsername()
        .then((value) => usernameController.text = value ?? '');
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Material(
        child: Container(
          constraints: BoxConstraints(maxWidth: 300),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(10),
                    color: colorScheme.primary,
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    )),
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(children: [
                    TextFormField(
                        decoration: InputDecoration(
                          border: const UnderlineInputBorder(),
                          labelText: 'Indirizzo Go!Gas',
                          suffixIcon: IconButton(
                              padding: const EdgeInsets.only(top: 5),
                              icon: Icon(
                                FontAwesomeIcons.solidCircleQuestion,
                                size: 28,
                                color: colorScheme.primary,
                              ),
                              onPressed: () => Get.defaultDialog(
                                  title: "Indirizzo Go!Gas",
                                  titleStyle:
                                      TextStyle(color: colorScheme.primary),
                                  content: const HostHint(),
                                  textConfirm: "OK",
                                  onConfirm: () => Get.back())),
                        ),
                        controller: urlController,
                        validator: (value) {
                          RegExp regExp = RegExp(
                            r"^.+\.aequos\.bio$",
                            caseSensitive: false,
                            multiLine: false,
                          );

                          if (!regExp.hasMatch(value ?? '')) {
                            return 'Inserire un indirizzo valido';
                          }

                          return null;
                        },
                        onChanged: (val) => _refreshSubmit()),
                    const SizedBox(height: 10),
                    TextFormField(
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Username',
                        ),
                        controller: usernameController,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Inserire la username'
                            : null,
                        onChanged: (val) => _refreshSubmit()),
                    const SizedBox(height: 10),
                    TextFormField(
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Password',
                        ),
                        controller: passwordController,
                        obscureText: true,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Inserire la password'
                            : null,
                        onChanged: (val) => _refreshSubmit()),
                    const SizedBox(height: 50),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                              onPressed: () => Get.back(),
                              child: Text("Annulla")),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.tertiary,
                                  foregroundColor: Colors.white),
                              onPressed:
                                  _canSubmit && !_loading ? _submit : null,
                              child: Row(children: [
                                const Expanded(
                                    child: Text(
                                  'Login',
                                  textAlign: TextAlign.center,
                                )),
                                _loading
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2.0),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(Icons.check)
                              ])),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                  ]),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _refreshSubmit() {
    setState(() {
      _canSubmit = urlController.text.isNotEmpty &&
          usernameController.text.isNotEmpty &&
          passwordController.text.isNotEmpty;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    _apiService
        .login(urlController.text, usernameController.text,
            passwordController.text)
        .then((value) {
      setState(() => _loading = false);

      if (value != null) {
        _notificationService.showError(value, duration: Duration(seconds: 3));
        return;
      }

      Get.back();
      _notificationService.showInfo("Login effettuato con successo");
    });
  }
}

class HostHint extends StatelessWidget {
  const HostHint({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: Text.rich(TextSpan(children: [
        TextSpan(
          text: "Inserire l'indirizzo di Go!Gas senza il prefisso ",
        ),
        TextSpan(
            text: "https://", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
          text: ".\n\nEsempio: ",
        ),
        TextSpan(
            text: "<nome-gas>.aequos.bio",
            style: TextStyle(
              fontStyle: FontStyle.italic,
            ))
      ])),
    );
  }
}
