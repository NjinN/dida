import 'dart:io';

import 'package:mysql1/mysql1.dart';
import '../conf.dart';
import './serverException.dart';

class DB {
  MySqlConnection? conn;
  ConnectionSettings? settings;
  List<MySqlConnection>? pool;
  int poolSize = 1;

  init() async {
    if (!CONF.containsKey('db')) {
      return;
    }

    var dbConf = CONF['db'] as Map;
    settings = new ConnectionSettings(
        host: dbConf['host'] as String,
        port: dbConf['port'] as int,
        user: dbConf['user'] as String,
        password: dbConf['password'] as String,
        db: dbConf['db'] as String);
    conn = await MySqlConnection.connect(settings!);
  }

  Future<MySqlConnection?> makeConn() async {
    if (settings == null) {
      return null;
    }
    return await MySqlConnection.connect(settings!);
  }

  initPool() async {
    if (!CONF.containsKey('db')) {
      return;
    }

    var dbConf = CONF['db'] as Map;
    settings = new ConnectionSettings(
        host: dbConf['host'] as String,
        port: dbConf['port'] as int,
        user: dbConf['user'] as String,
        password: dbConf['password'] as String,
        db: dbConf['db'] as String);

    if (dbConf.containsKey('poolSize')) {
      poolSize = dbConf['poolSize'];
    } else {
      poolSize = 1;
    }
    pool = [];
    for (var i = 0; i < poolSize; i++) {
      pool!.add(await MySqlConnection.connect(settings!));
    }
  }

  usePool(Function f, {bool newConn = false}) async {
    dynamic conn = null;
    try {
      if (pool == null) {
        throw Exception("DB conn pool have not init");
      }
      if (newConn) {
        conn = makeConn();
      } else {
        conn = await applyPool().catchError((e) {
          throw e;
        });
      }
      if (conn is! MySqlConnection) {
        throw Exception("Fail to apply db conn");
      }
      await conn.query('start transaction');
      try {
        await f(conn);
      } catch (e) {
        await conn.query('rollback');
        rethrow;
      }
      await conn.query('commit');

      // await conn.transaction((ctx) async {
      //   try {
      //     await f(ctx);
      //   } catch (e) {
      //     rethrow;
      //   }
      // }).catchError((e) {
      //   if (e is MySqlException && e.errorNumber == 1043) {
      //     if (conn is MySqlConnection) {
      //       try {
      //         conn.close();
      //       } catch (e) {
      //         print(e.toString());
      //       }
      //     }
      //     usePool(f, newConn: true);
      //   } else {
      //     throw e;
      //   }
      // });
    } catch (e) {
      if (e is MySqlException && e.errorNumber == 1043) {
        if (conn is MySqlConnection) {
          try {
            conn.close();
          } catch (e) {
            print(e.toString());
          }
          conn = null;
        }
        await usePool(f, newConn: true);
      } else {
        rethrow;
      }
    } finally {
      if (conn is MySqlConnection) {
        revertPoool(conn);
      }
    }
  }

  Future applyPool() async {
    try {
      if (pool!.length <= 0) {
        return await Future.delayed(Duration(milliseconds: 50), () async {
          return await applyPool();
        });
      }
      return pool!.removeAt(0);
    } catch (e) {
      rethrow;
    }
  }

  revertPoool(MySqlConnection conn) {
    if (pool!.length >= poolSize) {
      conn.close();
    } else {
      pool!.add(conn);
    }
  }
}
