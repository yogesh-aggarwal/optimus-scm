/// Unknown argument provided that isn't allowed for the respective command
class UnknownArgument {
  UnknownArgument([dynamic msg = "Provided argument isn't supported."]) {
    throw UnsupportedError(msg);
  }
}

class InitialCommit {
  InitialCommit([dynamic msg = "No previous commits."]) {
    throw UnsupportedError(msg);
  }
}
