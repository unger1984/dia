import 'dart:io';

import 'package:dia/dia.dart';
import 'package:dia_body/dia_body.dart';

class ContextWithBody extends Context with ParsedBody {
  ContextWithBody(HttpRequest request) : super(request);
}

void main() {
  final app = App((req) => ContextWithBody(req));

  app.use(body());

  app.use((ctx, next) async {
    ctx.body = ''' 
    query=${ctx.query}
    parsed=${ctx.parsed}
    files=${ctx.files}
    ''';
  });

  /// Start server listen on localhost:8080
  app
      .listen('localhost', 8080)
      .then((info) => print('Server started on http://localhost:8080'));
}
