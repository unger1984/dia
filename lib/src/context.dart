import 'dart:io';

import 'http_error.dart';

/// Application context class
/// TODO: add documentation
class Context {
  final HttpRequest _request;
  late dynamic body;

  Context(this._request) {
    // set default response content-type
    contentType ??= ContentType.html;
    // empty body
    body = null;
  }

  HttpRequest get request => _request;
  HttpResponse get response => _request.response;
  HttpHeaders get headers => _request.response.headers;

  /// Response status code
  int get statusCode => response.statusCode;
  set statusCode(int code) => response.statusCode = code;

  /// Response Content-type
  ContentType? get contentType => headers.contentType;
  set contentType(ContentType? type) => headers.contentType = type;

  /// Throw HttpError with status code, message and stackTrace
  void throwError(int status, {String? message, StackTrace? stackTrace}) {
    throw HttpError(status, message: message, stackTrace: stackTrace);
  }
}
