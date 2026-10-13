import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('kk'),
  ];

  /// No description provided for @exportReport.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт'**
  String get exportReport;

  /// No description provided for @reportPeriodHint.
  ///
  /// In ru, this message translates to:
  /// **'Наряды, выданные за выбранный период'**
  String get reportPeriodHint;

  /// No description provided for @todayPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get todayPeriod;

  /// No description provided for @weekPeriod.
  ///
  /// In ru, this message translates to:
  /// **'7 дней'**
  String get weekPeriod;

  /// No description provided for @monthPeriod.
  ///
  /// In ru, this message translates to:
  /// **'30 дней'**
  String get monthPeriod;

  /// No description provided for @allTimePeriod.
  ///
  /// In ru, this message translates to:
  /// **'Всё время'**
  String get allTimePeriod;

  /// No description provided for @noPeriodEmployees.
  ///
  /// In ru, this message translates to:
  /// **'За этот период нет исполнителей с нарядами'**
  String get noPeriodEmployees;

  /// No description provided for @editOrder.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование наряда'**
  String get editOrder;

  /// No description provided for @changeDeadline.
  ///
  /// In ru, this message translates to:
  /// **'Изменить срок выполнения'**
  String get changeDeadline;

  /// No description provided for @brigadeMembers.
  ///
  /// In ru, this message translates to:
  /// **'Состав бригады'**
  String get brigadeMembers;

  /// No description provided for @brigades.
  ///
  /// In ru, this message translates to:
  /// **'Бригады'**
  String get brigades;

  /// No description provided for @teamBrigadeSearch.
  ///
  /// In ru, this message translates to:
  /// **'Бригада, имя или специальность'**
  String get teamBrigadeSearch;

  /// No description provided for @eventDeadline.
  ///
  /// In ru, this message translates to:
  /// **'Срок изменён: {value}'**
  String eventDeadline(String value);

  /// No description provided for @filters.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get filters;

  /// No description provided for @applyFilters.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get applyFilters;

  /// No description provided for @resetFilters.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get resetFilters;

  /// No description provided for @closeFilters.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть фильтры'**
  String get closeFilters;

  /// No description provided for @statusFilter.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get statusFilter;

  /// No description provided for @onlyOverdue.
  ///
  /// In ru, this message translates to:
  /// **'Только просроченные'**
  String get onlyOverdue;

  /// No description provided for @clearSearch.
  ///
  /// In ru, this message translates to:
  /// **'Очистить поиск'**
  String get clearSearch;

  /// No description provided for @attachPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить фото'**
  String get attachPhoto;

  /// No description provided for @choosePhotoSource.
  ///
  /// In ru, this message translates to:
  /// **'Выберите источник фото'**
  String get choosePhotoSource;

  /// No description provided for @loginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите телефон и пароль вашего аккаунта.'**
  String get loginSubtitle;

  /// No description provided for @registrationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get registrationTitle;

  /// No description provided for @nameSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Укажите фамилию, имя и отчество.'**
  String get nameSubtitle;

  /// No description provided for @accountSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте телефон и придумайте пароль.'**
  String get accountSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть аккаунт? Войти'**
  String get alreadyHaveAccount;

  /// No description provided for @phoneLabel.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get phoneLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In ru, this message translates to:
  /// **'Показать пароль'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть пароль'**
  String get hidePassword;

  /// No description provided for @enterPassword.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get enterPassword;

  /// No description provided for @loginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginButton;

  /// No description provided for @lastName.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get lastName;

  /// No description provided for @firstName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get firstName;

  /// No description provided for @patronymic.
  ///
  /// In ru, this message translates to:
  /// **'Отчество'**
  String get patronymic;

  /// No description provided for @enterLastName.
  ///
  /// In ru, this message translates to:
  /// **'Введите фамилию'**
  String get enterLastName;

  /// No description provided for @enterFirstName.
  ///
  /// In ru, this message translates to:
  /// **'Введите имя'**
  String get enterFirstName;

  /// No description provided for @ifAvailable.
  ///
  /// In ru, this message translates to:
  /// **'При наличии'**
  String get ifAvailable;

  /// No description provided for @continueButton.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get continueButton;

  /// No description provided for @passwordHint.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 8 символов'**
  String get passwordHint;

  /// No description provided for @passwordTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Пароль должен содержать минимум 8 символов'**
  String get passwordTooShort;

  /// No description provided for @registerButton.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get registerButton;

  /// No description provided for @back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @enterPhone.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона'**
  String get enterPhone;

  /// No description provided for @incompletePhone.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер полностью'**
  String get incompletePhone;

  /// No description provided for @stepLabel.
  ///
  /// In ru, this message translates to:
  /// **'Шаг {step} из 2'**
  String stepLabel(int step);

  /// No description provided for @dashboard.
  ///
  /// In ru, this message translates to:
  /// **'Обзор смены'**
  String get dashboard;

  /// No description provided for @greeting.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте, Серик. Вот что происходит на участке.'**
  String get greeting;

  /// No description provided for @createOrder.
  ///
  /// In ru, this message translates to:
  /// **'Создать наряд'**
  String get createOrder;

  /// No description provided for @issuedOrders.
  ///
  /// In ru, this message translates to:
  /// **'Выдано нарядов'**
  String get issuedOrders;

  /// No description provided for @completed.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено'**
  String get completed;

  /// No description provided for @overdue.
  ///
  /// In ru, this message translates to:
  /// **'Просрочено'**
  String get overdue;

  /// No description provided for @awaitingAcceptance.
  ///
  /// In ru, this message translates to:
  /// **'На приёмке'**
  String get awaitingAcceptance;

  /// No description provided for @equipmentStopped.
  ///
  /// In ru, this message translates to:
  /// **'Оборудование в простое'**
  String get equipmentStopped;

  /// No description provided for @needsAttention.
  ///
  /// In ru, this message translates to:
  /// **'Требуют внимания'**
  String get needsAttention;

  /// No description provided for @noAttention.
  ///
  /// In ru, this message translates to:
  /// **'Нет нарядов, требующих внимания'**
  String get noAttention;

  /// No description provided for @shiftTeam.
  ///
  /// In ru, this message translates to:
  /// **'Команда на смене'**
  String get shiftTeam;

  /// No description provided for @allTeam.
  ///
  /// In ru, this message translates to:
  /// **'Вся команда →'**
  String get allTeam;

  /// No description provided for @allAreas.
  ///
  /// In ru, this message translates to:
  /// **'Все участки'**
  String get allAreas;

  /// No description provided for @allEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Всё оборудование'**
  String get allEquipment;

  /// No description provided for @allPriorities.
  ///
  /// In ru, this message translates to:
  /// **'Все приоритеты'**
  String get allPriorities;

  /// No description provided for @all.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get all;

  /// No description provided for @overduePlural.
  ///
  /// In ru, this message translates to:
  /// **'Просрочены'**
  String get overduePlural;

  /// No description provided for @issuedPlural.
  ///
  /// In ru, this message translates to:
  /// **'Выданные'**
  String get issuedPlural;

  /// No description provided for @acceptedPlural.
  ///
  /// In ru, this message translates to:
  /// **'Принятые'**
  String get acceptedPlural;

  /// No description provided for @working.
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get working;

  /// No description provided for @queued.
  ///
  /// In ru, this message translates to:
  /// **'В очереди'**
  String get queued;

  /// No description provided for @completedPlural.
  ///
  /// In ru, this message translates to:
  /// **'Выполненные'**
  String get completedPlural;

  /// No description provided for @pausedPlural.
  ///
  /// In ru, this message translates to:
  /// **'Приостановлены'**
  String get pausedPlural;

  /// No description provided for @rework.
  ///
  /// In ru, this message translates to:
  /// **'На доработке'**
  String get rework;

  /// No description provided for @rejectedPlural.
  ///
  /// In ru, this message translates to:
  /// **'Отклонены'**
  String get rejectedPlural;

  /// No description provided for @cancelledPlural.
  ///
  /// In ru, this message translates to:
  /// **'Отменены'**
  String get cancelledPlural;

  /// No description provided for @orders.
  ///
  /// In ru, this message translates to:
  /// **'Наряды'**
  String get orders;

  /// No description provided for @ordersSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Назначения, сроки и текущие статусы работ'**
  String get ordersSubtitle;

  /// No description provided for @newOrder.
  ///
  /// In ru, this message translates to:
  /// **'Новый наряд'**
  String get newOrder;

  /// No description provided for @listView.
  ///
  /// In ru, this message translates to:
  /// **'Список'**
  String get listView;

  /// No description provided for @kanban.
  ///
  /// In ru, this message translates to:
  /// **'Канбан'**
  String get kanban;

  /// No description provided for @orderSearch.
  ///
  /// In ru, this message translates to:
  /// **'Номер, работа или оборудование'**
  String get orderSearch;

  /// No description provided for @area.
  ///
  /// In ru, this message translates to:
  /// **'Участок'**
  String get area;

  /// No description provided for @equipment.
  ///
  /// In ru, this message translates to:
  /// **'Оборудование'**
  String get equipment;

  /// No description provided for @employee.
  ///
  /// In ru, this message translates to:
  /// **'Исполнитель'**
  String get employee;

  /// No description provided for @allEmployees.
  ///
  /// In ru, this message translates to:
  /// **'Все исполнители'**
  String get allEmployees;

  /// No description provided for @priority.
  ///
  /// In ru, this message translates to:
  /// **'Приоритет'**
  String get priority;

  /// No description provided for @noFilteredOrders.
  ///
  /// In ru, this message translates to:
  /// **'По выбранным фильтрам нарядов нет'**
  String get noFilteredOrders;

  /// No description provided for @overdueOrders.
  ///
  /// In ru, this message translates to:
  /// **'Просроченные'**
  String get overdueOrders;

  /// No description provided for @demoRating.
  ///
  /// In ru, this message translates to:
  /// **'Демо-рейтинг'**
  String get demoRating;

  /// No description provided for @available.
  ///
  /// In ru, this message translates to:
  /// **'Свободен'**
  String get available;

  /// No description provided for @team.
  ///
  /// In ru, this message translates to:
  /// **'Команда'**
  String get team;

  /// No description provided for @teamSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка исполнителей, специальности и доступность'**
  String get teamSubtitle;

  /// No description provided for @employeeSearch.
  ///
  /// In ru, this message translates to:
  /// **'Имя или специальность'**
  String get employeeSearch;

  /// No description provided for @onlyAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Только свободные'**
  String get onlyAvailable;

  /// No description provided for @noEmployees.
  ///
  /// In ru, this message translates to:
  /// **'Исполнители не найдены'**
  String get noEmployees;

  /// No description provided for @aiControl.
  ///
  /// In ru, this message translates to:
  /// **'ИИ-контроль'**
  String get aiControl;

  /// No description provided for @aiSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендации цифрового контролёра. Финальное решение принимает мастер.'**
  String get aiSubtitle;

  /// No description provided for @deadlineControl.
  ///
  /// In ru, this message translates to:
  /// **'Контроль сроков'**
  String get deadlineControl;

  /// No description provided for @deadlineHelp.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание за 30 минут до срока. Эскалация, если обычный наряд не принят за 10 минут, аварийный — за 3 минуты.'**
  String get deadlineHelp;

  /// No description provided for @completionCheck.
  ///
  /// In ru, this message translates to:
  /// **'Проверка выполнения'**
  String get completionCheck;

  /// No description provided for @noReviewOrders.
  ///
  /// In ru, this message translates to:
  /// **'Нет нарядов на проверке'**
  String get noReviewOrders;

  /// No description provided for @photoAnalysis.
  ///
  /// In ru, this message translates to:
  /// **'Анализ фото до / после'**
  String get photoAnalysis;

  /// No description provided for @photoAnalysisHelp.
  ///
  /// In ru, this message translates to:
  /// **'Проверка наличия и актуальности фото, сравнение оборудования и видимых дефектов. При низкой уверенности потребуется проверка мастера.'**
  String get photoAnalysisHelp;

  /// No description provided for @orderReport.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт по наряду'**
  String get orderReport;

  /// No description provided for @orderReportHelp.
  ///
  /// In ru, this message translates to:
  /// **'Работы, материалы, хронология, соблюдение срока и объяснение оценки собраны в карточке наряда.'**
  String get orderReportHelp;

  /// No description provided for @equipmentAnomalies.
  ///
  /// In ru, this message translates to:
  /// **'Аномалии оборудования'**
  String get equipmentAnomalies;

  /// No description provided for @employeeRating.
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг исполнителей'**
  String get employeeRating;

  /// No description provided for @ratingHelp.
  ///
  /// In ru, this message translates to:
  /// **'Качество, выполнение в срок, доработки, сложность работ и обоснованность отказов формируют оценку.'**
  String get ratingHelp;

  /// No description provided for @masterAssistant.
  ///
  /// In ru, this message translates to:
  /// **'Ассистент мастера'**
  String get masterAssistant;

  /// No description provided for @chatHelp.
  ///
  /// In ru, this message translates to:
  /// **'Макет чата. Ответы демонстрационные.'**
  String get chatHelp;

  /// No description provided for @chatHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: кто сейчас свободен?'**
  String get chatHint;

  /// No description provided for @showDemoAnswer.
  ///
  /// In ru, this message translates to:
  /// **'Показать демо-ответ'**
  String get showDemoAnswer;

  /// No description provided for @reportsRating.
  ///
  /// In ru, this message translates to:
  /// **'Отчёты и рейтинг'**
  String get reportsRating;

  /// No description provided for @reportsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Сводка текущей демонстрационной смены'**
  String get reportsSubtitle;

  /// No description provided for @pdfNotReady.
  ///
  /// In ru, this message translates to:
  /// **'Выгрузку PDF подключим вместе с backend'**
  String get pdfNotReady;

  /// No description provided for @exportPdf.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт PDF'**
  String get exportPdf;

  /// No description provided for @excelNotReady.
  ///
  /// In ru, this message translates to:
  /// **'Выгрузку Excel подключим вместе с backend'**
  String get excelNotReady;

  /// No description provided for @exportExcel.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт Excel'**
  String get exportExcel;

  /// No description provided for @periodNotReady.
  ///
  /// In ru, this message translates to:
  /// **'Отчёты за произвольный период подключим после добавления истории на backend'**
  String get periodNotReady;

  /// No description provided for @selectPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать период'**
  String get selectPeriod;

  /// No description provided for @totalOrders.
  ///
  /// In ru, this message translates to:
  /// **'Всего нарядов'**
  String get totalOrders;

  /// No description provided for @closed.
  ///
  /// In ru, this message translates to:
  /// **'Закрыто'**
  String get closed;

  /// No description provided for @rejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get rejected;

  /// No description provided for @equipmentDowntime.
  ///
  /// In ru, this message translates to:
  /// **'Простои оборудования'**
  String get equipmentDowntime;

  /// No description provided for @downtimeReportHelp.
  ///
  /// In ru, this message translates to:
  /// **'Макет отчёта: время остановки по оборудованию, причины и доля плановых / внеплановых работ.'**
  String get downtimeReportHelp;

  /// No description provided for @usedMaterials.
  ///
  /// In ru, this message translates to:
  /// **'Списанные материалы'**
  String get usedMaterials;

  /// No description provided for @materialsReportHelp.
  ///
  /// In ru, this message translates to:
  /// **'Макет отчёта: расход по материалам, участкам и исполнителям, сравнение с нормативами.'**
  String get materialsReportHelp;

  /// No description provided for @notificationCenter.
  ///
  /// In ru, this message translates to:
  /// **'Центр уведомлений'**
  String get notificationCenter;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Локальные уведомления прототипа. Push не подключён.'**
  String get notificationsSubtitle;

  /// No description provided for @noNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Новых уведомлений нет'**
  String get noNotifications;

  /// No description provided for @awaitingReview.
  ///
  /// In ru, this message translates to:
  /// **'Работа ожидает приёмки'**
  String get awaitingReview;

  /// No description provided for @emergencyAwaiting.
  ///
  /// In ru, this message translates to:
  /// **'Аварийный наряд ожидает ответа'**
  String get emergencyAwaiting;

  /// No description provided for @normalPriority.
  ///
  /// In ru, this message translates to:
  /// **'Обычный'**
  String get normalPriority;

  /// No description provided for @permissionDenied.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите доступ к камере или фото в настройках приложения.'**
  String get permissionDenied;

  /// No description provided for @pickerFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть камеру или галерею. Попробуйте ещё раз.'**
  String get pickerFailed;

  /// No description provided for @photoLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фото. Выберите другой снимок.'**
  String get photoLoadFailed;

  /// No description provided for @deadline.
  ///
  /// In ru, this message translates to:
  /// **'Срок исполнения'**
  String get deadline;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @select.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get select;

  /// No description provided for @executionTime.
  ///
  /// In ru, this message translates to:
  /// **'Время исполнения'**
  String get executionTime;

  /// No description provided for @futureDeadline.
  ///
  /// In ru, this message translates to:
  /// **'Выберите срок в будущем.'**
  String get futureDeadline;

  /// No description provided for @createOrderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Создание наряда'**
  String get createOrderTitle;

  /// No description provided for @workDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание работ'**
  String get workDescription;

  /// No description provided for @unplanned.
  ///
  /// In ru, this message translates to:
  /// **'Внеплановый'**
  String get unplanned;

  /// No description provided for @planned.
  ///
  /// In ru, this message translates to:
  /// **'Плановый'**
  String get planned;

  /// No description provided for @optionalWorkTitle.
  ///
  /// In ru, this message translates to:
  /// **'Название работы (необязательно)'**
  String get optionalWorkTitle;

  /// No description provided for @problemWorks.
  ///
  /// In ru, this message translates to:
  /// **'Проблема и необходимые работы'**
  String get problemWorks;

  /// No description provided for @voiceInput.
  ///
  /// In ru, this message translates to:
  /// **'Голосовой ввод'**
  String get voiceInput;

  /// No description provided for @voiceNotReady.
  ///
  /// In ru, this message translates to:
  /// **'Голосовой ввод подключим позже.'**
  String get voiceNotReady;

  /// No description provided for @describeProblem.
  ///
  /// In ru, this message translates to:
  /// **'Опишите проблему'**
  String get describeProblem;

  /// No description provided for @locationAssignee.
  ///
  /// In ru, this message translates to:
  /// **'Место и исполнитель'**
  String get locationAssignee;

  /// No description provided for @brigade.
  ///
  /// In ru, this message translates to:
  /// **'Бригада'**
  String get brigade;

  /// No description provided for @selectEmployee.
  ///
  /// In ru, this message translates to:
  /// **'Выберите исполнителя'**
  String get selectEmployee;

  /// No description provided for @selectBrigade.
  ///
  /// In ru, this message translates to:
  /// **'Выберите бригаду'**
  String get selectBrigade;

  /// No description provided for @deadlinePriority.
  ///
  /// In ru, this message translates to:
  /// **'Срок и приоритет'**
  String get deadlinePriority;

  /// No description provided for @emergencyPriority.
  ///
  /// In ru, this message translates to:
  /// **'Аварийный'**
  String get emergencyPriority;

  /// No description provided for @highPriority.
  ///
  /// In ru, this message translates to:
  /// **'Высокий'**
  String get highPriority;

  /// No description provided for @normHoursShort.
  ///
  /// In ru, this message translates to:
  /// **'Норматив, ч'**
  String get normHoursShort;

  /// No description provided for @dateTime.
  ///
  /// In ru, this message translates to:
  /// **'Дата и время'**
  String get dateTime;

  /// No description provided for @normHours.
  ///
  /// In ru, this message translates to:
  /// **'Норматив в часах'**
  String get normHours;

  /// No description provided for @normRange.
  ///
  /// In ru, this message translates to:
  /// **'Укажите от 1 минуты до 8760 часов'**
  String get normRange;

  /// No description provided for @optionalFaultCode.
  ///
  /// In ru, this message translates to:
  /// **'Шифр неисправности (необязательно)'**
  String get optionalFaultCode;

  /// No description provided for @notSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Не указан'**
  String get notSpecified;

  /// No description provided for @comment.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get comment;

  /// No description provided for @faultPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фото неисправности · до 5'**
  String get faultPhotos;

  /// No description provided for @issueOrder.
  ///
  /// In ru, this message translates to:
  /// **'Выдать наряд'**
  String get issueOrder;

  /// No description provided for @reason.
  ///
  /// In ru, this message translates to:
  /// **'Причина'**
  String get reason;

  /// No description provided for @specifyReason.
  ///
  /// In ru, this message translates to:
  /// **'Укажите причину'**
  String get specifyReason;

  /// No description provided for @confirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get confirm;

  /// No description provided for @employeeOrBrigade.
  ///
  /// In ru, this message translates to:
  /// **'Исполнитель или бригада'**
  String get employeeOrBrigade;

  /// No description provided for @orderPriority.
  ///
  /// In ru, this message translates to:
  /// **'Приоритет наряда'**
  String get orderPriority;

  /// No description provided for @masterScore.
  ///
  /// In ru, this message translates to:
  /// **'Оценка мастера'**
  String get masterScore;

  /// No description provided for @overdueSingular.
  ///
  /// In ru, this message translates to:
  /// **'Просрочен'**
  String get overdueSingular;

  /// No description provided for @orderInformation.
  ///
  /// In ru, this message translates to:
  /// **'Информация о наряде'**
  String get orderInformation;

  /// No description provided for @workType.
  ///
  /// In ru, this message translates to:
  /// **'Тип работ'**
  String get workType;

  /// No description provided for @description.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get description;

  /// No description provided for @issueDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата выдачи'**
  String get issueDate;

  /// No description provided for @norm.
  ///
  /// In ru, this message translates to:
  /// **'Норматив'**
  String get norm;

  /// No description provided for @faultCode.
  ///
  /// In ru, this message translates to:
  /// **'Шифр неисправности'**
  String get faultCode;

  /// No description provided for @master.
  ///
  /// In ru, this message translates to:
  /// **'Мастер'**
  String get master;

  /// No description provided for @orderDowntime.
  ///
  /// In ru, this message translates to:
  /// **'Простой оборудования'**
  String get orderDowntime;

  /// No description provided for @stopped.
  ///
  /// In ru, this message translates to:
  /// **'Оборудование остановлено'**
  String get stopped;

  /// No description provided for @noDowntime.
  ///
  /// In ru, this message translates to:
  /// **'Нет активного простоя'**
  String get noDowntime;

  /// No description provided for @beforeWork.
  ///
  /// In ru, this message translates to:
  /// **'До выполнения'**
  String get beforeWork;

  /// No description provided for @afterWork.
  ///
  /// In ru, this message translates to:
  /// **'После выполнения'**
  String get afterWork;

  /// No description provided for @reassign.
  ///
  /// In ru, this message translates to:
  /// **'Переназначить'**
  String get reassign;

  /// No description provided for @changePriority.
  ///
  /// In ru, this message translates to:
  /// **'Изменить приоритет'**
  String get changePriority;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отмена наряда'**
  String get cancelOrderTitle;

  /// No description provided for @cancelOrder.
  ///
  /// In ru, this message translates to:
  /// **'Отменить наряд'**
  String get cancelOrder;

  /// No description provided for @workerReport.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт исполнителя'**
  String get workerReport;

  /// No description provided for @completedWorks.
  ///
  /// In ru, this message translates to:
  /// **'Выполненные работы'**
  String get completedWorks;

  /// No description provided for @materials.
  ///
  /// In ru, this message translates to:
  /// **'Материалы'**
  String get materials;

  /// No description provided for @notSpecifiedPlural.
  ///
  /// In ru, this message translates to:
  /// **'Не указаны'**
  String get notSpecifiedPlural;

  /// No description provided for @changeScore.
  ///
  /// In ru, this message translates to:
  /// **'Изменить оценку'**
  String get changeScore;

  /// No description provided for @acceptedByMaster.
  ///
  /// In ru, this message translates to:
  /// **'Работы приняты мастером'**
  String get acceptedByMaster;

  /// No description provided for @acceptClose.
  ///
  /// In ru, this message translates to:
  /// **'Принять и закрыть'**
  String get acceptClose;

  /// No description provided for @returnRework.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть на доработку'**
  String get returnRework;

  /// No description provided for @toRework.
  ///
  /// In ru, this message translates to:
  /// **'На доработку'**
  String get toRework;

  /// No description provided for @actionHistory.
  ///
  /// In ru, this message translates to:
  /// **'История действий'**
  String get actionHistory;

  /// No description provided for @reports.
  ///
  /// In ru, this message translates to:
  /// **'Отчёты'**
  String get reports;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @shift.
  ///
  /// In ru, this message translates to:
  /// **'Смена'**
  String get shift;

  /// No description provided for @shiftManagement.
  ///
  /// In ru, this message translates to:
  /// **'УПРАВЛЕНИЕ СМЕНОЙ'**
  String get shiftManagement;

  /// No description provided for @masterRole.
  ///
  /// In ru, this message translates to:
  /// **'Мастер смены'**
  String get masterRole;

  /// No description provided for @offShift.
  ///
  /// In ru, this message translates to:
  /// **'Не на смене'**
  String get offShift;

  /// No description provided for @aiDemoLabel.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрационные данные · ИИ не подключён'**
  String get aiDemoLabel;

  /// No description provided for @photoOpenFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть фото'**
  String get photoOpenFailed;

  /// No description provided for @noPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фото не прикреплены'**
  String get noPhotos;

  /// No description provided for @camera.
  ///
  /// In ru, this message translates to:
  /// **'Камера'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In ru, this message translates to:
  /// **'Галерея'**
  String get gallery;

  /// No description provided for @statusIssued.
  ///
  /// In ru, this message translates to:
  /// **'Выдан'**
  String get statusIssued;

  /// No description provided for @statusAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Принят'**
  String get statusAccepted;

  /// No description provided for @statusPaused.
  ///
  /// In ru, this message translates to:
  /// **'Приостановлен'**
  String get statusPaused;

  /// No description provided for @statusReview.
  ///
  /// In ru, this message translates to:
  /// **'На проверке'**
  String get statusReview;

  /// No description provided for @statusClosed.
  ///
  /// In ru, this message translates to:
  /// **'Закрыт'**
  String get statusClosed;

  /// No description provided for @statusRejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонён'**
  String get statusRejected;

  /// No description provided for @statusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get statusCancelled;

  /// No description provided for @emergencyFull.
  ///
  /// In ru, this message translates to:
  /// **'Аварийный — срочно в работу'**
  String get emergencyFull;

  /// No description provided for @normalFull.
  ///
  /// In ru, this message translates to:
  /// **'Обычный — в порядке очереди'**
  String get normalFull;

  /// No description provided for @noAiVerdict.
  ///
  /// In ru, this message translates to:
  /// **'Нет заключения'**
  String get noAiVerdict;

  /// No description provided for @aiUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'ИИ пока не подключён.'**
  String get aiUnavailable;

  /// No description provided for @positiveNorm.
  ///
  /// In ru, this message translates to:
  /// **'Норматив должен быть больше нуля'**
  String get positiveNorm;

  /// No description provided for @onShiftAssignee.
  ///
  /// In ru, this message translates to:
  /// **'Выберите исполнителя или бригаду на смене'**
  String get onShiftAssignee;

  /// No description provided for @futureDeadlineError.
  ///
  /// In ru, this message translates to:
  /// **'Срок должен быть в будущем'**
  String get futureDeadlineError;

  /// No description provided for @fivePhotos.
  ///
  /// In ru, this message translates to:
  /// **'Не более 5 фото'**
  String get fivePhotos;

  /// No description provided for @employeeOffShift.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник не на смене'**
  String get employeeOffShift;

  /// No description provided for @brigadeOffShift.
  ///
  /// In ru, this message translates to:
  /// **'Бригада не на смене'**
  String get brigadeOffShift;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @complex.
  ///
  /// In ru, this message translates to:
  /// **'Минеральный комплекс'**
  String get complex;

  /// No description provided for @orderNumber.
  ///
  /// In ru, this message translates to:
  /// **'Наряд №{number}'**
  String orderNumber(String number);

  /// No description provided for @orderNumberUpper.
  ///
  /// In ru, this message translates to:
  /// **'НАРЯД №{number}'**
  String orderNumberUpper(String number);

  /// No description provided for @issuePreview.
  ///
  /// In ru, this message translates to:
  /// **'Выдача: {date}'**
  String issuePreview(String date);

  /// No description provided for @issuedAt.
  ///
  /// In ru, this message translates to:
  /// **'Выдан {date}'**
  String issuedAt(String date);

  /// No description provided for @dueAt.
  ///
  /// In ru, this message translates to:
  /// **'До {date}'**
  String dueAt(String date);

  /// No description provided for @hoursValue.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч'**
  String hoursValue(String hours);

  /// No description provided for @scoreValue.
  ///
  /// In ru, this message translates to:
  /// **'{score} из 5'**
  String scoreValue(String score);

  /// No description provided for @employeeGrade.
  ///
  /// In ru, this message translates to:
  /// **'{specialty} · {grade} разряд'**
  String employeeGrade(String specialty, String grade);

  /// No description provided for @workingOrder.
  ///
  /// In ru, this message translates to:
  /// **'В работе · №{number}'**
  String workingOrder(String number);

  /// No description provided for @workingQueue.
  ///
  /// In ru, this message translates to:
  /// **'В работе · №{number} · очередь {count}'**
  String workingQueue(String number, String count);

  /// No description provided for @queuedCount.
  ///
  /// In ru, this message translates to:
  /// **'В очереди · {count}'**
  String queuedCount(String count);

  /// No description provided for @assignedOrder.
  ///
  /// In ru, this message translates to:
  /// **'Занят · назначен №{number}'**
  String assignedOrder(String number);

  /// No description provided for @brigadeAvailability.
  ///
  /// In ru, this message translates to:
  /// **'На смене: {total} · свободны: {free} · заняты: {busy}'**
  String brigadeAvailability(String total, String free, String busy);

  /// No description provided for @overdueMinutes.
  ///
  /// In ru, this message translates to:
  /// **'Просрочка · {minutes} мин.'**
  String overdueMinutes(String minutes);

  /// No description provided for @removePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото {number}'**
  String removePhoto(String number);

  /// No description provided for @boardCount.
  ///
  /// In ru, this message translates to:
  /// **'{label} · {count}'**
  String boardCount(String label, String count);

  /// No description provided for @shiftTime.
  ///
  /// In ru, this message translates to:
  /// **'Смена №{number} · {time}'**
  String shiftTime(String number, String time);

  /// No description provided for @aiVerdict.
  ///
  /// In ru, this message translates to:
  /// **'Вердикт ИИ: {verdict}'**
  String aiVerdict(String verdict);

  /// No description provided for @aiSummary.
  ///
  /// In ru, this message translates to:
  /// **'{explanation}\nОценка ИИ: {aiScore} / 5.\nИтоговая оценка: {score} / 5.\nОкончательное решение принимает мастер.'**
  String aiSummary(String explanation, String aiScore, String score);

  /// No description provided for @eventIssued.
  ///
  /// In ru, this message translates to:
  /// **'Наряд выдан: {assignee}'**
  String eventIssued(String assignee);

  /// No description provided for @eventReassigned.
  ///
  /// In ru, this message translates to:
  /// **'Переназначен: {assignee}'**
  String eventReassigned(String assignee);

  /// No description provided for @eventPriority.
  ///
  /// In ru, this message translates to:
  /// **'Приоритет изменён: {priority}'**
  String eventPriority(String priority);

  /// No description provided for @eventScore.
  ///
  /// In ru, this message translates to:
  /// **'Оценка мастера: {score} / 5'**
  String eventScore(String score);

  /// No description provided for @eventReason.
  ///
  /// In ru, this message translates to:
  /// **'{status}: {reason}'**
  String eventReason(String status, String reason);

  /// No description provided for @myOrders.
  ///
  /// In ru, this message translates to:
  /// **'Мои наряды'**
  String get myOrders;

  /// No description provided for @orderHistory.
  ///
  /// In ru, this message translates to:
  /// **'История нарядов'**
  String get orderHistory;

  /// No description provided for @profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile;

  /// No description provided for @history.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get history;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @archivedOrdersHint.
  ///
  /// In ru, this message translates to:
  /// **'Завершённые, отменённые и отклонённые наряды'**
  String get archivedOrdersHint;

  /// No description provided for @executorSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по номеру или оборудованию'**
  String get executorSearch;

  /// No description provided for @noSearchResults.
  ///
  /// In ru, this message translates to:
  /// **'По вашему запросу ничего не найдено'**
  String get noSearchResults;

  /// No description provided for @emptyHistory.
  ///
  /// In ru, this message translates to:
  /// **'История пока пуста'**
  String get emptyHistory;

  /// No description provided for @noActiveOrders.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных нарядов'**
  String get noActiveOrders;

  /// No description provided for @refreshFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить данные. Потяните список вниз, чтобы повторить.'**
  String get refreshFailed;

  /// No description provided for @goodMorning.
  ///
  /// In ru, this message translates to:
  /// **'Доброе утро'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In ru, this message translates to:
  /// **'Добрый день'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In ru, this message translates to:
  /// **'Добрый вечер'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In ru, this message translates to:
  /// **'Доброй ночи'**
  String get goodNight;

  /// No description provided for @activeOrders.
  ///
  /// In ru, this message translates to:
  /// **'Активных'**
  String get activeOrders;

  /// No description provided for @onShift.
  ///
  /// In ru, this message translates to:
  /// **'На смене'**
  String get onShift;

  /// No description provided for @grade.
  ///
  /// In ru, this message translates to:
  /// **'Разряд'**
  String get grade;

  /// No description provided for @myRating.
  ///
  /// In ru, this message translates to:
  /// **'Мой рейтинг'**
  String get myRating;

  /// No description provided for @noRatingYet.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет оценки'**
  String get noRatingYet;

  /// No description provided for @executorRatingHint.
  ///
  /// In ru, this message translates to:
  /// **'После проверки выполненных нарядов здесь появятся рейтинг и его объяснение.'**
  String get executorRatingHint;

  /// No description provided for @quality.
  ///
  /// In ru, this message translates to:
  /// **'Качество'**
  String get quality;

  /// No description provided for @onTime.
  ///
  /// In ru, this message translates to:
  /// **'В срок'**
  String get onTime;

  /// No description provided for @reworks.
  ///
  /// In ru, this message translates to:
  /// **'Доработки'**
  String get reworks;

  /// No description provided for @closedOrders.
  ///
  /// In ru, this message translates to:
  /// **'Закрыто нарядов'**
  String get closedOrders;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите выйти?'**
  String get logoutConfirmation;

  /// No description provided for @ratingPending.
  ///
  /// In ru, this message translates to:
  /// **'Оценка ожидается'**
  String get ratingPending;

  /// No description provided for @aiShort.
  ///
  /// In ru, this message translates to:
  /// **'ИИ'**
  String get aiShort;

  /// No description provided for @emergencyResponse.
  ///
  /// In ru, this message translates to:
  /// **'Аварийный наряд — требуется ответ'**
  String get emergencyResponse;

  /// No description provided for @newOrderAssigned.
  ///
  /// In ru, this message translates to:
  /// **'Вам назначен новый наряд'**
  String get newOrderAssigned;

  /// No description provided for @returnedForRework.
  ///
  /// In ru, this message translates to:
  /// **'Наряд возвращён на доработку'**
  String get returnedForRework;

  /// No description provided for @masterClosedOrder.
  ///
  /// In ru, this message translates to:
  /// **'Мастер закрыл наряд'**
  String get masterClosedOrder;

  /// No description provided for @deadlineExpired.
  ///
  /// In ru, this message translates to:
  /// **'Срок выполнения истёк'**
  String get deadlineExpired;

  /// No description provided for @noExecutorNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомлений пока нет'**
  String get noExecutorNotifications;

  /// No description provided for @rejectReason.
  ///
  /// In ru, this message translates to:
  /// **'Причина отказа'**
  String get rejectReason;

  /// No description provided for @pauseReason.
  ///
  /// In ru, this message translates to:
  /// **'Причина приостановки'**
  String get pauseReason;

  /// No description provided for @savedReasonNotSent.
  ///
  /// In ru, this message translates to:
  /// **'Исправленная причина сохранена на телефоне, но не отправлена. Сервер принял предыдущую версию.'**
  String get savedReasonNotSent;

  /// No description provided for @orderReassignedWarning.
  ///
  /// In ru, this message translates to:
  /// **'Наряд переназначен другому исполнителю.'**
  String get orderReassignedWarning;

  /// No description provided for @acceptWork.
  ///
  /// In ru, this message translates to:
  /// **'Принять в работу'**
  String get acceptWork;

  /// No description provided for @queueOrder.
  ///
  /// In ru, this message translates to:
  /// **'Поставить в очередь'**
  String get queueOrder;

  /// No description provided for @rejectOrder.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get rejectOrder;

  /// No description provided for @resumeWork.
  ///
  /// In ru, this message translates to:
  /// **'Возобновить работу'**
  String get resumeWork;

  /// No description provided for @startExecution.
  ///
  /// In ru, this message translates to:
  /// **'Начать исполнение'**
  String get startExecution;

  /// No description provided for @pauseWork.
  ///
  /// In ru, this message translates to:
  /// **'Приостановить'**
  String get pauseWork;

  /// No description provided for @workDone.
  ///
  /// In ru, this message translates to:
  /// **'Исполнено'**
  String get workDone;

  /// No description provided for @executionDeadline.
  ///
  /// In ru, this message translates to:
  /// **'Срок выполнения'**
  String get executionDeadline;

  /// No description provided for @faultDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание неисправности'**
  String get faultDescription;

  /// No description provided for @photosBeforeWork.
  ///
  /// In ru, this message translates to:
  /// **'Фото до начала работ'**
  String get photosBeforeWork;

  /// No description provided for @masterNoPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Мастер не добавил фотографии'**
  String get masterNoPhotos;

  /// No description provided for @masterScorePending.
  ///
  /// In ru, this message translates to:
  /// **'Оценка мастера пока не выставлена'**
  String get masterScorePending;

  /// No description provided for @assessmentPending.
  ///
  /// In ru, this message translates to:
  /// **'Заключение по выполнению пока не получено.'**
  String get assessmentPending;

  /// No description provided for @reportAwaitingMaster.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт отправлен. Ожидает проверки мастером.'**
  String get reportAwaitingMaster;

  /// No description provided for @askMasterRemarks.
  ///
  /// In ru, this message translates to:
  /// **'Уточните замечания у мастера'**
  String get askMasterRemarks;

  /// No description provided for @yourReport.
  ///
  /// In ru, this message translates to:
  /// **'Ваш отчёт'**
  String get yourReport;

  /// No description provided for @workNotSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Работы не указаны'**
  String get workNotSpecified;

  /// No description provided for @photosAfter.
  ///
  /// In ru, this message translates to:
  /// **'Фото после'**
  String get photosAfter;

  /// No description provided for @goToRework.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к доработке'**
  String get goToRework;

  /// No description provided for @openOrder.
  ///
  /// In ru, this message translates to:
  /// **'Открыть наряд'**
  String get openOrder;

  /// No description provided for @addPhotoFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить фото. Проверьте разрешения.'**
  String get addPhotoFailed;

  /// No description provided for @unplannedPhotoRequired.
  ///
  /// In ru, this message translates to:
  /// **'Для внепланового наряда нужно фото после'**
  String get unplannedPhotoRequired;

  /// No description provided for @commitSelectedMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте выбранный материал в список'**
  String get commitSelectedMaterial;

  /// No description provided for @material.
  ///
  /// In ru, this message translates to:
  /// **'Материал'**
  String get material;

  /// No description provided for @selectMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Выберите материал'**
  String get selectMaterial;

  /// No description provided for @quantity.
  ///
  /// In ru, this message translates to:
  /// **'Количество'**
  String get quantity;

  /// No description provided for @positiveQuantity.
  ///
  /// In ru, this message translates to:
  /// **'Введите количество больше нуля'**
  String get positiveQuantity;

  /// No description provided for @addMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Добавить материал'**
  String get addMaterial;

  /// No description provided for @sending.
  ///
  /// In ru, this message translates to:
  /// **'Отправка…'**
  String get sending;

  /// No description provided for @submitForReview.
  ///
  /// In ru, this message translates to:
  /// **'Отправить на проверку'**
  String get submitForReview;

  /// No description provided for @materialsAndCode.
  ///
  /// In ru, this message translates to:
  /// **'Материалы и код'**
  String get materialsAndCode;

  /// No description provided for @photosAndComment.
  ///
  /// In ru, this message translates to:
  /// **'Фото и комментарий'**
  String get photosAndComment;

  /// No description provided for @whatWasDone.
  ///
  /// In ru, this message translates to:
  /// **'Что было сделано?'**
  String get whatWasDone;

  /// No description provided for @describeCompletedWork.
  ///
  /// In ru, this message translates to:
  /// **'Опишите выполненные работы'**
  String get describeCompletedWork;

  /// No description provided for @faultCodeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Код неисправности'**
  String get faultCodeLabel;

  /// No description provided for @selectCode.
  ///
  /// In ru, this message translates to:
  /// **'Выберите код'**
  String get selectCode;

  /// No description provided for @selectFaultCode.
  ///
  /// In ru, this message translates to:
  /// **'Выберите шифр'**
  String get selectFaultCode;

  /// No description provided for @usedExecutorMaterials.
  ///
  /// In ru, this message translates to:
  /// **'Использованные материалы'**
  String get usedExecutorMaterials;

  /// No description provided for @noMaterialsUsed.
  ///
  /// In ru, this message translates to:
  /// **'Материалы не использовались'**
  String get noMaterialsUsed;

  /// No description provided for @decrease.
  ///
  /// In ru, this message translates to:
  /// **'Уменьшить'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In ru, this message translates to:
  /// **'Увеличить'**
  String get increase;

  /// No description provided for @photosAfterWork.
  ///
  /// In ru, this message translates to:
  /// **'Фото после выполнения работ'**
  String get photosAfterWork;

  /// No description provided for @removePhotoLabel.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get removePhotoLabel;

  /// No description provided for @takeAfterPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Сделать фото после'**
  String get takeAfterPhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать из галереи'**
  String get chooseFromGallery;

  /// No description provided for @photoLimitReached.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено 5 из 5 фото. Удалите фото, чтобы добавить новое.'**
  String get photoLimitReached;

  /// No description provided for @optionalComment.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий (необязательно)'**
  String get optionalComment;

  /// No description provided for @additionalInformation.
  ///
  /// In ru, this message translates to:
  /// **'Дополнительная информация'**
  String get additionalInformation;

  /// No description provided for @changeStatusFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось изменить статус. Повторите попытку.'**
  String get changeStatusFailed;

  /// No description provided for @submitReportFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить отчёт. Повторите попытку.'**
  String get submitReportFailed;

  /// No description provided for @orderIssuedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Наряд выдан'**
  String get orderIssuedLabel;

  /// No description provided for @mechanicSpecialty.
  ///
  /// In ru, this message translates to:
  /// **'Слесарь'**
  String get mechanicSpecialty;

  /// No description provided for @electricianSpecialty.
  ///
  /// In ru, this message translates to:
  /// **'Электрик'**
  String get electricianSpecialty;

  /// No description provided for @welderSpecialty.
  ///
  /// In ru, this message translates to:
  /// **'Сварщик'**
  String get welderSpecialty;

  /// No description provided for @crushingArea.
  ///
  /// In ru, this message translates to:
  /// **'Дробление'**
  String get crushingArea;

  /// No description provided for @beneficiationArea.
  ///
  /// In ru, this message translates to:
  /// **'Обогащение'**
  String get beneficiationArea;

  /// No description provided for @repairArea.
  ///
  /// In ru, this message translates to:
  /// **'Ремонтный цех'**
  String get repairArea;

  /// No description provided for @transportArea.
  ///
  /// In ru, this message translates to:
  /// **'Транспортный участок'**
  String get transportArea;

  /// No description provided for @bearingMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Подшипник · шт'**
  String get bearingMaterial;

  /// No description provided for @sealMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Уплотнение · шт'**
  String get sealMaterial;

  /// No description provided for @cableMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Кабель · м'**
  String get cableMaterial;

  /// No description provided for @oilMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Масло · л'**
  String get oilMaterial;

  /// No description provided for @greaseMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Смазка · кг'**
  String get greaseMaterial;

  /// No description provided for @anomalyExample.
  ///
  /// In ru, this message translates to:
  /// **'Пример вывода: конвейер К-3 часто останавливается из-за подшипников. Рекомендация: проверить соосность привода и скорректировать план ППР.'**
  String get anomalyExample;

  /// No description provided for @closeOrderNumber.
  ///
  /// In ru, this message translates to:
  /// **'Закрытие наряда №{number}'**
  String closeOrderNumber(String number);

  /// No description provided for @resultOrderNumber.
  ///
  /// In ru, this message translates to:
  /// **'Результат · №{number}'**
  String resultOrderNumber(String number);

  /// No description provided for @deadlineMinutesLeft.
  ///
  /// In ru, this message translates to:
  /// **'До срока осталось {minutes} мин'**
  String deadlineMinutesLeft(String minutes);

  /// No description provided for @workTimeValue.
  ///
  /// In ru, this message translates to:
  /// **'Время в работе: {time}'**
  String workTimeValue(String time);

  /// No description provided for @workMinutesValue.
  ///
  /// In ru, this message translates to:
  /// **'Время в работе: {minutes} мин'**
  String workMinutesValue(String minutes);

  /// No description provided for @historyWorkMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин в работе'**
  String historyWorkMinutes(String minutes);

  /// No description provided for @priorityValue.
  ///
  /// In ru, this message translates to:
  /// **'Приоритет: {priority}'**
  String priorityValue(String priority);

  /// No description provided for @assessmentVerdict.
  ///
  /// In ru, this message translates to:
  /// **'Проверка: {verdict}'**
  String assessmentVerdict(String verdict);

  /// No description provided for @assessmentScore.
  ///
  /// In ru, this message translates to:
  /// **'Оценка: {score} / 5'**
  String assessmentScore(String score);

  /// No description provided for @assessmentStrengths.
  ///
  /// In ru, this message translates to:
  /// **'Что сделано хорошо: {text}'**
  String assessmentStrengths(String text);

  /// No description provided for @assessmentImprovements.
  ///
  /// In ru, this message translates to:
  /// **'Что улучшить: {text}'**
  String assessmentImprovements(String text);

  /// No description provided for @normHoursValue.
  ///
  /// In ru, this message translates to:
  /// **'Норматив: {hours} ч'**
  String normHoursValue(String hours);

  /// No description provided for @reworkReasonValue.
  ///
  /// In ru, this message translates to:
  /// **'Доработка: {reason}'**
  String reworkReasonValue(String reason);

  /// No description provided for @faultCodeValue.
  ///
  /// In ru, this message translates to:
  /// **'Шифр: {code}'**
  String faultCodeValue(String code);

  /// No description provided for @previousMaterialsValue.
  ///
  /// In ru, this message translates to:
  /// **'Ранее указанные материалы:\n{materials}'**
  String previousMaterialsValue(String materials);

  /// No description provided for @brigadeNumber.
  ///
  /// In ru, this message translates to:
  /// **'Бригада №{number}'**
  String brigadeNumber(String number);

  /// No description provided for @faultBearing.
  ///
  /// In ru, this message translates to:
  /// **'М-02 · Подшипник'**
  String get faultBearing;

  /// No description provided for @faultOilLeak.
  ///
  /// In ru, this message translates to:
  /// **'Г-01 · Течь масла'**
  String get faultOilLeak;

  /// No description provided for @faultCableBreak.
  ///
  /// In ru, this message translates to:
  /// **'Э-03 · Обрыв кабеля'**
  String get faultCableBreak;

  /// No description provided for @faultGreaseLack.
  ///
  /// In ru, this message translates to:
  /// **'С-01 · Недостаток смазки'**
  String get faultGreaseLack;

  /// No description provided for @faultAirLeak.
  ///
  /// In ru, this message translates to:
  /// **'П-02 · Утечка воздуха'**
  String get faultAirLeak;

  /// No description provided for @crusherEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Дробилка КМД-1750'**
  String get crusherEquipment;

  /// No description provided for @conveyorEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Конвейер К-3'**
  String get conveyorEquipment;

  /// No description provided for @screenEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Грохот ГИС-52'**
  String get screenEquipment;

  /// No description provided for @pumpEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Насос Н-12'**
  String get pumpEquipment;

  /// No description provided for @millEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Мельница МШР-3'**
  String get millEquipment;

  /// No description provided for @separatorEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Сепаратор С-4'**
  String get separatorEquipment;

  /// No description provided for @machineEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Станок Т-16'**
  String get machineEquipment;

  /// No description provided for @craneEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Кран-балка КБ-2'**
  String get craneEquipment;

  /// No description provided for @loaderEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Погрузчик П-7'**
  String get loaderEquipment;

  /// No description provided for @compressorEquipment.
  ///
  /// In ru, this message translates to:
  /// **'Компрессор ВК-22'**
  String get compressorEquipment;

  /// No description provided for @demoBearingWork.
  ///
  /// In ru, this message translates to:
  /// **'Замена подшипника привода'**
  String get demoBearingWork;

  /// No description provided for @demoOilLeakWork.
  ///
  /// In ru, this message translates to:
  /// **'Устранение течи масла'**
  String get demoOilLeakWork;

  /// No description provided for @demoPowerWork.
  ///
  /// In ru, this message translates to:
  /// **'Проверка питания двигателя'**
  String get demoPowerWork;

  /// No description provided for @demoLubricationWork.
  ///
  /// In ru, this message translates to:
  /// **'Плановая смазка узлов'**
  String get demoLubricationWork;

  /// No description provided for @demoSealWork.
  ///
  /// In ru, this message translates to:
  /// **'Замена уплотнения вала'**
  String get demoSealWork;

  /// No description provided for @demoGuardWork.
  ///
  /// In ru, this message translates to:
  /// **'Восстановление защитного кожуха'**
  String get demoGuardWork;

  /// No description provided for @demoLubricationCheckWork.
  ///
  /// In ru, this message translates to:
  /// **'Плановая смазка и проверка узлов'**
  String get demoLubricationCheckWork;

  /// No description provided for @demoOrderDescription.
  ///
  /// In ru, this message translates to:
  /// **'Проверить состояние оборудования, устранить неисправность и выполнить контрольный запуск.'**
  String get demoOrderDescription;

  /// No description provided for @demoSealReport.
  ///
  /// In ru, this message translates to:
  /// **'Заменено уплотнение. Соединения проверены. При контрольном запуске течь отсутствует.'**
  String get demoSealReport;

  /// No description provided for @demoBearingReport.
  ///
  /// In ru, this message translates to:
  /// **'Подшипник заменён. Проверены крепления и выполнен контрольный запуск. Посторонний шум устранён.'**
  String get demoBearingReport;

  /// No description provided for @demoLubricationReport.
  ///
  /// In ru, this message translates to:
  /// **'Выполнена смазка узлов. Проверены крепления и работа оборудования под нагрузкой.'**
  String get demoLubricationReport;

  /// No description provided for @demoWaitingBearing.
  ///
  /// In ru, this message translates to:
  /// **'Ждём подшипник со склада'**
  String get demoWaitingBearing;

  /// No description provided for @demoSealMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Уплотнение 40×60 — 1 шт.'**
  String get demoSealMaterial;

  /// No description provided for @demoOilMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Масло И-40 — 0,5 л'**
  String get demoOilMaterial;

  /// No description provided for @demoBearingMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Подшипник — 1 шт.'**
  String get demoBearingMaterial;

  /// No description provided for @demoGreaseSmall.
  ///
  /// In ru, this message translates to:
  /// **'Смазка — 0,2 кг'**
  String get demoGreaseSmall;

  /// No description provided for @demoGreaseHalf.
  ///
  /// In ru, this message translates to:
  /// **'Смазка — 0,5 кг'**
  String get demoGreaseHalf;

  /// No description provided for @awaitingCheck.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает проверки'**
  String get awaitingCheck;

  /// No description provided for @reportAiPending.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт отправлен. Проверка ИИ ещё не выполнена.'**
  String get reportAiPending;

  /// No description provided for @masterDemoAnswer.
  ///
  /// In ru, this message translates to:
  /// **'Демо-ответ: здесь появятся рекомендации по запросу «{query}». Для анализа необходимо подключить backend и ИИ.'**
  String masterDemoAnswer(String query);

  /// No description provided for @queuePosition.
  ///
  /// In ru, this message translates to:
  /// **'В очереди · позиция {position}'**
  String queuePosition(String position);

  /// No description provided for @finishCurrentFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала приостановите или завершите текущий наряд'**
  String get finishCurrentFirst;

  /// No description provided for @wholePieceQuantity.
  ///
  /// In ru, this message translates to:
  /// **'Для штучного материала укажите целое количество'**
  String get wholePieceQuantity;

  /// No description provided for @removeMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Удалить материал'**
  String get removeMaterial;

  /// No description provided for @removeMaterialQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Удалить материал из отчёта?'**
  String get removeMaterialQuestion;

  /// No description provided for @draftSaved.
  ///
  /// In ru, this message translates to:
  /// **'Черновик сохранён'**
  String get draftSaved;

  /// No description provided for @draftLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось восстановить черновик. Повторите попытку — сохранённые данные не изменены.'**
  String get draftLoadFailed;

  /// No description provided for @draftSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Черновик не сохранён. Нажмите, чтобы повторить.'**
  String get draftSaveFailed;

  /// No description provided for @discardOrderDraftTitle.
  ///
  /// In ru, this message translates to:
  /// **'Начать без черновика?'**
  String get discardOrderDraftTitle;

  /// No description provided for @discardOrderDraftMessage.
  ///
  /// In ru, this message translates to:
  /// **'Удалить сохранённый черновик и открыть пустую форму? Текст, настройки и фотографии черновика будут потеряны.'**
  String get discardOrderDraftMessage;

  /// No description provided for @discardOrderDraftAction.
  ///
  /// In ru, this message translates to:
  /// **'Удалить черновик'**
  String get discardOrderDraftAction;

  /// No description provided for @orderDraftDiscardFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить черновик. Сохранённые данные не изменены. Повторите попытку.'**
  String get orderDraftDiscardFailed;

  /// No description provided for @orderDraftChangedBeforeDiscard.
  ///
  /// In ru, this message translates to:
  /// **'Черновик изменился в другой форме. Нажмите «Повторить», чтобы загрузить актуальные данные.'**
  String get orderDraftChangedBeforeDiscard;

  /// No description provided for @overdueByMinutes.
  ///
  /// In ru, this message translates to:
  /// **'Просрочен на {minutes} мин'**
  String overdueByMinutes(String minutes);

  /// No description provided for @executionResult.
  ///
  /// In ru, this message translates to:
  /// **'Результат проверки'**
  String get executionResult;

  /// No description provided for @authLoginLabel.
  ///
  /// In ru, this message translates to:
  /// **'Логин'**
  String get authLoginLabel;

  /// No description provided for @authPinLabel.
  ///
  /// In ru, this message translates to:
  /// **'ПИН'**
  String get authPinLabel;

  /// No description provided for @authEnterLogin.
  ///
  /// In ru, this message translates to:
  /// **'Введите логин'**
  String get authEnterLogin;

  /// No description provided for @authPinLength.
  ///
  /// In ru, this message translates to:
  /// **'ПИН должен содержать от 4 до 12 символов'**
  String get authPinLength;

  /// No description provided for @authSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона и пароль.'**
  String get authSubtitle;

  /// No description provided for @authAccountHint.
  ///
  /// In ru, this message translates to:
  /// **'Учётную запись выдаёт администратор.'**
  String get authAccountHint;

  /// No description provided for @authNetworkError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подключиться. Проверьте связь и повторите.'**
  String get authNetworkError;

  /// No description provided for @authMobileRole.
  ///
  /// In ru, this message translates to:
  /// **'Эта роль доступна в веб-панели.'**
  String get authMobileRole;

  /// No description provided for @authRetryMinutes.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток. Повторите через {minutes} мин.'**
  String authRetryMinutes(String minutes);

  /// No description provided for @authRateLimited.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток. Повторите позже.'**
  String get authRateLimited;

  /// No description provided for @demoDataNotice.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрационные данные'**
  String get demoDataNotice;

  /// No description provided for @authInvalidPhone.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер от 10 до 15 цифр'**
  String get authInvalidPhone;

  /// No description provided for @changePasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Смена пароля'**
  String get changePasswordTitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Текущий пароль'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordLength.
  ///
  /// In ru, this message translates to:
  /// **'Пароль должен содержать от 6 до 128 символов'**
  String get newPasswordLength;

  /// No description provided for @passwordChanged.
  ///
  /// In ru, this message translates to:
  /// **'Пароль изменён'**
  String get passwordChanged;

  /// No description provided for @changePasswordButton.
  ///
  /// In ru, this message translates to:
  /// **'Изменить пароль'**
  String get changePasswordButton;

  /// No description provided for @passwordResetHint.
  ///
  /// In ru, this message translates to:
  /// **'Забытый пароль сбрасывает администратор.'**
  String get passwordResetHint;

  /// No description provided for @statusAiChecking.
  ///
  /// In ru, this message translates to:
  /// **'Выполнен · идёт AI-проверка'**
  String get statusAiChecking;

  /// No description provided for @statusMasterReview.
  ///
  /// In ru, this message translates to:
  /// **'На проверке у мастера'**
  String get statusMasterReview;

  /// No description provided for @checkingReport.
  ///
  /// In ru, this message translates to:
  /// **'Проверяем отчёт…'**
  String get checkingReport;

  /// No description provided for @orderUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Наряд недоступен'**
  String get orderUnavailable;

  /// No description provided for @photoTooLarge.
  ///
  /// In ru, this message translates to:
  /// **'Фото должно быть не больше 15 МБ.'**
  String get photoTooLarge;

  /// No description provided for @photoCaptureHint.
  ///
  /// In ru, this message translates to:
  /// **'Снимайте «до» и «после» с одной точки, чтобы результат ремонта был виден. До 5 фото, каждое не больше 15 МБ.'**
  String get photoCaptureHint;

  /// No description provided for @reassignOrderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Переназначить наряд'**
  String get reassignOrderTitle;

  /// No description provided for @reassignOrderQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Переназначить наряд?'**
  String get reassignOrderQuestion;

  /// No description provided for @reassignOrderExplanation.
  ///
  /// In ru, this message translates to:
  /// **'После переназначения наряд вернётся в статус «Выдан». Новый исполнитель получит уведомление.'**
  String get reassignOrderExplanation;

  /// No description provided for @orderCancelledMessage.
  ///
  /// In ru, this message translates to:
  /// **'Наряд отменён'**
  String get orderCancelledMessage;

  /// No description provided for @orderReworkMessage.
  ///
  /// In ru, this message translates to:
  /// **'Наряд отправлен на доработку'**
  String get orderReworkMessage;

  /// No description provided for @orderClosedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Наряд закрыт'**
  String get orderClosedMessage;

  /// No description provided for @orderUpdatedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Наряд обновлён'**
  String get orderUpdatedMessage;

  /// No description provided for @closeActionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get closeActionLabel;

  /// No description provided for @orderNotFoundMessage.
  ///
  /// In ru, this message translates to:
  /// **'Наряд не найден'**
  String get orderNotFoundMessage;

  /// No description provided for @notYourOrderMessage.
  ///
  /// In ru, this message translates to:
  /// **'Это не ваш наряд'**
  String get notYourOrderMessage;

  /// No description provided for @aiWorkCheckTitle.
  ///
  /// In ru, this message translates to:
  /// **'ИИ-проверка выполнения'**
  String get aiWorkCheckTitle;

  /// No description provided for @workStrengthsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что выполнено хорошо'**
  String get workStrengthsTitle;

  /// No description provided for @acceptWorkAction.
  ///
  /// In ru, this message translates to:
  /// **'Принять работу'**
  String get acceptWorkAction;

  /// No description provided for @closeWorkOrderAction.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть наряд'**
  String get closeWorkOrderAction;

  /// No description provided for @orderAcceptedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Наряд принят'**
  String get orderAcceptedMessage;

  /// No description provided for @orderRejectedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Наряд отклонён'**
  String get orderRejectedMessage;

  /// No description provided for @workStartedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Работа начата'**
  String get workStartedMessage;

  /// No description provided for @workPausedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Работа приостановлена'**
  String get workPausedMessage;

  /// No description provided for @workCompletedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Работа выполнена'**
  String get workCompletedMessage;

  /// No description provided for @chooseEquipmentFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала выберите оборудование.'**
  String get chooseEquipmentFirst;

  /// No description provided for @describeFaultFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала опишите неисправность.'**
  String get describeFaultFirst;

  /// No description provided for @recommendationAppliedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендация применена.'**
  String get recommendationAppliedMessage;

  /// No description provided for @photoSelectionFailedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выбрать фотографию.'**
  String get photoSelectionFailedMessage;

  /// No description provided for @chooseAreaValidation.
  ///
  /// In ru, this message translates to:
  /// **'Выберите участок.'**
  String get chooseAreaValidation;

  /// No description provided for @chooseEquipmentValidation.
  ///
  /// In ru, this message translates to:
  /// **'Выберите оборудование.'**
  String get chooseEquipmentValidation;

  /// No description provided for @chooseExecutorValidation.
  ///
  /// In ru, this message translates to:
  /// **'Выберите исполнителя.'**
  String get chooseExecutorValidation;

  /// No description provided for @chooseNormativeValidation.
  ///
  /// In ru, this message translates to:
  /// **'Выберите норматив.'**
  String get chooseNormativeValidation;

  /// No description provided for @creatingOrderLabel.
  ///
  /// In ru, this message translates to:
  /// **'Создание...'**
  String get creatingOrderLabel;

  /// No description provided for @voiceNextStageMessage.
  ///
  /// In ru, this message translates to:
  /// **'Голосовой ввод подключим следующим этапом.'**
  String get voiceNextStageMessage;

  /// No description provided for @descriptionMinimumLabel.
  ///
  /// In ru, this message translates to:
  /// **'Описание — минимум 3 символа'**
  String get descriptionMinimumLabel;

  /// No description provided for @getAiRecommendationLabel.
  ///
  /// In ru, this message translates to:
  /// **'Получить AI-рекомендацию'**
  String get getAiRecommendationLabel;

  /// No description provided for @chooseAreaLabel.
  ///
  /// In ru, this message translates to:
  /// **'Выберите участок'**
  String get chooseAreaLabel;

  /// No description provided for @estimatedTimeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Оценка времени'**
  String get estimatedTimeLabel;

  /// No description provided for @queueLabel.
  ///
  /// In ru, this message translates to:
  /// **'Очередь'**
  String get queueLabel;

  /// No description provided for @ratingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг'**
  String get ratingLabel;

  /// No description provided for @confidenceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Уверенность'**
  String get confidenceLabel;

  /// No description provided for @aiScoreLabel.
  ///
  /// In ru, this message translates to:
  /// **'Оценка ИИ'**
  String get aiScoreLabel;

  /// No description provided for @orderStatusChangedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Статус наряда изменился. Обновите данные'**
  String get orderStatusChangedMessage;

  /// No description provided for @orderNotWorkingMessage.
  ///
  /// In ru, this message translates to:
  /// **'Наряд уже не в работе'**
  String get orderNotWorkingMessage;

  /// No description provided for @workAndFaultRequiredMessage.
  ///
  /// In ru, this message translates to:
  /// **'Заполните работы и шифр неисправности'**
  String get workAndFaultRequiredMessage;

  /// No description provided for @checkMaterialsPhotosMessage.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте материалы и фотографии'**
  String get checkMaterialsPhotosMessage;

  /// No description provided for @orderFinishedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Наряд завершён'**
  String get orderFinishedMessage;

  /// No description provided for @mockSealMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Уплотнение 40×60'**
  String get mockSealMaterial;

  /// No description provided for @mockOilMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Масло И-40'**
  String get mockOilMaterial;

  /// No description provided for @mockBearingShort.
  ///
  /// In ru, this message translates to:
  /// **'Подшипник'**
  String get mockBearingShort;

  /// No description provided for @mockLubricantShort.
  ///
  /// In ru, this message translates to:
  /// **'Смазка'**
  String get mockLubricantShort;

  /// No description provided for @mockMasterReworkReason.
  ///
  /// In ru, this message translates to:
  /// **'Нет фото после выполненных работ'**
  String get mockMasterReworkReason;

  /// No description provided for @pieceUnit.
  ///
  /// In ru, this message translates to:
  /// **'шт.'**
  String get pieceUnit;

  /// No description provided for @hourUnit.
  ///
  /// In ru, this message translates to:
  /// **'ч.'**
  String get hourUnit;

  /// No description provided for @piecesShortUnit.
  ///
  /// In ru, this message translates to:
  /// **'шт'**
  String get piecesShortUnit;

  /// No description provided for @meterUnit.
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get meterUnit;

  /// No description provided for @kilogramUnit.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get kilogramUnit;

  /// No description provided for @literUnit.
  ///
  /// In ru, this message translates to:
  /// **'л'**
  String get literUnit;

  /// No description provided for @executorCurrentOrderQueue.
  ///
  /// In ru, this message translates to:
  /// **'выполняет наряд №{number}, в очереди {count}'**
  String executorCurrentOrderQueue(String number, String count);

  /// No description provided for @executorQueuedOrders.
  ///
  /// In ru, this message translates to:
  /// **'в очереди {count} наряда'**
  String executorQueuedOrders(String count);

  /// No description provided for @aiVerdictAcceptedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Принято'**
  String get aiVerdictAcceptedLabel;

  /// No description provided for @aiVerdictCommentsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Принято с замечаниями'**
  String get aiVerdictCommentsLabel;

  /// No description provided for @aiVerdictReworkLabel.
  ///
  /// In ru, this message translates to:
  /// **'Требуется доработка'**
  String get aiVerdictReworkLabel;

  /// No description provided for @historyMonthSummary.
  ///
  /// In ru, this message translates to:
  /// **'За 30 дней'**
  String get historyMonthSummary;

  /// No description provided for @historyAverageScore.
  ///
  /// In ru, this message translates to:
  /// **'Средняя оценка'**
  String get historyAverageScore;

  /// No description provided for @historyEarlier.
  ///
  /// In ru, this message translates to:
  /// **'Ранее'**
  String get historyEarlier;

  /// No description provided for @ratingCalculation.
  ///
  /// In ru, this message translates to:
  /// **'Как считается рейтинг'**
  String get ratingCalculation;

  /// No description provided for @ratingOnTimeOrders.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено в срок'**
  String get ratingOnTimeOrders;

  /// No description provided for @ratingReworkedOrders.
  ///
  /// In ru, this message translates to:
  /// **'Вернулись на доработку'**
  String get ratingReworkedOrders;

  /// No description provided for @ratingQualityExplanation.
  ///
  /// In ru, this message translates to:
  /// **'Средняя оценка ваших работ — {quality} из 5. Баллы за качество: {points} из 45.'**
  String ratingQualityExplanation(String quality, String points);

  /// No description provided for @ratingTimingExplanation.
  ///
  /// In ru, this message translates to:
  /// **'В срок выполнено {percent}% нарядов. Баллы за соблюдение сроков: {points} из 25.'**
  String ratingTimingExplanation(String percent, String points);

  /// No description provided for @ratingReliability.
  ///
  /// In ru, this message translates to:
  /// **'Надёжность ремонта'**
  String get ratingReliability;

  /// No description provided for @ratingReliabilityExplanation.
  ///
  /// In ru, this message translates to:
  /// **'{percent}% нарядов обошлись без доработок и повторных поломок в течение 7 дней. Баллы за надёжность ремонта: {points} из 15.'**
  String ratingReliabilityExplanation(String percent, String points);

  /// No description provided for @ratingVolumeExplanation.
  ///
  /// In ru, this message translates to:
  /// **'Вы закрыли {count} нарядов. Баллы за объём работы: {points} из 10.'**
  String ratingVolumeExplanation(String count, String points);

  /// No description provided for @ratingComplexity.
  ///
  /// In ru, this message translates to:
  /// **'Сложные работы'**
  String get ratingComplexity;

  /// No description provided for @ratingComplexityExplanation.
  ///
  /// In ru, this message translates to:
  /// **'За аварийные наряды и наряды с высоким приоритетом начислено ещё {points} из 5 баллов.'**
  String ratingComplexityExplanation(String points);

  /// No description provided for @ratingRejects.
  ///
  /// In ru, this message translates to:
  /// **'Необоснованные отказы'**
  String get ratingRejects;

  /// No description provided for @ratingRejectsExplanation.
  ///
  /// In ru, this message translates to:
  /// **'Отказов без уважительной причины: {count}. За них снято {points} баллов.'**
  String ratingRejectsExplanation(String count, String points);

  /// No description provided for @profileSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get profileSettings;

  /// No description provided for @completedShort.
  ///
  /// In ru, this message translates to:
  /// **'Завершено'**
  String get completedShort;

  /// No description provided for @orderSingular.
  ///
  /// In ru, this message translates to:
  /// **'Наряд'**
  String get orderSingular;

  /// No description provided for @noOrders.
  ///
  /// In ru, this message translates to:
  /// **'Нет нарядов'**
  String get noOrders;

  /// No description provided for @noScore.
  ///
  /// In ru, this message translates to:
  /// **'Нет оценки'**
  String get noScore;

  /// No description provided for @pushOrderOpenFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть наряд'**
  String get pushOrderOpenFailed;

  /// No description provided for @companyName.
  ///
  /// In ru, this message translates to:
  /// **'Костанайские минералы'**
  String get companyName;

  /// No description provided for @emergencyNotificationChannel.
  ///
  /// In ru, this message translates to:
  /// **'Аварийные наряды'**
  String get emergencyNotificationChannel;

  /// No description provided for @emergencyNotificationDescription.
  ///
  /// In ru, this message translates to:
  /// **'Новые аварийные наряды, требующие ответа'**
  String get emergencyNotificationDescription;

  /// No description provided for @offlineActionSaved.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено на телефоне. Ожидает отправки.'**
  String get offlineActionSaved;

  /// No description provided for @actionUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Действие недоступно из текущего статуса'**
  String get actionUnavailable;

  /// No description provided for @executorActionUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Недоступное действие исполнителя'**
  String get executorActionUnavailable;

  /// No description provided for @executionFieldsRequired.
  ///
  /// In ru, this message translates to:
  /// **'Заполните выполненные работы и шифр'**
  String get executionFieldsRequired;

  /// No description provided for @afterPhotosInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте фото после работ'**
  String get afterPhotosInvalid;

  /// No description provided for @materialsFromCatalogRequired.
  ///
  /// In ru, this message translates to:
  /// **'Выберите материалы из справочника'**
  String get materialsFromCatalogRequired;

  /// No description provided for @materialsInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте материалы'**
  String get materialsInvalid;

  /// No description provided for @employeeGradeOnly.
  ///
  /// In ru, this message translates to:
  /// **'{grade} разряд'**
  String employeeGradeOnly(String grade);

  /// No description provided for @shortOrderCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} нар.'**
  String shortOrderCount(String count);

  /// No description provided for @offlineActionNotApplied.
  ///
  /// In ru, this message translates to:
  /// **'Действие не применено: {reason}'**
  String offlineActionNotApplied(String reason);

  /// No description provided for @ratingPeriodLabel.
  ///
  /// In ru, this message translates to:
  /// **'Период рейтинга'**
  String get ratingPeriodLabel;

  /// No description provided for @ratingPeriodShift.
  ///
  /// In ru, this message translates to:
  /// **'За смену · 12 часов'**
  String get ratingPeriodShift;

  /// No description provided for @ratingPeriodDay.
  ///
  /// In ru, this message translates to:
  /// **'За сутки'**
  String get ratingPeriodDay;

  /// No description provided for @ratingPeriodWeek.
  ///
  /// In ru, this message translates to:
  /// **'За неделю'**
  String get ratingPeriodWeek;

  /// No description provided for @ratingPeriodMonth.
  ///
  /// In ru, this message translates to:
  /// **'За 30 дней'**
  String get ratingPeriodMonth;

  /// No description provided for @ratingPeriodCustom.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать даты'**
  String get ratingPeriodCustom;

  /// No description provided for @oilContaminationFault.
  ///
  /// In ru, this message translates to:
  /// **'Загрязнение масла'**
  String get oilContaminationFault;

  /// No description provided for @industrialOilMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Масло индустриальное И-40А'**
  String get industrialOilMaterial;

  /// No description provided for @oilFilterMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр масляный'**
  String get oilFilterMaterial;

  /// No description provided for @appSlogan.
  ///
  /// In ru, this message translates to:
  /// **'Наряд выдан — ИИ на контроле'**
  String get appSlogan;

  /// No description provided for @pinCreateTitle.
  ///
  /// In ru, this message translates to:
  /// **'Создайте ПИН-код'**
  String get pinCreateTitle;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Повторите ПИН-код'**
  String get pinConfirmTitle;

  /// No description provided for @pinEnterTitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите ПИН-код'**
  String get pinEnterTitle;

  /// No description provided for @pinCreateHint.
  ///
  /// In ru, this message translates to:
  /// **'Придумайте 4 цифры для входа в приложение'**
  String get pinCreateHint;

  /// No description provided for @pinUnlockHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите 4 цифры, чтобы открыть приложение'**
  String get pinUnlockHint;

  /// No description provided for @pinMismatch.
  ///
  /// In ru, this message translates to:
  /// **'ПИН-коды не совпадают. Повторите ввод'**
  String get pinMismatch;

  /// No description provided for @pinConfirmHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите придуманный ПИН-код ещё раз'**
  String get pinConfirmHint;

  /// No description provided for @pinChange.
  ///
  /// In ru, this message translates to:
  /// **'Изменить код'**
  String get pinChange;

  /// No description provided for @pinIncorrect.
  ///
  /// In ru, this message translates to:
  /// **'Неверный ПИН-код'**
  String get pinIncorrect;

  /// No description provided for @pinStorageError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть хранилище ПИН-кода. Повторите попытку или войдите с паролем'**
  String get pinStorageError;

  /// No description provided for @pinForgot.
  ///
  /// In ru, this message translates to:
  /// **'Забыли ПИН-код?'**
  String get pinForgot;

  /// No description provided for @pinUseAnotherAccount.
  ///
  /// In ru, this message translates to:
  /// **'Войти в другой аккаунт'**
  String get pinUseAnotherAccount;

  /// No description provided for @pinResetHint.
  ///
  /// In ru, this message translates to:
  /// **'Для создания нового ПИН-кода потребуется вход с паролем'**
  String get pinResetHint;

  /// No description provided for @pinDeleteDigit.
  ///
  /// In ru, this message translates to:
  /// **'Удалить цифру'**
  String get pinDeleteDigit;

  /// No description provided for @pinTryAgainSeconds.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток. Повторите через {seconds} сек.'**
  String pinTryAgainSeconds(String seconds);

  /// No description provided for @pinDigitsEntered.
  ///
  /// In ru, this message translates to:
  /// **'Введено {count} из 4 цифр'**
  String pinDigitsEntered(String count);

  /// No description provided for @voiceWorkInput.
  ///
  /// In ru, this message translates to:
  /// **'Продиктовать выполненные работы'**
  String get voiceWorkInput;

  /// No description provided for @executionWorkTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Выполненные работы — не больше 500 символов'**
  String get executionWorkTooLong;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
