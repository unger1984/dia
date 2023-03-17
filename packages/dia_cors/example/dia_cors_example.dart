import 'package:dia/dia.dart';
import 'package:dia_cors/dia_cors.dart';

void main() {
  final app = App();

  /// Add CORS middleware
  app.use(cors());

  /// final middleware to response
  app.use((ctx, next) async {
    ctx.body = 'success';
  });

  /// Start server listen on localhsot:8080
  app
      .listen('localhost', 8080)
      .then((info) => print('Server started on http://localhost:8080'));
}
