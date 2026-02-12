# Monorepo Workflow

Правила работы с монорепозиторием Dia и инструментом Melos.

## Структура монорепозитория

### Организация файлов

```
dia/
├── melos.yaml              # Конфигурация Melos
├── pubspec.yaml            # Workspace pubspec (SDK constraints)
├── packages/
│   ├── dia/                # Core пакет
│   │   ├── lib/
│   │   │   ├── dia.dart    # Главный экспорт
│   │   │   └── src/        # Реализация
│   │   ├── test/           # Тесты
│   │   ├── example/        # Примеры
│   │   ├── pubspec.yaml
│   │   ├── README.md
│   │   ├── CHANGELOG.md
│   │   ├── LICENSE
│   │   └── analysis_options.yaml
│   ├── dia_router/         # Router пакет
│   ├── dia_body/           # Body parser пакет
│   ├── dia_cors/           # CORS пакет
│   └── dia_static/         # Static files пакет
└── .gitignore
```

### Обязательные файлы в каждом пакете

Каждый пакет ДОЛЖЕН содержать:

- ✅ `pubspec.yaml` - метаданные и зависимости
- ✅ `README.md` - документация и примеры использования
- ✅ `CHANGELOG.md` - история изменений
- ✅ `LICENSE` - лицензия (общая для всех пакетов)
- ✅ `analysis_options.yaml` - lint правила
- ✅ `lib/{package_name}.dart` - главный экспорт файл
- ✅ `lib/src/` - директория с реализацией
- ✅ `test/` - директория с тестами
- ✅ `example/` - примеры использования

## FVM (Flutter Version Manager)

Проект использует FVM для управления версией Flutter/Dart.

### Установка FVM

```bash
# Установи FVM глобально
dart pub global activate fvm

# Или через brew (macOS)
brew tap leoafarias/fvm
brew install fvm
```

### Использование FVM

```bash
# Установка версии Flutter из .fvmrc
fvm install

# Использование Flutter/Dart через FVM
fvm flutter --version
fvm dart --version

# Все команды должны использовать префикс fvm
fvm dart test
fvm flutter analyze
fvm melos bootstrap
```

**ВАЖНО:** Все команды `dart`, `flutter`, `melos` в этом документе должны выполняться через `fvm`:
- `dart` → `fvm dart`
- `flutter` → `fvm flutter`
- `melos` → `fvm melos`

## Melos конфигурация

### melos.yaml

```yaml
name: Flame # Название workspace
repository: https://github.com/flame-engine/flame

packages:
  - packages/** # Путь к пакетам

command:
  version:
    branch: main # Версионирование только на main
    releaseUrl: true # Генерация ссылки на GitHub release

scripts:
  # Полная проверка кода
  lint:all:
    run: melos run analyze && melos run format
    description: Run all static analysis checks.

  # Анализ кода
  analyze:
    run: |
      melos exec -c 10 -- \
        flutter analyze --fatal-infos
    description: Run `flutter analyze` for all packages.

  # Форматирование
  format:
    run: melos exec dart format . --fix
    description: Run `dart format` for all packages.

  # Проверка форматирования
  format-check:
    run: melos exec dart format . --set-exit-if-changed
    description: Run `dart format` checks for all packages.

  # Тесты
  test:
    run: melos run test:select --no-select
    description: Run all Flutter tests in this project.

  test:select:
    run: melos exec -- flutter test
    packageFilters:
      dirExists: test
    description: Run `flutter test` for selected packages.
```

## Melos команды

### Основные команды

```bash
# Bootstrap - установка зависимостей для всех пакетов
fvm melos bootstrap

# Очистка
fvm melos clean

# Проверка кода
fvm melos run lint:all      # Полная проверка (analyze + format)
fvm melos run analyze       # Только анализ
fvm melos run format        # Форматирование с исправлениями
fvm melos run format-check  # Проверка без изменений

# Тесты
fvm melos run test          # Все тесты
fvm melos run test:select   # Выбор пакетов для тестирования

# Версионирование
fvm melos version          # Интерактивное версионирование
fvm melos publish          # Публикация на pub.dev
```

### Выполнение команд в пакетах

```bash
# Выполнить команду во всех пакетах
fvm melos exec -- dart pub get

# С параллелизмом (10 пакетов одновременно)
fvm melos exec -c 10 -- flutter analyze

# С фильтром по директориям
fvm melos exec --dir-exists=test -- flutter test

# В конкретном пакете
fvm melos exec --scope=dia -- dart test
```

