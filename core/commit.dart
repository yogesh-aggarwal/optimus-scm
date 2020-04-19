import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../data.dart';

class Commit extends Data {
  List commits;
  dynamic attributes;
  List<Map> commitFiles = [];

  bool initialCommit = true;

  Commit(dynamic this.attributes) {
    this.commits = json.decode(File("$baseDir/config.json").readAsStringSync())[
            "master"] // Change master to current branch
        ["commits"];
    this.commits.isEmpty ? createInitialCommit() : addCommit();
    this.createCommitEntry();
  }

  getTimeStamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  getHash(String x) {
    return md5.convert(utf8.encode(x)).toString();
  }

  getFileContentByHash(String x) {
    return File(x).readAsStringSync();
  }

  compareFile(String path) {
    if (!commits.isEmpty) {
      print(commits);
    } else {
      print("Create new commit");
      return true;
    }
  }

  createCommitEntry() {
    // this.commits.add();
    Map commit = {"id": getHash(getTimeStamp().toString()), "files": {}};

    for (Map file in this.commitFiles) {
      String commitFile = file.keys.elementAt(0);
      commit["files"][commitFile] = file[commitFile]["data"];
    }
    Map commitFileRead = json.decode(File("$baseDir/config.json").readAsStringSync());
    commitFileRead["master"]["commits"].add(commit);
    File("$baseDir/config.json").writeAsStringSync(json.encode(commitFileRead));
  }

  _createCommitFiles(File file) {
    if (!file.path.contains(".git") &&
        !file.path.contains(".dart_tool") &&
        !file.path.contains(".optimus")) {
      if (!Directory(file.path).existsSync()) {
        String fileName =
            "$baseDir/indices/${getHash(file.path + getTimeStamp().toString())}";

        File currentFile = File(fileName);
        currentFile.createSync();

        if (currentFile.existsSync()) {
          try {
            String originalFileData = File(file.path).readAsStringSync();
            currentFile.writeAsStringSync(originalFileData);
            this.commitFiles.add({
              file.path.replaceFirst(".\\", ""): {
                "data": [fileName.replaceFirst(".optimus/indices/", "")]
              }
            });
          } catch (Error) {}
        }
      } else {
        for (var nestedFile in Directory(file.path).listSync()) {
          _createCommitFiles(File(nestedFile.path));
        }
      }
    }
  }

  createInitialCommit() {
    //& Creating folder to store files
    Directory indices = Directory("$baseDir/indices");
    indices.createSync(recursive: true);

    //& Getting files
    Directory filesDir = Directory("$baseDir").parent;
    List<FileSystemEntity> files = filesDir.listSync();

    String fileName;
    //& Copying files
    for (FileSystemEntity file in files) {
      {
        _createCommitFiles(File(file.path));
      }
    }
    ;
  }

  addCommit() {
    Directory directory = Directory("$baseDir").parent;
    directory.list(recursive: true).listen((data) {
      if (!data.path.contains(".git") && !data.path.contains(".dart_tool")) {
        compareFile(data.path);
      }
    });
  }
}
