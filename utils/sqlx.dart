import '../core/dbConnection.dart';
import './dd.dart';

class Sqlx {
  String sqlMode = "SELECT";

  String selectStr = "";
  String fromStr = "";
  String whereStr = "";
  String groupStr = "";
  String havingStr = "";
  String orderStr = "";
  String limitStr = "";
  String returnStr = "";
  String insertStr = "";
  String valuesStr = "";
  // String tableStr = "";
  String updateStr = "";
  String deleteStr = "";

  List<Object> params = [];

  Sqlx mode(String s) {
    sqlMode = s.toUpperCase();
    return this;
  }

  Sqlx init() {
    sqlMode = "SELECT";
    selectStr = "";
    fromStr = "";
    whereStr = "";
    groupStr = "";
    havingStr = "";
    orderStr = "";
    limitStr = "";
    returnStr = "";
    insertStr = "";
    valuesStr = "";
    // tableStr = "";
    updateStr = "";
    deleteStr = "";
    params = [];
    return this;
  }

  Sqlx select(dynamic sel, {String alias = ""}) {
    sqlMode = "SELECT";
    if (sel is String) {
      selectStr += sel + " ";
    } else if (sel is List) {
      if (alias != "") {
        alias += ".";
      }
      for (var item in sel) {
        selectStr += alias + item + ",";
      }
    } else if (sel is Map) {
      if (alias != "") {
        alias += ".";
      }
      for (var item in sel.keys) {
        selectStr += alias + item + ",";
      }
    }

    return this;
  }

  Sqlx from(String tb, {String alias = ""}) {
    fromStr += tb + " " + alias + " ";
    return this;
  }

  Sqlx leftJoin(String tb, String alias, String oon) {
    fromStr += " LEFT JOIN " + tb + " " + alias + " ON " + oon + " ";
    return this;
  }

  Sqlx where(dynamic cond, {String alias = ""}) {
    if (cond is String) {
      whereStr += cond + " ";
    } else if (cond is Map) {
      Map m = cond;
      if (alias != "") {
        alias += ".";
      }
      for (var k in m.keys) {
        var v = m[k];
        if (v == "" || v == "offset" || v == "limit") {
          continue;
        }
        if (k == "where") {
          if (v is List) {
            v.forEach((element) {
              whereStr += " AND ?";
              params.add(element);
            });
          } else {
            whereStr += " AND ?";
            params.add(v);
          }
        } else if (k.endsWith("__ne")) {
          var attr = k.substring(0, k.length - 4);

          whereStr += "AND ${alias + attr} <> ? ";
          params.add(v!);
        } else if (k.endsWith("__like")) {
          var attr = k.substring(0, k.length - 6);

          whereStr += "AND ${alias + attr} LIKE CONCAT('%', ?, '%') ";
          params.add(v!);
        } else if (k.endsWith("__llike")) {
          var attr = k.substring(0, k.length - 7);

          whereStr += "AND ${alias + attr} LIKE CONCAT('%', ?) ";
          params.add(v!);
        } else if (k.endsWith("__rlike")) {
          var attr = k.substring(0, k.length - 7);

          whereStr += "AND ${alias + attr} LIKE CONCAT(?, '%') ";
          params.add(v!);
        } else if (k.endsWith("__isn")) {
          var attr = k.substring(0, k.length - 5);
          if (v as bool) {
            whereStr += "AND ${alias + attr} IS NULL ";
          } else {
            whereStr += "AND ${alias + attr} IS NOT NULL ";
          }
        } else if (k.endsWith("__lt")) {
          var attr = k.substring(0, k.length - 4);

          whereStr += "AND ${alias + attr} < ? ";
          params.add(v!);
        } else if (k.endsWith("__gt")) {
          var attr = k.substring(0, k.length - 4);

          whereStr += "AND ${alias + attr} > ? ";
          params.add(v!);
        } else if (k.endsWith("__le")) {
          var attr = k.substring(0, k.length - 4);

          whereStr += "AND ${alias + attr} <= ? ";
          params.add(v!);
        } else if (k.endsWith("__ge")) {
          var attr = k.substring(0, k.length - 4);

          whereStr += "AND ${alias + attr} >= ? ";
          params.add(v!);
        } else if (k.endsWith("__ltgt") && v is List && v.length == 2) {
          var attr = k.substring(0, k.length - 6);

          whereStr += "AND ${alias + attr} < ? AND ${alias + attr} > ? ";
          params.add(v[0]);
          params.add(v[1]);
        } else if (k.endsWith("__legt") && v is List && v.length == 2) {
          var attr = k.substring(0, k.length - 6);

          whereStr += "AND ${alias + attr} <= ? AND ${alias + attr} > ? ";
          params.add(v[0]);
          params.add(v[1]);
        } else if (k.endsWith("__ltge") && v is List && v.length == 2) {
          var attr = k.substring(0, k.length - 6);

          whereStr += "AND ${alias + attr} < ? AND ${alias + attr} >= ? ";
          params.add(v[0]);
          params.add(v[1]);
        } else if (k.endsWith("__lege") && v is List && v.length == 2) {
          var attr = k.substring(0, k.length - 6);

          whereStr += "AND ${alias + attr} <= ? AND ${alias + attr} >= ? ";
          params.add(v[0]);
          params.add(v[1]);
        } else if (v is List) {
          var list = v;
          if (k.endsWith("__in") && list.length > 0) {
            var attr = k.substring(0, k.length - 4);
            var str = " AND ${alias + attr} IN (";
            for (var i = 0; i < list.length; i++) {
              str += "?";
              params.add(list[i]);
              if (i < list.length - 1) {
                str += ",";
              } else {
                str += ") ";
              }
            }
            whereStr += str;
          } else {
            whereStr += " AND " + whereList(list, alias + k);
          }
        } else if (v is Map) {
          whereStr += " AND " + whereMap(v, '${alias + k}');
        } else {
          whereStr += " AND ${alias + k} = ? ";
          params.add(v!);
        }
      }
    }

    return this;
  }

