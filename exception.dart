/// Unknown argument provided that isn't allowed for the respective command
class UnknownArgument {
  UnknownArgument([dynamic msg = "Provided argument isn't supported."]) {
    throw UnsupportedError(msg);
  }
}
