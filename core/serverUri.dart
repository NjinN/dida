class ServerUri {
  String scheme = "";
  String userInfo = "";
  String host = "";
  int port = 0;
  String path = "";
  Iterable<String> pathSegments = [];
  String query = "";
  Map<String, dynamic> queryParameters = Map();
  String fragment = "";
}
