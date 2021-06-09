import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:collection';
import 'dart:async';

import 'package:mysql1/mysql1.dart';
import 'package:uuid/uuid.dart';

import 'core/worker.dart';
import './core/serverRequest.dart';
import './core/serverResponse.dart';
import './core/serverUri.dart';
import './core/logger.dart';
import './conf.dart';
import './utils/dd.dart';

class Server {
  bool logAccessEnable = CONF['access_log'] as bool;
  HashMap<String, HttpRequestWrap> requestMap = new HashMap();
  List<SendPort> sendLogPortList = [];
  run() async {
    print("start dispatcher");
    var uuid = Uuid();

    List<SendPort> dispatchList = [];
    int idx = 0;

    ReceivePort loggerReceivePort = ReceivePort();
    await Isolate.spawn(createLogger, loggerReceivePort.sendPort);
    var p = await loggerReceivePort.first;
    (p as List).forEach((item) => sendLogPortList.add(item));
    loggerReceivePort.close();
    var sendLogPort = sendLogPortList[0];

    int workerCount = CONF["worker_count"] as int;
    for (var i = 0; i < workerCount; i++) {
      var receivePort = new ReceivePort();
      await Isolate.spawn(createWorker, receivePort.sendPort);

      receivePort.listen((dynamic msg) async {
        if (dispatchList.length < workerCount && msg is SendPort) {
          dispatchList.add(msg);
          msg.send(sendLogPortList[dispatchList.length]);
          print("worker" + dispatchList.length.toString() + " started");
          return;
        }

        ServerResponse response = msg;

        if (requestMap.containsKey(response.uuid)) {
          var req = requestMap[response.uuid]!.request;
          try {
            var res = req.response;
            res.statusCode = response.code;
            res.headers.contentType = ContentType.parse(response.contentType);
            if (response.headers.length > 0) {
              response.headers.forEach((key, value) {
                res.headers.set(key, value);
              });
            }

            dynamic data = response.data;
            if (res.headers.contentType!.mimeType ==
                ContentType.json.mimeType) {
              if (data is Results) {
                data = DD.rows2str(data);
              } else if (!(data is String)) {
                data = jsonEncode(data);
              }
            }
            if (data is List<int>) {
              res.add(data);
              await res.flush();
              res.close();
            } else {
              res
                ..write(data)
                ..close();
            }
          } catch (e) {
            print(e.toString());
          }
          requestMap.remove(response.uuid);
        }
      });
    }

    HttpServer requestServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4, CONF['listen_port'] as int);

    print("listening port: " + (CONF['listen_port'] as int).toString());

    int timeout = CONF['timeout'] as int;
    if (timeout > 0) {
      Timer.periodic(Duration(seconds: 20), (timer) {
        clearQueue(requestMap, timeout);
      });
    }
    int maxQueueSize = CONF['max_queue_size'] as int;
    await for (HttpRequest request in requestServer) {
      try {
        if (maxQueueSize > 0 && requestMap.length > maxQueueSize) {
          request.response.statusCode = 503;
          request.response
            ..write("Message queue overflow")
            ..close();
          if (logAccessEnable) {
            sendLogPort.send(
                'Access ${request.uri.path}  from ${request.requestedUri.host} Rejected');
          }

          continue;
        }

        ServerRequest req = new ServerRequest();
        req.uuid = uuid.v1();
        req.contentLength = request.contentLength;
        req.method = request.method;
        req.origin = request.requestedUri.origin;
        req.host = request.connectionInfo?.remoteAddress.host ?? "";
        req.port = request.connectionInfo?.localPort ?? 0;
        var headers = HashMap<String, List<String>>();
        request.headers.forEach((name, values) {
          headers[name] = values;
        });
        req.headers = headers;
        ServerUri uri = ServerUri();
        uri.fragment = request.uri.fragment;
        uri.host = request.uri.host;
        uri.path = request.uri.path;
        uri.pathSegments = request.uri.pathSegments;
        uri.port = request.uri.port;
        uri.query = request.uri.query;
        uri.queryParameters = request.uri.queryParameters;
        uri.scheme = request.uri.scheme;
        uri.userInfo = request.uri.userInfo;

        req.uri = uri;
        req.body = await request.toList();
        if (request.headers.contentType?.mimeType ==
            ContentType.json.mimeType) {
          req.data = jsonDecode(utf8.decoder.convert(req.body[0]));
        }

        dispatchList[idx].send(req);
        idx++;
        if (idx >= dispatchList.length) {
          idx = 0;
        }

        if (logAccessEnable) {
          sendLogPort.send(
              'Access  ${request.uri.path}  from ${request.requestedUri.host} ');
        }

        requestMap[req.uuid] = HttpRequestWrap(request);
      } catch (e, s) {
        sendLogPort.send('Error: ${e.toString()}\r\n${s.toString()}');
        request.response.statusCode = 500;
        request.response
          ..write('Error: ${e.toString()}\r\n${s.toString()}')
          ..close();
      }
    }
  }

  void clearQueue(HashMap<String, HttpRequestWrap> queue, int timeout) {
    int nowSecond = DateTime.now().second;
    var keys = queue.keys;
    for (var k in keys) {
      var reqw = queue[k]!;
      if (nowSecond - reqw.timeStamp > timeout) {
        reqw.request.response.statusCode = 504;
        reqw.request.response
          ..write("Timeout")
          ..close();
        queue.remove(k);
      }
    }
  }

  static void createWorker(SendPort sendPort) async {
    Worker worker = new Worker();
    await worker.init();

    var port = new ReceivePort();

    port.listen((dynamic msg) {
      if (msg is ServerRequest) {
        ServerRequest request = msg;
        worker.router.handleRequest(request).then((response) {
          sendPort.send(response);
        });
      } else if (msg is SendPort) {
        worker.setSendLogPort(msg);
      }
    });

    sendPort.send(port.sendPort);
  }

  static void createLogger(SendPort sendPort) {
    List<ReceivePort> list = [];
    int workerCount = CONF['worker_count'] as int;
    for (var i = 0; i < workerCount + 1; i++) {
      list.add(ReceivePort());
    }
    ReceivePort logReceivePort = ReceivePort();
    Logger logger = Logger(list);
    logger.init();
    // sendLogPort = logReceivePort.sendPort;
    var sendPortList = [];
    list.forEach((item) => sendPortList.add(item.sendPort));
    sendPort.send(sendPortList);
    // sendPort.send(list);
    print('Logger started');
  }
}

main(List<String> args) async {
  try {
    args.forEach((arg) {
      if (arg.startsWith('-w')) {
        CONF['worker_count'] = int.parse(arg.substring(2));
      }else if(arg.startsWith('-c')){
        (CONF['db'] as Map)['poolSize'] = int.parse(arg.substring(2));
      }
    });
  } catch (e) {
    print(e);
    exit(1);
  }

  Server().run();
}
