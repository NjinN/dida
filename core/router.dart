import 'dart:collection';
import 'dart:io';

import './route.dart';
import 'serverRequest.dart';
import 'serverResponse.dart';
import 'serverException.dart';
import './db.dart';
import '../conf.dart';
import 'worker.dart';
import '../utils/dd.dart';

class Router {
  Worker? worker;
  SplayTreeMap getMap = SplayTreeMap();
  SplayTreeMap postMap = SplayTreeMap();
  List<Function> beforeWare = [];
  List<Function> afterWare = [];
  DB db = DB();
  bool hasCrossDomain = CONF.containsKey('cross_domain') &&
      (CONF['cross_domain'] as List).length > 0;

  initDB() async {
    await db.initPool();
  }

  addBeforeWare(Function f) {
    beforeWare.add(f);
  }

  addAfterWare(Function f) {
    afterWare.add(f);
  }

  get(String url, Function handle,
      {List<Function>? bw = null,
      List<Function>? aw = null,
      bool useDB = true}) {
    if (bw == null) {
      bw = [];
    }
    if (aw == null) {
      aw = [];
    }
    getMap[url] = Route(url, handle, bw, aw, useDB);
  }

  post(String url, Function handle,
      {List<Function>? bw = null,
      List<Function>? aw = null,
      bool useDB = true}) {
    if (bw == null) {
      bw = [];
    }
    if (aw == null) {
      aw = [];
    }
    postMap[url] = Route(url, handle, bw, aw, useDB);
  }

  Future<ServerResponse> handleRequest(ServerRequest request) async {
    ServerResponse response = ServerResponse(request);
    response.uuid = request.uuid;
    try {
      if (beforeWare.length > 0) {
        for (var f in beforeWare) {
          await f(request, response);
        }
      }

      String url = request.uri.path;

      if (request.method == "GET") {
        if (hasCrossDomain) {
          checkCrossDomain(request, response);
        }

        if (getMap.containsKey(url)) {
          Route route = getMap[url];
          if (route.beforeWare.length > 0) {
            for (var f in route.beforeWare) {
              await f(request, response);
            }
          }

          if (route.useDB) {
            await db.usePool(response, (ctx) async {
              await route.fn(request, response, ctx);
            });
          } else {
            await route.fn(request, response);
          }

          if (route.afterWare.length > 0) {
            for (var f in route.afterWare) {
              await f(request, response);
            }
          }
        } else {
          response.code = 404;
          response.data = "No such method";
        }
      } else if (request.method == "POST") {
        if (hasCrossDomain) {
          checkCrossDomain(request, response);
        }

        if (postMap.containsKey(request.uri.path)) {
          Route route = postMap[url];
          if (route.beforeWare.length > 0) {
            for (var f in route.beforeWare) {
              await f(request, response);
            }
          }

          if (route.useDB) {
            await db.usePool(response, (ctx) async {
              await route.fn(request, response, ctx);
            });
          } else {
            await route.fn(request, response);
          }

          if (route.afterWare.length > 0) {
            for (var f in route.afterWare) {
              await f(request, response);
            }
          }
        } else {
          response.code = 404;
          response.data = "No such method";
        }
      } else if (request.method == "OPTIONS") {
        List<String> allowHosts = [];
        if (CONF.containsKey('cross_domain')) {
          allowHosts = CONF['cross_domain'] as List<String>;
        }

        String referer = "";
        if (request.headers.containsKey('referer')) {
          referer = request.headers['referer']?[0] ?? '';
        }
        if (referer == "" && request.headers.containsKey('origin')) {
          referer = request.headers['origin']?[0] ?? '';
        }

        if (referer != '') {
          for (var address in allowHosts) {
            if (DD.eqDomainRule(referer, address)) {
              response.headers['Allow'] = ['OPTIONS', 'GET', 'POST'];
              response.headers['Access-Control-Allow-Credentials'] = ['true'];
              response.headers['Access-Control-Allow-Origin'] = [address];
              response.headers['Access-Control-Allow-Methods'] = [
                'OPTIONS',
                'GET',
                'POST'
              ];
              response.headers['Access-Control-Allow-Headers'] = [
                'X-PINGOTHER',
                'Content-Type'
              ];
              // response.headers['Access-Control-Max-Age'] = ['86400'];
              break;
            }
          }
        }
      } else {
        throw ServerException("No such method", code: 404);
      }

      if (afterWare.length > 0) {
        for (var f in afterWare) {
          await f(request, response);
        }
      }
    } on ServerHaltException {} on ServerException catch (e) {
      response.code = e.code;
      response.data = e.message;
      response.contentType = ContentType.text.toString();
    } catch (e, s) {
      response.code = 500;
      response.data = e.toString();
      response.contentType = ContentType.text.toString();
      Worker.logError('Error: ${e.toString()}\r\n${s.toString()}');
      print('${e.toString()}\r\n${s.toString()}');
    }

    return response;
  }

  checkCrossDomain(ServerRequest request, ServerResponse response) {
    if (request.headers.containsKey('referer')) {
      String referer = request.headers['referer']?[0] ?? '';
      if (!referer.startsWith(request.origin)) {
        for (var address in CONF['cross_domain'] as List) {
          if (DD.eqDomainRule(referer, address)) {
            response.headers['Access-Control-Allow-Origin'] = [address];
            return;
          }
        }
      }
    }
  }
}
