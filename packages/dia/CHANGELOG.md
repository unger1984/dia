# 0.1.6

- Workspace/monorepo support (Melos 7)
- Dependency constraints updated for publication

# 0.1.4

- Update dependencies
- Move to monorepo

# 0.1.3

- Fix error handling

# 0.1.2

- Fix error handling

## 0.1.1

- Change Error field in HttpError class to Exception.
- Add HttpError field in Context to handle http error before response
- Add handling error example to readme

## 0.1.0

- Remove dart:mirror, this now allows you to compile Dia in AOT mode.
- Add more information to readme

## 0.0.8

- Add `listenOn` method to listen http/https requests an existing ServerSocket
- Add more information to Readme
- Add more dartdoc comments in code

## 0.0.7

- Add default 404 answer
- Fix types

## 0.0.6

- Add link to dia_static
- Allow `Context.body` write `Stream`, `List` and `String`

## 0.0.5

- Change LICENSE

## 0.0.4

- Add `void close()` method, that close connection
- Add simple tests

## 0.0.3

- Fix links and descriptions

## 0.0.2

- Make `createInstance` public static in `Context`
- Add method `set(String key, String value)` to `Context` as symlink to `headers.set`
- Add the link to [dia_router](https://github.com/unger1984/dia_router)

## 0.0.1

- Initial version
