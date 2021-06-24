
import 'dart:io';
import 'dart:isolate';
import 'dart:collection';

import 'core/worker.dart';
import './core/serverRequest.dart';
import './core/logger.dart';
import './conf.dart';

class Server {
  bool logAccessEnable = CONF['access_log'] as bool;
  HashMap<String, HttpRequestWrap> requestMap = new HashMap();
  List<SendPort> sendLogPortList = [];
  static var httpServer =
      HttpServer.bind(InternetAddress.anyIPv4, CONF['listen_port'] as int, shared: true);

  start() async {
    print("start server");
    List<ReceivePort> list = [];
    int workerCount = CONF['worker_count'] as int;
    for (var i = 0; i < workerCount + 1; i++) {
      list.add(ReceivePort());
    }
    ReceivePort logReceivePort = ReceivePort();
    Logger logger = Logger(list);
    logger.init();
    print('Logger started');

    for (var i = 0; i < workerCount + 1; i++) {
      await Isolate.spawn(createWorker, list[i].sendPort);
      print("Worker${i} started");
    }

    print("Listening port ${CONF['listen_port']}");
  }


  static void createWorker(SendPort sendPort) async {
    Worker worker = new Worker();
    await worker.init();
    worker.setSendLogPort(sendPort);

    await for (HttpRequest request in await httpServer) {
      worker.handleRequest(request);
    }
  }

}

main(List<String> args) async {
  try {
    args.forEach((arg) {
      if (arg.startsWith('-w')) {
        CONF['worker_count'] = int.parse(arg.substring(2));
      } else if (arg.startsWith('-c')) {
        (CONF['db'] as Map)['poolSize'] = int.parse(arg.substring(2));
      }
    });
  } catch (e) {
    print(e);
    exit(1);
  }

  Server().start();
}
