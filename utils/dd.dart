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

  static bool eqDomainRule(String d1, String d2) {
    var slice1 = d1.split('://');
    if (slice1.length < 2) {
      return false;
    }

    var slice2 = d2.split('://');
    if (slice2.length < 2) {
      return false;
    }

    if (slice1[0] != '*' && slice2[0] != '*' && slice1[0] != slice2[0]) {
      return false;
    }

    var port1 = '80';
    var port2 = '80';

    if (slice1[1].indexOf(':') > 0) {
      var temp = slice1[1].split(':')[0];
      if (temp[1].contains('?')) {
        port1 = temp.split('?')[0];
      }
    }
    if (slice2[1].indexOf(':') > 0) {
      var temp = slice2[1].split(':')[0];
      if (temp[1].contains('?')) {
        port1 = temp.split('?')[0];
      }
    }

    if (port1 != port2) {
      return false;
    }

    slice1 = slice1[1].split(':');
    slice2 = slice2[1].split(':');

    var list1 = slice1[0].split('.');
    if (list1.length != 4) {
      return false;
    }

    var list2 = slice2[0].split('.');
    if (list2.length != 4) {
      return false;
    }

    for (var i = 0; i < 4; i++) {
      if (list1[i] == '*' || list2[i] == '*') {
        continue;
      }
      if (list1[i] != list2[i]) {
        return false;
      }
    }

    return true;
  }

  
}
