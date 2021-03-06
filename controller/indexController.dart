import 'dart:io';

import '../core/serverRequest.dart';
import '../core/serverResponse.dart';
import '../utils/sqlx.dart';
import '../utils/dd.dart';
import '../core/dbConnection.dart';

class IndexController {
  static index(ServerRequest request, ServerResponse response) async {
    response.data = "Hello word";
  }

  static file(ServerRequest request, ServerResponse response) async {
    File f = File('./data.txt');
    response.data = f.readAsBytesSync();
    response.contentType = ContentType.binary.toString();
  }

  static post(
      ServerRequest request, ServerResponse response, DbConnection conn) async {
    // DD.checkParams(request.data, ['usr_phone', 'psw']);
    Sqlx x = Sqlx();
    x
        .select("*")
        .from("doc")
        .where(DD.takeParams(request.data, ['id__lege', 'name']));
    // x.select("*").from("doc").where(request.data);
    try {
      var result = await conn.query(x.collect(), x.params);
      response.data = result;
    } catch (e) {
      rethrow;
    }
  }

  static listDocs(
      ServerRequest request, ServerResponse response, DbConnection conn) async {
    var params = {
      "id__lege": [7, 4],
      "name__like": "数"
    };
    Sqlx x = Sqlx();
    x.select("*").from("doc").where(params);
    // x.params.addAll([1, 2, 3]);
    var result = await conn.query(x.collect(), x.params);

    response.data = DD.rows2list(result);
  }
}
