import 'package:dia/dia.dart';
import 'package:dia_static/dia_static.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('Static test', () {
    App? dia;

    setUp(() {
      dia = App();
      dia?.listen('localhost', 8085);
    });

    tearDown(() async {
      dia?.close();
    });

    test('Not found', () async {
      dia?.use(serve('./example'));
      final response =
          await http.get(Uri.parse('http://localhost:8085/notfound.txt'));
      expect(response.statusCode, equals(404));
    });

    test('test.txt', () async {
      dia?.use(serve('./example'));
      final response =
          await http.get(Uri.parse('http://localhost:8085/test.txt'));
      expect(response.statusCode, equals(200));
      expect(response.body, equals('test\n'));
    });

    test('prefix', () async {
      dia?.use(serve('./example', prefix: '/download'));
      final response =
          await http.get(Uri.parse('http://localhost:8085/download/test.txt'));
      expect(response.statusCode, equals(200));
      expect(response.body, equals('test\n'));
    });

    test('index.html', () async {
      dia?.use(serve('./example', prefix: '/download', index: 'index.html'));
      final response =
          await http.get(Uri.parse('http://localhost:8085/download/'));
      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], equals('text/html'));
    });
  });
}
