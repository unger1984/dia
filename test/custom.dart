import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../lib/dia.dart';

class CustomContext extends Context {
  String? field;
  CustomContext(HttpRequest request) : super(request);
}

void main() {
  App<CustomContext>? dia;

  setUp(() {
    dia = App<CustomContext>();
    dia?.listen('localhost', 8080);
  });

  tearDown(() async {
    dia?.close();
  });

  test('Dia serve custom context', () async {
    dia?.use((ctx, next) async {
      ctx.field = 'custom';
      await next();
    });

    dia?.use((ctx, next) async {
      ctx.body = ctx.field;
    });

    final response = await http.get(Uri.parse('http://localhost:8080'));
    expect(response.statusCode, equals(200));
    expect(response.body, equals('custom'));
  });
}