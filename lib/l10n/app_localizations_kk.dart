// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get exportReport => 'Экспорт';

  @override
  String get reportPeriodHint => 'Таңдалған кезеңде берілген нарядтар';

  @override
  String get todayPeriod => 'Бүгін';

  @override
  String get weekPeriod => '7 күн';

  @override
  String get monthPeriod => '30 күн';

  @override
  String get allTimePeriod => 'Барлық уақыт';

  @override
  String get noPeriodEmployees => 'Бұл кезеңде наряды бар орындаушылар жоқ';

  @override
  String get editOrder => 'Нарядты өңдеу';

  @override
  String get changeDeadline => 'Орындау мерзімін өзгерту';

  @override
  String get brigadeMembers => 'Бригада құрамы';

  @override
  String get brigades => 'Бригадалар';

  @override
  String get teamBrigadeSearch => 'Бригада, аты немесе мамандығы';

  @override
  String eventDeadline(String value) {
    return 'Мерзім өзгертілді: $value';
  }

  @override
  String get filters => 'Сүзгілер';

  @override
  String get applyFilters => 'Қолдану';

  @override
  String get resetFilters => 'Қалпына келтіру';

  @override
  String get closeFilters => 'Сүзгілерді жабу';

  @override
  String get statusFilter => 'Күйі';

  @override
  String get onlyOverdue => 'Тек мерзімі өткендер';

  @override
  String get clearSearch => 'Іздеуді тазарту';

  @override
  String get attachPhoto => 'Фото тіркеу';

  @override
  String get choosePhotoSource => 'Фото көзін таңдаңыз';

  @override
  String get loginTitle => 'Кіру';

  @override
  String get loginSubtitle => 'Телефон нөміріңіз бен құпиясөзіңізді енгізіңіз.';

  @override
  String get registrationTitle => 'Тіркелу';

  @override
  String get nameSubtitle =>
      'Тегіңізді, атыңызды және әкеңіздің атын енгізіңіз.';

  @override
  String get accountSubtitle =>
      'Телефон нөміріңізді енгізіп, құпиясөз жасаңыз.';

  @override
  String get createAccount => 'Тіркелгі жасау';

  @override
  String get alreadyHaveAccount => 'Тіркелгіңіз бар ма? Кіру';

  @override
  String get phoneLabel => 'Телефон нөмірі';

  @override
  String get passwordLabel => 'Құпиясөз';

  @override
  String get showPassword => 'Құпиясөзді көрсету';

  @override
  String get hidePassword => 'Құпиясөзді жасыру';

  @override
  String get enterPassword => 'Құпиясөзді енгізіңіз';

  @override
  String get loginButton => 'Кіру';

  @override
  String get lastName => 'Тегі';

  @override
  String get firstName => 'Аты';

  @override
  String get patronymic => 'Әкесінің аты';

  @override
  String get enterLastName => 'Тегіңізді енгізіңіз';

  @override
  String get enterFirstName => 'Атыңызды енгізіңіз';

  @override
  String get ifAvailable => 'Бар болса';

  @override
  String get continueButton => 'Жалғастыру';

  @override
  String get passwordHint => 'Кемінде 8 таңба';

  @override
  String get passwordTooShort => 'Құпиясөз кемінде 8 таңбадан тұруы керек';

  @override
  String get registerButton => 'Тіркелу';

  @override
  String get back => 'Артқа';

  @override
  String get enterPhone => 'Телефон нөмірін енгізіңіз';

  @override
  String get incompletePhone => 'Телефон нөмірін толық енгізіңіз';

  @override
  String stepLabel(int step) {
    return '2 қадамның $step-қадамы';
  }

  @override
  String get dashboard => 'Ауысымға шолу';

  @override
  String get greeting => 'Сәлеметсіз бе, Серик. Учаскедегі ағымдағы жағдай.';

  @override
  String get createOrder => 'Наряд жасау';

  @override
  String get issuedOrders => 'Берілген нарядтар';

  @override
  String get completed => 'Орындалды';

  @override
  String get overdue => 'Мерзімі өтті';

  @override
  String get awaitingAcceptance => 'Қабылдауда';

  @override
  String get equipmentStopped => 'Жабдық тоқтап тұр';

  @override
  String get needsAttention => 'Назар аудару қажет';

  @override
  String get noAttention => 'Назар аударуды қажет ететін нарядтар жоқ';

  @override
  String get shiftTeam => 'Ауысымдағы команда';

  @override
  String get allTeam => 'Барлық команда →';

  @override
  String get allAreas => 'Барлық учаскелер';

  @override
  String get allEquipment => 'Барлық жабдық';

  @override
  String get allPriorities => 'Барлық басымдықтар';

  @override
  String get all => 'Барлығы';

  @override
  String get overduePlural => 'Мерзімі өткен';

  @override
  String get issuedPlural => 'Берілген';

  @override
  String get acceptedPlural => 'Қабылданған';

  @override
  String get working => 'Орындалуда';

  @override
  String get queued => 'Кезекте';

  @override
  String get completedPlural => 'Орындалған';

  @override
  String get pausedPlural => 'Уақытша тоқтатылған';

  @override
  String get rework => 'Қайта орындауда';

  @override
  String get rejectedPlural => 'Қабылданбаған';

  @override
  String get cancelledPlural => 'Күші жойылған';

  @override
  String get orders => 'Нарядтар';

  @override
  String get ordersSubtitle =>
      'Тапсырмалар, мерзімдер және жұмыстардың ағымдағы күйлері';

  @override
  String get newOrder => 'Жаңа наряд';

  @override
  String get listView => 'Тізім';

  @override
  String get kanban => 'Канбан';

  @override
  String get orderSearch => 'Нөмір, жұмыс немесе жабдық';

  @override
  String get area => 'Учаске';

  @override
  String get equipment => 'Жабдық';

  @override
  String get employee => 'Орындаушы';

  @override
  String get allEmployees => 'Барлық орындаушылар';

  @override
  String get priority => 'Басымдық';

  @override
  String get noFilteredOrders => 'Таңдалған сүзгілер бойынша нарядтар жоқ';

  @override
  String get overdueOrders => 'Мерзімі өткен нарядтар';

  @override
  String get demoRating => 'Демонстрациялық рейтинг';

  @override
  String get available => 'Бос';

  @override
  String get team => 'Топ';

  @override
  String get teamSubtitle =>
      'Орындаушылардың жүктемесі, мамандықтары және қолжетімділігі';

  @override
  String get employeeSearch => 'Аты немесе мамандығы';

  @override
  String get onlyAvailable => 'Тек бос орындаушылар';

  @override
  String get noEmployees => 'Орындаушылар табылмады';

  @override
  String get aiControl => 'ЖИ бақылауы';

  @override
  String get aiSubtitle =>
      'Цифрлық бақылаушының ұсыныстары. Соңғы шешімді шебер қабылдайды.';

  @override
  String get deadlineControl => 'Мерзімдерді бақылау';

  @override
  String get deadlineHelp =>
      'Мерзімге 30 минут қалғанда еске салу. Қалыпты наряд 10 минутта, апаттық наряд 3 минутта қабылданбаса, шеберге хабарлау.';

  @override
  String get completionCheck => 'Орындалуын тексеру';

  @override
  String get noReviewOrders => 'Тексерілетін нарядтар жоқ';

  @override
  String get photoAnalysis => 'Дейінгі және кейінгі фотоларды талдау';

  @override
  String get photoAnalysisHelp =>
      'Фотолардың бар-жоғын және өзектілігін тексеру, жабдық пен көрінетін ақауларды салыстыру. Сенімділік төмен болса, шебердің тексеруі қажет.';

  @override
  String get orderReport => 'Наряд бойынша есеп';

  @override
  String get orderReportHelp =>
      'Жұмыстар, материалдар, оқиғалар реті, мерзімнің сақталуы және баға түсіндірмесі наряд карточкасында жиналған.';

  @override
  String get equipmentAnomalies => 'Жабдық ауытқулары';

  @override
  String get employeeRating => 'Орындаушылар рейтингі';

  @override
  String get ratingHelp =>
      'Баға жұмыс сапасына, мерзімінде орындалуына, қайта орындау қажеттілігіне, жұмыстың күрделілігіне және бас тарту себептерінің негізділігіне байланысты қалыптасады.';

  @override
  String get masterAssistant => 'Шебер көмекшісі';

  @override
  String get chatHelp => 'Чат үлгісі. Жауаптар демонстрациялық.';

  @override
  String get chatHint => 'Мысалы: қазір кім бос?';

  @override
  String get showDemoAnswer => 'Демо-жауапты көрсету';

  @override
  String get reportsRating => 'Есептер мен рейтинг';

  @override
  String get reportsSubtitle =>
      'Ағымдағы демонстрациялық ауысымның қорытындысы';

  @override
  String get pdfNotReady => 'PDF экспортын сервермен бірге қосамыз';

  @override
  String get exportPdf => 'PDF экспорты';

  @override
  String get excelNotReady => 'Excel экспортын сервермен бірге қосамыз';

  @override
  String get exportExcel => 'Excel экспорты';

  @override
  String get periodNotReady =>
      'Кез келген кезең бойынша есептерді серверге тарих қосылғаннан кейін қосамыз';

  @override
  String get selectPeriod => 'Кезеңді таңдау';

  @override
  String get totalOrders => 'Барлық нарядтар';

  @override
  String get closed => 'Жабылды';

  @override
  String get rejected => 'Қабылданбады';

  @override
  String get equipmentDowntime => 'Жабдықтың тоқтап тұруы';

  @override
  String get downtimeReportHelp =>
      'Есеп үлгісі: жабдықтың тоқтау уақыты, себептері және жоспарлы / жоспардан тыс жұмыстардың үлесі.';

  @override
  String get usedMaterials => 'Есептен шығарылған материалдар';

  @override
  String get materialsReportHelp =>
      'Есеп үлгісі: материалдар, учаскелер және орындаушылар бойынша шығын, нормативтермен салыстыру.';

  @override
  String get notificationCenter => 'Хабарландырулар орталығы';

  @override
  String get notificationsSubtitle =>
      'Прототиптің жергілікті хабарландырулары. Push қосылмаған.';

  @override
  String get noNotifications => 'Жаңа хабарландырулар жоқ';

  @override
  String get awaitingReview => 'Жұмыс қабылдауды күтуде';

  @override
  String get emergencyAwaiting => 'Апаттық наряд жауап күтуде';

  @override
  String get normalPriority => 'Қалыпты';

  @override
  String get permissionDenied =>
      'Қолданба баптауларында камераға немесе фотоларға қолжетімділік беріңіз.';

  @override
  String get pickerFailed =>
      'Камераны немесе галереяны ашу мүмкін болмады. Қайта көріңіз.';

  @override
  String get photoLoadFailed =>
      'Фотоны жүктеу мүмкін болмады. Басқа суретті таңдаңыз.';

  @override
  String get deadline => 'Орындау мерзімі';

  @override
  String get cancel => 'Бас тарту';

  @override
  String get select => 'Таңдау';

  @override
  String get executionTime => 'Орындау уақыты';

  @override
  String get futureDeadline => 'Болашақтағы мерзімді таңдаңыз.';

  @override
  String get createOrderTitle => 'Наряд жасау';

  @override
  String get workDescription => 'Жұмыс сипаттамасы';

  @override
  String get unplanned => 'Жоспардан тыс';

  @override
  String get planned => 'Жоспарлы';

  @override
  String get optionalWorkTitle => 'Жұмыс атауы (міндетті емес)';

  @override
  String get problemWorks => 'Мәселе және қажетті жұмыстар';

  @override
  String get voiceInput => 'Дауыспен енгізу';

  @override
  String get voiceNotReady => 'Дауыспен енгізуді кейін қосамыз.';

  @override
  String get describeProblem => 'Мәселені сипаттаңыз';

  @override
  String get locationAssignee => 'Орын және орындаушы';

  @override
  String get brigade => 'Бригада';

  @override
  String get selectEmployee => 'Орындаушыны таңдаңыз';

  @override
  String get selectBrigade => 'Бригаданы таңдаңыз';

  @override
  String get deadlinePriority => 'Мерзім және басымдық';

  @override
  String get emergencyPriority => 'Апаттық';

  @override
  String get highPriority => 'Жоғары';

  @override
  String get normHoursShort => 'Норматив, сағ';

  @override
  String get dateTime => 'Күн мен уақыт';

  @override
  String get normHours => 'Сағатпен берілген норматив';

  @override
  String get normRange => '1 минуттан 8760 сағатқа дейін көрсетіңіз';

  @override
  String get optionalFaultCode => 'Ақау коды (міндетті емес)';

  @override
  String get notSpecified => 'Көрсетілмеген';

  @override
  String get comment => 'Түсініктеме';

  @override
  String get faultPhotos => 'Ақау фотолары · 5-ке дейін';

  @override
  String get issueOrder => 'Наряд беру';

  @override
  String get reason => 'Себеп';

  @override
  String get specifyReason => 'Себебін көрсетіңіз';

  @override
  String get confirm => 'Растау';

  @override
  String get employeeOrBrigade => 'Орындаушы немесе бригада';

  @override
  String get orderPriority => 'Наряд басымдығы';

  @override
  String get masterScore => 'Шебердің бағасы';

  @override
  String get overdueSingular => 'Мерзімі өткен';

  @override
  String get orderInformation => 'Наряд туралы ақпарат';

  @override
  String get workType => 'Жұмыс түрі';

  @override
  String get description => 'Сипаттама';

  @override
  String get issueDate => 'Берілген күні';

  @override
  String get norm => 'Норматив';

  @override
  String get faultCode => 'Ақау коды';

  @override
  String get master => 'Шебер';

  @override
  String get orderDowntime => 'Жабдықтың тоқтап тұруы';

  @override
  String get stopped => 'Жабдық тоқтатылған';

  @override
  String get noDowntime => 'Жабдық тоқтап тұрған жоқ';

  @override
  String get beforeWork => 'Орындалғанға дейін';

  @override
  String get afterWork => 'Орындалғаннан кейін';

  @override
  String get reassign => 'Қайта тағайындау';

  @override
  String get changePriority => 'Басымдықты өзгерту';

  @override
  String get cancelOrderTitle => 'Нарядтан бас тарту';

  @override
  String get cancelOrder => 'Нарядтың күшін жою';

  @override
  String get workerReport => 'Орындаушы есебі';

  @override
  String get completedWorks => 'Орындалған жұмыстар';

  @override
  String get materials => 'Материалдар';

  @override
  String get notSpecifiedPlural => 'Көрсетілмеген';

  @override
  String get changeScore => 'Бағаны өзгерту';

  @override
  String get acceptedByMaster => 'Жұмыстарды шебер қабылдады';

  @override
  String get acceptClose => 'Қабылдау және жабу';

  @override
  String get returnRework => 'Қайта орындауға қайтару';

  @override
  String get toRework => 'Қайта орындауға';

  @override
  String get actionHistory => 'Әрекеттер тарихы';

  @override
  String get reports => 'Есептер';

  @override
  String get notifications => 'Хабарландырулар';

  @override
  String get shift => 'Ауысым';

  @override
  String get shiftManagement => 'АУЫСЫМДЫ БАСҚАРУ';

  @override
  String get masterRole => 'Ауысым шебері';

  @override
  String get offShift => 'Ауысымда емес';

  @override
  String get aiDemoLabel => 'Демонстрациялық деректер · ЖИ қосылмаған';

  @override
  String get photoOpenFailed => 'Фотоны ашу мүмкін болмады';

  @override
  String get noPhotos => 'Фотолар тіркелмеген';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерея';

  @override
  String get statusIssued => 'Берілді';

  @override
  String get statusAccepted => 'Қабылданды';

  @override
  String get statusPaused => 'Уақытша тоқтатылды';

  @override
  String get statusReview => 'Тексерілуде';

  @override
  String get statusClosed => 'Жабылды';

  @override
  String get statusRejected => 'Қабылданбады';

  @override
  String get statusCancelled => 'Күші жойылды';

  @override
  String get emergencyFull => 'Апаттық — шұғыл орындау';

  @override
  String get normalFull => 'Қалыпты — кезек тәртібімен';

  @override
  String get noAiVerdict => 'Қорытынды жоқ';

  @override
  String get aiUnavailable => 'ЖИ әлі қосылмаған.';

  @override
  String get positiveNorm => 'Норматив нөлден үлкен болуы керек';

  @override
  String get onShiftAssignee =>
      'Ауысымдағы орындаушыны немесе бригаданы таңдаңыз';

  @override
  String get futureDeadlineError => 'Мерзім болашақта болуы керек';

  @override
  String get fivePhotos => '5 фотодан артық емес';

  @override
  String get employeeOffShift => 'Қызметкер ауысымда емес';

  @override
  String get brigadeOffShift => 'Бригада ауысымда емес';

  @override
  String get language => 'Тіл';

  @override
  String get complex => 'Минералдық кешен';

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
    return 'Берілетін уақыт: $date';
  }

  @override
  String issuedAt(String date) {
    return 'Берілді: $date';
  }

  @override
  String dueAt(String date) {
    return 'Мерзімі: $date';
  }

  @override
  String hoursValue(String hours) {
    return '$hours сағ';
  }

  @override
  String scoreValue(String score) {
    return '5-тен $score';
  }

  @override
  String employeeGrade(String specialty, String grade) {
    return '$specialty · $grade дәреже';
  }

  @override
  String workingOrder(String number) {
    return 'Орындалуда · №$number';
  }

  @override
  String workingQueue(String number, String count) {
    return 'Орындалуда · №$number · кезекте $count';
  }

  @override
  String queuedCount(String count) {
    return 'Кезекте · $count';
  }

  @override
  String assignedOrder(String number) {
    return 'Бос емес · №$number тағайындалған';
  }

  @override
  String brigadeAvailability(String total, String free, String busy) {
    return 'Ауысымда: $total · бос: $free · бос емес: $busy';
  }

  @override
  String overdueMinutes(String minutes) {
    return 'Кешігу · $minutes мин.';
  }

  @override
  String removePhoto(String number) {
    return '$number-фотоны жою';
  }

  @override
  String boardCount(String label, String count) {
    return '$label · $count';
  }

  @override
  String shiftTime(String number, String time) {
    return 'Ауысым №$number · $time';
  }

  @override
  String aiVerdict(String verdict) {
    return 'ЖИ қорытындысы: $verdict';
  }

  @override
  String aiSummary(String explanation, String aiScore, String score) {
    return '$explanation\nЖИ бағасы: $aiScore / 5.\nҚорытынды баға: $score / 5.\nСоңғы шешімді шебер қабылдайды.';
  }

  @override
  String eventIssued(String assignee) {
    return 'Наряд берілді: $assignee';
  }

  @override
  String eventReassigned(String assignee) {
    return 'Қайта тағайындалды: $assignee';
  }

  @override
  String eventPriority(String priority) {
    return 'Басымдық өзгертілді: $priority';
  }

  @override
  String eventScore(String score) {
    return 'Шебер бағасы: $score / 5';
  }

  @override
  String eventReason(String status, String reason) {
    return '$status: $reason';
  }

  @override
  String get myOrders => 'Менің нарядтарым';

  @override
  String get orderHistory => 'Нарядтар тарихы';

  @override
  String get profile => 'Профиль';

  @override
  String get history => 'Тарих';

  @override
  String get retry => 'Қайталау';

  @override
  String get archivedOrdersHint =>
      'Аяқталған, күші жойылған және қабылданбаған нарядтар';

  @override
  String get executorSearch => 'Нөмірі немесе жабдық бойынша іздеу';

  @override
  String get noSearchResults => 'Сұрауыңыз бойынша ештеңе табылмады';

  @override
  String get emptyHistory => 'Тарих әзірге бос';

  @override
  String get noActiveOrders => 'Белсенді нарядтар жоқ';

  @override
  String get refreshFailed =>
      'Деректерді жаңарту мүмкін болмады. Қайталау үшін тізімді төмен тартыңыз.';

  @override
  String get goodMorning => 'Қайырлы таң';

  @override
  String get goodAfternoon => 'Қайырлы күн';

  @override
  String get goodEvening => 'Қайырлы кеш';

  @override
  String get goodNight => 'Қайырлы түн';

  @override
  String get activeOrders => 'Белсенді';

  @override
  String get onShift => 'Ауысымда';

  @override
  String get grade => 'Дәреже';

  @override
  String get myRating => 'Менің рейтингім';

  @override
  String get noRatingYet => 'Әзірге баға жоқ';

  @override
  String get executorRatingHint =>
      'Орындалған нарядтар тексерілгеннен кейін мұнда рейтинг пен оның түсіндірмесі пайда болады.';

  @override
  String get quality => 'Сапа';

  @override
  String get onTime => 'Мерзімінде';

  @override
  String get reworks => 'Қайта орындаулар';

  @override
  String get closedOrders => 'Жабылған нарядтар';

  @override
  String get logout => 'Шығу';

  @override
  String get logoutConfirmation => 'Шығуды растайсыз ба?';

  @override
  String get ratingPending => 'Баға күтілуде';

  @override
  String get aiShort => 'ЖИ';

  @override
  String get emergencyResponse => 'Апаттық наряд — жауап беру қажет';

  @override
  String get newOrderAssigned => 'Сізге жаңа наряд тағайындалды';

  @override
  String get returnedForRework => 'Наряд қайта орындауға қайтарылды';

  @override
  String get masterClosedOrder => 'Шебер нарядты жапты';

  @override
  String get deadlineExpired => 'Орындау мерзімі өтті';

  @override
  String get noExecutorNotifications => 'Әзірге хабарландырулар жоқ';

  @override
  String get rejectReason => 'Бас тарту себебі';

  @override
  String get pauseReason => 'Уақытша тоқтату себебі';

  @override
  String get savedReasonNotSent =>
      'Түзетілген себеп телефонда сақталды, бірақ жіберілмеді. Сервер алдыңғы нұсқаны қабылдады.';

  @override
  String get orderReassignedWarning =>
      'Наряд басқа орындаушыға қайта тағайындалды.';

  @override
  String get acceptWork => 'Жұмысқа қабылдау';

  @override
  String get queueOrder => 'Кезекке қою';

  @override
  String get rejectOrder => 'Қабылдамау';

  @override
  String get resumeWork => 'Жұмысты жалғастыру';

  @override
  String get startExecution => 'Орындауды бастау';

  @override
  String get pauseWork => 'Уақытша тоқтату';

  @override
  String get workDone => 'Орындалды';

  @override
  String get executionDeadline => 'Орындау мерзімі';

  @override
  String get faultDescription => 'Ақау сипаттамасы';

  @override
  String get photosBeforeWork => 'Жұмыс басталғанға дейінгі фотолар';

  @override
  String get masterNoPhotos => 'Шебер фотоларды тіркемеген';

  @override
  String get masterScorePending => 'Шебердің бағасы әлі қойылмаған';

  @override
  String get assessmentPending => 'Орындалу туралы қорытынды әлі алынбаған.';

  @override
  String get reportAwaitingMaster =>
      'Есеп жіберілді. Шебердің тексеруін күтуде.';

  @override
  String get askMasterRemarks => 'Ескертулерді шеберден нақтылаңыз';

  @override
  String get yourReport => 'Сіздің есебіңіз';

  @override
  String get workNotSpecified => 'Жұмыстар көрсетілмеген';

  @override
  String get photosAfter => 'Жұмыстан кейінгі фотолар';

  @override
  String get goToRework => 'Қайта орындауға өту';

  @override
  String get openOrder => 'Нарядты ашу';

  @override
  String get addPhotoFailed =>
      'Фото қосу мүмкін болмады. Рұқсаттарды тексеріңіз.';

  @override
  String get unplannedPhotoRequired =>
      'Жоспардан тыс наряд үшін жұмыстан кейінгі фото қажет';

  @override
  String get commitSelectedMaterial => 'Таңдалған материалды тізімге қосыңыз';

  @override
  String get material => 'Материал';

  @override
  String get selectMaterial => 'Материалды таңдаңыз';

  @override
  String get quantity => 'Саны';

  @override
  String get positiveQuantity => 'Нөлден үлкен сан енгізіңіз';

  @override
  String get addMaterial => 'Материал қосу';

  @override
  String get sending => 'Жіберілуде…';

  @override
  String get submitForReview => 'Тексеруге жіберу';

  @override
  String get materialsAndCode => 'Материалдар мен код';

  @override
  String get photosAndComment => 'Фото мен түсініктеме';

  @override
  String get whatWasDone => 'Не істелді?';

  @override
  String get describeCompletedWork => 'Орындалған жұмыстарды сипаттаңыз';

  @override
  String get faultCodeLabel => 'Ақау коды';

  @override
  String get selectCode => 'Кодты таңдаңыз';

  @override
  String get selectFaultCode => 'Ақау кодын таңдаңыз';

  @override
  String get usedExecutorMaterials => 'Пайдаланылған материалдар';

  @override
  String get noMaterialsUsed => 'Материалдар пайдаланылмады';

  @override
  String get decrease => 'Азайту';

  @override
  String get increase => 'Көбейту';

  @override
  String get photosAfterWork => 'Жұмыстар орындалғаннан кейінгі фотолар';

  @override
  String get removePhotoLabel => 'Фотоны жою';

  @override
  String get takeAfterPhoto => 'Жұмыстан кейін фото түсіру';

  @override
  String get chooseFromGallery => 'Галереядан таңдау';

  @override
  String get photoLimitReached =>
      '5 фотодан 5 фото қосылды. Жаңасын қосу үшін бір фотоны жойыңыз.';

  @override
  String get optionalComment => 'Түсініктеме (міндетті емес)';

  @override
  String get additionalInformation => 'Қосымша ақпарат';

  @override
  String get changeStatusFailed =>
      'Күйді өзгерту мүмкін болмады. Қайта көріңіз.';

  @override
  String get submitReportFailed =>
      'Есепті жіберу мүмкін болмады. Қайта көріңіз.';

  @override
  String get orderIssuedLabel => 'Наряд берілді';

  @override
  String get mechanicSpecialty => 'Жөндеуші';

  @override
  String get electricianSpecialty => 'Электрші';

  @override
  String get welderSpecialty => 'Дәнекерлеуші';

  @override
  String get crushingArea => 'Ұсақтау';

  @override
  String get beneficiationArea => 'Байыту';

  @override
  String get repairArea => 'Жөндеу цехы';

  @override
  String get transportArea => 'Көлік учаскесі';

  @override
  String get bearingMaterial => 'Мойынтірек · дана';

  @override
  String get sealMaterial => 'Тығыздағыш · дана';

  @override
  String get cableMaterial => 'Кабель · м';

  @override
  String get oilMaterial => 'Май · л';

  @override
  String get greaseMaterial => 'Майлағыш · кг';

  @override
  String get anomalyExample =>
      'Қорытынды мысалы: К-3 конвейері мойынтіректерге байланысты жиі тоқтайды. Ұсыныс: жетектің осьтестігін тексеріп, жоспарлы алдын алу жөндеу жоспарын түзету.';

  @override
  String closeOrderNumber(String number) {
    return '№$number нарядты жабу';
  }

  @override
  String resultOrderNumber(String number) {
    return 'Нәтиже · №$number';
  }

  @override
  String deadlineMinutesLeft(String minutes) {
    return 'Мерзімге $minutes мин қалды';
  }

  @override
  String workTimeValue(String time) {
    return 'Жұмыс уақыты: $time';
  }

  @override
  String workMinutesValue(String minutes) {
    return 'Жұмыс уақыты: $minutes мин';
  }

  @override
  String historyWorkMinutes(String minutes) {
    return '$minutes мин жұмыс істеді';
  }

  @override
  String priorityValue(String priority) {
    return 'Басымдық: $priority';
  }

  @override
  String assessmentVerdict(String verdict) {
    return 'Тексеру: $verdict';
  }

  @override
  String assessmentScore(String score) {
    return 'Баға: $score / 5';
  }

  @override
  String assessmentStrengths(String text) {
    return 'Жақсы орындалғаны: $text';
  }

  @override
  String assessmentImprovements(String text) {
    return 'Жақсартуға болатын тұстары: $text';
  }

  @override
  String normHoursValue(String hours) {
    return 'Норматив: $hours сағ';
  }

  @override
  String reworkReasonValue(String reason) {
    return 'Қайта орындау: $reason';
  }

  @override
  String faultCodeValue(String code) {
    return 'Код: $code';
  }

  @override
  String previousMaterialsValue(String materials) {
    return 'Бұрын көрсетілген материалдар:\n$materials';
  }

  @override
  String brigadeNumber(String number) {
    return '№$number бригада';
  }

  @override
  String get faultBearing => 'М-02 · Мойынтірек';

  @override
  String get faultOilLeak => 'Г-01 · Майдың ағуы';

  @override
  String get faultCableBreak => 'Э-03 · Кабельдің үзілуі';

  @override
  String get faultGreaseLack => 'С-01 · Майлағыштың жеткіліксіздігі';

  @override
  String get faultAirLeak => 'П-02 · Ауаның ағуы';

  @override
  String get crusherEquipment => 'КМД-1750 ұсақтағышы';

  @override
  String get conveyorEquipment => 'К-3 конвейері';

  @override
  String get screenEquipment => 'ГИС-52 елегі';

  @override
  String get pumpEquipment => 'Н-12 сорғысы';

  @override
  String get millEquipment => 'МШР-3 диірмені';

  @override
  String get separatorEquipment => 'С-4 сепараторы';

  @override
  String get machineEquipment => 'Т-16 станогы';

  @override
  String get craneEquipment => 'КБ-2 кран-балкасы';

  @override
  String get loaderEquipment => 'П-7 тиегіші';

  @override
  String get compressorEquipment => 'ВК-22 компрессоры';

  @override
  String get demoBearingWork => 'Жетек мойынтірегін ауыстыру';

  @override
  String get demoOilLeakWork => 'Майдың ағуын жою';

  @override
  String get demoPowerWork => 'Қозғалтқыштың қоректенуін тексеру';

  @override
  String get demoLubricationWork => 'Тораптарды жоспарлы майлау';

  @override
  String get demoSealWork => 'Білік тығыздағышын ауыстыру';

  @override
  String get demoGuardWork => 'Қорғаныш қаптамасын қалпына келтіру';

  @override
  String get demoLubricationCheckWork =>
      'Тораптарды жоспарлы майлау және тексеру';

  @override
  String get demoOrderDescription =>
      'Жабдықтың күйін тексеріп, ақауды жою және бақылау іске қосуын орындау.';

  @override
  String get demoSealReport =>
      'Тығыздағыш ауыстырылды. Қосылыстар тексерілді. Бақылау іске қосуы кезінде ағу байқалмады.';

  @override
  String get demoBearingReport =>
      'Мойынтірек ауыстырылды. Бекітпелер тексеріліп, бақылау іске қосуы орындалды. Бөгде шу жойылды.';

  @override
  String get demoLubricationReport =>
      'Тораптар майланды. Бекітпелер мен жабдықтың жүктеме кезіндегі жұмысы тексерілді.';

  @override
  String get demoWaitingBearing => 'Қоймадан мойынтіректі күтіп отырмыз';

  @override
  String get demoSealMaterial => '40×60 тығыздағышы — 1 дана';

  @override
  String get demoOilMaterial => 'И-40 майы — 0,5 л';

  @override
  String get demoBearingMaterial => 'Мойынтірек — 1 дана';

  @override
  String get demoGreaseSmall => 'Майлағыш — 0,2 кг';

  @override
  String get demoGreaseHalf => 'Майлағыш — 0,5 кг';

  @override
  String get awaitingCheck => 'Тексеруді күтуде';

  @override
  String get reportAiPending => 'Есеп жіберілді. ЖИ тексеруі әлі орындалмаған.';

  @override
  String masterDemoAnswer(String query) {
    return 'Демо-жауап: мұнда «$query» сұрауы бойынша ұсыныстар пайда болады. Талдау үшін сервер мен ЖИ қосылуы қажет.';
  }

  @override
  String queuePosition(String position) {
    return 'Кезекте · $position-орын';
  }

  @override
  String get finishCurrentFirst =>
      'Алдымен ағымдағы нарядты уақытша тоқтатыңыз немесе аяқтаңыз';

  @override
  String get wholePieceQuantity =>
      'Данамен есептелетін материал үшін бүтін сан енгізіңіз';

  @override
  String get removeMaterial => 'Материалды жою';

  @override
  String get removeMaterialQuestion => 'Материалды есептен жою керек пе?';

  @override
  String get draftSaved => 'Қаралама сақталды';

  @override
  String get draftLoadFailed =>
      'Қараламаны қалпына келтіру мүмкін болмады. Қайта көріңіз — сақталған деректер өзгерген жоқ.';

  @override
  String get draftSaveFailed => 'Қаралама сақталмады. Қайталау үшін басыңыз.';

  @override
  String get discardOrderDraftTitle => 'Қараламасыз бастау керек пе?';

  @override
  String get discardOrderDraftMessage =>
      'Сақталған қараламаны жойып, бос нысанды ашу керек пе? Қараламаның мәтіні, баптаулары және фотосуреттері жоғалады.';

  @override
  String get discardOrderDraftAction => 'Қараламаны жою';

  @override
  String get orderDraftDiscardFailed =>
      'Қараламаны жою мүмкін болмады. Сақталған деректер өзгерген жоқ. Қайталап көріңіз.';

  @override
  String get orderDraftChangedBeforeDiscard =>
      'Қаралама басқа нысанда өзгерді. Өзекті деректерді жүктеу үшін «Қайталау» түймесін басыңыз.';

  @override
  String overdueByMinutes(String minutes) {
    return 'Мерзімі $minutes мин өтті';
  }

  @override
  String get executionResult => 'Тексеру нәтижесі';

  @override
  String get authLoginLabel => 'Логин';

  @override
  String get authPinLabel => 'ПИН';

  @override
  String get authEnterLogin => 'Логинді енгізіңіз';

  @override
  String get authPinLength => 'ПИН 4–12 таңбадан тұруы керек';

  @override
  String get authSubtitle => 'Телефон нөмірі мен құпиясөзді енгізіңіз.';

  @override
  String get authAccountHint => 'Тіркелгіні әкімші береді.';

  @override
  String get authNetworkError =>
      'Қосылу мүмкін болмады. Байланысты тексеріп, қайталаңыз.';

  @override
  String get authMobileRole => 'Бұл рөл веб-панельде қолжетімді.';

  @override
  String authRetryMinutes(String minutes) {
    return 'Әрекет тым көп. $minutes минуттан кейін қайталаңыз.';
  }

  @override
  String get authRateLimited => 'Әрекет тым көп. Кейінірек қайталаңыз.';

  @override
  String get demoDataNotice => 'Демонстрациялық деректер';

  @override
  String get authInvalidPhone => '10–15 цифрдан тұратын нөмірді енгізіңіз';

  @override
  String get changePasswordTitle => 'Құпиясөзді өзгерту';

  @override
  String get currentPasswordLabel => 'Қазіргі құпиясөз';

  @override
  String get newPasswordLabel => 'Жаңа құпиясөз';

  @override
  String get newPasswordLength => 'Құпиясөз 6–128 таңбадан тұруы керек';

  @override
  String get passwordChanged => 'Құпиясөз өзгертілді';

  @override
  String get changePasswordButton => 'Құпиясөзді өзгерту';

  @override
  String get passwordResetHint =>
      'Ұмытылған құпиясөзді әкімші қалпына келтіреді.';

  @override
  String get statusAiChecking => 'Орындалды · AI тексеруі жүріп жатыр';

  @override
  String get statusMasterReview => 'Шебердің тексеруінде';

  @override
  String get checkingReport => 'Есеп тексерілуде…';

  @override
  String get orderUnavailable => 'Наряд қолжетімсіз';

  @override
  String get photoTooLarge => 'Фото көлемі 15 МБ-тан аспауы керек.';

  @override
  String get photoCaptureHint =>
      'Жөндеу нәтижесі көрінуі үшін «дейін» және «кейін» фотоларын бір жерден түсіріңіз. 5 фотоға дейін, әрқайсысы 15 МБ-тан аспауы керек.';

  @override
  String get reassignOrderTitle => 'Нарядты қайта тағайындау';

  @override
  String get reassignOrderQuestion => 'Нарядты қайта тағайындау керек пе?';

  @override
  String get reassignOrderExplanation =>
      'Қайта тағайындағаннан кейін наряд «Берілді» мәртебесіне өтеді. Жаңа орындаушы хабарландыру алады.';

  @override
  String get orderCancelledMessage => 'Наряд тоқтатылды';

  @override
  String get orderReworkMessage => 'Наряд қайта өңдеуге жіберілді';

  @override
  String get orderClosedMessage => 'Наряд жабылды';

  @override
  String get orderUpdatedMessage => 'Наряд жаңартылды';

  @override
  String get closeActionLabel => 'Жабу';

  @override
  String get orderNotFoundMessage => 'Наряд табылмады';

  @override
  String get notYourOrderMessage => 'Бұл сіздің нарядыңыз емес';

  @override
  String get aiWorkCheckTitle => 'Жұмыстың орындалуын ЖИ арқылы тексеру';

  @override
  String get workStrengthsTitle => 'Жақсы орындалған жұмыстар';

  @override
  String get acceptWorkAction => 'Жұмысты қабылдау';

  @override
  String get closeWorkOrderAction => 'Нарядты жабу';

  @override
  String get orderAcceptedMessage => 'Наряд қабылданды';

  @override
  String get orderRejectedMessage => 'Наряд қабылданбады';

  @override
  String get workStartedMessage => 'Жұмыс басталды';

  @override
  String get workPausedMessage => 'Жұмыс тоқтатыла тұрды';

  @override
  String get workCompletedMessage => 'Жұмыс орындалды';

  @override
  String get chooseEquipmentFirst => 'Алдымен жабдықты таңдаңыз.';

  @override
  String get describeFaultFirst => 'Алдымен ақауды сипаттаңыз.';

  @override
  String get recommendationAppliedMessage => 'Ұсыныс қолданылды.';

  @override
  String get photoSelectionFailedMessage =>
      'Фотосуретті таңдау мүмкін болмады.';

  @override
  String get chooseAreaValidation => 'Учаскені таңдаңыз.';

  @override
  String get chooseEquipmentValidation => 'Жабдықты таңдаңыз.';

  @override
  String get chooseExecutorValidation => 'Орындаушыны таңдаңыз.';

  @override
  String get chooseNormativeValidation => 'Нормативті таңдаңыз.';

  @override
  String get creatingOrderLabel => 'Жасалуда...';

  @override
  String get voiceNextStageMessage =>
      'Дауыспен енгізуді келесі кезеңде қосамыз.';

  @override
  String get descriptionMinimumLabel => 'Сипаттама — кемінде 3 таңба';

  @override
  String get getAiRecommendationLabel => 'ЖИ ұсынысын алу';

  @override
  String get chooseAreaLabel => 'Учаскені таңдаңыз';

  @override
  String get estimatedTimeLabel => 'Болжамды уақыт';

  @override
  String get queueLabel => 'Кезек';

  @override
  String get ratingLabel => 'Рейтинг';

  @override
  String get confidenceLabel => 'Сенімділік';

  @override
  String get aiScoreLabel => 'ЖИ бағасы';

  @override
  String get orderStatusChangedMessage =>
      'Наряд мәртебесі өзгерді. Деректерді жаңартыңыз';

  @override
  String get orderNotWorkingMessage =>
      'Наряд бойынша жұмыс қазір жүргізілмейді';

  @override
  String get workAndFaultRequiredMessage =>
      'Жұмыстар мен ақау кодын толтырыңыз';

  @override
  String get checkMaterialsPhotosMessage =>
      'Материалдар мен фотосуреттерді тексеріңіз';

  @override
  String get orderFinishedMessage => 'Наряд аяқталды';

  @override
  String get mockSealMaterial => '40×60 тығыздағыш';

  @override
  String get mockOilMaterial => 'И-40 майы';

  @override
  String get mockBearingShort => 'Мойынтірек';

  @override
  String get mockLubricantShort => 'Майлау материалы';

  @override
  String get mockMasterReworkReason =>
      'Орындалған жұмыстан кейінгі фотосурет жоқ';

  @override
  String get pieceUnit => 'дана';

  @override
  String get hourUnit => 'сағ.';

  @override
  String get piecesShortUnit => 'дана';

  @override
  String get meterUnit => 'м';

  @override
  String get kilogramUnit => 'кг';

  @override
  String get literUnit => 'л';

  @override
  String executorCurrentOrderQueue(String number, String count) {
    return '№$number нарядын орындауда, кезекте $count';
  }

  @override
  String executorQueuedOrders(String count) {
    return 'кезекте $count наряд';
  }

  @override
  String get aiVerdictAcceptedLabel => 'Қабылданды';

  @override
  String get aiVerdictCommentsLabel => 'Ескертулермен қабылданды';

  @override
  String get aiVerdictReworkLabel => 'Қайта өңдеу қажет';

  @override
  String get historyMonthSummary => 'Соңғы 30 күн';

  @override
  String get historyAverageScore => 'Орташа баға';

  @override
  String get historyEarlier => 'Бұрын';

  @override
  String get ratingCalculation => 'Рейтинг қалай есептеледі';

  @override
  String get ratingOnTimeOrders => 'Мерзімінде орындалған';

  @override
  String get ratingReworkedOrders => 'Қайта орындауға қайтарылған';

  @override
  String ratingQualityExplanation(String quality, String points) {
    return 'Жұмыстарыңыздың орташа бағасы — 5-тен $quality. Сапа үшін берілген ұпай: 45-тен $points.';
  }

  @override
  String ratingTimingExplanation(String percent, String points) {
    return 'Нарядтардың $percent%-ы мерзімінде орындалды. Мерзімді сақтау үшін берілген ұпай: 25-тен $points.';
  }

  @override
  String get ratingReliability => 'Жөндеу сенімділігі';

  @override
  String ratingReliabilityExplanation(String percent, String points) {
    return 'Нарядтардың $percent%-ы қайта орындауды қажет етпеді және 7 күн ішінде қайта бұзылмады. Жөндеу сенімділігі үшін берілген ұпай: 15-тен $points.';
  }

  @override
  String ratingVolumeExplanation(String count, String points) {
    return 'Сіз $count нарядты жаптыңыз. Жұмыс көлемі үшін берілген ұпай: 10-нан $points.';
  }

  @override
  String get ratingComplexity => 'Күрделі жұмыстар';

  @override
  String ratingComplexityExplanation(String points) {
    return 'Апаттық және басымдығы жоғары нарядтар үшін қосымша 5-тен $points ұпай берілді.';
  }

  @override
  String get ratingRejects => 'Негізсіз бас тартулар';

  @override
  String ratingRejectsExplanation(String count, String points) {
    return 'Дәлелді себепсіз бас тартулар саны: $count. Олар үшін $points ұпай шегерілді.';
  }

  @override
  String get profileSettings => 'Баптаулар';

  @override
  String get completedShort => 'Аяқталды';

  @override
  String get orderSingular => 'Наряд';

  @override
  String get noOrders => 'Нарядтар жоқ';

  @override
  String get noScore => 'Баға жоқ';

  @override
  String get pushOrderOpenFailed => 'Нарядты ашу мүмкін болмады';

  @override
  String get companyName => 'Қостанай минералдары';

  @override
  String get emergencyNotificationChannel => 'Апаттық нарядтар';

  @override
  String get emergencyNotificationDescription =>
      'Жауап беруді талап ететін жаңа апаттық нарядтар';

  @override
  String get offlineActionSaved => 'Телефонда сақталды. Жіберуді күтіп тұр.';

  @override
  String get actionUnavailable => 'Бұл мәртебеде әрекет қолжетімсіз';

  @override
  String get executorActionUnavailable => 'Орындаушыға бұл әрекет қолжетімсіз';

  @override
  String get executionFieldsRequired =>
      'Орындалған жұмыстарды және ақау кодын толтырыңыз';

  @override
  String get afterPhotosInvalid => 'Жұмыстан кейінгі фотоларды тексеріңіз';

  @override
  String get materialsFromCatalogRequired =>
      'Материалдарды анықтамалықтан таңдаңыз';

  @override
  String get materialsInvalid => 'Материалдарды тексеріңіз';

  @override
  String employeeGradeOnly(String grade) {
    return '$grade разряд';
  }

  @override
  String shortOrderCount(String count) {
    return '$count наряд';
  }

  @override
  String offlineActionNotApplied(String reason) {
    return 'Әрекет қолданылмады: $reason';
  }

  @override
  String get ratingPeriodLabel => 'Рейтинг кезеңі';

  @override
  String get ratingPeriodShift => 'Ауысым · 12 сағат';

  @override
  String get ratingPeriodDay => 'Тәулік бойынша';

  @override
  String get ratingPeriodWeek => 'Апта бойынша';

  @override
  String get ratingPeriodMonth => '30 күн бойынша';

  @override
  String get ratingPeriodCustom => 'Күндерді таңдау';

  @override
  String get oilContaminationFault => 'Майдың ластануы';

  @override
  String get industrialOilMaterial => 'Өнеркәсіптік май И-40А';

  @override
  String get oilFilterMaterial => 'Май сүзгісі';

  @override
  String get appSlogan => 'Наряд берілді — ЖИ бақылауында';

  @override
  String get pinCreateTitle => 'ПИН-код жасаңыз';

  @override
  String get pinConfirmTitle => 'ПИН-кодты қайталаңыз';

  @override
  String get pinEnterTitle => 'ПИН-кодты енгізіңіз';

  @override
  String get pinCreateHint => 'Қолданбаға кіру үшін 4 цифр ойлап табыңыз';

  @override
  String get pinUnlockHint => 'Қолданбаны ашу үшін 4 цифрды енгізіңіз';

  @override
  String get pinMismatch => 'ПИН-кодтар сәйкес келмейді. Қайта енгізіңіз';

  @override
  String get pinConfirmHint => 'Ойлап тапқан ПИН-кодты қайта енгізіңіз';

  @override
  String get pinChange => 'Кодты өзгерту';

  @override
  String get pinIncorrect => 'ПИН-код қате';

  @override
  String get pinStorageError =>
      'ПИН-код қоймасын ашу мүмкін болмады. Қайталап көріңіз немесе құпиясөзбен кіріңіз';

  @override
  String get pinForgot => 'ПИН-кодты ұмыттыңыз ба?';

  @override
  String get pinUseAnotherAccount => 'Басқа аккаунтқа кіру';

  @override
  String get pinResetHint => 'Жаңа ПИН-код жасау үшін құпиясөзбен кіру қажет';

  @override
  String get pinDeleteDigit => 'Цифрды өшіру';

  @override
  String pinTryAgainSeconds(String seconds) {
    return 'Әрекеттер тым көп. $seconds секундтан кейін қайталаңыз.';
  }

  @override
  String pinDigitsEntered(String count) {
    return '4 цифрдың $count цифры енгізілді';
  }

  @override
  String get voiceWorkInput => 'Орындалған жұмыстарды дауыспен енгізу';

  @override
  String get executionWorkTooLong =>
      'Орындалған жұмыстар 500 таңбадан аспауы керек';
}
