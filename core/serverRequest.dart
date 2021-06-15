import 'dart:collection';
import 'dart:typed_data';
import 'dart:io';
import './serverUri.dart';

class ServerRequest {
  String uuid = "";
  int contentLength = 0;
  String method = "GET";
  String origin = "";
  String host = "";
  int port = 0;
  ServerUri uri = ServerUri();
  HashMap<String, List<String>> headers = HashMap();
  List<Uint8List> body = [];
  Map data = {};
}

class HttpRequestWrap {
  late HttpRequest request;
  late int timeStamp;

  HttpRequestWrap(HttpRequest req) {
    request = req;
    timeStamp = DateTime.now().millisecondsSinceEpoch;
  }
}
