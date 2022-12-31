import 'package:essentiel/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Env {
  static Env? value;

  String? spreadsheetId;

  String? saEmail;
  String? saId;
  String? saPK;

  Env() {
    value = this;
  }

  void init() async {
    debugPrint("******* Running with env: ${this.name} *******");

    WidgetsFlutterBinding.ensureInitialized();

    //Force portrait-mode
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    runApp(MyApp(this));
  }

  String get name => runtimeType.toString();
}
