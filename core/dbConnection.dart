import 'package:mysql1/mysql1.dart';
import './serverResponse.dart';
import 'worker.dart';

class DbConnection {
  late MySqlConnection conn;

  DbConnection(MySqlConnection c) {
    conn = c;
  }

  Future close() async {
    await conn.close();
  }

  Future<Results> query(String sql, List<Object> values,
      {bool log = true}) async {
    var rows = await conn.query(sql, values);
    if (log) {
      var afs = rows.affectedRows;
      Worker.logDb(
          'Sql: ${sql}\r\nParams: ${values.toString()}\r\nResults: ${rows.length}\r\nAffected: ${afs}');
    }

    return rows;
  }

  Future<List<Results>> queryMulti(String sql, Iterable<List<Object?>> values,
      {bool log = true}) async {
    var rows = await conn.queryMulti(sql, values);

    if (log) {
      Worker.logDb(
          'Sql: ${sql}\r\nParams: ${values.toString()}\r\nResults: ${rows.length}');
    }

    return rows;
  }

  Future transaction(Function queryBlock) async {
    await conn.transaction(queryBlock);
  }
}
