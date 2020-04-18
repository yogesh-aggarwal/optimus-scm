import 'data.dart';
import 'exception.dart';

class Tools extends Data {
  Map seperateArgs(List<String> args) {
    List<String> singleHyphen = [];
    List<Map> doubleHyphen = [];
    List<String> commands = [];

    for (dynamic arg in args) {
      if (arg[0] == "-" && arg[1] == "-") {
        try {
          arg = arg.split("=");
          if (super
              .doubleHyphenAllowed
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
        if (super.singleHyphenAllowed.contains(arg.replaceFirst("-", ""))) {
          singleHyphen.add(arg.substring(1, arg.length));
        } else {
          UnknownArgument();
        }
      } else {
        commands.add(arg);
      }
    }

    return {
      "singleHyp": singleHyphen,
      "doubleHyp": doubleHyphen,
      "commands": commands
    };
  }
}
