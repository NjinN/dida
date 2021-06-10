import 'dart:io';
import 'package:process_run/shell.dart';
import 'dart:async';

main(List<String> args) async {
  var listeningList = [
    './controller',
    './core',
    './utils',
    './conf.dart',
    './server.dart',
    './pubspec.yaml',
  ];

  var tmList = [];
  listeningList.forEach((item) {
    if (File(item).existsSync()) {
      getFileMdfTs(File(item), tmList);
    } else {
      getFileMdfTs(Directory(item), tmList);
    }
  });

  var p = await Process.start('dart', ['server.dart'],
      mode: ProcessStartMode.inheritStdio);

  Timer.periodic(Duration(seconds: 1), (timer) async {
    var list = [];
    listeningList.forEach((item) {
      if (File(item).existsSync()) {
        getFileMdfTs(File(item), list);
      } else {
        getFileMdfTs(Directory(item), list);
      }
    });

    bool changed = false;
    if (list.length != tmList.length) {
      changed;
    }
    if (!changed) {
      for (var i = 0; i < list.length; i++) {
        if (list[i] != tmList[i]) {
          changed = true;
          break;
        }
      }
    }
    if (changed) {
      print('******* RESTART ********');
      p.kill();
      p = await Process.start('dart', ['server.dart'],
          mode: ProcessStartMode.inheritStdio);
      // shell.kill();

      // shell = Shell(runInShell: true);
      // shell.run('dart server.dart');

      tmList = list;
    }
  });
}

void getFileMdfTs(dynamic f, List ts) {
  if (f is File) {
    ts.add(f.lastModifiedSync().microsecondsSinceEpoch);
  } else if (f is Directory) {
    var list = f.listSync();
    list.forEach((item) {
      if (item is Directory) {
        getFileMdfTs(item, ts);
      } else if (item is File) {
        ts.add(item.lastModifiedSync().microsecondsSinceEpoch);
      }
    });
  }
}
