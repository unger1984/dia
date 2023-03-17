import 'package:http/http.dart' as http;
import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../lib/dia.dart';

void main() {
  App? dia;

  setUp(() {
    dia = App();
    dia?.listen('localhost', 8080);
  });

  tearDown(() async {
    dia?.close();
  });

  test('Dia serve', () async {
    dia?.use((ctx, next) async {
      ctx.body = 'success';
    });

    final response = await http.get(Uri.parse('http://localhost:8080'));
    expect(response.statusCode, equals(200));
    expect(response.body, equals('success'));
  });
}
