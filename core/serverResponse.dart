import 'dart:io';
import 'dart:collection';
import 'dart:convert';
import 'package:mysql1/mysql1.dart';

import 'serverRequest.dart';
import '../utils/dd.dart';

class ServerResponse {
  String uuid = "";
  int code = 200;
  String contentType = ContentType.json.toString();
  Object data = {};
  HashMap<String, List<String>> headers = HashMap();
  late HttpResponse raw;

  ServerResponse(ServerRequest request) {
    raw = request.raw.response;
  }

  reply() async {
    try {
      raw.statusCode = code;
      raw.headers.contentType = ContentType.parse(contentType);
      if (headers.length > 0) {
        headers.forEach((key, value) {
          raw.headers.set(key, value);
        });
      }

      if (raw.headers.contentType!.mimeType == ContentType.json.mimeType) {
        if (data is Results) {
          data = DD.rows2str(data as Results);
        } else if (!(data is String)) {
          data = jsonEncode(data);
        }
      }
      if (data is List<int>) {
        raw.add(data as List<int>);
        await raw.flush();
        raw.close();
      } else {
        raw
          ..write(data)
          ..close();
      }
    } catch (e) {
      print(e.toString());
    }
  }
}
