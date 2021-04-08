import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'context.dart';
import 'http_error.dart';

/// Middleware, it is an asynchronous function
/// that accepts a [Context] and a future for the next function.
typedef Middleware<T extends Context> = Future<void> Function(
    T ctx, FutureOr<void> Function() next);

/// Dia application class
/// The web server listens to the http / https port and applies
/// the middleware to the received requests
///
/// [Middleware] in App must be in the same [Context] as App
class App<T extends Context> {
  late io.HttpServer _server;
  final List<Middleware<T>> _middlewares = [];
  StreamSubscription? _listener;
  late Function(io.HttpRequest request) _createContext;

  App([T Function(io.HttpRequest request)? createContext]) {
    if (createContext != null) {
      _createContext = createContext;
    } else {
      _createContext = (io.HttpRequest request) => Context(request);
    }
  }

  /// Add [Middleware] to App
  /// [Middleware] must be in the same [Context] as App
  void use(Middleware<T> middleware) {
    _middlewares.add(middleware);
  }

  /// Call this method to listen http/https requests on the
  /// specified [address] and [port]
  ///
  /// The [address] can either be a [String] or an
  /// [InternetAddress]. If [address] is a [String], [bind] will
  /// perform a [InternetAddress.lookup] and use the first value in the
  /// list. To listen on the loopback adapter, which will allow only
  /// incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or
  /// [InternetAddress.loopbackIPv6]. To allow for incoming
  /// connection from the network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces or the IP address of a specific interface.
  ///
  /// If an IP version 6 (IPv6) address is used, both IP version 6
  /// (IPv6) and version 4 (IPv4) connections will be accepted. To
  /// restrict this to version 6 (IPv6) only, use [v6Only] to set
  /// version 6 only. However, if the address is
  /// [InternetAddress.loopbackIPv6], only IP version 6 (IPv6) connections
  /// will be accepted.
  ///
  /// If [port] has the value 0 an ephemeral port will be chosen by
  /// the system. The actual port used can be retrieved using the
  /// [port] getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of 0 (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// The optional argument [shared] specifies whether additional HttpServer
  /// objects can bind to the same combination of `address`, `port` and `v6Only`.
  /// If `shared` is `true` and more `HttpServer`s from this isolate or other
  /// isolates are bound to the port, then the incoming connections will be
  /// distributed among all the bound `HttpServer`s. Connections can be
  /// distributed over multiple isolates this way.
  Future<void> listen(address, int port,
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
    await _listen();
  }

  /// Call this method to listen http/https requests an
  /// existing [ServerSocket]. When the [HttpServer] is closed,
  /// the [HttpServer] will just detach itself, closing current
  /// connections but not closing [serverSocket].
  Future<void> listenOn(io.ServerSocket serverSocket) async {
    _server = io.HttpServer.listenOn(serverSocket);
    await _listen();
  }

  /// Close HTTP/HTTPS listener
  void close() {
    _listener?.cancel();
  }

  /// Private method for listen server stream
  Future<void> _listen() async {
    _listener = _server.listen((request) async {
      final ctx = _createContext(request);
      if (_middlewares.isNotEmpty) {
        final fn = _compose(_middlewares);
        await fn(ctx, null);
      }
      Stream<List<int>>? stream;
      if (ctx.body is String) {
        stream = Stream.fromIterable([utf8.encode(ctx.body)]);
      } else if (ctx.body is List) {
        stream = Stream.fromIterable([ctx.body]);
      } else if (ctx.body is Stream) {
        stream = ctx.body;
      }
      if (stream != null) {
        await request.response.addStream(stream);
      } else {
        request.response.headers.contentType = io.ContentType.html;
        request.response.statusCode = 404;
        request.response.write(HttpError(404).defaultBody);
      }
      await request.response.close();
    });
  }

  /// Private method for generate HTTP error response
  void _responseHttpError(T ctx, HttpError error) {
    ctx.statusCode = error.status;
    ctx.contentType = io.ContentType.html;
    ctx.body = error.defaultBody;
  }

  /// Private method for compose middlewares to one function
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
            final err =
                HttpError(500, stackTrace: stackTrace, exception: error);
            _responseHttpError(ctx, err);
          }
        });
      }

      return dispatch(0);
    };
  }
}
