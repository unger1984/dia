import 'dart:io';
import 'dart:mirrors';

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
      {String? message, StackTrace? stackTrace, Error? error}) {
    throw HttpError(status,
        message: message, stackTrace: stackTrace, error: error);
  }

  /// create Context or custom Context instance
  /// necessary for internal use when you need to create an object
  /// from an inherited class [Context]
  /// TODO may be protected/private?
  static dynamic createInstance(Type type,
      {Symbol? constructor,
      List? arguments,
      Map<Symbol, dynamic>? namedArguments}) {
    constructor ??= const Symbol('');
    arguments ??= const [];

    var typeMirror = reflectType(type);
    if (typeMirror is ClassMirror) {
      if (namedArguments != null) {
        return typeMirror
            .newInstance(constructor, arguments, namedArguments)
            .reflectee;
      } else {
        return typeMirror.newInstance(constructor, arguments).reflectee;
      }
    } else {
      throw ArgumentError("Cannot create the instance of the type '$type'.");
    }
  }
}
