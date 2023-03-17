import 'dart:io';

import 'package:dia/dia.dart';
import 'package:dia_router/dia_router.dart';

class ContextWithRouting extends Context with Routing {
  ContextWithRouting(HttpRequest request) : super(request);
}

void main() {
  /// create Dia app with Routing mixin on Context
  final app = App((request) => ContextWithRouting(request));

  /// create router and sub router
  final router1 = Router('/route');
  final router2 = Router('/subroute');

  /// add router middleware to app
  app.use(router1.middleware);

  /// add sub router middleware to router
  router1.use(router2.middleware);

  /// add handler to GET request
  router2.get('/data/:id', (ctx, next) async {
    ctx.body = '${ctx.params}';
  });

  /// start server
  app.listen('localhost', 8080).then((_) => print(
        'Router example start on http://localhost:8080/route/subroute/data/18',
      ));
}
