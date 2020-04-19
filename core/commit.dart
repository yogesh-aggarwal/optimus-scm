import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../data.dart';

/// Handler for `commit` command
class Commit extends Data {
  List commits; // Stores fetched commits from the file.
  dynamic attributes; // For storing command variables like `-a` etc.
  List<Map> commitFiles =
      []; // For storing file names & their data for the upcoming commit entry.

  bool initialCommit = true; // Whether it's the first commit or not.

  Commit(dynamic this.attributes) {
    // Read the commits of current branch
    this.commits = json.decode(File("$baseDir/config.json").readAsStringSync())[
            "master"] // TODO: Change master to current branch everywhere.
        ["commits"];
    // Decide whether the commit is initial or not on the basis of read `config.json` file.
    this.commits.isEmpty ? addInitialCommit() : addCommit();
    // After successfully loading the new commit in the class variables, create an entry in the `config.json` file.
    this.createCommitEntry();
  }

  /// Generates the timestamp
  int getTimeStamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Generates the hash of provided string.
  String getHash(String x) {
    return md5.convert(utf8.encode(x)).toString();
  }

  /// Reads the index file in ".optimus/indices" folder.
  String getFileContentByHash(String x) {
    return File("$baseDir/indices/$x").readAsStringSync();
  }

  compareFile(String path) {
    // print("Create new commit");
  }

  /// Creates commit entry in the config.json file. **Only this function can do it**.
  createCommitEntry() {
    // Basic new commit with newly generated ID
    Map commit = {"id": getHash(getTimeStamp().toString()), "files": {}};

    // Adding files to commit.
    for (Map file in this.commitFiles) {
      String commitFile = file.keys.elementAt(0);
      commit["files"][commitFile] = file[commitFile]["data"];
    }
    // Reading `config.json` to add new to existing commit.
    Map commitFileRead =
        json.decode(File("$baseDir/config.json").readAsStringSync());
    // Adding new commit.
    commitFileRead["master"]["commits"].add(commit);
    // Rewriting `config.json` to save the changes.
    File("$baseDir/config.json").writeAsStringSync(json.encode(commitFileRead));
  }

  /// Creates hash files in the ".optimus/indices" directory.
  _createCommitFiles(File file) {
    // Checking whether the file is ignored or not.
    if (!file.path.contains(".git") &&
        !file.path.contains(".dart_tool") &&
        !file.path.contains(".optimus")) {
      // Check if the file is a directory.
      if (!Directory(file.path).existsSync()) {
        // Generating new file hashed name.
        String fileName =
            "$baseDir/indices/${getHash(file.path + getTimeStamp().toString())}";

        // Creating the file.
        File currentFile = File(fileName);
        currentFile.createSync();

        if (currentFile.existsSync()) {
          try {
            // Read the original file.
            String originalFileData = File(file.path).readAsStringSync();
            // Write data of the original file to "hashed" file.
            currentFile.writeAsStringSync(originalFileData);
            // Adding a new commit to class variable (NOT config.json).
            this.commitFiles.add({
              file.path.replaceFirst(".\\", ""): {
                "data": [fileName.replaceFirst(".optimus/indices/", "")]
              }
            });
          } catch (Error) {}
        }
      } else {
        // If the file is a directory, the function keep calling itself recursively for depth files.
        // Traversing over files in the directory.
        for (var nestedFile in Directory(file.path).listSync()) {
          _createCommitFiles(File(nestedFile.path)); // Calling itself.
        }
      }
    }
  }

  /// Adds initial commit
  addInitialCommit() {
    // Creating folder to store files
    Directory indices = Directory("$baseDir/indices");
    indices.createSync(recursive: true);

    // Getting files
    Directory filesDir = Directory("$baseDir").parent;
    List<FileSystemEntity> files = filesDir.listSync();

    // Copying files
    for (FileSystemEntity file in files) {
      _createCommitFiles(File(file.path));
    }
  }

  /// Adds new commit to class variables
  addCommit() {
    Directory directory = Directory("$baseDir").parent;
    directory.list(recursive: true).listen((data) {
      if (!data.path.contains(".git") && !data.path.contains(".dart_tool")) {
        compareFile(data.path);
      }
    });
  }
}
