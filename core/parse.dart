import '../data.dart';
import 'commit.dart';
import 'repo.dart';

class ParseArguments extends Data {
  // Single hyphened args provide with the command.
  List<String> singleHyphenArgs;
  // Double hyphened args provide with the command.
  List<Map> doubleHyphenArgs;
  // Command provided.
  String command;
  // Command data container from `Data` class.
  Map commandAttributes;

  ParseArguments(
    List<String> this.singleHyphenArgs,
    List<Map> this.doubleHyphenArgs,
    String this.command,
  ) {
    // Assign command attributes
    this.commandAttributes = commandData[command];
  }

  // Passes the command configuration to their respective hadlers & initailizes the handling process
  void stackCalls() {
    switch (command) {
      case "init":
        Repository().init();
        break;
      case "commit":
        Commit(this.commandAttributes);
        break;
      default:
    }
  }

  /// Checks whether there's is any invalid argument provided or not. If yes, raises error!
  void checkParameters() {
    for (String singleHypArg in singleHyphenArgs) {
      if (!commandAttributes["singleHyphenAllowed"].contains(singleHypArg)) {
        throw ArgumentError();
      }
    }
  }
}
