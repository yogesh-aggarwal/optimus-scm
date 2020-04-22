import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import '../tools.dart';
import '../core/repo.dart';

import '../data.dart';

Tools tools = Tools();
Repository repo = Repository();

/// Handler for `commit` command
class Commit extends Data {
  // Stores fetched commits from the file.
  List commits;
  // For storing command variables like `-a` etc.
  dynamic attributes;
  // For storing file names & their data for the upcoming commit entry.
  List<Map> commitFiles = [];
  // Whether it's the first commit or not.
  bool initialCommit = true;

  Commit(dynamic this.attributes) {
    // TODO: Change master to current branch everywhere.
    //& Read the commits of current branch.
    this.commits = json.decode(File(
      "$baseDir/$configFile",
    ).readAsStringSync())["master"]["commits"];

    //& Decide whether the commit is initial or not on the basis of read `config.json` file.
    this.commits.isEmpty ? this.addInitialCommit() : addCommit();

    //& After successfully loading the new commit in the class variables, create an entry in the `config.json` file.
    this.createCommitEntry();
  }

  /// Creates commit entry in the config.json file. **Only this function can do it**.
  createCommitEntry() {
    // Basic new commit with newly generated ID
    Map commit = {
      "id": tools.getHash(tools.getTimeStamp().toString()),
      "files": {}
    };

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
  createCommitFiles(File file) {
    //? Checking whether the file is ignored or not.
    if (repo.isIgnored(file.path)) {
      return false;
    }

    //& Main
    //? Check if the file is a directory.
    if (!Directory(file.path).existsSync()) {
      //? Generating hashed name for changed file.
      String fileName = tools.createHashNamedFile(file.path, create: false);

      //? Creating the file.
      File hashFile = File("$baseDir/indices/$fileName");
      hashFile.createSync();

      //? Read the original file.
      String originalFileData = File(file.path).readAsStringSync();
      //? Write data of the original file to "hashed" file.
      hashFile.writeAsStringSync(originalFileData);

      //? Adding a new commit to class variable (NOT config.json).
      List<String> data = [];
      for (var i = 0; i < hashFile.readAsLinesSync().length; i++) {
        data.add("$fileName/\\$i");
      }

      this.commitFiles.add({
        file.path.replaceFirst(".\\", ""): {"data": data}
      });
    } else {
      //? If the file is a directory, the function keep calling itself recursively for depth files.
      //? Traversing over files in the directory.
      for (var nestedFile in Directory(file.path).listSync()) {
        createCommitFiles(
          File(nestedFile.path),
        ); // Calling itself.
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
      createCommitFiles(File(file.path));
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
        //? Compare object
        Compare compare = Compare(data.path);
        //? Prepare the lineMap
        compare.prepareLineMap();
        //? Appending the commit file to this.commitFiles (global commit holder/variable)
        this.commitFiles.add(compare.compareAndPrepareCommitFiles());
      }
    }
  }
}

class Compare extends Data {
  // Stores new(current) file name
  String changedFile;
  // Stores lines of new(changed) file
  List<String> changedFileLines;
  // Stores the line & the respective file name `line: fileName/\lineNumber`
  Map<String, String> lineMap = {};

  Compare(String this.changedFile);

  /// Prepares lineMap of the file in format {"line": "fileName/\lineNumber"}
  void prepareLineMap() {
    //? Extracting the last commit
    Map lastCommit = json
        .decode(File("$baseDir/$configFile").readAsStringSync())["master"]
            ["commits"]
        .last;
    //? Storing the hashed file names that contains the data of current file
    List hashedFiles = lastCommit["files"][changedFile] ?? [];
    //? Reads the lines of current file
    changedFileLines = File(this.changedFile).readAsLinesSync();

    //? Iterating over each hased name file to prepare the line map
    for (dynamic file in hashedFiles) {
      //? Extracting the attributes of the current file that is stored as `fileName/\lineNumber`
      List<String> fileAttr = file.split("/\\");
      //? Overiding the file(name + attributes) to file (fileName)
      file = fileAttr[0]; // File name

      //? Reading the lines of current hashed file
      List<String> fileReadLines =
          File("$baseDir/indices/$file").readAsLinesSync();

      //? Get line acc. to file name of format `name/\line`
      lineMap[fileReadLines[int.parse(
        fileAttr[1],
      )]] = "$file/\\${fileAttr[1]}";
    }
    //? Removing extra relative path denotions from current file name that is about to be compared
    this.changedFile = this.changedFile.replaceFirst(".\\", "");
  }

  /// Compare the existing files & prepares the new commit files
  Map compareAndPrepareCommitFiles() {
    //? Whether the changed file containing all the new stuff created or not
    bool ischangedFileCreated = false;
    //? The line no. to which the new line to be appended
    int changedFileLineNo = 0;
    //? Stores the name of new hash file
    String _newHashFileCreateName;
    //? Stores the commit file in the class
    List<String> commitFiles = [];

    //& Main
    //? Interating through each line of changedFile for line comparision
    changedFileLines.forEach((line) {
      //? Checking whether the line of changed file is there in our lineMap
      if (lineMap[line] == null) {
        //? Whether the new hash named file created for new lines
        if (!ischangedFileCreated) {
          //? Creating new hashed name file
          _newHashFileCreateName = tools.createHashNamedFile(changedFile);
          //? Setting the valur to true so that file don't get created twice
          ischangedFileCreated = true;
        }
        //? Appending to the file the new line (diff line)
        File("$baseDir/indices/$_newHashFileCreateName")
            .writeAsStringSync("$line\n", mode: FileMode.append);
        //? Adding file name to commit files in the format `fileName/\lineNumber`
        commitFiles.add("$_newHashFileCreateName/\\$changedFileLineNo");
        //? Incrementing the line no. to append to next line in the next round of line verification
        changedFileLineNo++;
      }
    });

    return {
      changedFile: {"data": commitFiles}
    };
  }
}
