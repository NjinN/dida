import 'dart:collection';
import 'dart:typed_data';
import 'dart:io';
import './serverUri.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

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
  late HttpRequest raw;

  ServerRequest(HttpRequest req) {
    uuid = Uuid().v1();
    raw = req;
    contentLength = req.contentLength;
    method = req.method;
    origin = req.requestedUri.origin;
    host = req.connectionInfo?.remoteAddress.host ?? "";
    port = req.connectionInfo?.localPort ?? 0;

    var hds = HashMap<String, List<String>>();
    req.headers.forEach((name, values) {
      hds[name] = values;
    });
    headers = hds;
    uri = ServerUri();
    uri.fragment = req.uri.fragment;
    uri.host = req.uri.host;
    uri.path = req.uri.path;
    uri.pathSegments = req.uri.pathSegments;
    uri.port = req.uri.port;
    uri.query = req.uri.query;
    uri.queryParameters = req.uri.queryParameters;
    uri.scheme = req.uri.scheme;
    uri.userInfo = req.uri.userInfo;
  }

  init() async {
    body = await raw.toList();
    if (raw.headers.contentType?.mimeType == ContentType.json.mimeType) {
      data = jsonDecode(utf8.decoder.convert(body[0]));
    }
  }
}

class HttpRequestWrap {
  late HttpRequest request;
  late int timeStamp;

  HttpRequestWrap(HttpRequest req) {
    request = req;
    timeStamp = DateTime.now().millisecondsSinceEpoch;
  }
}
