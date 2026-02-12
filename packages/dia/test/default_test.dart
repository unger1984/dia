import 'package:http/http.dart' as http;
import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../lib/dia.dart';

void main() {
  App? dia;

  setUp(() async {
    dia = App();
    dia?.use((ctx, next) async {
      ctx.body = 'success';
    });
    await dia?.listen('localhost', 0);
  });

  tearDown(() async {
    dia?.close();
  });

  test('Dia serve', () async {
    final port = dia!.port;
    final response = await http.get(Uri.parse('http://localhost:$port'));
    expect(response.statusCode, equals(200));
    expect(response.body, equals('success'));
  });
}
