import 'dart:convert';
import 'dart:io';

/// Data container
class Data {
  // All the allowed single hyphened commands.
  List<String> singleHyphenAllAllowed = ["a", "d", "m"];
  // All the allowed double hyphened commands.
  List<String> doubleHyphenAllAllowed = ["base"];
  // All the allowed commands.
  List<String> commands = ["init", "add", "commit"];

  // Working directory.
  String baseDir = ".optimus"; // MUST NOT INCLUDE ENDING "/"
  // Configuration file where all the commits & other stuff are stored.
  String configFile = "config.json"; // MUST NOT INCLUDE ENDING "/"

  //& Command map
  Map commandData = {
    "init": {
      "singleHyphenAllowed": ["a"],
    },
    "add": {
      "singleHyphenAllowed": ["a", "d"],
    },
    "commit": {
      "singleHyphenAllowed": ["a", "m"],
    },
  };

  //& Docs data
  Map greetData = json.decode(File("./docs/greet.json").readAsStringSync());
}
