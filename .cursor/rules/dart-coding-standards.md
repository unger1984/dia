# Dart Coding Standards

Правила кодирования для проекта Dia Framework.

## Стиль кодирования

### Форматирование

- Используй `dart format` для автоматического форматирования
- **ВСЕГДА** добавляй trailing comma после последнего параметра в многострочных вызовах
- Максимальная длина строки: 80 символов (стандарт Dart)
- Используй 2 пробела для отступов

```dart
// Правильно
final app = App(
  (request) => CustomContext(request),
);

// Неправильно
final app = App(
  (request) => CustomContext(request)
);
```

### Пробелы и отступы

- Один пустой ряд между top-level декларациями
- Используй `newline-before-return` - пустая строка перед return
- Группируй импорты с пустой строкой между группами

## Именование

### Классы и типы

- **PascalCase** для классов, enum, typedef, type parameters
- Избегай префиксов вроде `I`, `A`, `T` (например, `IContext` → `Context`)

```dart
// Правильно
class App<T extends Context> { }
class HttpError extends Error { }
typedef Middleware<T extends Context> = Future<void> Function(...);

// Неправильно
class app { }
class http_error { }
```

### Методы и переменные

- **camelCase** для методов, переменных, параметров, именованных параметров
- Избегай сокращений (кроме общеизвестных: `ctx`, `uri`, `http`)

```dart
// Правильно
void use(Middleware<T> middleware) { }
final HttpServer server;
final Context ctx;

// Неправильно
void Use(Middleware<T> middleware) { }
void add_middleware(Middleware<T> mw) { }
```

### Приватные члены

- **Underscore prefix** (`_`) для приватных членов
- Применяется к классам, методам, переменным, конструкторам

```dart
class App<T extends Context> {
  late io.HttpServer _server;  // приватное поле
  final List<Middleware<T>> _middlewares = [];
  
  void _listen() async { }  // приватный метод
  
  void use(Middleware<T> middleware) {  // публичный метод
    _middlewares.add(middleware);
  }
}
```

### Константы

- **lowerCamelCase** для обычных констант
- **SCREAMING_SNAKE_CASE** только для enum-like константных групп

```dart
// Правильно
const defaultPort = 8080;
const Map<int, String> _codes = {...};

// Приемлемо для enum-like групп
const int STATUS_OK = 200;
const int STATUS_NOT_FOUND = 404;
```

## Импорты

### Порядок импортов

1. **dart:** импорты (стандартная библиотека)
2. **package:** импорты (внешние пакеты)
3. **Относительные импорты** (внутри пакета)

Разделяй группы пустой строкой:

```dart
import 'dart:async';
import 'dart:io' as io;

import 'package:dia/dia.dart';
import 'package:stream_channel/stream_channel.dart';

import 'context.dart';
import 'http_error.dart';
```

### Экспорты в главном файле

- Главный файл пакета (`lib/{package_name}.dart`) экспортирует публичное API
- Экспортируй только необходимые файлы из `src/`

```dart
// lib/dia.dart
library dia;

export 'src/app.dart';
export 'src/context.dart';
export 'src/http_error.dart';
// НЕ экспортируй внутренние утилиты
```

### Префиксы импортов

- Используй `as` для устранения конфликтов или улучшения читаемости
- Стандартные префиксы: `io` для `dart:io`, `async` для `dart:async`

```dart
import 'dart:io' as io;

void listen(
  address,
  int port, {
  io.SecurityContext? securityContext,  // явно из dart:io
}) async { }
```

## Документация

### Dartdoc комментарии

- Используй `///` для публичных API
- Первая строка - краткое описание (заканчивается точкой)
- Ссылки на типы в квадратных скобках: `[Context]`, `[HttpRequest]`
- Документируй параметры отдельными строками

```dart
/// Dia application class
/// The web server listens to the http / https port and applies
/// the middleware to the received requests
///
/// [Middleware] in App must be in the same [Context] as App
class App<T extends Context> {
  /// Add [Middleware] to App
  /// [Middleware] must be in the same [Context] as App
  void use(Middleware<T> middleware) {
    _middlewares.add(middleware);
  }
}
```

### Комментарии в коде

- Используй `//` для inline комментариев
- Объясняй "почему", а не "что"
- Избегай очевидных комментариев

```dart
// Правильно - объясняет причину
// Set default response content-type
contentType ??= ContentType.html;

// Неправильно - очевидно из кода
// Add middleware to list
_middlewares.add(middleware);
```

## Типы и null-safety

### Nullable типы

- Используй `?` для nullable типов
- Используй `late` для отложенной инициализации non-nullable полей
- Используй `??` и `??=` для null-coalescing

