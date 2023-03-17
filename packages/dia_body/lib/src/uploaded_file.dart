import 'dart:io';

/// Uploaded file information
/// [filename] - original name of uploaded file
/// [file] - [File] object of uploaded file
class UploadedFile {
  final String filename;
  final File file;

  UploadedFile(this.filename, this.file);

  @override
  String toString() => 'filename:$filename path:${file.path}';
}
