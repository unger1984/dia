import 'dart:io';

import 'package:dia/dia.dart';
import 'package:dia_router/dia_router.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class ContextWithRouting extends Context with Routing {
  ContextWithRouting(HttpRequest request) : super(request);
}

void main() {
  App<ContextWithRouting>? dia;

  setUp(() {
    dia = App((req) => ContextWithRouting(req));
    dia?.listen('localhost', 8084);

    final router = Router('/');

    router.get('/', (ctx, next) async {
      ctx.body = 'success';
    });

    router.get('/query', (ctx, next) async {
      ctx.body = '${ctx.query}';
    });

    router.get('/params/:name/:id', (ctx, next) async {
      ctx.body = '${ctx.params}';
    });

    dia?.use(router.middleware);
  });

  tearDown(() async {
    dia?.close();
  });

  test('Router GET', () async {
    var response = await http.get(Uri.parse('http://localhost:8084/'));
    expect(response.statusCode, equals(200));
    expect(response.body, equals('success'));
  });

  test('Router 404', () async {
    var response = await http.get(Uri.parse('http://localhost:8084/404'));
    expect(response.statusCode, equals(404));
  });

  test('Router query params', () async {
    var response =
        await http.get(Uri.parse('http://localhost:8084/query?key=value'));
    expect(response.statusCode, equals(200));
    expect(response.body, equals('{key: value}'));
  });

  test('Router router params', () async {
    var response =
        await http.get(Uri.parse('http://localhost:8084/params/user/12'));
    expect(response.statusCode, equals(200));
    expect(response.body, equals('{name: user, id: 12}'));
  });
}