### Фильтры пакетов

```bash
# По имени
--scope=dia
--scope=dia_router

# По зависимостям
--depends-on=dia

# По изменениям (git diff)
--since=main

# По наличию директории
--dir-exists=test
--no-dir-exists=example
```

## Управление зависимостями

### Типы зависимостей

#### 1. Внешние зависимости (pub.dev)

```yaml
# packages/dia/pubspec.yaml
dependencies:
  stream_channel: ^2.1.1

dev_dependencies:
  test: ^1.29.0
  http: ^1.6.0
```

#### 2. Path зависимости (для разработки)

```yaml
# packages/dia_body/pubspec.yaml
dependencies:
  dia:
    path: ../dia/ # Локальный путь для разработки
  web_socket_channel: ^2.3.0
```

**ВАЖНО:** Path зависимости используются только во время разработки. Перед публикацией они должны быть заменены на версионные зависимости.

#### 3. Hosted зависимости (pub.dev)

```yaml
# packages/dia_router/pubspec.yaml
dependencies:
  dia: ^0.1.5 # Версия с pub.dev
  path_to_regexp: ^0.4.0
```

### Версионирование зависимостей

- Используй **caret syntax** (`^1.0.0`) для совместимых версий
- Core пакет `dia` должен использовать последнюю стабильную версию
- Все пакеты должны иметь одинаковый SDK constraint

```yaml
environment:
  sdk: ">=3.8.0 <4.0.0"
```

### Обновление зависимостей

```bash
# Bootstrap обновляет все зависимости
fvm melos bootstrap

# Обновление конкретного пакета
cd packages/dia
fvm dart pub upgrade

# Обновление всех пакетов
fvm melos exec -- dart pub upgrade
```

## Создание нового пакета

### Шаг 1: Создание структуры

```bash
cd packages/
mkdir dia_newfeature
cd dia_newfeature
```

### Шаг 2: Создание pubspec.yaml

```yaml
name: dia_newfeature
description: Description of the new feature for Dia framework
version: 0.1.0
homepage: https://github.com/unger1984/dia

environment:
  sdk: ">=3.8.0 <4.0.0"

dependencies:
  dia: ^0.1.5 # или path: ../dia/ для разработки

dev_dependencies:
  lints: ^6.1.0
  test: ^1.29.0
  http: ^1.6.0 # если нужны HTTP тесты
```

### Шаг 3: Копирование стандартных файлов

```bash
# Копируй analysis_options.yaml из другого пакета
cp ../dia/analysis_options.yaml .

# Копируй LICENSE
cp ../dia/LICENSE .

# Создай базовую структуру
mkdir -p lib/src
mkdir -p test
mkdir -p example
```

### Шаг 4: Создание главного файла

```dart
// lib/dia_newfeature.dart
/// Description of the package
library dia_newfeature;

export 'src/main_class.dart';
export 'src/helper.dart';
```

### Шаг 5: Создание README.md

````markdown
# Dia NewFeature

Description of the feature.

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  dia_newfeature: ^0.1.0
```
````

## Usage

```dart
import 'package:dia/dia.dart';
import 'package:dia_newfeature/dia_newfeature.dart';

void main() {
  final app = App();

  // Use the feature
  app.use(newFeature());

  app.listen('localhost', 8080);
}
```

## Features

- Feature 1
- Feature 2

## API Reference

See [API documentation](https://pub.dev/documentation/dia_newfeature/latest/).

````

### Шаг 6: Создание CHANGELOG.md

```markdown
## 0.1.0

* Initial release
* Feature 1 implementation
* Basic documentation
````

### Шаг 7: Bootstrap

```bash
# Из корня проекта
fvm melos bootstrap
```

## Workflow разработки

### 1. Начало работы над фичей

```bash
# Создай ветку
git checkout -b feat/new-feature

# Bootstrap если нужно
fvm melos bootstrap
```

### 2. Разработка

```bash
# Работай в конкретном пакете
cd packages/dia_router

# Запускай тесты
fvm dart test

# Или из корня
fvm melos exec --scope=dia_router -- dart test
```

### 3. Проверка кода

```bash
# Из корня проекта
fvm melos run lint:all

# Если есть ошибки форматирования
fvm melos run format

# Проверка анализа
fvm melos run analyze
```

### 4. Коммит изменений

```bash
git add .
git commit -m "feat(router): add nested router support"
```

### 5. Тестирование всех пакетов

