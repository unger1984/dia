# Architecture Patterns

Архитектурные паттерны и принципы проекта Dia Framework.

## Философия фреймворка

### Минимализм

- **Core пакет** содержит только базовую функциональность
- Каждая дополнительная фича - отдельный пакет
- Избегай feature creep в core пакете

### Расширяемость

- Функциональность расширяется через middleware
- Context расширяется через наследование или mixins
- API должен быть гибким но типобезопасным

### Консистентность

- Единый подход к middleware во всех пакетах
- Одинаковые паттерны error handling
- Согласованное именование методов (`use`, `listen`, `close`)

## Middleware Pattern

### Сигнатура middleware

```dart
typedef Middleware<T extends Context> = Future<void> Function(
  T ctx,
  FutureOr<void> Function() next,
);
```

### Композиция middleware

Middleware выполняются последовательно через паттерн композиции:

```dart
app.use((ctx, next) async {
  // Код ДО обработки запроса
  print('Before request');
  
  await next();  // Передать управление следующему middleware
  
  // Код ПОСЛЕ обработки запроса
  print('After request');
});
```

### Правила middleware

1. **ВСЕГДА** вызывай `await next()` если хочешь продолжить цепочку
2. **НЕ вызывай** `next()` если обработал запрос и установил `ctx.body`
3. **НЕ вызывай** `next()` больше одного раза (будет Exception)
4. Код после `await next()` выполняется в обратном порядке (как stack)

### Примеры middleware

```dart
// Логирование
app.use((ctx, next) async {
  final start = DateTime.now();
  await next();
  final duration = DateTime.now().difference(start);
  print('${ctx.request.method} ${ctx.request.uri} - ${duration.inMilliseconds}ms');
});

// Обработка ошибок
app.use((ctx, next) async {
  try {
    await next();
  } catch (e) {
    ctx.statusCode = 500;
    ctx.body = 'Internal Server Error';
  }
});

// Завершение обработки (не вызываем next)
app.use((ctx, next) async {
  ctx.body = 'Hello World';
  // НЕ вызываем next() - запрос обработан
});
```

### Внутренняя реализация композиции

Middleware композиция использует dispatch функцию:

```dart
Function _compose(List<Middleware<T>> middlewares) {
  return (T ctx, Middleware<T>? next) {
    var lastCalledIndex = -1;
    
    FutureOr dispatch(int currentCallIndex) async {
      // Защита от множественного вызова next()
      if (currentCallIndex <= lastCalledIndex) {
        throw Exception('next() called multiple times');
      }
      lastCalledIndex = currentCallIndex;
      
      var fn = middlewares.length > currentCallIndex
          ? middlewares[currentCallIndex]
          : null;
      
      if (fn == null) return () => null;
      
      // Рекурсивно вызываем следующий middleware
      return fn(ctx, () => dispatch(currentCallIndex + 1))
          .catchError((error, stackTrace) {
        // Обработка ошибок...
      });
    }
    
    return dispatch(0);
  };
}
```

**Ключевые моменты:**
- `lastCalledIndex` предотвращает множественный вызов `next()`
- Рекурсия через `dispatch(currentCallIndex + 1)`
- Централизованная обработка ошибок через `.catchError()`

## Context Pattern

### Базовый Context

Context оборачивает `HttpRequest` и `HttpResponse` для удобного доступа:

```dart
class Context {
  final HttpRequest _request;
  late dynamic body;
  HttpError? error;
  
  Context(this._request) {
    contentType ??= ContentType.html;
    body = null;
  }
  
  // Удобные геттеры/сеттеры
  HttpRequest get request => _request;
  HttpResponse get response => _request.response;
  HttpHeaders get headers => _request.response.headers;
  
  int get statusCode => response.statusCode;
  set statusCode(int code) => response.statusCode = code;
  
  ContentType? get contentType => headers.contentType;
  set contentType(ContentType? type) => headers.contentType = type;
}
```

### Расширение Context через наследование

```dart
class CustomContext extends Context {
  String? userId;
  Map<String, dynamic>? sessionData;
  
  CustomContext(HttpRequest request) : super(request);
}

// Использование
final app = App((request) => CustomContext(request));

app.use((ctx, next) async {
  ctx.userId = '123';  // доступ к кастомным полям
  await next();
});
```

### Расширение Context через Mixins

