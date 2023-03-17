import 'package:dia/dia.dart';
import 'package:dia_static/dia_static.dart';

void main() {
  final app = App();

  /// Serve files from example folder
  app.use(serve('./example', prefix: '/download', index: 'index.html'));

  /// Start server listen on localhost:8080
  app.listen('localhost', 8080).then((info) =>
      print('Server start serving file on http://localhost:8080/download/'));
}
