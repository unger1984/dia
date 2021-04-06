# Dia

<a href="https://pub.dartlang.org/packages/dia">  
    <img src="https://img.shields.io/pub/v/dia.svg"  
      alt="Pub Package" />  
</a>
<a href="https://github.com/unger1984/dia">  
    <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/unger1984/dia">
</a>

A simple dart http server like KoaJS.

This package is a wrapper over dart:io.HttpServer and allows you to create a queue of Middlewares. Each `Middleware` accepts a `Context` as its first argument, which can change, and as a second argument, a `Future` to the next `Middleware`, which allows you to wait for the execution of the following `Middleware` after the current one.

## Usage:

A simple usage example:

```dart
import 'package:dia/dia.dart';

main() {
  final app = App();
  
  app.use((ctx,next) async {
    ctx.body = 'Hello world!';
  });

  app
      .listen('localhost', 8080)
      .then((info) => print('Server started on http://localhost:8080'));
}
```

Context contain getters and setters for `Request` fields response,  response.headers, response.headers.contentType, response.statusCode, that allow use it easy.
Context contain method `throwError` that allow easy return HTTP errors by statusCode.

Example `throwError`:

```dart
    app.use((ctx,next) async {
      ctx.throwError(401);
    });
```

For details, please, see example folder.

## Use with:

* [dia_router](https://github.com/unger1984/dia_router) - Package to route request as koa-router.
* [dia_cors](https://github.com/unger1984/dia_cors) - Package for CORS middleware.
* [dia_body](https://github.com/unger1984/dia_body) - Package with the middleware for parse request body.
* [dia_static](https://github.com/unger1984/dia_static) - Package to serving static files.

## Features and bugs:

I will be glad for any help and feedback!
Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/unger1984/dia/issues
