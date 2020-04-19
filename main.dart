import 'dart:convert';

import './tools.dart';
import 'dart:io';

import 'core/parse.dart';
import 'core/repo.dart';
import 'data.dart';

/// Main Thread handeled here
class Optimus extends Data {
  /// Greets new user
  void greet() {
    File greetFile = new File("./docs/greet.json");
    Map greetRead = json.decode(greetFile.readAsStringSync());
    print(greetRead["introMsg"]);
  }

  Optimus() {
    Repository repo = Repository();
    if (!repo.checkRepo()) this.greet();
    repo.setup();
  }
}

main(List<String> args) {
  //& Initialize: Main Thread
  Optimus();

  //& Initialize: `Tools` class
  Tools tools = Tools();

  //& Parsing command
  Map seperatedArgs = tools.seperateArgs(args);
  ParseArguments argParse = ParseArguments(
    seperatedArgs["singleHyp"],
    seperatedArgs["doubleHyp"],
    seperatedArgs["command"],
  );
  argParse.checkParameters();
  argParse.stackCalls();
}
