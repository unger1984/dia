import 'dart:io';

import 'package:dia/dia.dart';
import 'package:dia_body/dia_body.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:test/test.dart';

class ContextWithBody extends Context with ParsedBody {
  ContextWithBody(HttpRequest request) : super(request);
}

void main() {
  group('body parser tests', () {
    App<ContextWithBody>? dia;

    setUp(() {
      dia = App((req) => ContextWithBody(req));

      dia?.use(body());

      dia?.listen('localhost', 8082);
    });

    tearDown(() async {
      dia?.close();
    });

    test('Test query params', () async {
      dia?.use((ctx, next) async {
        ctx.body = '${ctx.query}';
      });

      final response = await http.post(Uri.parse('http://localhost:8082?p1=1'));
      expect(response.body, equals('{p1: 1}'));
    });

    test('Test x-www-form-urlencoded', () async {
      dia?.use((ctx, next) async {
        ctx.body = '${ctx.parsed}';
      });

      final response = await http
          .post(Uri.parse('http://localhost:8082'), body: {'p1': '1'});
      expect(response.body, equals('{p1: 1}'));
    });

    test('Test json', () async {
      dia?.use((ctx, next) async {
        ctx.body = '${ctx.parsed}';
      });

      final response = await http.post(
        Uri.parse('http://localhost:8082'),
        body: '{"p1":"1"}',
        headers: {'Content-type': 'application/json'},
      );
      expect(response.body, equals('{p1: 1}'));
    });

    test('Test multipart/form-data', () async {
      dia?.use((ctx, next) async {
        ctx.body = '''${ctx.parsed}''';
      });

      var request =
          http.MultipartRequest('POST', Uri.parse('http://localhost:8082'))
            ..fields['p1'] = '1';
      var response = await http.Response.fromStream(await request.send());

      expect(response.body, equals('{p1: 1}'));
    });

    test('Test file upload', () async {
      dia?.use((ctx, next) async {
        ctx.body = '''${ctx.files}''';
      });

      var request =
          http.MultipartRequest('POST', Uri.parse('http://localhost:8082'))
            ..files.add(await http.MultipartFile.fromPath(
              'file',
              'test/nophoto.png',
              contentType: MediaType('image', 'png'),
            ));
      var response = await http.Response.fromStream(await request.send());

      expect(response.body, startsWith('{file: [filename:nophoto.png path:'));
    });
  });
}
