// Stub file for non-web platforms
// This file provides empty implementations for dart:html classes

class Blob {
  Blob(List<dynamic> parts, [String? type, String? endings]);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({String? href});
  String download = '';
  void click() {}
  void setAttribute(String name, String value) {}
}

class FileUploadInputElement {
  String accept = '';
  void click() {}
  Stream<dynamic> get onChange => const Stream.empty();
  List<File>? files;
}

class File {
  String get name => '';
  int get size => 0;
}

class FileReader {
  void readAsArrayBuffer(File file) {}
  Stream<dynamic> get onLoadEnd => const Stream.empty();
  Stream<dynamic> get onLoad => const Stream.empty();
  dynamic result;
}
