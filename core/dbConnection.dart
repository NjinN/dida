import 'package:mysql1/mysql1.dart';
import './serverResponse.dart';
import 'worker.dart';

class DbConnection {
  Worker? worker;
  late MySqlConnection conn;

  DbConnection(MySqlConnection c, Worker? w) {
    conn = c;
    worker = w;
  }

  Future close() async {
    await conn.close();
  }

  Future<Results> query(String sql, List<Object> values,
      {bool log = true}) async {
    var rows = await conn.query(sql, values);

    if (log) {
      worker?.logDb(
          'Sql: ${sql}\r\nParams: ${values.toString()}\r\nResults: ${rows.length}');
    }

    return rows;
  }

  Future<List<Results>> queryMulti(String sql, Iterable<List<Object?>> values,
      {bool log = true}) async {
    var rows = await conn.queryMulti(sql, values);

    if (log) {
      worker?.logDb(
          'Sql: ${sql}\r\nParams: ${values.toString()}\r\nResults: ${rows.length}');
    }

    return rows;
  }

  Future transaction(Function queryBlock) async {
    await conn.transaction(queryBlock);
  }
}
