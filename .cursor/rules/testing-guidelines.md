# Testing Guidelines

Руководство по тестированию в проекте Dia Framework.

## Философия тестирования

### Принципы

- **Integration-first**: используй integration тесты с реальным HTTP сервером
- **Реалистичность**: тестируй как пользователь будет использовать API
- **Изоляция**: каждый тест должен быть независимым
- **Полнота**: покрывай happy path, edge cases и error cases

### Что тестировать

✅ **Обязательно:**
- Публичное API (все публичные методы)
- Middleware execution flow
- Router path matching и параметры
- Error handling
- Custom context extensions

✅ **Желательно:**
- Edge cases (пустые данные, большие данные)
- Concurrent requests
- Error recovery

❌ **Не нужно:**
- Приватные методы (тестируются через публичные)
- Тривиальные геттеры/сеттеры
- Third-party библиотеки

## Структура тестов

### Организация файлов

```
packages/your_package/
├── lib/
│   ├── your_package.dart
│   └── src/
│       ├── feature_a.dart
│       └── feature_b.dart
└── test/
    ├── feature_a_test.dart      # Один файл на фичу
    ├── feature_b_test.dart
    └── integration_test.dart    # Комплексные сценарии
```

### Именование файлов

- Файлы тестов: `*_test.dart`
- Соответствие коду: `feature.dart` → `feature_test.dart`
- Integration тесты: `integration_test.dart` или `e2e_test.dart`

### Структура test файла

```dart
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:dia/dia.dart';

void main() {
  // Setup переменные
  App? app;
  
  // Setup выполняется перед каждым тестом
  setUp(() {
    app = App();
    app?.listen('localhost', 8080);
  });
  
  // Teardown выполняется после каждого теста
  tearDown(() async {
    app?.close();
  });
  
  // Группировка тестов
  group('Feature A', () {
    test('should do X', () async {
      // Arrange
      app?.use((ctx, next) async {
        ctx.body = 'success';
      });
      
      // Act
      final response = await http.get(Uri.parse('http://localhost:8080'));
      
      // Assert
      expect(response.statusCode, equals(200));
      expect(response.body, equals('success'));
    });
    
    test('should do Y', () async {
      // ...
    });
  });
  
  group('Feature B', () {
    // ...
  });
}
```

## Паттерн setUp/tearDown

### Базовый паттерн

```dart
void main() {
  App? app;
  
  setUp(() {
    app = App();
    app?.listen('localhost', 8080);
  });
  
  tearDown(() async {
    app?.close();  // ВАЖНО: закрывай сервер
  });
  
  test('example', () async {
    // app доступен здесь
  });
}
```

### Почему nullable App?

```dart
App? app;  // Nullable потому что инициализируется в setUp
```

Альтернатива с `late`:

```dart
late App app;  // Гарантирует что будет инициализирован

setUp(() {
  app = App();
  app.listen('localhost', 8080);
});

tearDown(() async {
  app.close();  // Без ?. оператора
});
```

### SetUp для разных типов Context

```dart
void main() {
  App<CustomContext>? app;
  
  setUp(() {
    app = App((request) => CustomContext(request));
    app?.listen('localhost', 8081);
  });
  
  tearDown(() async {
    app?.close();
  });
}
```

## Integration тесты с HTTP клиентом

### Базовый HTTP запрос

```dart
import 'package:http/http.dart' as http;

test('GET request', () async {
  app?.use((ctx, next) async {
    ctx.body = 'Hello World';
  });
  
  final response = await http.get(
    Uri.parse('http://localhost:8080'),
  );
  
  expect(response.statusCode, equals(200));
  expect(response.body, equals('Hello World'));
});
```

### POST с данными

```dart
test('POST request with JSON', () async {
  app?.use((ctx, next) async {
    // В реальности используй dia_body для парсинга
    ctx.body = 'received';
  });
  
  final response = await http.post(
    Uri.parse('http://localhost:8080/api/users'),
    headers: {'Content-Type': 'application/json'},
    body: '{"name": "John"}',
  );
  
  expect(response.statusCode, equals(200));
});
```

### Проверка headers

```dart
test('should set custom header', () async {
  app?.use((ctx, next) async {
    ctx.set('X-Custom-Header', 'value');
    ctx.body = 'ok';
  });
  
  final response = await http.get(Uri.parse('http://localhost:8080'));
  
  expect(response.headers['x-custom-header'], equals('value'));
});
```

### Тестирование status codes

```dart
test('should return 404 for unknown route', () async {
  final response = await http.get(
    Uri.parse('http://localhost:8080/unknown'),
  );
  
  expect(response.statusCode, equals(404));
});

test('should return 500 on error', () async {
  app?.use((ctx, next) async {
    throw Exception('Something went wrong');
  });
  
  final response = await http.get(Uri.parse('http://localhost:8080'));
  
  expect(response.statusCode, equals(500));
});
```

## Изоляция тестов через порты

### Проблема

Несколько тестов не могут использовать один и тот же порт одновременно.

