import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<Null> showAppAboutDialog(BuildContext context) async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final currentYear = DateTime.now().year;
  final copyrightYears = currentYear > 2020 ? '2020-$currentYear' : '2020';

  showAboutDialog(
    context: context,
    applicationVersion: packageInfo.version,
    applicationIcon: Image.asset("assets/images/essentiel_logo.svg.png",
        fit: BoxFit.scaleDown, width: 65.0, cacheWidth: 130),
    applicationLegalese: '© $copyrightYears',
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  text: 'Application pour les groupes de partage Essentiel'
                      '\n\nDisponible sur ${kIsWeb ? 'web' : 'mobile'} (${_getPlatformDescription()}).')
            ],
          ),
        ),
      ),
    ],
  );
}

String _getPlatformDescription() {
  if (kIsWeb) {
    return 'navigateurs modernes';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'iOS';
    case TargetPlatform.android:
      return 'Android';
    default:
      return 'iOS, Android, et web';
  }
}
