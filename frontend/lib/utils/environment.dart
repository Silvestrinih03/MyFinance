class Environment {
  static const bool isProduction = false;

  static String get apiBaseUrl {
    if (isProduction) {
      return "https://SEU-BACKEND.up.railway.app";
    } else {
      return "http://10.0.2.2:8000";
    }
  }
}