```dart
// Определение mixin
mixin Routing on Context {
  Map<String, String> params = {};
  Map<String, String> query = {};
  String routerPrefix = '';
}

// Применение mixin
class ContextWithRouting extends Context with Routing {
  ContextWithRouting(HttpRequest request) : super(request);
}

// Использование
final router = Router<ContextWithRouting>('/api');
router.get('/users/:id', (ctx, next) async {
  final id = ctx.params['id'];  // доступ из mixin
  ctx.body = 'User $id';
});
```

### Правила работы с Context

1. **НЕ мутируй** `request` напрямую - используй Context API
2. **Устанавливай** `ctx.body` для ответа (String, List<int>, или Stream<List<int>>)
3. **Используй** `ctx.throwError()` для генерации HTTP ошибок
4. **Расширяй** через mixins для добавления функциональности
5. **Документируй** какие mixins требуются для middleware

### Context body handling

```dart
// String - автоматически кодируется в UTF-8
ctx.body = 'Hello World';

// List<int> - бинарные данные
ctx.body = [0x48, 0x65, 0x6c, 0x6c, 0x6f];

// Stream<List<int>> - для больших файлов или streaming
ctx.body = file.openRead();

// Null - 404 Not Found (если никто не установил body)
ctx.body = null;
```

## Error Handling Pattern

### HttpError класс

```dart
class HttpError extends Error {
  final int _status;
  late String _message;
  late Exception? _exception;
  late final StackTrace? _stackTrace;
  
  HttpError(
    this._status, {
    String? message,
    StackTrace? stackTrace,
    Exception? exception,
  }) : assert(_status >= 400 && _status <= 600) {
    _message = message ?? _codes[_status] ?? 'Unknown error';
    _stackTrace = stackTrace;
    _exception = exception;
  }
  
  String get defaultBody {
    // Генерирует HTML страницу с деталями ошибки
  }
}
```

### Генерация ошибок

```dart
// Через Context метод
ctx.throwError(404, message: 'User not found');

// С exception и stackTrace
try {
  await dangerousOperation();
} catch (e, stackTrace) {
  ctx.throwError(500, exception: e, stackTrace: stackTrace);
}

// Прямое создание HttpError
throw HttpError(403, message: 'Access denied');
```

### Централизованная обработка ошибок

Ошибки перехватываются в middleware композиции:

```dart
return fn(ctx, () => dispatch(currentCallIndex + 1))
    .catchError((error, stackTrace) {
  if (error is HttpError) {
    _responseHttpError(ctx, error);
  } else {
    // Неожиданные ошибки оборачиваем в 500
    final err = HttpError(
      500,
      stackTrace: stackTrace,
      exception: Exception(error),
    );
    _responseHttpError(ctx, err);
  }
});
```

### Правила error handling

1. **Используй HttpError** для HTTP ошибок (4xx, 5xx)
2. **НЕ ловi** ошибки если не можешь их обработать
3. **Передавай stackTrace** для отладки
4. **Логируй** критические ошибки (500)
5. **НЕ раскрывай** детали внутренних ошибок клиенту в production

### Пример middleware для обработки ошибок

```dart
app.use((ctx, next) async {
  try {
    await next();
  } on HttpError catch (e) {
    // HttpError уже обработан middleware композицией
    rethrow;
  } catch (e, stackTrace) {
    // Логирование необработанных ошибок
    print('Unexpected error: $e\n$stackTrace');
    rethrow;
  }
});
```

## Router Pattern

### Структура Router

```dart
class Router<T extends Routing> {
  late final String _prefix;
  final List<RouterMiddleware<T>> _routerMiddlewares = [];
  
  Router(String prefix)
      : assert(RegExp(r'^/').hasMatch(prefix), 'Prefix must start with "/"') {
    _prefix = prefix.replaceAll(RegExp(r'/$'), '');
  }
  
  void get(String path, Middleware<T> middleware) {
    _routerMiddlewares.add(RouterMiddleware('get', path, middleware));
  }
  
  Middleware<T> get middleware => (T ctx, next) async {
    await _handle(ctx);
    await next();
  };
}
```

### Path параметры

Используется библиотека `path_to_regexp` для парсинга:

