# Dia Core Package Rules

Правила разработки для основного пакета `dia`.

## Философия

### Минимализм

Core пакет содержит **только** базовую функциональность:
- ✅ HTTP/HTTPS сервер
- ✅ Middleware композиция
- ✅ Базовый Context
- ✅ Error handling (HttpError)

**НЕ добавляй** в core:
- ❌ Routing (это `dia_router`)
- ❌ Body parsing (это `dia_body`)
- ❌ Static files (это `dia_static`)
- ❌ CORS (это `dia_cors`)
- ❌ Специфичные middleware

### Стабильность

Core пакет должен быть **стабильным**:
- Breaking changes только в major версиях
- API должен быть простым и понятным
- Backward compatibility где возможно
- Тщательное тестирование перед релизом

### Расширяемость

Core должен быть **легко расширяемым**:
- Context расширяется через наследование
- Mixins для добавления функциональности
- Generic типы для type safety
- Документированные extension points

## API Design

### App класс

```dart
class App<T extends Context> {
  // Конструктор с optional factory функцией
  App([T Function(HttpRequest request)? createContext]);
  
  // Минимальный набор публичных методов
  void use(Middleware<T> middleware);
  Future<void> listen(address, int port, {...});
  Future<void> listenOn(ServerSocket serverSocket);
  void close();
}
```

**Правила:**
- Конструктор должен принимать optional factory для Context
- Методы должны быть понятными и self-documenting
- НЕ добавляй методы которые можно реализовать через middleware
- НЕ добавляй конфигурационные параметры без крайней необходимости

### Context класс

```dart
class Context {
  final HttpRequest _request;
  late dynamic body;
  HttpError? error;
  
  Context(this._request);
  
  // Удобные геттеры для HttpRequest/HttpResponse
  HttpRequest get request => _request;
  HttpResponse get response => _request.response;
  HttpHeaders get headers => _request.response.headers;
  
  // Удобные геттеры/сеттеры для часто используемых полей
  int get statusCode;
  set statusCode(int code);
  
  ContentType? get contentType;
  set contentType(ContentType? type);
  
  // Утилиты
  void set(String key, String value);
  void throwError(int status, {...});
  Never hijack(void Function(StreamChannel<List<int>>) callback);
}
```

**Правила:**
- Context должен быть легким wrapper над HttpRequest/HttpResponse
- НЕ добавляй бизнес-логику в Context
- Предоставляй удобные геттеры/сеттеры для частых операций
- Документируй все публичные методы

### Middleware typedef

```dart
typedef Middleware<T extends Context> = Future<void> Function(
  T ctx,
  FutureOr<void> Function() next,
);
```

**Правила:**
- НЕ меняй сигнатуру без major version bump
- Тип должен быть generic для type safety
- Документируй контракт middleware (когда вызывать next)

### HttpError класс

```dart
class HttpError extends Error {
  HttpError(
    int status, {
    String? message,
    StackTrace? stackTrace,
    Exception? exception,
  });
  
  String get message;
  int get status;
  Exception? get exception;
  StackTrace? get stackTrace;
  String get defaultBody;  // HTML representation
}
```

**Правила:**
- HttpError для HTTP ошибок (4xx, 5xx)
- Должен предоставлять HTML representation
- НЕ добавляй JSON/XML serialization (это ответственность пользователя)
- Поддерживай stackTrace для отладки

## Реализация

### Middleware композиция

**КРИТИЧНО:** Паттерн композиции не должен меняться без major version:

```dart
Function _compose(List<Middleware<T>> middlewares) {
  return (T ctx, Middleware<T>? next) {
    var lastCalledIndex = -1;
    
    FutureOr dispatch(int currentCallIndex) async {
      if (currentCallIndex <= lastCalledIndex) {
        throw Exception('next() called multiple times');
      }
      lastCalledIndex = currentCallIndex;
      
      var fn = middlewares.length > currentCallIndex
          ? middlewares[currentCallIndex]
          : null;
      
      if (currentCallIndex == middlewares.length) {
        fn = next;
      }
      
      if (fn == null) return () => null;
      
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
    }
    
    return dispatch(0);
  };
}
```

**Правила:**
- Защита от множественного вызова `next()`
- Централизованная обработка ошибок
- HttpError обрабатывается отдельно от других исключений
- Все ошибки логируются с stackTrace

### Context body handling

```dart
// В _listen методе
Stream<List<int>>? stream;
if (ctx.body is String) {
  stream = Stream.fromIterable([utf8.encode(ctx.body)]);
} else if (ctx.body is List) {
  stream = Stream.fromIterable([ctx.body]);
} else if (ctx.body is Stream) {
  stream = ctx.body;
}
```

**Правила:**
- Поддерживай String, List<int>, Stream<List<int>>
- Автоматически конвертируй String в UTF-8
- Если body не установлен (null) → 404

### Request hijacking

```dart
class Context {
  late final _OnHijack _onHijack;
  
  bool get canHijack => !_onHijack.called;
  
  Never hijack(void Function(StreamChannel<List<int>>) callback) {
    _onHijack.run(callback);
    throw const HijackException();
  }
}
```

**Правила:**
- Hijacking только один раз на запрос
- Бросай HijackException после hijack
- Проверяй canHijack перед использованием
- НЕ меняй API hijacking без major version

## Расширение

### Custom Context

Пользователи должны иметь возможность создавать кастомные Context:

```dart
// Пример расширения
class CustomContext extends Context {
  String? userId;
  Map<String, dynamic>? sessionData;
  
  CustomContext(HttpRequest request) : super(request);
}

// Использование
final app = App((request) => CustomContext(request));
```

