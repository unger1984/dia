# Dia

<a href="https://pub.dartlang.org/packages/dia">  
    <img src="https://img.shields.io/pub/v/dia.svg"  
      alt="Pub Package" />  
</a>
<a href="https://github.com/unger1984/dia">  
    <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/unger1984/dia">
</a>

A simple dart http server like KoaJS.

This package allows you to create a http / http server in a couple of lines. Dia creates a context from a bunch of request and response and passes it through the middleware.

The main idea of the project is minimalism. The package contains only basic functionality, everything else is implemented in separate packages. This allows you to keep the project code clean and connect only those dependencies that are really needed in it.

## Install:

Add to pubspec.yaml in dependencies section this:

```yaml
    dia: ^0.1.4
```

Then run `pub get`

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

Context contain getters and setters for `HttpRequest` fields: response,  response.headers, response.headers.contentType, response.statusCode, that allow use it easy.
Context contain method `throwError` that allow easy return HTTP errors by statusCode.

Example `throwError`:

```dart
    app.use((ctx,next) async {
      ctx.throwError(401);
    });
```

You can use custom `Context` with additional fields and methods. In this case, you need to inherit from the base Context and pass the instance of context creation function to the App constructor.

```dart
/// Create custom context class
class CustomContext extends Context{
  String? additionalField;
  CustomContext(HttpRequest request) : super(request);
}

void main() {
  /// Create Dia instance 
  final app = App((request) => CustomContext(request));

  /// Add additionalField value
  app.use((ctx, next) async {
    ctx.additionalField = 'additional value';
    await next();
  });

  /// final middleware to response
  app.use((ctx, next) async {
    ctx.contentType = ContentType.text;
    ctx.body = ctx.additionalField;
  });

  /// Start server listen on localhost:8080
  app
      .listen('localhost', 8080)
      .then((info) => print('Server started on http://localhost:8080'));
}
```

Your can add handler to all Http errors:

```dart
app.use((ctx,next) async {
  await next();
  if(ctx.statusCode!=200){
    //....
  }
});
```

You can start your server with SSL:

```dart
const serverKey = 'cert/key.pem';
const certificateChain = 'cert/chain.pem';

final serverContext = SecurityContext();
serverContext
    .useCertificateChainBytes(await File(certificateChain).readAsBytes());
serverContext.usePrivateKey(serverKey, password: 'password');

app.listen('localhost', 8444, securityContext: serverContext);
```

For more details, please, see example and test folder.

## Use with:

* [dia_router](https://github.com/unger1984/dia/packages/dia_router/README.md) - Package to route request as koa-router.
* [dia_cors](https://github.com/unger1984/dia/packages/dia_cors/README.md) - Package for CORS middleware.
* [dia_body](https://github.com/unger1984/dia/packages/dia_body/README.md) - Package with the middleware for parse request body.
* [dia_static](https://github.com/unger1984/dia/packages/dia_static/README.md) - Package to serving static files.

## Features and bugs:

I will be glad for any help and feedback!
Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/unger1984/dia/issues
