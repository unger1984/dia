# Dia Router Package Rules

Правила разработки для пакета `dia_router`.

## Философия

### Цель пакета

Router предоставляет **URL-based routing** для Dia:
- ✅ Path matching с параметрами
- ✅ HTTP method routing (GET, POST, PUT, DELETE, etc.)
- ✅ Вложенные роутеры (nested routing)
- ✅ Query параметры
- ✅ Автоматическая обработка OPTIONS для CORS

### Что НЕ должен делать Router

❌ **НЕ добавляй:**
- Body parsing (это `dia_body`)
- Authentication/Authorization
- Rate limiting
- Caching
- Специфичную бизнес-логику

## Требования к Context

### Routing Mixin

Router **требует** Context с `Routing` mixin:

```dart
mixin Routing on Context {
  Map<String, String> _params = {};
  final Map<String, String> _query = {};
  String routerPrefix = '';
  
  Map<String, String> get params => _params;
  set params(Map<String, String> params) => _params = params;
  
  Map<String, String> get query => _query;
}
```

**Правила:**
- `params` - path параметры (`:id`, `:name`)
- `query` - URL query параметры (`?key=value`)
- `routerPrefix` - для вложенных роутеров (внутреннее использование)

### Context создание

```dart
import 'dart:io';
import 'package:dia/dia.dart';
import 'package:dia_router/dia_router.dart';

class ContextWithRouting extends Context with Routing {
  ContextWithRouting(HttpRequest request) : super(request);
}

void main() {
  final app = App<ContextWithRouting>(
    (request) => ContextWithRouting(request),
  );
  
  final router = Router<ContextWithRouting>('/api');
  app.use(router.middleware);
}
```

## API Design

### Router класс

```dart
class Router<T extends Routing> {
  Router(String prefix);
  
  // Регистрация middleware
  void use(Middleware<T> middleware);
  
  // HTTP методы
  void get(String path, Middleware<T> middleware);
  void post(String path, Middleware<T> middleware);
  void put(String path, Middleware<T> middleware);
  void patch(String path, Middleware<T> middleware);
  void delete(String path, Middleware<T> middleware);
  void del(String path, Middleware<T> middleware);  // alias
  void head(String path, Middleware<T> middleware);
  void connect(String path, Middleware<T> middleware);
  void options(String path, Middleware<T> middleware);
  void trace(String path, Middleware<T> middleware);
  void all(String path, Middleware<T> middleware);
  
  // Middleware getter для App
  Middleware<T> get middleware;
}
```

### Prefix validation

```dart
Router(String prefix)
    : assert(RegExp(r'^/').hasMatch(prefix), 'Prefix must start with "/"') {
  _prefix = prefix.replaceAll(RegExp(r'/$'), '');
}
```

**Правила:**
- Prefix ДОЛЖЕН начинаться с `/`
- Trailing slash удаляется автоматически
- Пустой prefix (`/`) валиден
- Prefix может содержать несколько сегментов (`/api/v1`)

## Path Matching

### Path-to-RegExp

Router использует библиотеку `path_to_regexp` для matching:

```dart
import 'package:path_to_regexp/path_to_regexp.dart';

// Простой path
pathToRegExp('/users').hasMatch('/users')  // true

// С параметрами
final params = <String>[];
final regExp = pathToRegExp('/users/:id', parameters: params);
regExp.hasMatch('/users/123')  // true
// params = ['id']

// Извлечение параметров
final match = regExp.matchAsPrefix('/users/123');
final values = extract(params, match!);  // {'id': '123'}
```

### Паттерны путей

```dart
// Статичный путь
router.get('/users', handler);

// Параметр
router.get('/users/:id', handler);

// Множественные параметры
router.get('/posts/:postId/comments/:commentId', handler);

// Опциональный параметр
router.get('/users/:id?', handler);

// Wildcard (через path-to-regexp синтаксис)
router.get('/files/(.*)', handler);
```

### Path matching правила

1. Prefix роутера комбинируется с path: `prefix + path`
2. Matching с учетом вложенных префиксов
3. Query параметры не влияют на matching
4. Trailing slash игнорируется

