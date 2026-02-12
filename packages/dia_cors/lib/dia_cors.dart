/// [Middleware] for Dia that set CORS headers
import 'package:dia/dia.dart';

/// [Middleware] for Dia that set CORS headers
/// [origin] - Access-Control-Allow-Origin header
/// [maxAge] - Access-Control-Max-Age header
/// [credentials] - Access-Control-Allow-Credentials header
/// [expose] - Access-Control-Expose-Headers header
Middleware<T> cors<T extends Context>({
  String origin = '*',
  int? maxAge,
  bool? credentials,
  String? expose,
}) =>
    (T ctx, next) async {
      ctx.set('Access-Control-Allow-Origin', origin);
      if (ctx.request.headers.value('access-control-request-headers') != null) {
        ctx.set(
          'Access-Control-Allow-Headers',
          ctx.request.headers.value('access-control-request-headers') ?? '',
        );
      }
      if (expose != null) ctx.set('Access-Control-Expose-Headers', expose);
      if (maxAge != null) ctx.set('Access-Control-Max-Age', maxAge.toString());
      if (credentials != null) {
        ctx.set('Access-Control-Allow-Credentials', credentials.toString());
      }
      if (ctx.request.method.toLowerCase() == 'options') {
        ctx.statusCode = 204;
        // ctx.body = '';
      }
      await next();
    };
