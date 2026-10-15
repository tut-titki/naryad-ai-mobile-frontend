# Редизайн мастера смены

Обновлён существующий проект. Визуальный образец — `ExecutorGreeting`, `ExecutorOrderScreen`, `OrderSection` и профиль исполнителя. Цвета взяты из этих компонентов: основной `#01408B`, градиент до `#0A57A3`, фон `#F5F7FB`, белые карточки, голубые акценты. Глобальная тема и файлы исполнителя не менялись.

## Экраны и композиция

- **Обзор смены:** адаптивные показатели в два столбца на телефоне, затем наряды, требующие внимания, и команда. Аналитика, рейтинг, частые отказы, прогноз и аномалии сохранены ниже. Сохранены все существующие источники данных, интервалы обновления, сортировка и кнопка создания.
- **Наряды:** карточки разделены на номер/статус, описание, блок оборудования и участка, исполнителя и срок/приоритет. Список, поиск, канбан, фильтры и перетаскивание сохранены.
- **Создание:** компактная сводка заполнения; отдельные карточки описания и назначения; оформлен блок дополнительных параметров. Все поля, голос, фото, QR, черновики и защита повторной отправки сохранены.
- **Детальная страница:** контекст оборудования и описание отделены от действий; история, сведения, отчёт, оценка ИИ, фото и материалы сгруппированы в читаемые секции.
- **Отчёты:** заголовок показывает фактический выбранный тип и период. Показатели оформлены компактно. На телефоне составляющие рейтинга представлены карточками вместо горизонтальной таблицы; на широком экране таблица сохранена. Сохранены существующие график, баллы, фильтры, сортировка, переход к деталям и выгрузки. API и расчёты не исправлялись и не менялись в рамках этой задачи.
- **Чат:** информационная карточка ассистента, разделение входящих/исходящих сообщений, оформление ответа ассистента, нижнее поле ввода. Отправка, повтор, история и состояние сохранены.
- **Профиль:** компактный блок личности и статуса, сведения о бригаде/разряде, отдельная группа настроек, прежние смена языка, пароля и подтверждение выхода.
- **Дополнительные страницы:** прогноз, аномалии, история оборудования, команда и состав бригады используют общие секции и верхнюю панель. Дополнительный экран ИИ также использует карточки мастера.
- **Общие страницы:** оформление уведомлений и смены пароля применяется к мастеру; условия включения сохраняют исходный интерфейс исполнителя.

## Изменённые исходники

- `lib/features/master/widgets/master_ui.dart` — новые локальные визуальные компоненты; `MasterSection` повторно использует `OrderSection` исполнителя.
- `lib/features/master/widgets/dashboard_data.dart`
- `lib/features/master/screens/dashboard_screen.dart`
- `lib/features/master/screens/master_shell.dart`
- `lib/features/master/screens/master_profile_screen.dart`
- `lib/features/master/screens/equipment_anomalies_screen.dart`
- `lib/features/master/screens/equipment_failure_forecast_screen.dart`
- `lib/features/orders/screens/orders_screen.dart`
- `lib/features/orders/screens/order_screens.dart`
- `lib/features/orders/screens/order_detail_screen.dart`
- `lib/features/orders/screens/equipment_history_screen.dart`
- `lib/features/reports/screens/reports_screen.dart`
- `lib/features/reports/widgets/rating_report_view.dart`
- `lib/features/assistant/screens/master_chat_screen.dart`
- `lib/features/assistant/screens/ai_screen.dart`
- `lib/features/team/screens/team_screen.dart`
- `lib/features/team/screens/brigade_screen.dart`
- `lib/features/auth/screens/change_password_screen.dart`
- `lib/features/notifications/screens/notifications_screen.dart`

## Тесты и проверки

- `test/master_dashboard_layout_test.dart` — проверка адаптивных рядов показателей вместо прежнего обязательного одного ряда.
- `test/rating_reports_test.dart` — проверка тех же серверных баллов, порядка, фильтрации и обновления в мобильных карточках вместо горизонтальной таблицы.
- `test/master_mobile_redesign_test.dart` — новые проверки 360/390/430 логических пикселей, длинных названий и увеличения текста до 140%; опциональная генерация PNG.
- Полный `flutter test --no-pub`: **368 прошли, 2 упали**. Оба падения отдельно воспроизведены в резервной копии исходного кода до редизайна:
  - `api_executor_repository_test.dart`: `durable COMPLETE survives restart, keeps UUID and never uploads twice` — черновик остаётся после завершения;
  - `executor_localization_test.dart`: `Kazakh completion validates fields and keeps catalog IDs` — отсутствует ожидаемая строка валидации.
- `flutter analyze --no-pub`: исходное предупреждение `unused_local_variable` для `submittedVersion`, `lib/features/executor/data/api_executor_repository.dart:935`. Новые предупреждения редизайна устранены.
- `flutter build apk --debug --no-pub`: успешно.
- Сверка хешей с резервной копией: **0 изменений** в API, моделях, авторизации и исходниках исполнителя.
- Физическое устройство и iOS вручную не проверялись.

## Превью

Изображения получены рендерингом Flutter-виджетов с HTTP-фикстурами тестов. Показанные числа и имена являются только тестовыми данными и не добавлены в приложение.

| Ширина | Обзор | Отчёты |
|---|---|---|
| 360 | [Обзор](master-previews/overview-360.png) | [Отчёты](master-previews/reports-360.png) |
| 390 | [Обзор](master-previews/overview-390.png) | [Отчёты](master-previews/reports-390.png) |
| 430 | [Обзор](master-previews/overview-430.png) | [Отчёты](master-previews/reports-430.png) |

Генерация: `flutter test --no-pub --dart-define=MASTER_UI_PREVIEW=true test/master_mobile_redesign_test.dart`. Без флага тесты не записывают изображения и не требуют локальных шрифтов.
