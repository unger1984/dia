<a href="https://pub.dartlang.org/packages/dia_body">  
    <img src="https://img.shields.io/pub/v/dia_body.svg"  
      alt="Pub Package" />  
</a>


The request body parser middleware for [Dia](https://github.com/unger1984/dia/packages/dia).
Parse query, x-www-form-urlencoded, json and form-data params and uploaded files form HttpRequest.

## Install:

Add to pubspec.yaml in dependencies section this:

```yaml
    dia_body: ^0.1.3
```

Then run `pub get`

## Usage:

A simple usage example:

```dart
class ContextWithBody extends Context with ParsedBody {
  ContextWithBody(HttpRequest request) : super(request);
}

void main() {
  final app = App((req) => ContextWithBody(req));

  app.use(body());

  app.use((ctx, next) async {
    ctx.body = ''' 
    query=${ctx.query}
    parsed=${ctx.parsed}
    files=${ctx.files}
    ''';
  });

  /// Start server listen on localhsot:8080
  app
      .listen('localhost', 8080)
      .then((info) => print('Server started on http://localhost:8080'));
}
```

## Optional named params:

* `uploadDirectory` - directory for upload files. Default: `Directory.systemTemp`

## Use with:

* [dia](https://github.com/unger1984/dia/packages/dia/README.md) - A simple dart http server in Koa2 style.
* [dia_router](https://github.com/unger1984/dia/packages/dia_router/README.md) - Middleware like as koa_router.
* [dia_cors](https://github.com/unger1984/dia/packages/dia_cors/README.md) - CORS middleware.
* [dia_static](https://github.com/unger1984/dia/packages/dia_static/README.md) - Package to serving static files.

## Migration from 0.0.*

change

```dart
final app = App<ContextWithBody>();
```

to

```dart
final app = App((req) => ContextWithBody(req));
```


## Features and bugs:

I will be glad for any help and feedback!
Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/unger1984/dia/issues
