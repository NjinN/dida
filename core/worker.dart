import 'dart:io';
import 'dart:isolate';
import 'dart:collection';
import 'dart:async';

import './router.dart';
import 'serverRequest.dart';
import 'serverResponse.dart';
import '../conf.dart';

import '../controller/indexController.dart';
import '../controller/commonController.dart';

class Worker {
  static SendPort? sendLogPort;
  static bool logAccessEnable = CONF['access_log'] as bool;
  static bool logDbEnable = CONF['db_log'] as bool;
  static bool logErrorEnable = CONF['error_log'] as bool;
  static int timeout = CONF['timeout'] as int;
  static int maxQueueSize = CONF['max_queue_size'] as int;

  HashMap<String, HttpRequestWrap> requestMap = new HashMap();

  static logAccess(String msg) {
    if (sendLogPort == null) {
      print('sendLogPort is null');
    }
    if (logAccessEnable) {
      sendLogPort?.send(msg);
    }
  }

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

  void clearQueue(HashMap<String, HttpRequestWrap> queue, int timeout) {
    int nowMs = DateTime.now().millisecondsSinceEpoch;
    var keys = queue.keys;
    for (var k in keys) {
      var reqw = queue[k]!;
      if (nowMs - reqw.timeStamp > timeout * 1000) {
        reqw.request.response.statusCode = 504;
        reqw.request.response
          ..write("Timeout")
          ..close();
        queue.remove(k);
      }
    }
  }

  void handleRequest(HttpRequest request) async {
    if (requestMap.length > maxQueueSize) {
      request.response.statusCode = 500;
      request.response
        ..write("Requset queue overflow")
        ..close();
      if (logAccessEnable) {
        logAccess(
            'Access  ${request.uri.path}  from ${request.requestedUri.host}  Rejected');
      }
      return;
    }

    try {
      ServerRequest req = ServerRequest(request);
      requestMap[req.uuid] = HttpRequestWrap(request);
      if (logAccessEnable) {
        logAccess(
            'Access  ${request.uri.path}  from ${request.requestedUri.host} ');
      }
      ServerResponse res = await router.handleRequest(req);
      if (requestMap.containsKey(res.uuid)) {
        res.reply();
        requestMap.remove(res.uuid);
      }
    } catch (e) {
      print(e.toString());
      logError(e.toString());
    }
  }

  init() async {
    if (timeout > 0) {
      Timer.periodic(Duration(seconds: 20), (timer) {
        clearQueue(requestMap, timeout);
      });
    }

    router.worker = this;
    await router.initDB();

    router.addBeforeWare((ServerRequest req, ServerResponse res) async {
      // throw ServerException("Auth fail", code:200);
    });

    router.addAfterWare((ServerRequest req, ServerResponse res) async {
      // throw ServerException("Auth fail", code:200);
    });

    router.get('/', IndexController.index, useDB: false);

    router.get('/file', IndexController.file, useDB: false);

    router.get('/listDocs', IndexController.listDocs);

    router.post('/post', IndexController.post);

    router.post('/common/query', CommonController.query);
    router.post('/common/insert', CommonController.insert);
    router.post('/common/update', CommonController.update);
    router.post('/common/delete', CommonController.delete);
  }
}
