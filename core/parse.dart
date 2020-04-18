import '../data.dart';

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
    print("All verified! Now stacking calls!");
  }

  void checkParameters() {
    for (String singleHypArg in singleHyphenArgs) {
      if (!attributes["singleHyphenAllowed"].contains(singleHypArg)) {
        throw ArgumentError();
      }
    }
  }
}