## HTTP Methods

### Поддерживаемые методы

```dart
router.get('/resource', handler);      // GET
router.post('/resource', handler);     // POST
router.put('/resource', handler);      // PUT
router.patch('/resource', handler);    // PATCH
router.delete('/resource', handler);   // DELETE (или .del())
router.head('/resource', handler);     // HEAD
router.connect('/resource', handler);  // CONNECT
router.options('/resource', handler);  // OPTIONS (редко нужно вручную)
router.trace('/resource', handler);    // TRACE
router.all('/resource', handler);      // Любой метод
```

### Метод .all()

```dart
router.all('/resource', (ctx, next) async {
  // Выполняется для GET, POST, PUT, DELETE, etc.
});
```

**Использование:**
- Общий middleware для всех методов определенного пути
- Логирование, валидация, authentication

### Метод .use()

```dart
router.use((ctx, next) async {
  // Выполняется для ВСЕХ путей под этим роутером
  print('Request to ${ctx.request.uri}');
  await next();
});
```

**Разница между .use() и .all():**
- `.use()` - для всех путей, выполняется первым
- `.all(path)` - только для конкретного пути, но любого метода

## Автоматическая обработка OPTIONS

Router автоматически обрабатывает OPTIONS запросы:

```dart
// В конструкторе Router
use((ctx, next) async {
  if (ctx.request.method.toLowerCase() == 'options') {
    var allow = _getAllow(ctx);
    if (allow.isNotEmpty) {
      if (ctx.request.headers.value('Access-Control-Request-Method') != null) {
        ctx.set(
          'Access-Control-Allow-Methods',
          '${allow.join(', ')}, OPTIONS',
        );
      }
      ctx.set('Allow', '${allow.join(', ')}, OPTIONS');
      ctx.statusCode = 204;
      ctx.body = '';
    }
  }
  await next();
});
```

**Правила:**
- Автоматически определяет допустимые методы для пути
- Устанавливает `Allow` header
- Устанавливает `Access-Control-Allow-Methods` для CORS preflight
- Возвращает 204 No Content
- Пользователь может переопределить через `.options(path, handler)`

## Вложенные роутеры

### Базовый паттерн

```dart
final app = App<ContextWithRouting>(
  (request) => ContextWithRouting(request),
);

// API роутер
final apiRouter = Router<ContextWithRouting>('/api');

// V1 роутер
final v1Router = Router<ContextWithRouting>('/v1');
v1Router.get('/users', (ctx, next) async {
  // Доступен как /api/v1/users
  ctx.body = 'API v1 users';
});

// V2 роутер
final v2Router = Router<ContextWithRouting>('/v2');
v2Router.get('/users', (ctx, next) async {
  // Доступен как /api/v2/users
  ctx.body = 'API v2 users';
});

apiRouter.use(v1Router.middleware);
apiRouter.use(v2Router.middleware);
app.use(apiRouter.middleware);
```

### Правила вложенности

1. Префиксы комбинируются: `/api` + `/v1` = `/api/v1`
2. Порядок регистрации важен (первый matching wins)
3. Каждый роутер независим (можно переиспользовать)
4. `routerPrefix` отслеживает текущий накопленный префикс

### routerPrefix (внутреннее использование)

```dart
// Сохраняем предыдущий префикс
final savedPrefix = ctx.routerPrefix;
await _handle(ctx);
// Восстанавливаем
ctx.routerPrefix = savedPrefix;
```

**НЕ модифицируй** `routerPrefix` в пользовательском коде.

## Параметры

### Path параметры

```dart
router.get('/users/:id', (ctx, next) async {
  final id = ctx.params['id'];
  ctx.body = 'User ID: $id';
});

// Multiple params
router.get('/posts/:postId/comments/:commentId', (ctx, next) async {
  final postId = ctx.params['postId'];
  final commentId = ctx.params['commentId'];
  ctx.body = 'Post $postId, Comment $commentId';
});
```

**Правила:**
- Параметры доступны через `ctx.params`
- Тип всегда `String`
- Конвертируй в нужный тип вручную
- Валидируй параметры в handler

