import 'dart:convert';

import './tools.dart';
import 'dart:io';

import 'core/parse.dart';
import 'data.dart';

class Optimus extends Data {
  void setup() {
    Directory(super.baseDir).createSync();
  }

  void greet() {
    File greetFile = new File("./docs/greet.json");
    Map greetRead = json.decode(greetFile.readAsStringSync());
    print(greetRead["introMsg"]);
  }

  bool checkRepo() {
    File optConfig = new File("$baseDir/$configFile");
    return optConfig.existsSync();
  }

  Optimus() {
    bool workingDirExists = Directory(super.baseDir).existsSync();

    if (workingDirExists) {
      if (!this.checkRepo()) this.greet();
    } else {
      this.greet();
    }
    this.setup();
  }
}

main(List<String> args) {
  //& Initialize: Main Thread
  // Optimus();

  //& Initialize: `Tools` class
  Tools tools = Tools();

  Map seperatedArgs = tools.seperateArgs(args);

  ParseArguments argParse = ParseArguments(
    seperatedArgs["singleHyp"],
    seperatedArgs["doubleHyp"],
    seperatedArgs["command"],
  );
  argParse.checkParameters();
  argParse.stackCalls();
}
