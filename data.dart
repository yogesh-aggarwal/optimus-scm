class Data {
  List<String> singleHyphenAllAllowed = ["a", "d", "m"];
  List<String> doubleHyphenAllAllowed = ["base"];
  List<String> commands = ["init", "add", "commit"];

  String baseDir = ".optimus"; // MUST NOT INCLUDE ENDING "/"
  String configFile = "config.json"; // MUST NOT INCLUDE ENDING "/"

  Map commandData = {
    "init": {
      "singleHyphenAllowed": ["a"]
    },
    "add": {
      "singleHyphenAllowed": ["a", "d"],
    },
    "commit": {
      "singleHyphenAllowed": ["a", "m"],
    },
  };
}
