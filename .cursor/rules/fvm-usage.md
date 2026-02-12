# FVM Usage Guide

Руководство по использованию FVM (Flutter Version Manager) в проекте Dia.

## Что такое FVM

FVM - это инструмент для управления версиями Flutter/Dart в проекте. Позволяет использовать разные версии Flutter для разных проектов.

### Преимущества

- ✅ Изолированные версии Flutter для каждого проекта
- ✅ Команда использует одну и ту же версию
- ✅ Легкое переключение между версиями
- ✅ Совместимость гарантирована через `.fvmrc`

## Установка FVM

### Через Dart

```bash
dart pub global activate fvm
```

### Через Homebrew (macOS)

```bash
brew tap leoafarias/fvm
brew install fvm
```

### Проверка установки

```bash
fvm --version
```

## Конфигурация проекта

Проект содержит файл `.fvmrc`:

```json
{
  "flutter": "stable"
}
```

Это означает что используется стабильная версия Flutter.

### Директория .fvm

После `fvm install` создается директория `.fvm/` которая содержит:
- Ссылку на используемую версию Flutter
- Локальные настройки

**Важно:** `.fvm/` добавлена в `.gitignore`.

## Базовые команды

### Установка Flutter версии

```bash
# Установить версию из .fvmrc
fvm install

# Установить конкретную версию
fvm install 3.16.0
fvm install stable
fvm install beta
```

### Использование команд

Все команды `dart`, `flutter`, `melos` должны выполняться через `fvm`:

```bash
# Dart команды
fvm dart --version
fvm dart pub get
fvm dart test
fvm dart analyze
fvm dart format

# Flutter команды
fvm flutter --version
fvm flutter pub get
fvm flutter test
fvm flutter analyze

# Melos команды
fvm melos bootstrap
fvm melos run test
fvm melos run lint:all
```

### Переключение версий

```bash
# Использовать другую версию для проекта
fvm use 3.16.0
fvm use stable
fvm use beta

# Список установленных версий
fvm list

# Список доступных версий Flutter
fvm releases
```

## Настройка IDE

### VS Code

Создай/обнови `.vscode/settings.json`:

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "search.exclude": {
    "**/.fvm": true
  },
  "files.watcherExclude": {
    "**/.fvm": true
  }
}
```

### IntelliJ IDEA / Android Studio

1. Открой **Preferences/Settings**
2. Перейди в **Languages & Frameworks > Flutter**
3. Установи Flutter SDK path: `<project_path>/.fvm/flutter_sdk`

### Cursor

Cursor автоматически подхватывает настройки из `.vscode/settings.json`.

## Workflow разработки

### Первый раз в проекте

```bash
# 1. Клонируй репозиторий
git clone <repo>
cd dia

# 2. Установи FVM если ещё не установлен
dart pub global activate fvm

# 3. Установи Flutter версию
fvm install

# 4. Установи зависимости
fvm melos bootstrap

# 5. Проверь что всё работает
fvm melos run test
```

### Повседневная работа

```bash
# Тесты
fvm dart test
fvm melos run test

# Анализ
fvm melos run analyze

# Форматирование
fvm melos run format

# Все проверки
fvm melos run lint:all
```

### При обновлении .fvmrc

Если `.fvmrc` изменился (например, после pull):

```bash
# Установи новую версию
fvm install

# Переустанови зависимости
fvm melos clean
fvm melos bootstrap
```

## Troubleshooting

### FVM команда не найдена

```bash
# Убедись что FVM в PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Или переустанови FVM
dart pub global activate fvm
```

### Версия Flutter не установлена

```bash
# Установи версию из .fvmrc
fvm install

# Или конкретную версию
fvm use stable
```

### IDE не видит Flutter SDK

```bash
# Проверь что .fvm/flutter_sdk существует
ls -la .fvm/

# Переустанови если нужно
fvm install

# Перезапусти IDE
```

### Конфликт с глобальным Flutter

FVM изолирует версии, но если возникают проблемы:

```bash
# Используй FVM консистентно
fvm flutter doctor

# НЕ смешивай global и fvm команды
# ❌ flutter pub get
# ✅ fvm flutter pub get
```

## Best Practices

### Всегда используй FVM

```bash
# ✅ Правильно
fvm dart test
fvm melos bootstrap

# ❌ Неправильно (использует global flutter)
dart test
melos bootstrap
```

### Коммит .fvmrc

- ✅ Коммить `.fvmrc` в git
- ❌ НЕ коммитить `.fvm/` директорию

### Обновление Flutter

```bash
# Обнови версию в .fvmrc
fvm use 3.19.0

# Тестируй изменения
fvm melos run test

# Коммитируй .fvmrc
git add .fvmrc
git commit -m "chore: update Flutter to 3.19.0"
```

### CI/CD

В CI/CD пайплайнах также используй FVM:

```yaml
# .github/workflows/test.yml
- name: Install FVM
  run: dart pub global activate fvm

- name: Install Flutter
  run: fvm install

- name: Run tests
  run: fvm melos run test
```

## Полезные алиасы

Добавь в `~/.zshrc` или `~/.bashrc`:

```bash
# FVM алиасы
alias fd='fvm dart'
alias ff='fvm flutter'
alias fm='fvm melos'

# Теперь можно использовать
fd test
ff analyze
fm bootstrap
```

## Дополнительные ресурсы

- [FVM Documentation](https://fvm.app/)
- [FVM GitHub](https://github.com/leoafarias/fvm)
- [Flutter Version Management](https://docs.flutter.dev/release/archive)

---

**Помни:** Консистентное использование FVM гарантирует что все в команде работают с одной и той же версией Flutter/Dart.
