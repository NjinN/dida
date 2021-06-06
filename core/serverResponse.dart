import 'dart:io';
import 'dart:collection';

class ServerResponse {
  String uuid = "";
  int code = 200;
  String contentType = ContentType.json.toString();
  Object data = {};
  HashMap<String, List<String>> headers = HashMap();
}
