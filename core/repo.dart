import 'dart:io';

import '../data.dart';

class Repository extends Data {
  Map init() {
    print(greetData["repo"]["initialized"]);

    File("$baseDir/$configFile").createSync(recursive: true);
    return {};
  }
}