```dart
class Context {
  final HttpRequest _request;
  late dynamic body;  // будет инициализирован позже
  HttpError? error;  // может быть null
  
  Context(this._request) {
    contentType ??= ContentType.html;  // default если null
  }
}
```

### Type inference

- Используй `var` и `final` когда тип очевиден
- Указывай тип явно для публичных API и когда это улучшает читаемость

```dart
// Хорошо - тип очевиден
var statusCode = 200;
final uri = request.uri;

// Хорошо - явный тип для ясности
final List<Middleware<T>> _middlewares = [];
Middleware<T> Function() get middleware => ...;
```

### Generics

- Используй осмысленные имена для type parameters
- `T` для основного типа, `T extends BaseType` для ограничений
- Документируй generic ограничения

```dart
/// [Middleware] in App must be in the same [Context] as App
class App<T extends Context> {
  final List<Middleware<T>> _middlewares = [];
  
  void use(Middleware<T> middleware) {
    _middlewares.add(middleware);
  }
}
```

## Lint правила

Проект использует `analysis_options.yaml` с следующими настройками:

### Основа

```yaml
include: package:lints/recommended.yaml
```

### Рекомендации по стилю

- Пустая строка перед return
- Избегай `if (flag == true)` — используй `if (flag)`
- Запрет пустых блоков кода
- Используй trailing comma в многострочных вызовах
- Тернарный оператор где уместно вместо if-else

### Примеры

```dart
// Правильно - newline-before-return
Future<void> handle(T ctx) async {
  await processRequest(ctx);
  
  return;
}

// Правильно - no-boolean-literal-compare
if (canHijack) { }  // не if (canHijack == true)

// Правильно - prefer-trailing-comma
final server = await HttpServer.bind(
  address,
  port,
  backlog: backlog,
  v6Only: v6Only,
  shared: shared,  // trailing comma
);

// Правильно - prefer-conditional-expressions
final message = error != null ? error.message : 'Unknown';
// вместо if-else для простых случаев
```

## Assertions

- Используй `assert` для проверки инвариантов
- Добавляй понятные сообщения об ошибках

```dart
Router(String prefix)
    : assert(RegExp(r'^/').hasMatch(prefix), 'Prefix must start with "/"') {
  _prefix = prefix;
}

HttpError(this._status, {...})
    : assert(_status >= 400 && _status <= 600,
          'The status should be an error code: 400-600') {
  // ...
}
```

## Исключения и ошибки

### Типы исключений

- Используй `Error` для программных ошибок (наследуй от `Error`)
- Используй `Exception` для ожидаемых исключительных ситуаций
- Документируй какие исключения может бросить метод

```dart
class HttpError extends Error {
  final int _status;
  // ...
}

class HijackException implements Exception {
  const HijackException();
  // ...
}
```

### Обработка ошибок

- Используй try-catch для обработки исключений
- Используй `.catchError()` для Future
- Предоставляй контекст в stackTrace

```dart
return fn(ctx, () => dispatch(currentCallIndex + 1))
    .catchError((error, stackTrace) {
  if (error is HttpError) {
    _responseHttpError(ctx, error);
  } else {
    final err = HttpError(
      500,
      stackTrace: stackTrace,
      exception: Exception(error),
    );
    _responseHttpError(ctx, err);
  }
});
```

## Асинхронность

### Async/Await

- Используй `async`/`await` вместо raw Futures
- Всегда указывай `async` если используешь `await`
- Возвращай `Future<void>` для async методов без возвращаемого значения

```dart
Future<void> listen(address, int port) async {
  _server = await io.HttpServer.bind(address, port);
  await _listen();
}
```

### FutureOr

- Используй `FutureOr<T>` когда функция может быть синхронной или асинхронной
- Полезно для middleware и callback

```dart
typedef Middleware<T extends Context> = Future<void> Function(
  T ctx,
  FutureOr<void> Function() next,  // next может быть sync или async
);
```

## Проверка кода

### Перед коммитом

**ВАЖНО:** Проект использует FVM, все команды должны выполняться через `fvm`:

1. Запусти `fvm melos run analyze` - проверка lint правил
2. Запусти `fvm melos run format` - автоформатирование
3. Запусти `fvm melos run test` - все тесты
4. Проверь что нет новых lint warnings

### Автоматизация

Используй Melos команды из корня проекта:

```bash
# Полная проверка
fvm melos run lint:all

# Только анализ
fvm melos run analyze

# Форматирование с исправлениями
fvm melos run format

# Проверка форматирования без изменений
fvm melos run format-check
```
