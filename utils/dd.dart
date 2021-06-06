import 'dart:convert';
import 'package:mysql1/mysql1.dart';
import '../core/serverException.dart';

class DD {
  static List<Map> rows2list(Results res) {
    List<Map> rows = [];
    res.forEach((element) {
      rows.add(element.fields);
    });
    return rows;
  }

  static String rows2str(Results res) {
    return jsonEncode(rows2list(res));
  }

  static checkParams(Map m, List<String> ks) {
    ks.forEach((k) {
      if (!m.containsKey(k)) {
        throw ServerException("Param ${k} can not be empty");
      }
    });
  }

  static Map takeParams(Map m, List<String> ks) {
    Map ps = {};
    ks.forEach((k) {
      if (m.containsKey(k)) {
        ps[k] = m[k];
      }
    });
    return ps;
  }
}