```bash
fvm melos run test
```

### 6. Подготовка к релизу

```bash
# Обнови CHANGELOG.md в измененных пакетах
# Обнови версию в pubspec.yaml

# Или используй melos version (только на main)
git checkout main
git merge feat/new-feature
melos version
```

## Версионирование

### Semantic Versioning

Используй [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** (1.0.0) - Breaking changes
- **MINOR** (0.1.0) - Новая функциональность (обратно совместимая)
- **PATCH** (0.0.1) - Bug fixes

### Версионирование через Melos

```bash
# Интерактивный режим (только на main branch)
fvm melos version

# Выбери пакеты для версионирования
# Укажи тип изменений (major/minor/patch)
# Обнови CHANGELOG.md

# Melos автоматически:
# - Обновит версии в pubspec.yaml
# - Создаст git tag
# - Обновит CHANGELOG.md
```

### Ручное версионирование

Если используешь ручное версионирование:

1. Обнови версию в `pubspec.yaml`
2. Обнови `CHANGELOG.md` с описанием изменений
3. Создай git commit
4. Создай git tag: `git tag dia-v0.1.5`

## Публикация пакетов

### Подготовка к публикации

1. **Проверь pubspec.yaml:**

   - Корректное имя и описание
   - Правильная версия
   - Homepage/repository указаны
   - Зависимости используют hosted версии (не path:)

2. **Обнови документацию:**

   - README.md актуален
   - CHANGELOG.md содержит изменения
   - Примеры работают
   - API документирован (dartdoc)

3. **Проверь код:**

```bash
fvm melos run lint:all
fvm melos run test
```

4. **Dry run публикации:**

```bash
cd packages/dia
fvm dart pub publish --dry-run
```

### Публикация

```bash
# Из директории пакета
cd packages/dia
fvm dart pub publish

# Или через Melos (все измененные пакеты)
fvm melos publish
```

## Best Practices

### Зависимости

- ✅ Используй **path dependencies** во время разработки
- ✅ Переключайся на **hosted dependencies** перед публикацией
- ✅ Используй **^** для совместимых версий
- ❌ НЕ используй конкретные версии без причины
- ❌ НЕ публикуй с path dependencies

### Структура

- ✅ Держи пакеты **независимыми** где возможно
- ✅ Следуй **единой структуре** во всех пакетах
- ✅ Документируй все **публичные API**
- ❌ НЕ дублируй код между пакетами
- ❌ НЕ создавай циклические зависимости

### Версионирование

- ✅ Следуй **Semantic Versioning**
- ✅ Обновляй **CHANGELOG.md** для каждого релиза
- ✅ Используй **melos version** на main branch
- ❌ НЕ забывай обновить версии зависимостей
- ❌ НЕ делай breaking changes в patch/minor версиях

### Тестирование

- ✅ Пиши **тесты для новой функциональности**
- ✅ Запускай **все тесты** перед коммитом
- ✅ Используй **integration тесты** для middleware
- ❌ НЕ коммить код с падающими тестами
- ❌ НЕ пропускай проверку lint

### Коммиты

- ✅ Используй **conventional commits**: `feat:`, `fix:`, `docs:`
- ✅ Указывай **scope**: `feat(router):`, `fix(body):`
- ✅ Пиши **понятные** commit messages
- ❌ НЕ коммить несвязанные изменения вместе
- ❌ НЕ коммить generated код

## Troubleshooting

### Проблема: Зависимости не разрешаются

```bash
# Очисти и переустанови
fvm melos clean
fvm melos bootstrap
```

### Проблема: Изменения не применяются

```bash
# Если используешь path dependencies, убедись что bootstrap был выполнен
fvm melos bootstrap

# Или пересобери конкретный пакет
cd packages/dia_router
fvm dart pub get
```

### Проблема: Тесты падают после изменений в dia

```bash
# Обнови версию dia во всех зависимых пакетах
# И выполни bootstrap
fvm melos bootstrap
fvm melos run test
```

### Проблема: Lint ошибки

```bash
# Автофикс форматирования
fvm melos run format

# Проверь analysis_options.yaml
# Убедись что все пакеты используют одинаковую конфигурацию
```

## Полезные команды

```bash
# Список всех пакетов
fvm melos list

# График зависимостей
fvm melos list --graph

# Информация о пакете
fvm melos list --scope=dia

# Запуск примера
cd packages/dia/example
fvm dart run example.dart

# Генерация документации
fvm dart doc .
```
