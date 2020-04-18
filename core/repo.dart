import 'dart:io';

import '../data.dart';

class Repository extends Data {
  Map init() {
    File(configFile).createSync(recursive: true);
    return {};
  }
}
