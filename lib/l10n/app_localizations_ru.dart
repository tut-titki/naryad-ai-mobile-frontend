// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get exportReport => 'Экспорт';

  @override
  String get reportPeriodHint => 'Наряды, выданные за выбранный период';

  @override
  String get todayPeriod => 'Сегодня';

  @override
  String get weekPeriod => '7 дней';

  @override
  String get monthPeriod => '30 дней';

  @override
  String get allTimePeriod => 'Всё время';

  @override
  String get noPeriodEmployees => 'За этот период нет исполнителей с нарядами';

  @override
  String get editOrder => 'Редактирование наряда';

  @override
  String get changeDeadline => 'Изменить срок выполнения';

  @override
  String get brigadeMembers => 'Состав бригады';

  @override
  String get brigades => 'Бригады';

  @override
  String get teamBrigadeSearch => 'Бригада, имя или специальность';

  @override
  String eventDeadline(String value) {
    return 'Срок изменён: $value';
  }

  @override
  String get filters => 'Фильтры';

  @override
  String get applyFilters => 'Применить';

  @override
  String get resetFilters => 'Сбросить';

  @override
  String get closeFilters => 'Закрыть фильтры';

  @override
  String get statusFilter => 'Статус';

  @override
  String get onlyOverdue => 'Только просроченные';

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String get attachPhoto => 'Прикрепить фото';

  @override
  String get choosePhotoSource => 'Выберите источник фото';

  @override
  String get loginTitle => 'Вход';

  @override
  String get loginSubtitle => 'Введите телефон и пароль вашего аккаунта.';

  @override
  String get registrationTitle => 'Регистрация';

  @override
  String get nameSubtitle => 'Укажите фамилию, имя и отчество.';

  @override
  String get accountSubtitle => 'Добавьте телефон и придумайте пароль.';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get phoneLabel => 'Номер телефона';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get loginButton => 'Войти';

  @override
  String get lastName => 'Фамилия';

  @override
  String get firstName => 'Имя';

  @override
  String get patronymic => 'Отчество';

  @override
  String get enterLastName => 'Введите фамилию';

  @override
  String get enterFirstName => 'Введите имя';

  @override
  String get ifAvailable => 'При наличии';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get passwordHint => 'Минимум 8 символов';

  @override
  String get passwordTooShort => 'Пароль должен содержать минимум 8 символов';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get back => 'Назад';

  @override
  String get enterPhone => 'Введите номер телефона';

  @override
  String get incompletePhone => 'Введите номер полностью';

  @override
  String stepLabel(int step) {
    return 'Шаг $step из 2';
  }

  @override
  String get dashboard => 'Обзор смены';

  @override
  String get greeting => 'Здравствуйте, Серик. Вот что происходит на участке.';

  @override
  String get createOrder => 'Создать наряд';

  @override
  String get issuedOrders => 'Выдано нарядов';

  @override
  String get completed => 'Выполнено';

  @override
  String get overdue => 'Просрочено';

  @override
  String get awaitingAcceptance => 'На приёмке';

  @override
  String get equipmentStopped => 'Оборудование в простое';

  @override
  String get needsAttention => 'Требуют внимания';

  @override
  String get noAttention => 'Нет нарядов, требующих внимания';

  @override
  String get shiftTeam => 'Команда на смене';

  @override
  String get allTeam => 'Вся команда →';

  @override
  String get allAreas => 'Все участки';

  @override
  String get allEquipment => 'Всё оборудование';

  @override
  String get allPriorities => 'Все приоритеты';

  @override
  String get all => 'Все';

  @override
  String get overduePlural => 'Просрочены';

  @override
  String get issuedPlural => 'Выданные';

  @override
  String get acceptedPlural => 'Принятые';

  @override
  String get working => 'В работе';

  @override
  String get queued => 'В очереди';

  @override
  String get completedPlural => 'Выполненные';

  @override
  String get pausedPlural => 'Приостановлены';

  @override
  String get rework => 'На доработке';

  @override
  String get rejectedPlural => 'Отклонены';

  @override
  String get cancelledPlural => 'Отменены';

  @override
  String get orders => 'Наряды';

  @override
  String get ordersSubtitle => 'Назначения, сроки и текущие статусы работ';

  @override
  String get newOrder => 'Новый наряд';

  @override
  String get listView => 'Список';

  @override
  String get kanban => 'Канбан';

  @override
  String get orderSearch => 'Номер, работа или оборудование';

  @override
  String get area => 'Участок';

  @override
  String get equipment => 'Оборудование';

  @override
  String get employee => 'Исполнитель';

  @override
  String get allEmployees => 'Все исполнители';

  @override
  String get priority => 'Приоритет';

  @override
  String get noFilteredOrders => 'По выбранным фильтрам нарядов нет';

  @override
  String get overdueOrders => 'Просроченные';

  @override
  String get demoRating => 'Демо-рейтинг';

  @override
  String get available => 'Свободен';

  @override
  String get team => 'Команда';

  @override
  String get teamSubtitle =>
      'Загрузка исполнителей, специальности и доступность';

  @override
  String get employeeSearch => 'Имя или специальность';

  @override
  String get onlyAvailable => 'Только свободные';

  @override
  String get noEmployees => 'Исполнители не найдены';

  @override
  String get aiControl => 'ИИ-контроль';

  @override
  String get aiSubtitle =>
      'Рекомендации цифрового контролёра. Финальное решение принимает мастер.';

  @override
  String get deadlineControl => 'Контроль сроков';

  @override
  String get deadlineHelp =>
      'Напоминание за 30 минут до срока. Эскалация, если обычный наряд не принят за 10 минут, аварийный — за 3 минуты.';

  @override
  String get completionCheck => 'Проверка выполнения';

  @override
  String get noReviewOrders => 'Нет нарядов на проверке';

  @override
  String get photoAnalysis => 'Анализ фото до / после';

  @override
  String get photoAnalysisHelp =>
      'Проверка наличия и актуальности фото, сравнение оборудования и видимых дефектов. При низкой уверенности потребуется проверка мастера.';

  @override
  String get orderReport => 'Отчёт по наряду';

  @override
  String get orderReportHelp =>
      'Работы, материалы, хронология, соблюдение срока и объяснение оценки собраны в карточке наряда.';

  @override
  String get equipmentAnomalies => 'Аномалии оборудования';

  @override
  String get employeeRating => 'Рейтинг исполнителей';

  @override
  String get ratingHelp =>
      'Качество, выполнение в срок, доработки, сложность работ и обоснованность отказов формируют оценку.';

  @override
  String get masterAssistant => 'Ассистент мастера';

  @override
  String get chatHelp => 'Макет чата. Ответы демонстрационные.';

  @override
  String get chatHint => 'Например: кто сейчас свободен?';

  @override
  String get showDemoAnswer => 'Показать демо-ответ';

  @override
  String get reportsRating => 'Отчёты и рейтинг';

  @override
  String get reportsSubtitle => 'Сводка текущей демонстрационной смены';

  @override
  String get pdfNotReady => 'Выгрузку PDF подключим вместе с backend';

  @override
  String get exportPdf => 'Экспорт PDF';

  @override
  String get excelNotReady => 'Выгрузку Excel подключим вместе с backend';

  @override
  String get exportExcel => 'Экспорт Excel';

  @override
  String get periodNotReady =>
      'Отчёты за произвольный период подключим после добавления истории на backend';

  @override
  String get selectPeriod => 'Выбрать период';

  @override
  String get totalOrders => 'Всего нарядов';

  @override
  String get closed => 'Закрыто';

  @override
  String get rejected => 'Отклонено';

  @override
  String get equipmentDowntime => 'Простои оборудования';

  @override
  String get downtimeReportHelp =>
      'Макет отчёта: время остановки по оборудованию, причины и доля плановых / внеплановых работ.';

  @override
  String get usedMaterials => 'Списанные материалы';

  @override
  String get materialsReportHelp =>
      'Макет отчёта: расход по материалам, участкам и исполнителям, сравнение с нормативами.';

  @override
  String get notificationCenter => 'Центр уведомлений';

  @override
  String get notificationsSubtitle =>
      'Локальные уведомления прототипа. Push не подключён.';

  @override
  String get noNotifications => 'Новых уведомлений нет';

  @override
  String get awaitingReview => 'Работа ожидает приёмки';

  @override
  String get emergencyAwaiting => 'Аварийный наряд ожидает ответа';

  @override
  String get normalPriority => 'Обычный';

  @override
  String get permissionDenied =>
      'Разрешите доступ к камере или фото в настройках приложения.';

  @override
  String get pickerFailed =>
      'Не удалось открыть камеру или галерею. Попробуйте ещё раз.';

  @override
  String get photoLoadFailed =>
      'Не удалось загрузить фото. Выберите другой снимок.';

  @override
  String get deadline => 'Срок исполнения';

  @override
  String get cancel => 'Отмена';

  @override
  String get select => 'Выбрать';

  @override
  String get executionTime => 'Время исполнения';

  @override
  String get futureDeadline => 'Выберите срок в будущем.';

  @override
  String get createOrderTitle => 'Создание наряда';

  @override
  String get workDescription => 'Описание работ';

  @override
  String get unplanned => 'Внеплановый';

  @override
  String get planned => 'Плановый';

  @override
  String get optionalWorkTitle => 'Название работы (необязательно)';

  @override
  String get problemWorks => 'Проблема и необходимые работы';

  @override
  String get voiceInput => 'Голосовой ввод';

  @override
  String get voiceNotReady => 'Голосовой ввод подключим позже.';

  @override
  String get describeProblem => 'Опишите проблему';

  @override
  String get locationAssignee => 'Место и исполнитель';

  @override
  String get brigade => 'Бригада';

  @override
  String get selectEmployee => 'Выберите исполнителя';

  @override
  String get selectBrigade => 'Выберите бригаду';

  @override
  String get deadlinePriority => 'Срок и приоритет';

  @override
  String get emergencyPriority => 'Аварийный';

  @override
  String get highPriority => 'Высокий';

  @override
  String get normHoursShort => 'Норматив, ч';

  @override
  String get dateTime => 'Дата и время';

  @override
  String get normHours => 'Норматив в часах';

  @override
  String get normRange => 'Укажите от 1 минуты до 8760 часов';

  @override
  String get optionalFaultCode => 'Шифр неисправности (необязательно)';

  @override
  String get notSpecified => 'Не указан';

  @override
  String get comment => 'Комментарий';

  @override
  String get faultPhotos => 'Фото неисправности · до 5';

  @override
  String get issueOrder => 'Выдать наряд';

  @override
  String get reason => 'Причина';

  @override
  String get specifyReason => 'Укажите причину';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get employeeOrBrigade => 'Исполнитель или бригада';

  @override
  String get orderPriority => 'Приоритет наряда';

  @override
  String get masterScore => 'Оценка мастера';

  @override
  String get overdueSingular => 'Просрочен';

  @override
  String get orderInformation => 'Информация о наряде';

  @override
  String get workType => 'Тип работ';

  @override
  String get description => 'Описание';

  @override
  String get issueDate => 'Дата выдачи';

  @override
  String get norm => 'Норматив';

  @override
  String get faultCode => 'Шифр неисправности';

  @override
  String get master => 'Мастер';

  @override
  String get orderDowntime => 'Простой оборудования';

  @override
  String get stopped => 'Оборудование остановлено';

  @override
  String get noDowntime => 'Нет активного простоя';

  @override
  String get beforeWork => 'До выполнения';

  @override
  String get afterWork => 'После выполнения';

  @override
  String get reassign => 'Переназначить';

  @override
  String get changePriority => 'Изменить приоритет';

  @override
  String get cancelOrderTitle => 'Отмена наряда';

  @override
  String get cancelOrder => 'Отменить наряд';

  @override
  String get workerReport => 'Отчёт исполнителя';

  @override
  String get completedWorks => 'Выполненные работы';

  @override
  String get materials => 'Материалы';

  @override
  String get notSpecifiedPlural => 'Не указаны';

  @override
  String get changeScore => 'Изменить оценку';

  @override
  String get acceptedByMaster => 'Работы приняты мастером';

  @override
  String get acceptClose => 'Принять и закрыть';

  @override
  String get returnRework => 'Вернуть на доработку';

  @override
  String get toRework => 'На доработку';

  @override
  String get actionHistory => 'История действий';

  @override
  String get reports => 'Отчёты';

  @override
  String get notifications => 'Уведомления';

  @override
  String get shift => 'Смена';

  @override
  String get shiftManagement => 'УПРАВЛЕНИЕ СМЕНОЙ';

  @override
  String get masterRole => 'Мастер смены';

  @override
  String get offShift => 'Не на смене';

  @override
  String get aiDemoLabel => 'Демонстрационные данные · ИИ не подключён';

  @override
  String get photoOpenFailed => 'Не удалось открыть фото';

  @override
  String get noPhotos => 'Фото не прикреплены';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерея';

  @override
  String get statusIssued => 'Выдан';

  @override
  String get statusAccepted => 'Принят';

  @override
  String get statusPaused => 'Приостановлен';

  @override
  String get statusReview => 'На проверке';

  @override
  String get statusClosed => 'Закрыт';

  @override
  String get statusRejected => 'Отклонён';

  @override
  String get statusCancelled => 'Отменён';

  @override
  String get emergencyFull => 'Аварийный — срочно в работу';

  @override
  String get normalFull => 'Обычный — в порядке очереди';

  @override
  String get noAiVerdict => 'Нет заключения';

  @override
  String get aiUnavailable => 'ИИ пока не подключён.';

  @override
  String get positiveNorm => 'Норматив должен быть больше нуля';

  @override
  String get onShiftAssignee => 'Выберите исполнителя или бригаду на смене';

  @override
  String get futureDeadlineError => 'Срок должен быть в будущем';

  @override
  String get fivePhotos => 'Не более 5 фото';

  @override
  String get employeeOffShift => 'Сотрудник не на смене';

  @override
  String get brigadeOffShift => 'Бригада не на смене';

  @override
  String get language => 'Язык';

  @override
  String get complex => 'Минеральный комплекс';

  @override
  String orderNumber(String number) {
    return 'Наряд №$number';
  }

  @override
  String orderNumberUpper(String number) {
    return 'НАРЯД №$number';
  }

  @override
  String issuePreview(String date) {
    return 'Выдача: $date';
  }

  @override
  String issuedAt(String date) {
    return 'Выдан $date';
  }

  @override
  String dueAt(String date) {
    return 'До $date';
  }

  @override
  String hoursValue(String hours) {
    return '$hours ч';
  }

  @override
  String scoreValue(String score) {
    return '$score из 5';
  }

  @override
  String employeeGrade(String specialty, String grade) {
    return '$specialty · $grade разряд';
  }

  @override
  String workingOrder(String number) {
    return 'В работе · №$number';
  }

  @override
  String workingQueue(String number, String count) {
    return 'В работе · №$number · очередь $count';
  }

  @override
  String queuedCount(String count) {
    return 'В очереди · $count';
  }

  @override
  String assignedOrder(String number) {
    return 'Занят · назначен №$number';
  }

  @override
  String brigadeAvailability(String total, String free, String busy) {
    return 'На смене: $total · свободны: $free · заняты: $busy';
  }

  @override
  String overdueMinutes(String minutes) {
    return 'Просрочка · $minutes мин.';
  }

  @override
  String removePhoto(String number) {
    return 'Удалить фото $number';
  }

  @override
  String boardCount(String label, String count) {
    return '$label · $count';
  }

  @override
  String shiftTime(String number, String time) {
    return 'Смена №$number · $time';
  }

  @override
  String aiVerdict(String verdict) {
    return 'Вердикт ИИ: $verdict';
  }

  @override
  String aiSummary(String explanation, String aiScore, String score) {
    return '$explanation\nОценка ИИ: $aiScore / 5.\nИтоговая оценка: $score / 5.\nОкончательное решение принимает мастер.';
  }

  @override
  String eventIssued(String assignee) {
    return 'Наряд выдан: $assignee';
  }

  @override
  String eventReassigned(String assignee) {
    return 'Переназначен: $assignee';
  }

  @override
  String eventPriority(String priority) {
    return 'Приоритет изменён: $priority';
  }

  @override
  String eventScore(String score) {
    return 'Оценка мастера: $score / 5';
  }

  @override
  String eventReason(String status, String reason) {
    return '$status: $reason';
  }

  @override
  String get myOrders => 'Мои наряды';

  @override
  String get orderHistory => 'История нарядов';

  @override
  String get profile => 'Профиль';

  @override
  String get history => 'История';

  @override
  String get retry => 'Повторить';

  @override
  String get archivedOrdersHint =>
      'Завершённые, отменённые и отклонённые наряды';

  @override
  String get executorSearch => 'Поиск по номеру или оборудованию';

  @override
  String get noSearchResults => 'По вашему запросу ничего не найдено';

  @override
  String get emptyHistory => 'История пока пуста';

  @override
  String get noActiveOrders => 'Нет активных нарядов';

  @override
  String get refreshFailed =>
      'Не удалось обновить данные. Потяните список вниз, чтобы повторить.';

  @override
  String get goodMorning => 'Доброе утро';

  @override
  String get goodAfternoon => 'Добрый день';

  @override
  String get goodEvening => 'Добрый вечер';

  @override
  String get goodNight => 'Доброй ночи';

  @override
  String get activeOrders => 'Активных';

  @override
  String get onShift => 'На смене';

  @override
  String get grade => 'Разряд';

  @override
  String get myRating => 'Мой рейтинг';

  @override
  String get noRatingYet => 'Пока нет оценки';

  @override
  String get executorRatingHint =>
      'После проверки выполненных нарядов здесь появятся рейтинг и его объяснение.';

  @override
  String get quality => 'Качество';

  @override
  String get onTime => 'В срок';

  @override
  String get reworks => 'Доработки';

  @override
  String get closedOrders => 'Закрыто нарядов';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutConfirmation => 'Вы уверены, что хотите выйти?';

  @override
  String get ratingPending => 'Оценка ожидается';

  @override
  String get aiShort => 'ИИ';

  @override
  String get emergencyResponse => 'Аварийный наряд — требуется ответ';

  @override
  String get newOrderAssigned => 'Вам назначен новый наряд';

  @override
  String get returnedForRework => 'Наряд возвращён на доработку';

  @override
  String get masterClosedOrder => 'Мастер закрыл наряд';

  @override
  String get deadlineExpired => 'Срок выполнения истёк';

  @override
  String get noExecutorNotifications => 'Уведомлений пока нет';

  @override
  String get rejectReason => 'Причина отказа';

  @override
  String get pauseReason => 'Причина приостановки';

  @override
  String get savedReasonNotSent =>
      'Исправленная причина сохранена на телефоне, но не отправлена. Сервер принял предыдущую версию.';

  @override
  String get orderReassignedWarning =>
      'Наряд переназначен другому исполнителю.';

  @override
  String get acceptWork => 'Принять в работу';

  @override
  String get queueOrder => 'Поставить в очередь';

  @override
  String get rejectOrder => 'Отклонить';

  @override
  String get resumeWork => 'Возобновить работу';

  @override
  String get startExecution => 'Начать исполнение';

  @override
  String get pauseWork => 'Приостановить';

  @override
  String get workDone => 'Исполнено';

  @override
  String get executionDeadline => 'Срок выполнения';

  @override
  String get faultDescription => 'Описание неисправности';

  @override
  String get photosBeforeWork => 'Фото до начала работ';

  @override
  String get masterNoPhotos => 'Мастер не добавил фотографии';

  @override
  String get masterScorePending => 'Оценка мастера пока не выставлена';

  @override
  String get assessmentPending => 'Заключение по выполнению пока не получено.';

  @override
  String get reportAwaitingMaster =>
      'Отчёт отправлен. Ожидает проверки мастером.';

  @override
  String get askMasterRemarks => 'Уточните замечания у мастера';

  @override
  String get yourReport => 'Ваш отчёт';

  @override
  String get workNotSpecified => 'Работы не указаны';

  @override
  String get photosAfter => 'Фото после';

  @override
  String get goToRework => 'Перейти к доработке';

  @override
  String get openOrder => 'Открыть наряд';

  @override
  String get addPhotoFailed =>
      'Не удалось добавить фото. Проверьте разрешения.';

  @override
  String get unplannedPhotoRequired =>
      'Для внепланового наряда нужно фото после';

  @override
  String get commitSelectedMaterial => 'Добавьте выбранный материал в список';

  @override
  String get material => 'Материал';

  @override
  String get selectMaterial => 'Выберите материал';

  @override
  String get quantity => 'Количество';

  @override
  String get positiveQuantity => 'Введите количество больше нуля';

  @override
  String get addMaterial => 'Добавить материал';

  @override
  String get sending => 'Отправка…';

  @override
  String get submitForReview => 'Отправить на проверку';

  @override
  String get materialsAndCode => 'Материалы и код';

  @override
  String get photosAndComment => 'Фото и комментарий';

  @override
  String get whatWasDone => 'Что было сделано?';

  @override
  String get describeCompletedWork => 'Опишите выполненные работы';

  @override
  String get faultCodeLabel => 'Код неисправности';

  @override
  String get selectCode => 'Выберите код';

  @override
  String get selectFaultCode => 'Выберите шифр';

  @override
  String get usedExecutorMaterials => 'Использованные материалы';

  @override
  String get noMaterialsUsed => 'Материалы не использовались';

  @override
  String get decrease => 'Уменьшить';

  @override
  String get increase => 'Увеличить';

  @override
  String get photosAfterWork => 'Фото после выполнения работ';

  @override
  String get removePhotoLabel => 'Удалить фото';

  @override
  String get takeAfterPhoto => 'Сделать фото после';

  @override
  String get chooseFromGallery => 'Выбрать из галереи';

  @override
  String get photoLimitReached =>
      'Добавлено 5 из 5 фото. Удалите фото, чтобы добавить новое.';

  @override
  String get optionalComment => 'Комментарий (необязательно)';

  @override
  String get additionalInformation => 'Дополнительная информация';

  @override
  String get changeStatusFailed =>
      'Не удалось изменить статус. Повторите попытку.';

  @override
  String get submitReportFailed =>
      'Не удалось отправить отчёт. Повторите попытку.';

  @override
  String get orderIssuedLabel => 'Наряд выдан';

  @override
  String get mechanicSpecialty => 'Слесарь';

  @override
  String get electricianSpecialty => 'Электрик';

  @override
  String get welderSpecialty => 'Сварщик';

  @override
  String get crushingArea => 'Дробление';

  @override
  String get beneficiationArea => 'Обогащение';

  @override
  String get repairArea => 'Ремонтный цех';

  @override
  String get transportArea => 'Транспортный участок';

  @override
  String get bearingMaterial => 'Подшипник · шт';

  @override
  String get sealMaterial => 'Уплотнение · шт';

  @override
  String get cableMaterial => 'Кабель · м';

  @override
  String get oilMaterial => 'Масло · л';

  @override
  String get greaseMaterial => 'Смазка · кг';

  @override
  String get anomalyExample =>
      'Пример вывода: конвейер К-3 часто останавливается из-за подшипников. Рекомендация: проверить соосность привода и скорректировать план ППР.';

  @override
  String closeOrderNumber(String number) {
    return 'Закрытие наряда №$number';
  }

  @override
  String resultOrderNumber(String number) {
    return 'Результат · №$number';
  }

  @override
  String deadlineMinutesLeft(String minutes) {
    return 'До срока осталось $minutes мин';
  }

  @override
  String workTimeValue(String time) {
    return 'Время в работе: $time';
  }

  @override
  String workMinutesValue(String minutes) {
    return 'Время в работе: $minutes мин';
  }

  @override
  String historyWorkMinutes(String minutes) {
    return '$minutes мин в работе';
  }

  @override
  String priorityValue(String priority) {
    return 'Приоритет: $priority';
  }

  @override
  String assessmentVerdict(String verdict) {
    return 'Проверка: $verdict';
  }

  @override
  String assessmentScore(String score) {
    return 'Оценка: $score / 5';
  }

  @override
  String assessmentStrengths(String text) {
    return 'Что сделано хорошо: $text';
  }

  @override
  String assessmentImprovements(String text) {
    return 'Что улучшить: $text';
  }

  @override
  String normHoursValue(String hours) {
    return 'Норматив: $hours ч';
  }

  @override
  String reworkReasonValue(String reason) {
    return 'Доработка: $reason';
  }

  @override
  String faultCodeValue(String code) {
    return 'Шифр: $code';
  }

  @override
  String previousMaterialsValue(String materials) {
    return 'Ранее указанные материалы:\n$materials';
  }

  @override
  String brigadeNumber(String number) {
    return 'Бригада №$number';
  }

  @override
  String get faultBearing => 'М-02 · Подшипник';

  @override
  String get faultOilLeak => 'Г-01 · Течь масла';

  @override
  String get faultCableBreak => 'Э-03 · Обрыв кабеля';

  @override
  String get faultGreaseLack => 'С-01 · Недостаток смазки';

  @override
  String get faultAirLeak => 'П-02 · Утечка воздуха';

  @override
  String get crusherEquipment => 'Дробилка КМД-1750';

  @override
  String get conveyorEquipment => 'Конвейер К-3';

  @override
  String get screenEquipment => 'Грохот ГИС-52';

  @override
  String get pumpEquipment => 'Насос Н-12';

  @override
  String get millEquipment => 'Мельница МШР-3';

  @override
  String get separatorEquipment => 'Сепаратор С-4';

  @override
  String get machineEquipment => 'Станок Т-16';

  @override
  String get craneEquipment => 'Кран-балка КБ-2';

  @override
  String get loaderEquipment => 'Погрузчик П-7';

  @override
  String get compressorEquipment => 'Компрессор ВК-22';

  @override
  String get demoBearingWork => 'Замена подшипника привода';

  @override
  String get demoOilLeakWork => 'Устранение течи масла';

  @override
  String get demoPowerWork => 'Проверка питания двигателя';

  @override
  String get demoLubricationWork => 'Плановая смазка узлов';

  @override
  String get demoSealWork => 'Замена уплотнения вала';

  @override
  String get demoGuardWork => 'Восстановление защитного кожуха';

  @override
  String get demoLubricationCheckWork => 'Плановая смазка и проверка узлов';

  @override
  String get demoOrderDescription =>
      'Проверить состояние оборудования, устранить неисправность и выполнить контрольный запуск.';

  @override
  String get demoSealReport =>
      'Заменено уплотнение. Соединения проверены. При контрольном запуске течь отсутствует.';

  @override
  String get demoBearingReport =>
      'Подшипник заменён. Проверены крепления и выполнен контрольный запуск. Посторонний шум устранён.';

  @override
  String get demoLubricationReport =>
      'Выполнена смазка узлов. Проверены крепления и работа оборудования под нагрузкой.';

  @override
  String get demoWaitingBearing => 'Ждём подшипник со склада';

  @override
  String get demoSealMaterial => 'Уплотнение 40×60 — 1 шт.';

  @override
  String get demoOilMaterial => 'Масло И-40 — 0,5 л';

  @override
  String get demoBearingMaterial => 'Подшипник — 1 шт.';

  @override
  String get demoGreaseSmall => 'Смазка — 0,2 кг';

  @override
  String get demoGreaseHalf => 'Смазка — 0,5 кг';

  @override
  String get awaitingCheck => 'Ожидает проверки';

  @override
  String get reportAiPending =>
      'Отчёт отправлен. Проверка ИИ ещё не выполнена.';

  @override
  String masterDemoAnswer(String query) {
    return 'Демо-ответ: здесь появятся рекомендации по запросу «$query». Для анализа необходимо подключить backend и ИИ.';
  }

  @override
  String queuePosition(String position) {
    return 'В очереди · позиция $position';
  }

  @override
  String get finishCurrentFirst =>
      'Сначала приостановите или завершите текущий наряд';

  @override
  String get wholePieceQuantity =>
      'Для штучного материала укажите целое количество';

  @override
  String get removeMaterial => 'Удалить материал';

  @override
  String get removeMaterialQuestion => 'Удалить материал из отчёта?';

  @override
  String get draftSaved => 'Черновик сохранён';

  @override
  String get draftLoadFailed =>
      'Не удалось восстановить черновик. Повторите попытку — сохранённые данные не изменены.';

  @override
  String get draftSaveFailed =>
      'Черновик не сохранён. Нажмите, чтобы повторить.';

  @override
  String get discardOrderDraftTitle => 'Начать без черновика?';

  @override
  String get discardOrderDraftMessage =>
      'Удалить сохранённый черновик и открыть пустую форму? Текст, настройки и фотографии черновика будут потеряны.';

  @override
  String get discardOrderDraftAction => 'Удалить черновик';

  @override
  String get orderDraftDiscardFailed =>
      'Не удалось удалить черновик. Сохранённые данные не изменены. Повторите попытку.';

  @override
  String get orderDraftChangedBeforeDiscard =>
      'Черновик изменился в другой форме. Нажмите «Повторить», чтобы загрузить актуальные данные.';

  @override
  String overdueByMinutes(String minutes) {
    return 'Просрочен на $minutes мин';
  }

  @override
  String get executionResult => 'Результат проверки';

  @override
  String get authLoginLabel => 'Логин';

  @override
  String get authPinLabel => 'ПИН';

  @override
  String get authEnterLogin => 'Введите логин';

  @override
  String get authPinLength => 'ПИН должен содержать от 4 до 12 символов';

  @override
  String get authSubtitle => 'Введите номер телефона и пароль.';

  @override
  String get authAccountHint => 'Учётную запись выдаёт администратор.';

  @override
  String get authNetworkError =>
      'Не удалось подключиться. Проверьте связь и повторите.';

  @override
  String get authMobileRole => 'Эта роль доступна в веб-панели.';

  @override
  String authRetryMinutes(String minutes) {
    return 'Слишком много попыток. Повторите через $minutes мин.';
  }

  @override
  String get authRateLimited => 'Слишком много попыток. Повторите позже.';

  @override
  String get demoDataNotice => 'Демонстрационные данные';

  @override
  String get authInvalidPhone => 'Введите номер от 10 до 15 цифр';

  @override
  String get changePasswordTitle => 'Смена пароля';

  @override
  String get currentPasswordLabel => 'Текущий пароль';

  @override
  String get newPasswordLabel => 'Новый пароль';

  @override
  String get newPasswordLength =>
      'Пароль должен содержать от 6 до 128 символов';

  @override
  String get passwordChanged => 'Пароль изменён';

  @override
  String get changePasswordButton => 'Изменить пароль';

  @override
  String get passwordResetHint => 'Забытый пароль сбрасывает администратор.';

  @override
  String get statusAiChecking => 'Выполнен · идёт AI-проверка';

  @override
  String get statusMasterReview => 'На проверке у мастера';

  @override
  String get checkingReport => 'Проверяем отчёт…';

  @override
  String get orderUnavailable => 'Наряд недоступен';

  @override
  String get photoTooLarge => 'Фото должно быть не больше 15 МБ.';

  @override
  String get photoCaptureHint =>
      'Снимайте «до» и «после» с одной точки, чтобы результат ремонта был виден. До 5 фото, каждое не больше 15 МБ.';

  @override
  String get reassignOrderTitle => 'Переназначить наряд';

  @override
  String get reassignOrderQuestion => 'Переназначить наряд?';

  @override
  String get reassignOrderExplanation =>
      'После переназначения наряд вернётся в статус «Выдан». Новый исполнитель получит уведомление.';

  @override
  String get orderCancelledMessage => 'Наряд отменён';

  @override
  String get orderReworkMessage => 'Наряд отправлен на доработку';

  @override
  String get orderClosedMessage => 'Наряд закрыт';

  @override
  String get orderUpdatedMessage => 'Наряд обновлён';

  @override
  String get closeActionLabel => 'Закрыть';

  @override
  String get orderNotFoundMessage => 'Наряд не найден';

  @override
  String get notYourOrderMessage => 'Это не ваш наряд';

  @override
  String get aiWorkCheckTitle => 'ИИ-проверка выполнения';

  @override
  String get workStrengthsTitle => 'Что выполнено хорошо';

  @override
  String get acceptWorkAction => 'Принять работу';

  @override
  String get closeWorkOrderAction => 'Закрыть наряд';

  @override
  String get orderAcceptedMessage => 'Наряд принят';

  @override
  String get orderRejectedMessage => 'Наряд отклонён';

  @override
  String get workStartedMessage => 'Работа начата';

  @override
  String get workPausedMessage => 'Работа приостановлена';

  @override
  String get workCompletedMessage => 'Работа выполнена';

  @override
  String get chooseEquipmentFirst => 'Сначала выберите оборудование.';

  @override
  String get describeFaultFirst => 'Сначала опишите неисправность.';

  @override
  String get recommendationAppliedMessage => 'Рекомендация применена.';

  @override
  String get photoSelectionFailedMessage => 'Не удалось выбрать фотографию.';

  @override
  String get chooseAreaValidation => 'Выберите участок.';

  @override
  String get chooseEquipmentValidation => 'Выберите оборудование.';

  @override
  String get chooseExecutorValidation => 'Выберите исполнителя.';

  @override
  String get chooseNormativeValidation => 'Выберите норматив.';

  @override
  String get creatingOrderLabel => 'Создание...';

  @override
  String get voiceNextStageMessage =>
      'Голосовой ввод подключим следующим этапом.';

  @override
  String get descriptionMinimumLabel => 'Описание — минимум 3 символа';

  @override
  String get getAiRecommendationLabel => 'Получить AI-рекомендацию';

  @override
  String get chooseAreaLabel => 'Выберите участок';

  @override
  String get estimatedTimeLabel => 'Оценка времени';

  @override
  String get queueLabel => 'Очередь';

  @override
  String get ratingLabel => 'Рейтинг';

  @override
  String get confidenceLabel => 'Уверенность';

  @override
  String get aiScoreLabel => 'Оценка ИИ';

  @override
  String get orderStatusChangedMessage =>
      'Статус наряда изменился. Обновите данные';

  @override
  String get orderNotWorkingMessage => 'Наряд уже не в работе';

  @override
  String get workAndFaultRequiredMessage =>
      'Заполните работы и шифр неисправности';

  @override
  String get checkMaterialsPhotosMessage => 'Проверьте материалы и фотографии';

  @override
  String get orderFinishedMessage => 'Наряд завершён';

  @override
  String get mockSealMaterial => 'Уплотнение 40×60';

  @override
  String get mockOilMaterial => 'Масло И-40';

  @override
  String get mockBearingShort => 'Подшипник';

  @override
  String get mockLubricantShort => 'Смазка';

  @override
  String get mockMasterReworkReason => 'Нет фото после выполненных работ';

  @override
  String get pieceUnit => 'шт.';

  @override
  String get hourUnit => 'ч.';

  @override
  String get piecesShortUnit => 'шт';

  @override
  String get meterUnit => 'м';

  @override
  String get kilogramUnit => 'кг';

  @override
  String get literUnit => 'л';

  @override
  String executorCurrentOrderQueue(String number, String count) {
    return 'выполняет наряд №$number, в очереди $count';
  }

  @override
  String executorQueuedOrders(String count) {
    return 'в очереди $count наряда';
  }

  @override
  String get aiVerdictAcceptedLabel => 'Принято';

  @override
  String get aiVerdictCommentsLabel => 'Принято с замечаниями';

  @override
  String get aiVerdictReworkLabel => 'Требуется доработка';

  @override
  String get historyMonthSummary => 'За 30 дней';

  @override
  String get historyAverageScore => 'Средняя оценка';

  @override
  String get historyEarlier => 'Ранее';

  @override
  String get ratingCalculation => 'Как считается рейтинг';

  @override
  String get ratingOnTimeOrders => 'Выполнено в срок';

  @override
  String get ratingReworkedOrders => 'Вернулись на доработку';

  @override
  String ratingQualityExplanation(String quality, String points) {
    return 'Средняя оценка ваших работ — $quality из 5. Баллы за качество: $points из 45.';
  }

  @override
  String ratingTimingExplanation(String percent, String points) {
    return 'В срок выполнено $percent% нарядов. Баллы за соблюдение сроков: $points из 25.';
  }

  @override
  String get ratingReliability => 'Надёжность ремонта';

  @override
  String ratingReliabilityExplanation(String percent, String points) {
    return '$percent% нарядов обошлись без доработок и повторных поломок в течение 7 дней. Баллы за надёжность ремонта: $points из 15.';
  }

  @override
  String ratingVolumeExplanation(String count, String points) {
    return 'Вы закрыли $count нарядов. Баллы за объём работы: $points из 10.';
  }

  @override
  String get ratingComplexity => 'Сложные работы';

  @override
  String ratingComplexityExplanation(String points) {
    return 'За аварийные наряды и наряды с высоким приоритетом начислено ещё $points из 5 баллов.';
  }

  @override
  String get ratingRejects => 'Необоснованные отказы';

  @override
  String ratingRejectsExplanation(String count, String points) {
    return 'Отказов без уважительной причины: $count. За них снято $points баллов.';
  }

  @override
  String get profileSettings => 'Настройки';

  @override
  String get completedShort => 'Завершено';

  @override
  String get orderSingular => 'Наряд';

  @override
  String get noOrders => 'Нет нарядов';

  @override
  String get noScore => 'Нет оценки';

  @override
  String get pushOrderOpenFailed => 'Не удалось открыть наряд';

  @override
  String get companyName => 'Костанайские минералы';

  @override
  String get emergencyNotificationChannel => 'Аварийные наряды';

  @override
  String get emergencyNotificationDescription =>
      'Новые аварийные наряды, требующие ответа';

  @override
  String get offlineActionSaved => 'Сохранено на телефоне. Ожидает отправки.';

  @override
  String get actionUnavailable => 'Действие недоступно из текущего статуса';

  @override
  String get executorActionUnavailable => 'Недоступное действие исполнителя';

  @override
  String get executionFieldsRequired => 'Заполните выполненные работы и шифр';

  @override
  String get afterPhotosInvalid => 'Проверьте фото после работ';

  @override
  String get materialsFromCatalogRequired =>
      'Выберите материалы из справочника';

  @override
  String get materialsInvalid => 'Проверьте материалы';

  @override
  String employeeGradeOnly(String grade) {
    return '$grade разряд';
  }

  @override
  String shortOrderCount(String count) {
    return '$count нар.';
  }

  @override
  String offlineActionNotApplied(String reason) {
    return 'Действие не применено: $reason';
  }

  @override
  String get ratingPeriodLabel => 'Период рейтинга';

  @override
  String get ratingPeriodShift => 'За смену · 12 часов';

  @override
  String get ratingPeriodDay => 'За сутки';

  @override
  String get ratingPeriodWeek => 'За неделю';

  @override
  String get ratingPeriodMonth => 'За 30 дней';

  @override
  String get ratingPeriodCustom => 'Выбрать даты';

  @override
  String get oilContaminationFault => 'Загрязнение масла';

  @override
  String get industrialOilMaterial => 'Масло индустриальное И-40А';

  @override
  String get oilFilterMaterial => 'Фильтр масляный';

  @override
  String get appSlogan => 'Наряд выдан — ИИ на контроле';

  @override
  String get pinCreateTitle => 'Создайте ПИН-код';

  @override
  String get pinConfirmTitle => 'Повторите ПИН-код';

  @override
  String get pinEnterTitle => 'Введите ПИН-код';

  @override
  String get pinCreateHint => 'Придумайте 4 цифры для входа в приложение';

  @override
  String get pinUnlockHint => 'Введите 4 цифры, чтобы открыть приложение';

  @override
  String get pinMismatch => 'ПИН-коды не совпадают. Повторите ввод';

  @override
  String get pinConfirmHint => 'Введите придуманный ПИН-код ещё раз';

  @override
  String get pinChange => 'Изменить код';

  @override
  String get pinIncorrect => 'Неверный ПИН-код';

  @override
  String get pinStorageError =>
      'Не удалось открыть хранилище ПИН-кода. Повторите попытку или войдите с паролем';

  @override
  String get pinForgot => 'Забыли ПИН-код?';

  @override
  String get pinUseAnotherAccount => 'Войти в другой аккаунт';

  @override
  String get pinResetHint =>
      'Для создания нового ПИН-кода потребуется вход с паролем';

  @override
  String get pinDeleteDigit => 'Удалить цифру';

  @override
  String pinTryAgainSeconds(String seconds) {
    return 'Слишком много попыток. Повторите через $seconds сек.';
  }

  @override
  String pinDigitsEntered(String count) {
    return 'Введено $count из 4 цифр';
  }

  @override
  String get voiceWorkInput => 'Продиктовать выполненные работы';

  @override
  String get executionWorkTooLong =>
      'Выполненные работы — не больше 500 символов';
}
