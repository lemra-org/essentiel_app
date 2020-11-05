import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

Future<Null> showAppAboutDialog(BuildContext context) async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();

  showAboutDialog(
    context: context,
    applicationVersion: packageInfo.version,
    applicationIcon: Image.asset("assets/images/essentiel_logo.svg.png",
        fit: BoxFit.scaleDown, width: 65.0),
    applicationLegalese: '© 2020',
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                  style: Theme.of(context).textTheme.bodyText1,
                  text: 'Application pour les groupes de partage Essentiel'
                      '\nDisponible sur '
                      '${defaultTargetPlatform == TargetPlatform.iOS ? 'plusieurs plateformes' : 'iOS et Android'}.')
            ],
          ),
        ),
      ),
    ],
  );
}
