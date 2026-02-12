# Contributing to Dia

Спасибо за интерес к проекту Dia! Мы рады любому вкладу - от исправления опечаток до новых фич.

## Содержание

- [Code of Conduct](#code-of-conduct)
- [Как начать](#как-начать)
- [Workflow разработки](#workflow-разработки)
- [Стандарты кода](#стандарты-кода)
- [Тестирование](#тестирование)
- [Коммиты и PR](#коммиты-и-pr)
- [Версионирование](#версионирование)
- [Где искать помощь](#где-искать-помощь)

## Code of Conduct

Будь вежлив и уважителен к другим участникам. Мы создаём инклюзивное сообщество где каждый может чувствовать себя комфортно.

## Как начать

### Требования

- **FVM**: Flutter Version Manager - установи глобально
- **Dart SDK**: >= 3.8.0 (через FVM)
- **Melos**: будет установлен через FVM
- **Git**: для работы с репозиторием

### Установка FVM

```bash
# Установи FVM глобально
dart pub global activate fvm

# Или через brew (macOS)
brew tap leoafarias/fvm
brew install fvm
```

### Настройка окружения

```bash
# 1. Форкни репозиторий на GitHub
# 2. Клонируй свой форк
git clone https://github.com/YOUR_USERNAME/dia.git
cd dia

# 3. Добавь upstream remote
git remote add upstream https://github.com/unger1984/dia.git

# 4. Установи Flutter через FVM
fvm install

# 5. Установи зависимости
fvm melos bootstrap

# 6. Проверь что всё работает
fvm melos run test
```

**ВАЖНО:** Все команды `dart`, `flutter`, `melos` должны выполняться через `fvm`:
- `dart test` → `fvm dart test`
- `flutter analyze` → `fvm flutter analyze`
- `melos bootstrap` → `fvm melos bootstrap`

### Структура проекта

```
dia/
├── packages/           # Все пакеты проекта
│   ├── dia/           # Core пакет
│   ├── dia_router/    # Router пакет
│   ├── dia_body/      # Body parser
│   ├── dia_cors/      # CORS
│   └── dia_static/    # Static files
├── melos.yaml         # Конфигурация Melos
├── AGENTS.md          # Руководство для AI ассистентов
└── CONTRIBUTING.md    # Это руководство
```

## Workflow разработки

### 1. Найди или создай Issue

- Проверь [существующие issues](https://github.com/unger1984/dia/issues)
- Если твоя идея новая - создай issue для обсуждения
- Дождись обсуждения перед началом работы над большими изменениями

### 2. Создай feature ветку

```bash
# Обнови main
git checkout main
git pull upstream main

# Создай ветку
git checkout -b feat/your-feature-name

# Для bug fixes используй prefix fix/
git checkout -b fix/issue-description
```

### 3. Разработка

```bash
# Работай в конкретном пакете
cd packages/dia_router

# Внеси изменения
# ...

# Запускай тесты
fvm dart test

# Или из корня для всех пакетов
fvm melos run test
```

### 4. Проверь код

```bash
# Запусти полную проверку
fvm melos run lint:all

# Или по отдельности
fvm melos run analyze    # Статический анализ
fvm melos run format     # Форматирование
fvm melos run test       # Тесты
```

### 5. Коммит изменений

```bash
git add .
git commit -m "feat(router): add support for nested routes"
```

См. [Conventional Commits](#conventional-commits) для правил именования коммитов.

### 6. Отправь изменения

```bash
git push origin feat/your-feature-name
```

### 7. Создай Pull Request

1. Перейди на свой форк на GitHub
2. Нажми "Pull Request"
3. Выбери `main` ветку upstream репозитория
4. Заполни template PR (описание, связанные issues)
5. Дождись review

## Стандарты кода

### Dart Style Guide

Следуй [официальному Dart style guide](https://dart.dev/guides/language/effective-dart/style):

```dart
// ✅ Хорошо
class Router<T extends Routing> {
  void get(String path, Middleware<T> middleware) {
    _middlewares.add(middleware);
  }
}

// ❌ Плохо
class router {
  void GET(string path,middleware) {
    this.middlewares.add(middleware);
  }
}
```

### Именование

- **Classes**: `PascalCase` - `App`, `Router`, `Context`
- **Methods**: `camelCase` - `use()`, `listen()`, `throwError()`
- **Variables**: `camelCase` - `statusCode`, `contentType`
- **Private**: `_prefix` - `_server`, `_middlewares`
- **Constants**: `lowerCamelCase` - `defaultPort`, `maxConnections`

### Trailing Commas

ВСЕГДА используй trailing comma для многострочных вызовов:

```dart
// ✅ Правильно
final app = App(
  (request) => CustomContext(request),
);

// ❌ Неправильно
final app = App(
  (request) => CustomContext(request)
);
```

### Импорты

Порядок импортов:

```dart
// 1. Dart core
import 'dart:async';
import 'dart:io';

// 2. Package imports
import 'package:dia/dia.dart';
import 'package:test/test.dart';

// 3. Relative imports
import 'context.dart';
import 'http_error.dart';
```

### Документация

Документируй все публичные API:

```dart
/// Router class for URL-based routing in Dia.
///
/// Provides HTTP method routing (GET, POST, etc.) with support for
/// path parameters like `/users/:id`.
///
/// Example:
/// ```dart
/// final router = Router<ContextWithRouting>('/api');
/// router.get('/users/:id', (ctx, next) async {
///   ctx.body = 'User ${ctx.params['id']}';
/// });
/// ```
class Router<T extends Routing> {
  // ...
}
```

## Тестирование

### Обязательные тесты

Все новые фичи ДОЛЖНЫ иметь тесты:

```dart
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  App? app;
  
  setUp(() {
    app = App();
    app?.listen('localhost', 8080);
  });
  
  tearDown(() async {
    app?.close();
  });
  
  test('should handle GET request', () async {
    app?.use((ctx, next) async {
      ctx.body = 'success';
    });
    
    final response = await http.get(Uri.parse('http://localhost:8080'));
    
    expect(response.statusCode, equals(200));
    expect(response.body, equals('success'));
  });
}
```

### Запуск тестов

```bash
# Все тесты в монорепозитории
fvm melos run test

# Конкретный пакет
cd packages/dia
fvm dart test

# Конкретный файл
fvm dart test test/middleware_test.dart

# С именем теста
fvm dart test --name="Router"
```

### Coverage

```bash
# Генерация coverage
fvm dart test --coverage=coverage

# Форматирование отчёта
fvm dart pub global activate coverage
fvm dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage.lcov --report-on=lib
```

## Коммиты и PR

### Conventional Commits

Используй [Conventional Commits](https://www.conventionalcommits.org/) формат:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat:` - новая функциональность
- `fix:` - исправление бага
- `docs:` - документация
- `style:` - форматирование (не влияет на код)
- `refactor:` - рефакторинг без изменения функциональности
- `test:` - добавление/изменение тестов
- `chore:` - обслуживание (зависимости, конфигурация)

**Scope** (опционально):
- `core` - изменения в dia пакете
- `router` - изменения в dia_router
- `body` - изменения в dia_body
- и т.д.

**Примеры:**

```bash
# Новая фича
git commit -m "feat(router): add support for nested routes"

# Bug fix
git commit -m "fix(core): correct middleware execution order"

# Breaking change
git commit -m "feat(core): change middleware signature

BREAKING CHANGE: Middleware now requires async function"

# Документация
git commit -m "docs(readme): add WebSocket example"

# Несколько файлов
git commit -m "refactor(router): simplify path matching logic"
```

### Pull Request Guidelines

**Заголовок PR:**
- Следуй формату conventional commits
- Краткое описание (до 72 символов)

**Описание PR должно содержать:**
1. **Что изменилось** - краткое описание изменений
2. **Почему** - причина изменений (ссылка на issue)
3. **Как тестировать** - инструкции для тестирования
4. **Breaking changes** - если есть
5. **Screenshots** - если применимо (UI изменения)

**Пример:**

```markdown
## Описание

Добавлена поддержка вложенных роутеров для версионирования API.

Fixes #123

## Изменения

- Добавлен метод `Router.use()` для вложенных роутеров
- Обновлена логика prefix matching
- Добавлены тесты для вложенных роутеров

## Как тестировать

```dart
final v1Router = Router('/v1');
final v2Router = Router('/v2');
final apiRouter = Router('/api');

apiRouter.use(v1Router.middleware);
apiRouter.use(v2Router.middleware);
```

## Breaking Changes

Нет

## Checklist

- [x] Код следует style guide
- [x] Добавлены тесты
- [x] Все тесты проходят
- [x] Документация обновлена
- [x] CHANGELOG обновлен
```

### Code Review Process

1. **Maintainer review** - один из мейнтейнеров проверит код
2. **Requested changes** - внеси правки если нужно
3. **Approval** - после апрува PR будет смержен
4. **Merge** - maintainer смержит PR в main

### После мержа PR

1. Обнови свой fork:
```bash
git checkout main
git pull upstream main
git push origin main
```

2. Удали feature ветку:
```bash
git branch -d feat/your-feature-name
git push origin --delete feat/your-feature-name
```

## Версионирование

Проект использует [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0) - Breaking changes
- **MINOR** (0.1.0) - Новая функциональность (backward compatible)
- **PATCH** (0.0.1) - Bug fixes

### CHANGELOG

При изменениях ВСЕГДА обновляй `CHANGELOG.md`:

```markdown
## Unreleased

### Added
- Support for nested routers (#123)

### Fixed
- Middleware execution order bug (#124)

### Changed
- None

### Breaking
- None
```

После релиза `Unreleased` станет версией:

```markdown
## 0.2.0 - 2024-01-15

### Added
- Support for nested routers (#123)

### Fixed
- Middleware execution order bug (#124)
```

## Типы контрибуций

### 🐛 Bug Fixes

1. Создай issue с описанием бага
2. Добавь шаги для воспроизведения
3. Создай PR с исправлением и тестом

### ✨ Новые фичи

1. Создай issue с предложением
2. Дождись обсуждения и апрува
3. Реализуй фичу с тестами
4. Обнови документацию

### 📚 Документация

1. Исправления опечаток - сразу PR
2. Новые разделы - создай issue для обсуждения
3. Примеры кода - очень welcome!

### 🧪 Тесты

1. Увеличение coverage - всегда welcome
2. Новые test cases для edge cases
3. Integration тесты

### 🎨 Улучшения кода

1. Рефакторинг - создай issue сначала
2. Performance improvements - с бенчмарками
3. Code style - следуй существующему стилю

## Создание нового пакета

Если хочешь добавить новый пакет в монорепозиторий:

### 1. Обсуждение

Создай issue с предложением:
- Название пакета (`dia_something`)
- Функциональность
- Почему это не должно быть в core
- Примеры использования

### 2. Структура

```bash
packages/dia_newfeature/
├── lib/
│   ├── dia_newfeature.dart    # Главный экспорт
│   └── src/                   # Реализация
├── test/                      # Тесты
├── example/                   # Примеры
├── pubspec.yaml               # Метаданные
├── README.md                  # Документация
├── CHANGELOG.md               # История
├── LICENSE                    # Копия из корня
└── analysis_options.yaml      # Копия из другого пакета
```

### 3. pubspec.yaml

```yaml
name: dia_newfeature
description: Description of the new feature
version: 0.1.0
homepage: https://github.com/unger1984/dia

environment:
  sdk: '>=3.8.0 <4.0.0'

dependencies:
  dia: ^0.1.5  # Всегда последняя стабильная

dev_dependencies:
  lints: ^6.1.0
  test: ^1.29.0
  http: ^1.6.0
```

### 4. README.md

```markdown
# Dia NewFeature

Description of what this package does.

## Installation

\`\`\`yaml
dependencies:
  dia_newfeature: ^0.1.0
\`\`\`

## Usage

\`\`\`dart
import 'package:dia/dia.dart';
import 'package:dia_newfeature/dia_newfeature.dart';

void main() {
  final app = App();
  app.use(newFeature());
  app.listen('localhost', 8080);
}
\`\`\`

## API

...
```

### 5. Bootstrap и тестирование

```bash
fvm melos bootstrap
cd packages/dia_newfeature
fvm dart test
```

## Где искать помощь

### Документация

- [AGENTS.md](AGENTS.md) - руководство для AI ассистентов
- [Architecture docs](.cursor/rules/) - детальная документация архитектуры
- [Dart documentation](https://dart.dev/guides)

### Коммуникация

- **Issues** - для багов и фич: https://github.com/unger1984/dia/issues
- **Discussions** - для вопросов: https://github.com/unger1984/dia/discussions
- **Pull Requests** - для кода: https://github.com/unger1984/dia/pulls

### Полезные команды

```bash
# Список всех пакетов
fvm melos list

# График зависимостей
fvm melos list --graph

# Выполнить команду во всех пакетах
fvm melos exec -- <command>

# Выполнить в конкретном пакете
fvm melos exec --scope=dia_router -- dart test

# Bootstrap после изменений в зависимостях
fvm melos bootstrap

# Очистка
fvm melos clean
```

## Вопросы?

Не стесняйся задавать вопросы:
- Создай [Discussion](https://github.com/unger1984/dia/discussions)
- Задай вопрос в [Issue](https://github.com/unger1984/dia/issues)

---

**Спасибо за вклад в Dia! 🎉**