### Решение: разные порты для каждого test файла

```dart
// packages/dia/test/default_test.dart
setUp(() {
  app = App();
  app?.listen('localhost', 8080);  // Порт 8080
});

// packages/dia/test/custom_test.dart
setUp(() {
  app = App((request) => CustomContext(request));
  app?.listen('localhost', 8081);  // Порт 8081 (другой)
});

// packages/dia_router/test/router_test.dart
setUp(() {
  app = App((req) => ContextWithRouting(req));
  app?.listen('localhost', 8084);  // Порт 8084 (другой)
});
```

### Динамические порты (альтернатива)

```dart
setUp(() async {
  app = App();
  await app?.listen('localhost', 0);  // 0 = случайный свободный порт
});

test('example', () async {
  final port = app?.port;  // Получи выбранный порт
  final response = await http.get(
    Uri.parse('http://localhost:$port'),
  );
});
```

## Тестирование Middleware

### Выполнение middleware chain

```dart
test('middleware chain execution order', () async {
  final order = <String>[];
  
  app?.use((ctx, next) async {
    order.add('first-before');
    await next();
    order.add('first-after');
  });
  
  app?.use((ctx, next) async {
    order.add('second-before');
    await next();
    order.add('second-after');
  });
  
  app?.use((ctx, next) async {
    order.add('handler');
    ctx.body = 'done';
  });
  
  await http.get(Uri.parse('http://localhost:8080'));
  
  expect(order, equals([
    'first-before',
    'second-before',
    'handler',
    'second-after',
    'first-after',
  ]));
});
```

### Middleware без вызова next()

```dart
test('middleware stops chain when body is set', () async {
  var secondCalled = false;
  
  app?.use((ctx, next) async {
    ctx.body = 'stopped';
    // НЕ вызываем next()
  });
  
  app?.use((ctx, next) async {
    secondCalled = true;
    ctx.body = 'should not reach';
  });
  
  final response = await http.get(Uri.parse('http://localhost:8080'));
  
  expect(response.body, equals('stopped'));
  expect(secondCalled, isFalse);  // Второй middleware не вызывался
});
```

### Middleware с ошибкой

```dart
test('middleware error handling', () async {
  app?.use((ctx, next) async {
    ctx.throwError(403, message: 'Access denied');
  });
  
  final response = await http.get(Uri.parse('http://localhost:8080'));
  
  expect(response.statusCode, equals(403));
  expect(response.body, contains('Access denied'));
});
```

## Тестирование Custom Context

### Context с дополнительными полями

```dart
class CustomContext extends Context {
  String? userId;
  Map<String, dynamic>? data;
  
  CustomContext(HttpRequest request) : super(request);
}

void main() {
  App<CustomContext>? app;
  
  setUp(() {
    app = App((request) => CustomContext(request));
    app?.listen('localhost', 8081);
  });
  
  test('should access custom context fields', () async {
    app?.use((ctx, next) async {
      ctx.userId = '123';
      ctx.data = {'key': 'value'};
      await next();
    });
    
    app?.use((ctx, next) async {
      ctx.body = 'User: ${ctx.userId}, Data: ${ctx.data}';
    });
    
    final response = await http.get(Uri.parse('http://localhost:8081'));
    
    expect(response.body, contains('User: 123'));
    expect(response.body, contains('key: value'));
  });
}
```

### Context с Mixins

```dart
class ContextWithRouting extends Context with Routing {
  ContextWithRouting(HttpRequest request) : super(request);
}

test('should access mixin fields', () async {
  final router = Router<ContextWithRouting>('/');
  
  router.get('/:id', (ctx, next) async {
    final id = ctx.params['id'];  // из Routing mixin
    ctx.body = 'ID: $id';
  });
  
  app?.use(router.middleware);
  
  final response = await http.get(Uri.parse('http://localhost:8084/123'));
  
  expect(response.body, equals('ID: 123'));
});
```

## Тестирование Router

### Path matching

```dart
test('should match exact path', () async {
  router.get('/users', (ctx, next) async {
    ctx.body = 'users list';
  });
  
  final response = await http.get(Uri.parse('http://localhost:8084/users'));
  
  expect(response.statusCode, equals(200));
  expect(response.body, equals('users list'));
});
```

### Path параметры

```dart
test('should extract path parameters', () async {
  router.get('/users/:id', (ctx, next) async {
    ctx.body = 'User ${ctx.params['id']}';
  });
  
  final response = await http.get(
    Uri.parse('http://localhost:8084/users/123'),
  );
  
  expect(response.body, equals('User 123'));
});

test('should extract multiple parameters', () async {
  router.get('/posts/:postId/comments/:commentId', (ctx, next) async {
    ctx.body = '${ctx.params}';
  });
  
  final response = await http.get(
    Uri.parse('http://localhost:8084/posts/5/comments/10'),
  );
  
  expect(response.body, equals('{postId: 5, commentId: 10}'));
});
```

### Query параметры

