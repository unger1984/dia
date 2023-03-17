import 'dart:io';

import 'package:dia/dia.dart';
import 'package:dia_cors/dia_cors.dart';
import 'package:test/test.dart';

void main() {
  group('CORS test', () {
    App? dia;

    setUp(() {
      dia = App();

      dia?.listen('localhost', 8083);
    });

    tearDown(() async {
      dia?.close();
    });

    test('Access-Control-Allow-Origin', () async {
      dia?.use(cors());

      final request = await HttpClient()
          .openUrl('OPTIONS', Uri.parse('http://localhost:8083'));
      final response = await request.close();
      expect(
        response.headers.value('access-control-allow-origin'),
        equals('*'),
      );
    });

    test('Access-Control-Expose-Headers', () async {
      dia?.use(cors(expose: 'Content-Encoding, X-Kuma-Revision'));

      final request = await HttpClient()
          .openUrl('OPTIONS', Uri.parse('http://localhost:8083'));
      final response = await request.close();
      expect(
        response.headers.value('access-control-expose-headers'),
        equals('Content-Encoding, X-Kuma-Revision'),
      );
    });

    test('Access-Control-Max-Age', () async {
      dia?.use(cors(maxAge: 60));

      final request = await HttpClient()
          .openUrl('OPTIONS', Uri.parse('http://localhost:8083'));
      final response = await request.close();
      expect(response.headers.value('Access-Control-Max-Age'), ('60'));
    });

    test('Access-Control-Max-Age', () async {
      dia?.use(cors(credentials: true));

      final request = await HttpClient()
          .openUrl('OPTIONS', Uri.parse('http://localhost:8083'));
      final response = await request.close();
      expect(
        response.headers.value('Access-Control-Allow-Credentials'),
        ('true'),
      );
    });
  });
}