  String whereList(List list, String attr, {String mode = "and"}) {
    var str = "";
    var origin = [...params];
    try {
      for (var i = 0; i < list.length - 1; i += 2) {
        if (i > 0) {
          if (list[i] != "and" && list[i] != "or") {
            if (mode == "and") {
              str += " AND ";
            } else {
              str += " OR ";
            }
          }
        }

        switch (list[i]) {
          case "eq":
            str += "${attr} = ?";
            params.add(list[i + 1]);
            break;
          case "ne":
            str += "${attr} <> ?";
            params.add(list[i + 1]);
            break;
          case "like":
            str += "${attr} LIKE CONCAT('%', ?, '%')";
            params.add(list[i + 1]);
            break;
          case "llike":
            str += "${attr} LIKE CONCAT(?, '%')";
            params.add(list[i + 1]);
            break;
          case "rlike":
            str += "${attr} LIKE CONCAT('%', ?)";
            params.add(list[i + 1]);
            break;
          case "lt":
            str += "${attr} < ?";
            params.add(list[i + 1]);
            break;
          case "gt":
            str += "${attr} > ?";
            params.add(list[i + 1]);
            break;
          case "le":
            str += "${attr} <= ?";
            params.add(list[i + 1]);
            break;
          case "ge":
            str += "${attr} >= ?";
            params.add(list[i + 1]);
            break;
          case "ltgt":
            str += "(${attr} < ? AND ${attr} > ?)";
            params.add(list[i + 1][0]);
            params.add(list[i + 1][1]);
            break;
          case "legt":
            str += "(${attr} <= ? AND ${attr} > ?)";
            params.add(list[i + 1][0]);
            params.add(list[i + 1][1]);
            break;
          case "ltge":
            str += "(${attr} < ? AND ${attr} >= ?)";
            params.add(list[i + 1][0]);
            params.add(list[i + 1][1]);
            break;
          case "lege":
            str += "(${attr} <= ? AND ${attr} >= ?)";
            params.add(list[i + 1][0]);
            params.add(list[i + 1][1]);
            break;
          case "and":
            if (list[i + 1] is List) {
              str += " (" + whereList(list[i + 1], attr) + ")";
            } else if (list[i + 1] is Map) {
              str += " (" + whereMap(list[i + 1], attr) + ")";
            }
            break;
          case "or":
            if (list[i + 1] is List) {
              str += " (" + whereList(list[i + 1], attr, mode: "or") + ")";
            } else if (list[i + 1] is Map) {
              str += " (" + whereMap(list[i + 1], attr, mode: "or") + ")";
            }

            break;
          default:
        }
      }
    } catch (e) {
      params = origin;
      return '';
    }

    return str;
  }