### Query параметры

```dart
router.get('/search', (ctx, next) async {
  final query = ctx.query['q'];
  final limit = int.tryParse(ctx.query['limit'] ?? '10') ?? 10;
  
  ctx.body = 'Search: $query, Limit: $limit';
});

// /search?q=test&limit=20
```

**Правила:**
- Query параметры доступны через `ctx.query`
- Парсятся из `ctx.request.uri.queryParameters`
- Тип всегда `String`
- Используй `tryParse()` для конвертации

### Валидация параметров

```dart
router.get('/users/:id', (ctx, next) async {
  final id = ctx.params['id'];
  
  // Валидация
  final userId = int.tryParse(id ?? '');
  if (userId == null || userId <= 0) {
    ctx.throwError(400, message: 'Invalid user ID');
    return;
  }
  
  // Бизнес-логика
  ctx.body = 'User $userId';
});
```

## Error Handling

### 404 для неизвестных роутов

Router автоматически возвращает 404 если ни один роут не совпал:

```dart
if (filteredMiddlewares.isEmpty) {
  ctx.throwError(404);
}
```

### Error propagation

Ошибки из handler'ов перехватываются в композиции:

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

### Обработка ошибок в handlers

```dart
router.get('/users/:id', (ctx, next) async {
  try {
    final user = await database.findUser(ctx.params['id']);
    if (user == null) {
      ctx.throwError(404, message: 'User not found');
      return;
    }
    ctx.body = jsonEncode(user);
  } catch (e, stackTrace) {
    ctx.throwError(500, exception: e, stackTrace: stackTrace);
  }
});
```

## Middleware в Router

### Early middleware через .use()

```dart
router.use((ctx, next) async {
  // Логирование
  print('${ctx.request.method} ${ctx.request.uri}');
  await next();
});

router.use((ctx, next) async {
  // Authentication
  final token = ctx.request.headers.value('Authorization');
  if (token == null) {
    ctx.throwError(401, message: 'Unauthorized');
    return;
  }
  await next();
});

// Роуты регистрируются после
router.get('/users', handler);
```

**Порядок выполнения:**
1. `.use()` middleware (в порядке регистрации)
2. Route-specific handlers (GET, POST, etc.)

### Остановка цепочки

```dart
router.use((ctx, next) async {
  if (!isAuthorized(ctx)) {
    ctx.throwError(403, message: 'Forbidden');
    return;  // НЕ вызываем next()
  }
  await next();
});
```

## Тестирование

### Базовая структура

```dart
import 'dart:io';
import 'package:dia/dia.dart';
import 'package:dia_router/dia_router.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class ContextWithRouting extends Context with Routing {
  ContextWithRouting(HttpRequest request) : super(request);
}

void main() {
  App<ContextWithRouting>? app;
  Router<ContextWithRouting>? router;
  
  setUp(() {
    app = App((req) => ContextWithRouting(req));
    app?.listen('localhost', 8084);
    
    router = Router('/');
    app?.use(router!.middleware);
  });
  
  tearDown(() async {
    app?.close();
  });
  
  test('should match route', () async {
    router?.get('/users', (ctx, next) async {
      ctx.body = 'users';
    });
    
    final response = await http.get(Uri.parse('http://localhost:8084/users'));
    expect(response.body, equals('users'));
  });
}
```

### Тесты для path параметров

```dart
test('should extract path parameters', () async {
  router?.get('/users/:id', (ctx, next) async {
    ctx.body = 'User ${ctx.params['id']}';
  });
  
  final response = await http.get(
    Uri.parse('http://localhost:8084/users/123'),
  );
  
  expect(response.body, equals('User 123'));
});
```

### Тесты для query параметров

```dart
test('should parse query parameters', () async {
  router?.get('/search', (ctx, next) async {
    ctx.body = 'Query: ${ctx.query['q']}';
  });
  
  final response = await http.get(
    Uri.parse('http://localhost:8084/search?q=test'),
  );
  
  expect(response.body, equals('Query: test'));
});
```

