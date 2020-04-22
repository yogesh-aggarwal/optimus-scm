import 'dart:convert';
import 'dart:io';

import '../data.dart';

/// Handler for `init...` command
class Repository extends Data {
  Map init() {
    print("\n${greetData["repo"]["initialized"]}");

    File config = File("$baseDir/$configFile");
    config.createSync(recursive: true);
    config.writeAsStringSync(json.encode({
      "master": {"commits": []} // Basic file structure
    }));
    return {};
  }

  /// Creates .optimus directory
  void setup() {
    Directory(super.baseDir).createSync();
  }

  /// Checks whether it's an Optimus Repository or not.
  bool checkRepo() {
    return File("$baseDir/$configFile").existsSync();
  }

  bool isIgnored(String name) {
    if (name.contains(".git") &&
        name.contains(".dart_tool") &&
        name.contains(".optimus")) return true;
    else {
      return false;
    }
  }
}
