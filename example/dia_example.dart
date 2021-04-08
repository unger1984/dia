import 'dart:io';

import 'package:dia/dia.dart';

/// Custom Context example
class MyContext extends Context {
  String? additionalField;

  MyContext(HttpRequest request) : super(request);
}

/// Middleware example
Middleware logger() => (ctx, next) async {
      var start = DateTime.now();
      await next();
      final time = DateTime.now().difference(start).inMilliseconds;
      print('${ctx.request.method} ${ctx.request.uri.path} ${time}ms');
    };

void main() {
  final app = App((request) => MyContext(request));

  /// Add logger middleware
  app.use(logger());

  /// Add additionalField value
  app.use((ctx, next) async {
    ctx.additionalField = 'additional value';
    await next();
  });

  /// Uncomment this to see throw example
  // app.use((ctx, next)async{
  //   ctx.throwError(401);
  // });

  /// final middleware to response
  app.use((ctx, next) async {
    ctx.contentType = ContentType.text;
    ctx.body = ctx.additionalField;
  });

  /// Start server listen on localhost:8080
  app
      .listen('localhost', 8080)
      .then((info) => print('Server started on http://localhost:8080'));
}
