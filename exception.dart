class UnknownArgument {
  UnknownArgument([dynamic msg = "Provided argument isn't supported."]) {
    throw UnsupportedError(msg);
  }
}
