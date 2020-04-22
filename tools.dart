import 'dart:convert';
import 'dart:io';

import 'data.dart';
import 'exception.dart';
import 'package:crypto/crypto.dart';

class Tools extends Data {
  Map seperateArgs(List<String> args) {
    List<String> singleHyphen = [];
    List<Map> doubleHyphen = [];
    String command;

    for (dynamic arg in args) {
      if (arg[0] == "-" && arg[1] == "-") {
        try {
          arg = arg.split("=");
          if (super
              .doubleHyphenAllAllowed
              .contains(arg[0].replaceFirst("--", ""))) {
            doubleHyphen
                .add({"name": arg[0].replaceFirst("--", ""), "value": arg[1]});
          } else {
            UnknownArgument();
          }
        } catch (Unhandled) {
          doubleHyphen
              .add({"name": arg[0].replaceFirst("--", ""), "value": true});
        }
      } else if (arg[0] == "-") {
        if (super.singleHyphenAllAllowed.contains(arg.replaceFirst("-", ""))) {
          singleHyphen.add(arg.substring(1, arg.length));
        } else {
          UnknownArgument();
        }
      } else {
        command = arg;
      }
    }

    if (command == null) {
      throw ArgumentError("No command provided.");
    }

    return {
      "singleHyp": singleHyphen,
      "doubleHyp": doubleHyphen,
      "command": command
    };
  }

  /// Generates timestamp
  int getTimeStamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Generates hash of provided string.
  String getHash(String x) {
    return md5.convert(utf8.encode(x)).toString();
  }

  /// Generates file with name as hash of provided string.
  String createHashNamedFile(String name, {create: true}) {
    String file = this.getHash(
      "$name${this.getTimeStamp().toString()}",
    );
    if (create) File("$baseDir/indices/$file").createSync();
    return file;
  }
}
