import 'package:essentiel/env.dart';

void main() {
  WebProd().init();
}

class WebProd extends Env {
  // Web builds use backend API instead of direct Google Sheets access
  // Backend API handles Service Account credentials server-side
  // Production backend URL (to be deployed to one of these URLs)
  final String backendApiUrl = 'https://api.essentiel.app';

  // Alternative production URL: 'https://api.essentiel.soro.io'

  // Service Account credentials not needed for web builds
  // (backend API handles authentication)
  @override
  String? get saEmail => null;

  @override
  String? get saId => null;

  @override
  String? get saPK => null;

  @override
  String? get spreadsheetId => null;
}