  String whereMap(Map m, String attr, {String mode = 'and'}) {
    var str = "";
    var origin = [...params];
    try {
      var i = 0;
      m.forEach((key, value) {
        i++;
        if (i > 1) {
          if (mode == 'and') {
            str += " AND ";
          } else {
            str += " OR ";
          }
        }
        if (key == 'eq') {
          str += " ${attr} = ? ";
          params.add(value);
        } else if (key == 'ne') {
          str += " ${attr} <> ? ";
          params.add(value);
        } else if (key == 'like') {
          str += " ${attr} LIKE CONCAT('%', ?, '%') ";
          params.add(value);
        } else if (key == 'llike') {
          str += " ${attr} LIKE CONCAT(?, '%') ";
          params.add(value);
        } else if (key == 'rlike') {
          str += " ${attr} LIKE CONCAT('%', ?) ";
          params.add(value);
        } else if (key == 'lt') {
          str += " ${attr} < ? ";
          params.add(value);
        } else if (key == 'gt') {
          str += " ${attr} < ? ";
          params.add(value);
        } else if (key == 'le') {
          str += " ${attr} <= ? ";
          params.add(value);
        } else if (key == 'ge') {
          str += " ${attr} >= ? ";
          params.add(value);
        } else if (key == 'ltgt' && value is List && value.length == 2) {
          str += " (${attr} < ? AND ${attr} > ?)  ";
          params.add(value[0]);
          params.add(value[1]);
        } else if (key == 'legt' && value is List && value.length == 2) {
          str += " (${attr} <= ? AND ${attr} > ?)  ";
          params.add(value[0]);
          params.add(value[1]);
        } else if (key == 'ltge' && value is List && value.length == 2) {
          str += " (${attr} < ? AND ${attr} >= ?)  ";
          params.add(value[0]);
          params.add(value[1]);
        } else if (key == 'lege' && value is List && value.length == 2) {
          str += " (${attr} <= ? AND ${attr} >= ?) ";
          params.add(value[0]);
          params.add(value[1]);
        } else if (key == 'isn') {
          if (value as bool) {
            str += " ${attr} IS NULL ";
          } else {
            str += " ${attr} IS NOT NULL ";
          }
        } else if (key == "and") {
          if (value is List) {
            str += " (" + whereList(value, attr) + ")";
          } else if (value is Map) {
            str += " (" + whereMap(value, attr) + ")";
          }
        } else if (key == "or") {
          if (value is List) {
            str += " (" + whereList(value, attr, mode: "or") + ")";
          } else if (value is Map) {
            str += " (" + whereMap(value, attr, mode: "or") + ")";
          }
        }
      });
    } catch (e) {
      params = origin;
      return '';
    }

    return str;
  }

  Sqlx and(String s, [List<Object>? list]) {
    whereStr += " AND " + s;
    if (list != null) {
      params.addAll(list);
    }
    return this;
  }

  Sqlx or(String s, [List<Object>? list]) {
    whereStr += " OR " + s;
    if (list != null) {
      params.addAll(list);
    }
    return this;
  }

  Sqlx group(dynamic grp, {String alias = ""}) {
    if (grp is String) {
      groupStr += grp + ",";
    } else if (grp is List) {
      if (alias != "") {
        alias += ".";
      }
      for (var item in grp) {
        groupStr += alias + item + ",";
      }
    }

    return this;
  }

  Sqlx having(dynamic hav, {String alias = ""}) {
    if (hav is String) {
      havingStr += " AND " + hav + " ";
    } else if (hav is List) {
      if (alias != "") {
        alias += ".";
      }
      for (var item in hav) {
        havingStr += " AND " + alias + item + ",";
      }
    }

    return this;
  }

  Sqlx order(dynamic ord, {String alias = ""}) {
    if (ord is String) {
      orderStr += ord + ",";
    } else if (ord is List) {
      if (alias != "") {
        alias += ".";
      }
      for (var item in ord) {
        orderStr += alias + item + ",";
      }
    }

    return this;
  }

  Sqlx limit(int ofs, int lmt) {
    limitStr = " ?, ? ";
    params.add(ofs);
    params.add(lmt);
    return this;
  }

  Sqlx returning() {
    returnStr = " RETURNING * ";
    return this;
  }

