<a href="https://pub.dartlang.org/packages/dia_cors">  
    <img src="https://img.shields.io/pub/v/dia_cors.svg"  
      alt="Pub Package" />  
</a>

The CORS middleware for [Dia](https://github.com/unger1984/dia/packages/dia).

## Install:

Add to pubspec.yaml in dependencies section this:

```yaml
    dia_cors: ^0.1.2
```

Then run `pub get`

## Usage:

A simple usage example:

```dart
    app.use(cors());
```

## Optional named params:

* `origin` - Access-Control-Allow-Origin header. Default: '*'
* `maxAge` - Access-Control-Max-Age header
* `credentials` - Access-Control-Allow-Credentials header
* `expose` - Access-Control-Expose-Headers header

## Use with:

* [dia](https://github.com/unger1984/dia/packages/dia/README.md) - A simple dart http server in Koa2 style.
* [dia_router](https://github.com/unger1984/dia/packages/dia_router/README.md) - Middleware like as koa_router.
* [dia_body](https://github.com/unger1984/dia/packages/dia_body/README.md) - Package with the middleware for parse request body.
* [dia_static](https://github.com/unger1984/dia/packages/dia_static/README.md) - Package to serving static files.

## Features and bugs:

I will be glad for any help and feedback!
Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/unger1984/dia/packages/dia_cors/issues
