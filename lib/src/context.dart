import 'dart:io';

import 'http_error.dart';

/// Default Dia Context
/// This object extended base [HttpRequest] and
/// [HttpResponse] object for easy access to they fields
///
/// [request] - base [HttpRequest]
/// [response] - base [HttpResponse]
/// [headers] - base response [HttpHeaders]
/// [statusCode] - response status code
/// [contentType] - response [ContentType] field of headers
class Context {
  final HttpRequest _request;
  late dynamic body;

  /// Error if ctxThrow
  HttpError? error;

  /// Create base [Context] object
  /// takes [HttpRequest]
  Context(this._request) {
    // set default response content-type
    contentType ??= ContentType.html;
    // empty body
    body = null;
  }

  /// base [HttpRequest]
  HttpRequest get request => _request;

  /// base [HttpResponse]
  HttpResponse get response => _request.response;

  /// base response [HttpHeaders]
  HttpHeaders get headers => _request.response.headers;

  /// Response status code
  int get statusCode => response.statusCode;
  set statusCode(int code) => response.statusCode = code;

  /// Response Content-type field of headers
  ContentType? get contentType => headers.contentType;
  set contentType(ContentType? type) => headers.contentType = type;

  /// Set Response [HttpHeaders] field
  /// [key] - key of header
  /// [value] - value for key of header
  void set(String key, String value) {
    headers.set(key, value);
  }

  /// Throw HttpError with [status] code, [message] and [stackTrace] and [error]
  void throwError(int status,
      {String? message, StackTrace? stackTrace, Exception? exception}) {
    error = HttpError(status,
        message: message, stackTrace: stackTrace, exception: exception);
    throw error!;
  }
}