```dart
// Определение роутов
router.get('/users/:id', (ctx, next) async {
  final id = ctx.params['id'];
  ctx.body = 'User ID: $id';
});

router.get('/posts/:postId/comments/:commentId', (ctx, next) async {
  final postId = ctx.params['postId'];
  final commentId = ctx.params['commentId'];
  ctx.body = 'Post $postId, Comment $commentId';
});

// Опциональные параметры
router.get('/users/:id?', (ctx, next) async {
  final id = ctx.params['id'] ?? 'all';
  ctx.body = 'User(s): $id';
});
```

### Вложенные роутеры

```dart
final app = App<ContextWithRouting>(
  (request) => ContextWithRouting(request),
);

// API router с префиксом /api
final apiRouter = Router<ContextWithRouting>('/api');

// Вложенный роутер для /api/v1
final v1Router = Router<ContextWithRouting>('/v1');
v1Router.get('/users', (ctx, next) async {
  // Доступен по /api/v1/users
  ctx.body = 'API v1 users';
});

apiRouter.use(v1Router.middleware);
app.use(apiRouter.middleware);
```

### HTTP методы

Router поддерживает все стандартные HTTP методы:

```dart
router.get('/resource', handler);      // GET
router.post('/resource', handler);     // POST
router.put('/resource', handler);      // PUT
router.patch('/resource', handler);    // PATCH
router.delete('/resource', handler);   // DELETE (или del)
router.head('/resource', handler);     // HEAD
router.options('/resource', handler);  // OPTIONS
router.all('/resource', handler);      // Любой метод
```

### Автоматическая обработка OPTIONS

Router автоматически обрабатывает OPTIONS запросы для CORS:

```dart
// Автоматически добавляется в конструкторе Router
use((ctx, next) async {
  if (ctx.request.method.toLowerCase() == 'options') {
    var allow = _getAllow(ctx);
    if (allow.isNotEmpty) {
      ctx.set('Allow', '${allow.join(', ')}, OPTIONS');
      ctx.statusCode = 204;
      ctx.body = '';
    }
  }
  await next();
});
```

## Factory Pattern для Context

### Определение фабрики

```dart
class App<T extends Context> {
  late Function(HttpRequest request) _createContext;
  
  App([T Function(HttpRequest request)? createContext]) {
    _createContext =
        createContext ?? (HttpRequest request) => Context(request);
  }
}
```

### Применение

```dart
// Default Context
final app = App();

// Custom Context
class MyContext extends Context with Routing, ParsedBody {
  String? authToken;
  
  MyContext(HttpRequest request) : super(request) {
    authToken = request.headers.value('Authorization');
  }
}

final customApp = App((request) => MyContext(request));
```

### Правила фабрик

1. Фабрика должна принимать `HttpRequest` и возвращать `T extends Context`
2. Тип Context в фабрике должен совпадать с типом App
3. Инициализация полей Context должна быть в конструкторе
4. Фабрика вызывается для КАЖДОГО запроса

## Type Safety

### Generic constraints

```dart
// App требует Context или его наследников
class App<T extends Context> { }

// Router требует Context с Routing mixin
class Router<T extends Routing> { }

// Middleware работает с тем же Context что и App/Router
typedef Middleware<T extends Context> = Future<void> Function(
  T ctx,
  FutureOr<void> Function() next,
);
```

### Проверка типов

```dart
// Правильно - типы совпадают
final app = App<ContextWithRouting>(
  (request) => ContextWithRouting(request),
);
final router = Router<ContextWithRouting>('/api');
app.use(router.middleware);  // OK

// Ошибка компиляции - несовместимые типы
final app = App<Context>((request) => Context(request));
final router = Router<ContextWithRouting>('/api');
app.use(router.middleware);  // Error: type mismatch
```

## Лучшие практики

### Middleware

- Делай middleware простыми и фокусированными на одной задаче
- Композируй сложное поведение из простых middleware
- Документируй требования к Context (mixins, поля)
- Обрабатывай ошибки на соответствующем уровне

### Context

- Минимизируй количество полей в Context
- Используй mixins для группировки связанной функциональности
- Не храни большие объекты в Context (утечки памяти)
- Делай поля readonly где возможно

### Error Handling

- Используй HttpError для HTTP ошибок
- Логируй ошибки на уровне приложения
- Не раскрывай stackTrace в production
- Предоставляй понятные сообщения об ошибках

### Router

- Группируй связанные роуты в отдельные роутеры
- Используй вложенные роутеры для версионирования API
- Документируй path параметры
- Валидируй параметры в handler'ах
