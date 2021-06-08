import 'dart:isolate';

import 'route.dart';

import './router.dart';
import '../controller/indexController.dart';
import 'serverRequest.dart';
import 'serverException.dart';
import 'serverResponse.dart';
import '../conf.dart';

class Worker {
  static SendPort? sendLogPort;
  static bool logDbEnable = CONF['db_log'] as bool;
  static bool logErrorEnable = CONF['error_log'] as bool;

  static logDb(String msg) {
    if (sendLogPort == null) {
      print('sendLogPort is null');
    }
    if (logDbEnable) {
      sendLogPort?.send(msg);
    }
  }

  static logError(String msg) {
    if (logErrorEnable) {
      sendLogPort?.send(msg);
    }
  }

  Router router = Router();

  setSendLogPort(SendPort sp) {
    Worker.sendLogPort = sp;
  }

  init() async {
    router.worker = this;
    await router.initDB();

    router.addBeforeWare((ServerRequest req, ServerResponse res) async {
      // throw ServerException("Auth fail", code:200);
    });

    router.get('/', IndexController.index, useDB: false);

    router.get('/file', IndexController.file, useDB: false);

    router.get('/listDocs', IndexController.listDocs);

    router.post('/post', IndexController.post);
  }
}
