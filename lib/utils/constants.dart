class Constants {
  static const String baseUrl = "http://127.0.0.1:5000";
  static String resolveImage(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    return "$baseUrl$path";
  }
}