### Тесты для HTTP методов

```dart
test('GET method', () async {
  router?.get('/resource', (ctx, next) async {
    ctx.body = 'GET';
  });
  
  final response = await http.get(
    Uri.parse('http://localhost:8084/resource'),
  );
  
  expect(response.body, equals('GET'));
});

test('POST method', () async {
  router?.post('/resource', (ctx, next) async {
    ctx.body = 'POST';
  });
  
  final response = await http.post(
    Uri.parse('http://localhost:8084/resource'),
  );
  
  expect(response.body, equals('POST'));
});
```

### Тесты для 404

```dart
test('should return 404 for unknown route', () async {
  router?.get('/known', (ctx, next) async {
    ctx.body = 'known';
  });
  
  final response = await http.get(
    Uri.parse('http://localhost:8084/unknown'),
  );
  
  expect(response.statusCode, equals(404));
});
```

### Тесты для вложенных роутеров

```dart
test('nested routers', () async {
  final apiRouter = Router<ContextWithRouting>('/api');
  final v1Router = Router<ContextWithRouting>('/v1');
  
  v1Router.get('/users', (ctx, next) async {
    ctx.body = 'v1 users';
  });
  
  apiRouter.use(v1Router.middleware);
  router?.use(apiRouter.middleware);
  
  final response = await http.get(
    Uri.parse('http://localhost:8084/api/v1/users'),
  );
  
  expect(response.body, equals('v1 users'));
});
```

## Best Practices

### RESTful маршруты

```dart
// Коллекция
router.get('/users', listUsers);
router.post('/users', createUser);

// Ресурс
router.get('/users/:id', getUser);
router.put('/users/:id', updateUser);
router.patch('/users/:id', partialUpdateUser);
router.delete('/users/:id', deleteUser);
```

### Группировка роутов

```dart
// Users роуты
final usersRouter = Router<ContextWithRouting>('/users');
usersRouter.get('/', listUsers);
usersRouter.post('/', createUser);
usersRouter.get('/:id', getUser);
usersRouter.put('/:id', updateUser);
usersRouter.delete('/:id', deleteUser);

// Posts роуты
final postsRouter = Router<ContextWithRouting>('/posts');
postsRouter.get('/', listPosts);
postsRouter.post('/', createPost);

app.use(usersRouter.middleware);
app.use(postsRouter.middleware);
```

### Версионирование API

```dart
// API v1
final v1Router = Router<ContextWithRouting>('/api/v1');
v1Router.get('/users', getUsersV1);

// API v2
final v2Router = Router<ContextWithRouting>('/api/v2');
v2Router.get('/users', getUsersV2);

app.use(v1Router.middleware);
app.use(v2Router.middleware);
```

### Middleware переиспользование

```dart
// Общий middleware для authentication
Future<void> requireAuth(ContextWithRouting ctx, next) async {
  final token = ctx.request.headers.value('Authorization');
  if (token == null) {
    ctx.throwError(401, message: 'Unauthorized');
    return;
  }
  await next();
}

// Применяем к защищенным роутам
final adminRouter = Router<ContextWithRouting>('/admin');
adminRouter.use(requireAuth);
adminRouter.get('/users', listUsers);
adminRouter.delete('/users/:id', deleteUser);
```

## Совместимость

### Зависимости

```yaml
dependencies:
  dia: ^0.1.5
  path_to_regexp: ^0.4.0
```

**НЕ меняй** версию `path_to_regexp` без причины (breaking change).

### Типы

Router требует `T extends Routing`:

```dart
class Router<T extends Routing> { }
```

Это compile-time гарантия что Context имеет нужные поля.

## Checklist для PR

- [ ] Все тесты проходят
- [ ] Path matching работает корректно
- [ ] Параметры извлекаются правильно
- [ ] HTTP методы обрабатываются
- [ ] 404 для неизвестных роутов
- [ ] Вложенные роутеры работают
- [ ] OPTIONS обработка корректна
- [ ] Документация обновлена
- [ ] Примеры актуальны
- [ ] CHANGELOG обновлен
