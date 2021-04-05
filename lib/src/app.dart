import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'context.dart';
import 'http_error.dart';

/// Typedef for Middleware
typedef Middleware<T extends Context> = Future Function(
    T ctx, FutureOr Function() next);

/// Dia application class
/// TODO: add documentations
class App<T extends Context> {
  late io.HttpServer _server;
  final List<Middleware<T>> _middlewares = [];
  StreamSubscription? _listener;

  /// Add [middleware] to queue
  void use(Middleware<T> middleware) {
    _middlewares.add(middleware);
  }

  /// wrapper for HttpServer listen method
  Future listen(address, int port,
      {io.SecurityContext? securityContext,
      int backlog = 0,
      bool v6Only = false,
      bool shared = false}) async {
    _server = await (securityContext == null
        ? io.HttpServer.bind(address, port,
            backlog: backlog, v6Only: v6Only, shared: shared)
        : io.HttpServer.bindSecure(
            address,
            port,
            securityContext,
            backlog: backlog,
            shared: shared,
          ));
    _listener = _server.listen((request) async {
      final T ctx = Context.createInstance(T, arguments: [request]);
      if (_middlewares.isNotEmpty) {
        final fn = _compose(_middlewares);
        await fn(ctx, null);
        Stream<List<int>>? stream;
        if (ctx.body == null) {
          stream = Stream.fromIterable([]);
        } else if (ctx.body is String) {
          stream = Stream.fromIterable([utf8.encode(ctx.body)]);
        } else if (ctx.body is List) {
          stream = Stream.fromIterable([ctx.body]);
        } else if (ctx.body is Stream) {
          stream = ctx.body;
        } else {
          request.response.write(ctx.body);
        }
        if (stream != null) await request.response.addStream(stream);
        await request.response.close();
      }
    });
  }

  /// Close connection listener
  void close() {
    _listener?.cancel();
  }

  void _responseHttpError(T ctx, HttpError error) {
    ctx.statusCode = error.status;
    ctx.contentType = io.ContentType.html;
    ctx.body = error.defaultBody;
  }

  Function _compose(List<Middleware<T>> middlewares) {
    return (T ctx, Middleware<T>? next) {
      var lastCalledIndex = -1;

      FutureOr dispatch(int currentCallIndex) async {
        if (currentCallIndex <= lastCalledIndex) {
          throw Exception('next() called multiple times');
        }
        lastCalledIndex = currentCallIndex;
        var fn = middlewares.length > currentCallIndex
            ? middlewares[currentCallIndex]
            : null;
        if (currentCallIndex == middlewares.length) {
          fn = next;
        }
        if (fn == null) return () => null;
        return fn(ctx, () => dispatch(currentCallIndex + 1))
            .catchError((error, stackTrace) {
          if (error is HttpError) {
            _responseHttpError(ctx, error);
          } else {
            final err = HttpError(500, stackTrace: stackTrace, error: error);
            _responseHttpError(ctx, err);
          }
        });
      }

      return dispatch(0);
    };
  }
}
