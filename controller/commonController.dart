import 'dart:io';

import '../core/serverRequest.dart';
import '../core/serverResponse.dart';
import '../utils/sqlx.dart';
import '../utils/dd.dart';
import '../core/dbConnection.dart';

class CommonController {
  static query(
      ServerRequest request, ServerResponse response, DbConnection conn) async {
    var param = request.data;
    DD.checkParams(param, ['table', 'where']);
    Sqlx sqlx = Sqlx();
    sqlx.select('*').from(param['table']).where(param['where']);
    if (param.containsKey('offset') && param.containsKey('limit')) {
      sqlx.limit(param['offset'], param['limit']);
    }
    // print(sqlx.collect());
    // print(sqlx.params);
    response.data = await sqlx.query(conn).catchError((e) => throw e);
  }

  static insert(
      ServerRequest request, ServerResponse response, DbConnection conn) async {
    var param = request.data;
    DD.checkParams(param, ['table', 'values']);
    Sqlx sqlx = Sqlx();
    sqlx.insertOne(param['table'], param['values']);

    // print(sqlx.collect());
    // print(sqlx.params);
    response.data = await sqlx.query(conn).catchError((e) => throw e);
  }

  static update(
      ServerRequest request, ServerResponse response, DbConnection conn) async {
    var param = request.data;
    DD.checkParams(param, ['table', 'values']);
    Sqlx sqlx = Sqlx();
    sqlx.update(param['table'], param['values']);
    if (param.containsKey('where')) {
      sqlx.where(param['where']);
    }

    // print(sqlx.collect());
    // print(sqlx.params);
    response.data = await sqlx.query(conn).catchError((e) => throw e);
  }

  static delete(
      ServerRequest request, ServerResponse response, DbConnection conn) async {
    var param = request.data;
    DD.checkParams(param, ['table', 'where']);
    Sqlx sqlx = Sqlx();
    sqlx.delete(param['table']).where(param['where']).returning();

    // print(sqlx.collect());
    // print(sqlx.params);
    response.data = await sqlx.query(conn).catchError((e) => throw e);
  }
}
