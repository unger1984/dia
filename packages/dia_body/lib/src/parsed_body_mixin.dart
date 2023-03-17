import 'package:dia/dia.dart';

import 'uploaded_file.dart';

/// Mixin to [Context]
/// extends default [Context] additional fields specified
/// for [dia_body]
/// [query] - Uri params as ?param=value
/// [parsed] - x-www-form-urlencoded, json and form-data params from POST/PUT
/// [files] - uploaded files
mixin ParsedBody on Context {
  final Map<String, String> _query = {};
  final Map<String, dynamic> _parsed = {};
  final Map<String, List<UploadedFile>> _files = {};

  /// Uri params
  Map<String, String> get query => _query;

  /// Parsed body params
  Map<String, dynamic> get parsed => _parsed;

  /// Uploaded files
  Map<String, List<UploadedFile>> get files => _files;
}