```dart
test('should parse query parameters', () async {
  router.get('/search', (ctx, next) async {
    ctx.body = '${ctx.query}';
  });
  
  final response = await http.get(
    Uri.parse('http://localhost:8084/search?q=test&limit=10'),
  );
  
  expect(response.body, contains('q: test'));
  expect(response.body, contains('limit: 10'));
});
```

### HTTP методы

```dart
test('GET method', () async {
  router.get('/resource', (ctx, next) async {
    ctx.body = 'GET response';
  });
  
  final response = await http.get(
    Uri.parse('http://localhost:8084/resource'),
  );
  
  expect(response.body, equals('GET response'));
});

test('POST method', () async {
  router.post('/resource', (ctx, next) async {
    ctx.body = 'POST response';
  });
  
  final response = await http.post(
    Uri.parse('http://localhost:8084/resource'),
  );
  
  expect(response.body, equals('POST response'));
});
```

### 404 handling

```dart
test('should return 404 for unknown route', () async {
  router.get('/known', (ctx, next) async {
    ctx.body = 'known';
  });
  
  final response = await http.get(
    Uri.parse('http://localhost:8084/unknown'),
  );
  
  expect(response.statusCode, equals(404));
});
```

## Best Practices

### Arrange-Act-Assert

Структурируй тесты в три секции:

```dart
test('example', () async {
  // Arrange - настройка
  app?.use((ctx, next) async {
    ctx.body = 'result';
  });
  
  // Act - выполнение
  final response = await http.get(Uri.parse('http://localhost:8080'));
  
  // Assert - проверка
  expect(response.statusCode, equals(200));
  expect(response.body, equals('result'));
});
```

### Один assert на концепцию

```dart
// Хорошо - логически связанные asserts
test('should return correct response', () async {
  final response = await http.get(Uri.parse('http://localhost:8080'));
  
  expect(response.statusCode, equals(200));
  expect(response.body, equals('success'));
});

// Плохо - не связанные проверки в одном тесте
test('multiple unrelated checks', () async {
  // Проверка A
  var response = await http.get(Uri.parse('http://localhost:8080/a'));
  expect(response.statusCode, equals(200));
  
  // Проверка B (не связана)
  response = await http.get(Uri.parse('http://localhost:8080/b'));
  expect(response.statusCode, equals(404));
});
```

### Используй group для организации

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
  
  group('Middleware', () {
    test('execution order', () async { });
    test('error handling', () async { });
  });
  
  group('Context', () {
    test('body handling', () async { });
    test('headers', () async { });
  });
  
  group('Error handling', () {
    test('404 errors', () async { });
    test('500 errors', () async { });
  });
}
```

### Описательные имена тестов

```dart
// Хорошо
test('should return 200 when middleware sets body', () async { });
test('should extract path parameters from URL', () async { });
test('should throw 404 when route not found', () async { });

// Плохо
test('test1', () async { });
test('works', () async { });
test('check response', () async { });
```

### Используй константы для URLs

```dart
void main() {
  const baseUrl = 'http://localhost:8080';
  
  test('example', () async {
    final response = await http.get(Uri.parse('$baseUrl/path'));
  });
}
```

### Async/Await

```dart
// Правильно - используй await
test('example', () async {
  final response = await http.get(Uri.parse('http://localhost:8080'));
  expect(response.statusCode, equals(200));
});

// Неправильно - забыл await
test('example', () async {
  final response = http.get(Uri.parse('http://localhost:8080'));
  // response это Future, а не Response!
});
```

## Запуск тестов

**ВАЖНО:** Проект использует FVM, все команды должны выполняться через `fvm`:

### Один файл

```bash
cd packages/dia
fvm dart test test/default_test.dart
```

### Все тесты в пакете

```bash
cd packages/dia
fvm dart test
```

### Все тесты в монорепозитории

```bash
# Из корня
fvm melos run test

# Или
fvm melos exec -- dart test
```

### С фильтром по имени

```bash
fvm dart test --name="Router"
```

### С coverage

```bash
fvm dart test --coverage=coverage
fvm dart pub global activate coverage
fvm dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage.lcov --report-on=lib
```

## Troubleshooting

### Порты заняты

```
Ошибка: Address already in use
```

**Решение:**
- Используй разные порты для разных test файлов
- Или используй порт `0` для автоматического выбора
- Убедись что `tearDown` закрывает сервер

### Тесты падают случайно

**Причины:**
- Не закрывается сервер в tearDown
- Используется один и тот же порт
- Зависимость от порядка выполнения тестов

**Решение:**
- ВСЕГДА закрывай сервер в tearDown
- Делай тесты изолированными
- Не полагайся на state из других тестов

### Timeout ошибки

```
TimeoutException after 0:00:30.000000: Test timed out
```

**Решение:**
- Проверь что сервер запущен (await listen)
- Проверь что порт правильный
- Убедись что middleware вызывает next() или устанавливает body

### Зависимости не разрешаются

```bash
# Переустанови зависимости
cd packages/your_package
fvm dart pub get

# Или через melos
fvm melos bootstrap
```
