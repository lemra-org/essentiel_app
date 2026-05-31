import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<Null> showAppAboutDialog(BuildContext context) async {
  final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final currentYear = DateTime.now().year;
  final copyrightYears = currentYear > 2020 ? '2020-$currentYear' : '2020';

  // For web, use a custom dialog with larger text
  if (kIsWeb) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Essentiel',
            style: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("assets/images/essentiel_logo.svg.png",
                    fit: BoxFit.scaleDown, width: 130.0, cacheWidth: 260),
                SizedBox(height: 16.0),
                Text(
                  packageInfo.version,
                  style: TextStyle(fontSize: 32.0, color: Colors.grey[600]),
                ),
                SizedBox(height: 24.0),
                Text(
                  '© $copyrightYears',
                  style: TextStyle(fontSize: 28.0, color: Colors.grey[600]),
                ),
                SizedBox(height: 32.0),
                Text(
                  'Application pour les groupes de partage Essentiel\n\nDisponible sur web (${_getPlatformDescription()}).',
                  style: TextStyle(fontSize: 36.0),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'FERMER',
                style: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  } else {
    // For mobile, use the standard showAboutDialog
    showAboutDialog(
      context: context,
      applicationVersion: packageInfo.version,
      applicationIcon: Image.asset("assets/images/essentiel_logo.svg.png",
          fit: BoxFit.scaleDown, width: 65.0, cacheWidth: 130),
      applicationLegalese: '© $copyrightYears',
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 24.0),
          child: Text(
            'Application pour les groupes de partage Essentiel'
                '\n\nDisponible sur mobile (${_getPlatformDescription()}).',
            style: TextStyle(fontSize: 14.0),
          ),
        ),
      ],
    );
  }
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