**Правила для расширения:**
- Конструктор Context должен принимать только HttpRequest
- НЕ добавляй обязательные параметры в конструктор
- Документируй как расширять Context
- Предоставляй примеры в README

### Mixins

Context должен поддерживать mixins:

```dart
mixin MyFeature on Context {
  Map<String, dynamic> data = {};
  
  void saveData(String key, dynamic value) {
    data[key] = value;
  }
}

class ContextWithFeature extends Context with MyFeature {
  ContextWithFeature(HttpRequest request) : super(request);
}
```

**Правила для mixins:**
- Используй `mixin Name on Context` для compile-time проверок
- Документируй какие поля/методы добавляет mixin
- НЕ меняй базовые поля Context в mixin
- Примеры mixins в README/примерах

## Тестирование

### Обязательные тесты

✅ **Middleware:**
- Последовательность выполнения
- Множественный вызов next() (должна быть ошибка)
- Остановка цепочки когда body установлен
- Error handling

✅ **Context:**
- Базовые геттеры/сеттеры
- Body handling (String, List, Stream)
- throwError метод
- Hijacking

✅ **App:**
- HTTP server запуск/остановка
- HTTPS с securityContext
- Custom Context factory
- Response generation

✅ **HttpError:**
- Создание с разными параметрами
- defaultBody генерация
- StackTrace handling

### Примеры тестов

```dart
void main() {
  App? app;
  
  setUp(() {
    app = App();
    app?.listen('localhost', 8080);
  });
  
  tearDown(() async {
    app?.close();
  });
  
  test('should execute middleware in order', () async {
    final order = <String>[];
    
    app?.use((ctx, next) async {
      order.add('first');
      await next();
    });
    
    app?.use((ctx, next) async {
      order.add('second');
      ctx.body = 'done';
    });
    
    await http.get(Uri.parse('http://localhost:8080'));
    
    expect(order, equals(['first', 'second']));
  });
}
```

## Версионирование

### Breaking Changes

**Breaking changes** требуют major version bump:
- Изменение сигнатуры Middleware typedef
- Удаление публичных методов/полей
- Изменение поведения по умолчанию
- Изменение паттерна композиции middleware

### Non-breaking Changes

**Minor version** для:
- Добавление новых методов с default значениями
- Новые optional параметры
- Улучшения производительности
- Исправления багов которые не меняют поведение

**Patch version** для:
- Bug fixes
- Документация
- Внутренние рефакторинги

### CHANGELOG

**ВСЕГДА** обновляй CHANGELOG.md:

```markdown
## 0.2.0

### Added
- Support for custom error pages
- New method `Context.redirect()`

### Fixed
- Memory leak in middleware composition
- Incorrect Content-Type for streams

### Breaking
- None

## 0.1.5

### Fixed
- Error handling for hijacked requests
```

## Документация

### README.md

Должен содержать:
- Краткое описание (что это и зачем)
- Установка
- Быстрый старт (hello world)
- Примеры middleware
- Примеры custom context
- Ссылки на другие пакеты
- API документация

### Dartdoc

Все публичные API должны быть документированы:

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

### Примеры

В `example/` должны быть:
- `basic_example.dart` - hello world
- `middleware_example.dart` - композиция middleware
- `custom_context_example.dart` - расширение context
- `error_handling_example.dart` - обработка ошибок
- `https_example.dart` - HTTPS сервер

## Performance

### Оптимизации

✅ **Допустимо:**
- Переиспользование объектов где безопасно
- Lazy initialization
- Кэширование compiled регулярок

❌ **НЕ допустимо:**
- Преждевременные оптимизации которые усложняют код
- Жертвовать читаемостью ради микрооптимизаций
- Использовать unsafe операции

### Бенчмарки

При оптимизациях:
1. Напиши бенчмарк
2. Измерь до оптимизации
3. Примени оптимизацию
4. Измерь после
5. Убедись что улучшение значительное (>10%)

## Безопасность

### Валидация входных данных

```dart
// Всегда валидируй параметры
HttpError(this._status, {...})
    : assert(_status >= 400 && _status <= 600,
          'The status should be an error code: 400-600');

Router(String prefix)
    : assert(RegExp(r'^/').hasMatch(prefix), 'Prefix must start with "/"');
```

### Обработка ошибок

- НЕ раскрывай stackTrace в production
- НЕ показывай детали внутренних ошибок пользователю
- Логируй все ошибки для отладки

### Headers

- НЕ добавляй заголовки безопасности по умолчанию (пусть пользователь контролирует)
- Документируй security best practices в README

## Совместимость

### Dart SDK

```yaml
environment:
  sdk: '>=3.8.0 <4.0.0'
```

- Используй фичи доступные с 3.8.0
- Тестируй на минимальной поддерживаемой версии
- Обновляй SDK constraint аккуратно (может быть breaking change)

### Dependencies

Минимизируй зависимости в core:

```yaml
dependencies:
  stream_channel: ^2.1.1  # Только для hijacking
```

**НЕ добавляй** зависимости без крайней необходимости.

## Checklist для PR

Перед созданием PR проверь:

- [ ] Все тесты проходят
- [ ] Lint правила соблюдены
- [ ] Dartdoc обновлен
- [ ] README обновлен (если нужно)
- [ ] CHANGELOG обновлен
- [ ] Примеры работают
- [ ] Breaking changes документированы
- [ ] Версия обновлена (если нужно)
