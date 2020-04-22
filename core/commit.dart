import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
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
    this.commits = json.decode(File("$baseDir/$configFile").readAsStringSync())[
            "master"] // TODO: Change master to current branch everywhere.
        ["commits"];
    // Decide whether the commit is initial or not on the basis of read `config.json` file.
    this.commits.isEmpty ? this.addInitialCommit() : addCommit();
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

  compareFile(String newFile) {
    Map lastCommit = json
        .decode(File("$baseDir/$configFile").readAsStringSync())["master"]
            ["commits"]
        .last;

    newFile = newFile.replaceFirst(".\\", "");

    try {
      List<String> newFileRead = File(newFile).readAsLinesSync();
      List files = lastCommit["files"][newFile] ?? [];
      Map<String, String> lineMap = {};

      for (dynamic file in files) {
        List<String> fileAttr = file.split("/\\");
        file = fileAttr[0];

        List<String> fileReadLines =
            File("$baseDir/indices/$file").readAsLinesSync();

        // Shorting acc. to line value
        if (fileAttr.length == 2) {
          // Getting line acc. to file name of format `name/\line`
          lineMap[fileReadLines[int.parse(fileAttr[1])]] =
              "$file/\\${fileAttr[1]}";
        } else {
          // There's only one single file (in case of initial commit)
          List<String> fileReadLines =
              File("$baseDir/indices/$file").readAsLinesSync();

          fileReadLines.asMap().forEach((int index, String line) {
            lineMap[line] = "$file/\\$index";
          });
        }
      }

      // Whether the new file containing all the new stuff created or not
      bool isNewFileCreated = false;
      // The line no. to which the new line to be appended
      int newFileLineNo = 0;
      String _newFileCreateName;
      List<String> commitFiles = [];

      newFileRead.forEach((line) {
        String file = lineMap[line];
        // Checking whether the line of new file is there in our prepared hash map of previous commit
        if (file == null) {
          if (!isNewFileCreated) {
            _newFileCreateName = getHash(
              "$newFile${getTimeStamp().toString()}",
            );
            File("$baseDir/indices/$_newFileCreateName").createSync();
            isNewFileCreated = true;
          }
          File("$baseDir/indices/$_newFileCreateName")
              .writeAsStringSync("$line\n", mode: FileMode.append);
          commitFiles.add("$_newFileCreateName/\\$newFileLineNo");
          newFileLineNo++;
        } else {
          // Line is deleted in the new commit
          // TODO: Add the deleted line to a new record for future log (reference)
          commitFiles.add("$file");
        }
      });
      this.commitFiles.add({
        newFile: {"data": commitFiles}
      });
    } catch (FileSystemException) {}
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
        json.decode(File("$baseDir/$configFile").readAsStringSync());
    Function deepEqualityCheck = const DeepCollectionEquality().equals;

    _createEntry() {
      // Adding new commit.
      commitFileRead["master"]["commits"].add(commit);
      // Rewriting `config.json` to save the changes.
      File("$baseDir/$configFile")
          .writeAsStringSync(json.encode(commitFileRead));
    }

    try {
      if (!deepEqualityCheck(
        commitFileRead["master"]["commits"].last["files"],
        commit["files"],
      )) {
        _createEntry();
      }
    } catch (Error) {
      _createEntry();
    }
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
        String fileName = getHash(file.path + getTimeStamp().toString());

        // Creating the file.
        File currentFile = File("$baseDir/indices/$fileName");
        currentFile.createSync();

        if (currentFile.existsSync()) {
          try {
            // Read the original file.
            String originalFileData = File(file.path).readAsStringSync();
            // Write data of the original file to "hashed" file.
            currentFile.writeAsStringSync(originalFileData);
            // Adding a new commit to class variable (NOT config.json).
            List<String> data = [];

            for (var i = 0; i < currentFile.readAsLinesSync().length; i++) {
              data.add("$fileName/\\$i");
            }

            this.commitFiles.add({
              file.path.replaceFirst(".\\", ""): {"data": data}
            });
          } catch (Error) {
            print("e");
          }
        }
      } else {
        // If the file is a directory, the function keep calling itself recursively for depth files.
        // Traversing over files in the directory.
        for (var nestedFile in Directory(file.path).listSync()) {
          _createCommitFiles(
            File(nestedFile.path),
          ); // Calling itself.
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
    List<FileSystemEntity> files = directory.listSync(recursive: true);

    for (var data in files) {
      if (!data.path.contains(".git") &&
          !data.path.contains(".dart_tool") &&
          !data.path.contains(".optimus")) {
        compareFile(data.path);
      }
    }
  }
}
