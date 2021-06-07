import 'dart:io';
import 'dart:isolate';

import 'package:date_time_format/date_time_format.dart';

class LogWrap {
  String timestamp = "";
  String message = "";
  LogWrap(String t, String m) {
    timestamp = t;
    message = m;
  }
}

class Logger {
  late List<ReceivePort> logPortList;
  Logger(List<ReceivePort> ps) {
    logPortList = ps;
  }

  List<LogWrap> logList = [];
  int lastLogTime = 0;
  String lastLogDate = "";

  init() {
    logPortList.forEach((logPort) {
      logPort.listen((msg) {
        int tm = DateTime.now().millisecondsSinceEpoch;
        String ts = DateTime.now().format();
        String dt = ts.substring(0, 10);
        logList.add(LogWrap(ts, msg));
        if (tm - lastLogTime >= 1000 || dt != lastLogDate) {
          writeLog(dt);
        }
      });
    });
    
  }

  writeLog(String date) {
    try {
      var dir = Directory('./log');
      if (!dir.existsSync()) {
        dir.createSync();
      }
      var file = File('./log/${date}.log');
      if (!file.existsSync()) {
        file.createSync();
      }

      StringBuffer sb = StringBuffer();
      // print(logList.length);
      logList.forEach((element) {
        sb.writeln('[${element.timestamp}]- ${element.message}');
      });
      logList.clear();
      file.writeAsStringSync(sb.toString(),
          mode: FileMode.writeOnlyAppend, flush: true);
      lastLogDate = date;
      lastLogTime = DateTime.now().millisecondsSinceEpoch;
    } catch (e, s) {
      print(e.toString());
      print(s.toString());
    }
  }
}
