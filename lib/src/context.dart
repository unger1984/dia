import 'dart:io';
import 'dart:mirrors';

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

  /// Set Response Header key=value
  void set(String key, String value) {
    headers.set(key, value);
  }

  /// Throw HttpError with status code, message and stackTrace
  void throwError(int status, {String? message, StackTrace? stackTrace}) {
    throw HttpError(status, message: message, stackTrace: stackTrace);
  }

  /// create Context or custom Context instance
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
