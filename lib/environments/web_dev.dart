import 'package:essentiel/env.dart';

void main() {
  WebDev().init();
}

class WebDev extends Env {
  // Web builds use backend API instead of direct Google Sheets access
  // Backend API handles Service Account credentials server-side
  final String backendApiUrl = 'http://localhost:8080';

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
