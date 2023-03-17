<a href="https://pub.dartlang.org/packages/dia_router">  
    <img src="https://img.shields.io/pub/v/dia_router.svg"  
      alt="Pub Package" />  
</a>

Router middleware for [Dia](https://github.com/unger1984/dia/packages/dia).

This package allows you to create separate middleware for specific urls and http methods

## Install:

Add to pubspec.yaml in dependencies section this:

```yaml
    dia_router: ^0.1.7
```

Then run `pub get`

## Usage:

A simple usage example:

```dart
import 'dart:io';

import 'package:dia/dia.dart';
import 'package:dia_router/dia_router.dart';

/// Custom Context with Routing mixin
class ContextWithRouting extends Context with Routing {
  ContextWithRouting(HttpRequest request) : super(request);
}

main() {
  final app = App((req)=>ContextWithRouting(req));
  
  final router = Router('/prefix');
  router.get('/path/:id', (ctx,next) async {
    ctx.body = 'params=${ctx.parsms} query=${ctx.query}';
  });
  
  app.use(router.middleware);

  app
      .listen('localhost', 8080)
      .then((info) => print('Route example on http://localhost:8080/perfix/path/12?count=10'));
}
```

GET http://localhost:8080/perfix/path/12?count=10
```
params={id:12} query={count:10}
```

Router support all HTTP method: GET,POST,PUT,PATCH,OPTION,DELETE,HEADER,CONNECT,TRACE

For more details, please, see example folder and test folder.

## Use with:

* [dia](https://github.com/unger1984/dia/packages/dia/README.md) - A simple dart http server in Koa2 style.
* [dia_cors](https://github.com/unger1984/dia/packages/dia_cors/README.md) - Package for CORS middleware.
* [dia_body](https://github.com/unger1984/dia/packages/dia_body/README.md) - Package with the middleware for parse request body.
* [dia_static](https://github.com/unger1984/dia/packages/dia_static/README.md) - Package to serving static files.

## Migration from 0.0.*

change 

```dart
final app = App<ContextWithRouting>();
```

to

```dart
final app = App((req)=>ContextWithRouting(req));
```

## Features and bugs:

I will be glad for any help and feedback!
Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/unger1984/dia/issues
