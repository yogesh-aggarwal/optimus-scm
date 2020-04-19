import '../data.dart';
import 'commit.dart';
import 'repo.dart';

class ParseArguments extends Data {
  List<String> singleHyphenArgs;
  List<Map> doubleHyphenArgs;
  String command;
  Map attributes;

  ParseArguments(
    List<String> this.singleHyphenArgs,
    List<Map> this.doubleHyphenArgs,
    String this.command,
  ) {
    this.attributes = commandData[command];
  }

  List<Function> stackCalls() {
    switch (command) {
      case "init":
        Repository().init();
        break;
      case "commit":
        Commit(this.attributes);
        break;
      default:
    }
  }

  void checkParameters() {
    for (String singleHypArg in singleHyphenArgs) {
      if (!attributes["singleHyphenAllowed"].contains(singleHypArg)) {
        throw ArgumentError();
      }
    }
  }
}