  String collect({bool count = false}) {
    var sql = "";

    selectStr = selectStr.trim();
    if (selectStr.endsWith(',')) {
      selectStr = selectStr.substring(0, selectStr.length - 1);
    }
    fromStr = fromStr.trim();
    if (fromStr.endsWith(',')) {
      fromStr = fromStr.substring(0, fromStr.length - 1);
    }
    whereStr = whereStr.trim();
    if (whereStr.endsWith(',')) {
      whereStr = whereStr.substring(0, whereStr.length - 1);
    }
    groupStr = groupStr.trim();
    if (groupStr.endsWith(',')) {
      groupStr = groupStr.substring(0, groupStr.length - 1);
    }
    havingStr = havingStr.trim();
    if (havingStr.endsWith(',')) {
      havingStr = havingStr.substring(0, havingStr.length - 1);
    }
    orderStr = orderStr.trim();
    if (orderStr.endsWith(',')) {
      orderStr = orderStr.substring(0, orderStr.length - 1);
    }
    limitStr = limitStr.trim();
    if (limitStr.endsWith(',')) {
      limitStr = limitStr.substring(0, limitStr.length - 1);
    }
    returnStr = returnStr.trim();
    if (returnStr.endsWith(',')) {
      returnStr = returnStr.substring(0, returnStr.length - 1);
    }

    if (sqlMode == "SELECT") {
      if (count) {
        sql += "SELECT COUNT(1) total ";
      } else if (selectStr == "") {
        sql += "SELECT * ";
      } else {
        sql += "SELECT " + selectStr;
      }
      sql += " FROM " + fromStr;
      if (whereStr != "") {
        sql += " WHERE true " + whereStr;
      }
      if (groupStr != "") {
        sql += " GROUP BY " + groupStr;
        if (havingStr != "") {
          sql += " HAVING " + havingStr;
        }
      }
      if (orderStr != "" && !count) {
        sql += " ORDER BY " + orderStr;
      }
      if (limitStr != "" && !count) {
        sql += " LIMIT " + limitStr;
      }
      if (returnStr != "") {
        sql += " " + returnStr;
      }
    } else if (sqlMode == "INSERT") {
      sql = "INSERT INTO " + insertStr + " " + valuesStr;
    } else if (sqlMode == "UPDATE") {
      sql = updateStr;
      if (whereStr != "") {
        sql += " WHERE true " + whereStr;
      }
      if (limitStr != "") {
        sql += " " + limitStr;
      }
    } else if (sqlMode == "DELETE") {
      sql = deleteStr;
      if (whereStr != "") {
        sql += " WHERE true " + whereStr;
      }
      if (limitStr != "") {
        sql += " " + limitStr;
      }
    }

    if (returnStr != "") {
      sql += " " + returnStr;
    }

    return sql;
  }

  Sqlx insertOne(String tb, Map m) {
    sqlMode = "INSERT";
    insertStr = tb + "(";
    valuesStr = "VALUES(";
    for (var k in m.keys) {
      insertStr += k + ",";
      valuesStr += "?,";
      params.add(m[k]);
    }
    if (insertStr.endsWith(',')) {
      insertStr = insertStr.substring(0, insertStr.length - 1) + ')';
    }
    if (valuesStr.endsWith(',')) {
      valuesStr = valuesStr.substring(0, valuesStr.length - 1) + ')';
    }
    return this;
  }

  Sqlx insertList(String tb, List<Map> list) {
    sqlMode = "INSERT";
    if (list.length == 0) {
      return this;
    }
    insertStr = tb + "(";
    valuesStr = "VALUES";
    var keys = list[0].keys;
    for (var k in keys) {
      insertStr += k + ",";
    }

    for (var item in list) {
      var vStr = "(";
      for (var k in keys) {
        vStr += "?,";
        if (item.containsKey(k)) {
          params.add(item[k]);
        } else {
          params.add('');
        }
      }
      if (vStr.endsWith(',')) {
        vStr = vStr.substring(0, vStr.length - 1) + ")";
      }
      valuesStr += vStr + ",";
    }
    if (insertStr.endsWith(',')) {
      insertStr = insertStr.substring(0, insertStr.length - 1) + ')';
    }
    if (valuesStr.endsWith(',')) {
      valuesStr = valuesStr.substring(0, valuesStr.length - 1);
    }

    return this;
  }

  Sqlx update(String tb, Map m, {String alias = ""}) {
    sqlMode = "UPDATE";
    updateStr = "UPDATE ${tb} ${alias} SET ";
    if (alias != "") {
      alias += ".";
    }
    m.forEach((k, v) {
      updateStr += " ${alias + k} = ?,";
      params.add(v);
    });
    if (updateStr.endsWith(',')) {
      updateStr = updateStr.substring(0, updateStr.length - 1) + " ";
    }
    return this;
  }

  Sqlx delete(String tb, {String alias = ""}) {
    sqlMode = "DELETE";
    deleteStr = "DELETE FROM ${tb} ${alias} ";
    return this;
  }

  Future<List<Map>> query(DbConnection conn, {bool count = false}) async {
    List<Map> result = [];
    var rows = await conn.query(collect(count: count), params);
    if (rows.length > 0) {
      return DD.rows2list(rows);
    }
    return result;
  }
}
