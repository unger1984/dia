# Cursor Rules для Dia Framework

Индекс всех правил и руководств для работы с проектом Dia в Cursor AI.

## Структура правил

### Общие правила

#### [`fvm-usage.md`](fvm-usage.md)
**Использование FVM (Flutter Version Manager)**

Когда использовать:
- При первоначальной настройке проекта
- При возникновении проблем с версиями Flutter/Dart
- При настройке CI/CD
- При обновлении Flutter версии

Содержит:
- Установка и настройка FVM
- Базовые команды
- Настройка IDE
- Workflow разработки
- Troubleshooting
- Best practices

**ВАЖНО:** Все команды `dart`, `flutter`, `melos` в проекте должны выполняться через `fvm`.

#### [`dart-coding-standards.md`](dart-coding-standards.md)
**Стандарты кодирования Dart**

Когда использовать:
- При написании любого Dart кода
- Перед коммитом изменений
- При code review

Содержит:
- Стиль кодирования и форматирование
- Правила именования (классы, методы, переменные)
- Порядок импортов
- Документация (dartdoc)
- Lint правила и метрики
- Assertions и error handling

#### [`architecture-patterns.md`](architecture-patterns.md)
**Архитектурные паттерны**

Когда использовать:
- При создании middleware
- При расширении Context
- При работе с Router
- При обработке ошибок

Содержит:
- Middleware pattern и композиция
- Context pattern и расширения
- Error handling pattern
- Router pattern
- Hijacking pattern
- Factory pattern для Context
- Type safety с generics

#### [`monorepo-workflow.md`](monorepo-workflow.md)
**Работа с монорепозиторием**

Когда использовать:
- При добавлении нового пакета
- При работе с зависимостями
- При версионировании
- При публикации пакетов

Содержит:
- Структура монорепозитория
- Melos команды и конфигурация
- Управление зависимостями
- Создание нового пакета
- Версионирование и публикация
- Best practices

#### [`testing-guidelines.md`](testing-guidelines.md)
**Руководство по тестированию**

Когда использовать:
- При написании тестов
- При добавлении новой функциональности
- При исправлении багов

Содержит:
- Структура тестов
- setUp/tearDown паттерн
- Integration тесты с HTTP
- Изоляция через порты
- Тестирование middleware
- Тестирование Router
- Best practices

### Специфичные правила для пакетов

#### [`dia-core.md`](dia-core.md)
**Правила для core пакета**

Когда использовать:
- При работе с пакетом `dia`
- При изменении App, Context, HttpError
- При модификации middleware композиции

Содержит:
- Философия минимализма
- API design для App/Context
- Реализация middleware композиции
- Context body handling
- Request hijacking
- Расширение через custom Context
- Performance и security
- Версионирование

#### [`dia-router.md`](dia-router.md)
**Правила для router пакета**

Когда использовать:
- При работе с пакетом `dia_router`
- При создании роутов
- При работе с path/query параметрами

Содержит:
- Требования к Context (Routing mixin)
- API design Router класса
- Path matching с path_to_regexp
- HTTP методы
- Вложенные роутеры
- Path и query параметры
- Error handling в router
- Тестирование роутов

#### [`dia-websocket.md`](dia-websocket.md)
**Правила для websocket пакета**

Когда использовать:
- При работе с WebSocket
- При добавлении real-time функциональности

Содержит:
- WebSocket upgrade process
- Protocol negotiation
- Origin validation для безопасности
- Ping/pong keep-alive
- Message handling
- Паттерны использования
- Security considerations

**Примечание:** Пакет `dia_websocket` удален в текущей ветке, но правила сохранены для будущего использования.

## Документация проекта

### В корне проекта

#### [`AGENTS.md`](../../AGENTS.md)
**Руководство для AI-ассистентов**

Краткий обзор проекта, ключевые концепции, паттерны разработки и частые задачи. Используй как quick reference.

#### [`CONTRIBUTING.md`](../../CONTRIBUTING.md)
**Руководство по контрибуции**

Workflow разработки, стандарты кода, процесс создания Pull Request, conventional commits.

#### [`ARCHITECTURE.md`](../../ARCHITECTURE.md)
**Детальная архитектура**

Философия дизайна, архитектурные паттерны, компоненты системы, жизненный цикл запроса, диаграммы.

## Как использовать эти правила

### Для разработчиков

1. **Начало работы**
   - Прочитай [`AGENTS.md`](../../AGENTS.md) для обзора
   - Изучи [`CONTRIBUTING.md`](../../CONTRIBUTING.md) для workflow
   - Используй [`ARCHITECTURE.md`](../../ARCHITECTURE.md) для понимания архитектуры

2. **Повседневная разработка**
   - [`dart-coding-standards.md`](dart-coding-standards.md) - всегда под рукой
   - [`architecture-patterns.md`](architecture-patterns.md) - при работе с паттернами
   - [`testing-guidelines.md`](testing-guidelines.md) - при написании тестов

3. **Специфичная работа**
   - Core изменения → [`dia-core.md`](dia-core.md)
   - Routing → [`dia-router.md`](dia-router.md)
   - Новый пакет → [`monorepo-workflow.md`](monorepo-workflow.md)

### Для AI-ассистентов

**Приоритет использования:**

1. **Критично** (читать всегда):
   - [`dart-coding-standards.md`](dart-coding-standards.md)
   - [`architecture-patterns.md`](architecture-patterns.md)
   - [`AGENTS.md`](../../AGENTS.md)

2. **Важно** (по задаче):
   - [`monorepo-workflow.md`](monorepo-workflow.md) - при работе с пакетами
   - [`testing-guidelines.md`](testing-guidelines.md) - при написании тестов
   - Специфичные правила пакетов - при работе с конкретным пакетом

3. **Справочно**:
   - [`ARCHITECTURE.md`](../../ARCHITECTURE.md) - для понимания системы
   - [`CONTRIBUTING.md`](../../CONTRIBUTING.md) - для процессов

## Быстрые ссылки

### Проверка кода перед коммитом

**ВАЖНО:** Проект использует FVM. Все команды через `fvm`:

```bash
# Из корня проекта
fvm melos run lint:all   # Полная проверка
fvm melos run test       # Все тесты
```

### Ключевые файлы для референса

- Middleware композиция: [`packages/dia/lib/src/app.dart`](../../packages/dia/lib/src/app.dart)
- Context реализация: [`packages/dia/lib/src/context.dart`](../../packages/dia/lib/src/context.dart)
- Router реализация: [`packages/dia_router/lib/src/router.dart`](../../packages/dia_router/lib/src/router.dart)
- Melos конфигурация: [`melos.yaml`](../../melos.yaml)
- Lint правила: [`packages/dia/analysis_options.yaml`](../../packages/dia/analysis_options.yaml)

### Внешние ресурсы

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Melos Documentation](https://melos.invertase.dev/)

## Обновление правил

Если находишь неточности или хочешь дополнить правила:

1. Создай issue с предложением
2. Опиши что нужно изменить/добавить
3. Создай PR с обновлениями
4. Обнови этот README если добавляешь новое правило

---

**Помни:** Эти правила созданы чтобы помочь, а не ограничить. Если есть веская причина отклониться от правил - обсуди это в issue или PR.
