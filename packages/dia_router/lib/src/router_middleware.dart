import 'package:dia/dia.dart';

import 'routing_mixin.dart';

/// [Router] [Middleware] for http request
/// Add to [Middleware] information about http method
/// and url path
/// For internal use
/// TODO may be private/protected ?
class RouterMiddleware<T extends Routing> {
  final Middleware<T> _handler;
  final String _path;
  final String? _method;

  RouterMiddleware(this._method, this._path, this._handler);

  /// Handler
  Middleware<T> get handler => _handler;

  /// Route path
  String get path => _path.replaceAll(RegExp(r'\/$'), '');

  /// HTTP Method
  String? get method => _method;
}
