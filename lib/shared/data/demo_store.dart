import 'package:mineral/features/executor/models/executor_rating_period.dart';
import 'package:flutter/material.dart';
import 'package:mineral/features/executor/data/executor_repository.dart';
import 'package:mineral/features/executor/data/execution_draft_storage.dart';
import 'package:mineral/features/executor/data/offline_action_queue.dart';
import 'package:mineral/features/executor/models/execution_assessment.dart';
import 'package:mineral/features/executor/models/pending_action.dart';
import 'package:uuid/uuid.dart';
import 'package:mineral/shared/models/models.dart';

class DemoStore extends ChangeNotifier implements ExecutorRepository {
  String createUniqueId() => const Uuid().v4();
  final OfflineActionQueue? queue;
  @override
  ExecutorRating? executorRating(
    int employeeId, {
    ExecutorRatingPeriod period = const ExecutorRatingPeriod(),
  }) => null;
  @override
  Future<ExecutorRating?> loadExecutorRating(
    int employeeId, {
    ExecutorRatingPeriod period = const ExecutorRatingPeriod(),
  }) async => executorRating(employeeId, period: period);
  @override
  bool get isLoading => false;
  @override
  String? get loadError => null;
  @override
  List<String> get executorFaultCodes => faultCodes;
  @override
  List<String> get executorMaterials => const [
    'Подшипник · шт',
    'Уплотнение · шт',
    'Кабель · м',
    'Масло · л',
    'Смазка · кг',
  ];
  final _executionDrafts = <(int, int), ExecutionDraft>{};
  @override
  ExecutionDraft? executionDraft(int employeeId, int number) =>
      _executionDrafts[(employeeId, number)];
  @override
  Future<ExecutionDraft?> restoreExecutionDraft(
    int employeeId,
    int number,
  ) async {
    final cached = executionDraft(employeeId, number);
    if (cached != null) return cached;
    final draft = await draftStorage?.load(employeeId, number);
    if (draft != null) _executionDrafts[(employeeId, number)] = draft;
    return draft;
  }

  @override
  Future<void> saveExecutionDraft(
    int employeeId,
    int number,
    ExecutionDraft draft,
  ) async {
    _executionDrafts[(employeeId, number)] = draft;
    await draftStorage?.save(employeeId, number, draft);
  }

  @override
  Future<void> clearExecutionDraft(int employeeId, int number) async {
    await draftStorage?.remove(employeeId, number);
    _executionDrafts.remove((employeeId, number));
  }

  @override
  Future<void> refreshExecutor(int employeeId) async {
    employee(employeeId);
    notifyListeners();
  }

  @override
  Future<WorkOrder> loadExecutorOrderTime(int employeeId, WorkOrder order) =>
      loadExecutorOrder(employeeId, order);

  @override
  Future<WorkOrder> loadExecutorOrder(int employeeId, WorkOrder order) async {
    _checkExecutor(employeeId, order);
    return order;
  }

  void _checkExecutor(int employeeId, WorkOrder order) {
    if (!assignedTo(employeeId).contains(order)) {
      throw StateError('Наряд переназначен другому исполнителю');
    }
  }

  @override
  Future<String?> restoreActionReason(
    int employeeId,
    WorkOrder order,
    OrderStatus status,
  ) async => null;

  @override
  Future<void> executorAction(
    int employeeId,
    WorkOrder order,
    OrderStatus status, {
    String reason = '',
  }) async {
    _checkExecutor(employeeId, order);
    final allowed = switch (order.status) {
      OrderStatus.issued => {
        OrderStatus.accepted,
        OrderStatus.queued,
        OrderStatus.rejected,
      },
      OrderStatus.accepted ||
      OrderStatus.queued ||
      OrderStatus.paused ||
      OrderStatus.rework => {OrderStatus.working},
      OrderStatus.working => {OrderStatus.paused},
      _ => <OrderStatus>{},
    };
    if (!allowed.contains(status)) {
      throw StateError('Статус наряда изменился. Обновите данные');
    }
    if (status == OrderStatus.working &&
        assignedTo(employeeId).any(
          (other) => other != order && other.status == OrderStatus.working,
        )) {
      throw StateError('Сначала приостановите или завершите текущий наряд');
    }
    if ({OrderStatus.paused, OrderStatus.rejected}.contains(status) &&
        reason.trim().isEmpty) {
      throw ArgumentError('Укажите причину');
    }
    final actionQueue = queue;

    if (actionQueue != null) {
      final action = PendingAction(
        id: createUniqueId(),
        employeeId: employeeId,
        orderNumber: order.number,
        type: 'changeStatus',
        payload: {'status': status.name, 'reason': reason.trim()},
        createdAt: now,
      );

      await actionQueue.enqueue(action);
    }

    changeStatus(
      order,
      status,
      reason: reason.trim(),
      author: employee(employeeId).name,
    );

    if (actionQueue != null) {
      await actionQueue.sync();
    }
  }

  @override
  Future<void> submitExecution(
    int employeeId,
    WorkOrder order,
    ExecutionDraft report,
  ) async {
    _checkExecutor(employeeId, order);
    if (order.status != OrderStatus.working) {
      throw StateError('Наряд уже не в работе');
    }
    if (report.work.trim().isEmpty || !faultCodes.contains(report.faultCode)) {
      throw ArgumentError('Заполните работы и шифр неисправности');
    }
    if (!order.planned && report.photos.isEmpty) {
      throw ArgumentError('Для внепланового наряда нужно фото после');
    }
    if (report.photos.length > 5 ||
        report.materials.entries.any(
          (e) =>
              !executorMaterials.contains(e.key) ||
              !e.value.isFinite ||
              e.value <= 0,
        )) {
      throw ArgumentError('Проверьте материалы и фотографии');
    }
    await clearExecutionDraft(employeeId, order.number);
    // The status could change while awaiting local IO or a future API adapter.
    _checkExecutor(employeeId, order);
    if (order.status != OrderStatus.working) {
      throw StateError('Наряд уже не в работе');
    }
    order.completedWork = report.work.trim();
    order.faultCode = report.faultCode;
    order.materials = [
      report.legacyMaterials,
      ...report.materials.entries.map((e) => '${e.key}: ${e.value}'),
    ].where((s) => s.isNotEmpty).join('\n');
    if (order.materials.isEmpty) {
      order.materials = 'Материалы не использовались';
    }
    if (report.comment.trim().isNotEmpty) {
      order.comment = '${order.comment}\n${report.comment.trim()}'.trim();
    }
    order.afterImages
      ..clear()
      ..addAll(report.photos);
    order.afterPhotos = report.photos.length;
    order.aiVerdict = 'Ожидает проверки';
    order.assessment = null;
    order.aiExplanation = 'Отчёт отправлен. Проверка ИИ ещё не выполнена.';
    changeStatus(order, OrderStatus.review, author: employee(employeeId).name);
  }

  DemoStore({
    DateTime Function()? clock,
    this.onOrderChanged,
    this.draftStorage,
    this.queue,
  }) : _clock = clock ?? DateTime.now;

  final void Function(OrderEventKind kind)? onOrderChanged;
  final ExecutionDraftStorage? draftStorage;

  void _orderChanged(OrderEventKind kind) {
    notifyListeners();
    onOrderChanged?.call(kind);
  }

  final DateTime Function() _clock;
  @override
  DateTime get now => _clock();

  static const masterName = 'Серик Омаров';
  static const areas = {
    'Дробление': ['Дробилка КМД-1750', 'Конвейер К-3', 'Грохот ГИС-52'],
    'Обогащение': ['Насос Н-12', 'Мельница МШР-3', 'Сепаратор С-4'],
    'Ремонтный цех': ['Станок Т-16', 'Кран-балка КБ-2'],
    'Транспортный участок': ['Погрузчик П-7', 'Компрессор ВК-22'],
  };

  static const priorities = ['Аварийный', 'Высокий', 'Обычный', 'Плановый'];
  static const priorityLabels = {
    'Аварийный': 'Аварийный — срочно в работу',
    'Высокий': 'Высокий',
    'Обычный': 'Обычный — в порядке очереди',
    'Плановый': 'Плановый',
  };
  static const faultCodes = [
    'М-02 · Подшипник',
    'Г-01 · Течь масла',
    'Э-03 · Обрыв кабеля',
    'С-01 · Недостаток смазки',
    'П-02 · Утечка воздуха',
  ];

  List<String> get brigades => employees.map((e) => e.brigade).toSet().toList();
  List<Employee> brigadeMembers(String brigade) =>
      employees.where((e) => e.brigade == brigade).toList();
  String assignmentLabel(WorkOrder order) =>
      order.brigade ?? employee(order.employeeId).name;

  DateTime get shiftStart {
    final current = now;
    if (current.hour >= 20) {
      return DateTime(current.year, current.month, current.day, 20);
    }
    if (current.hour >= 8) {
      return DateTime(current.year, current.month, current.day, 8);
    }
    return DateTime(current.year, current.month, current.day - 1, 20);
  }

  List<WorkOrder> get shiftOrders => orders
      .where(
        (o) => !o.createdAt.isBefore(shiftStart) && !o.createdAt.isAfter(now),
      )
      .toList();
  int get completedThisShift => orders
      .where(
        (o) =>
            [OrderStatus.review, OrderStatus.closed].contains(o.status) &&
            o.history.any(
              (event) =>
                  !event.time.isBefore(shiftStart) &&
                  (event.title.startsWith(OrderStatus.review.label) ||
                      event.title.startsWith(OrderStatus.closed.label)),
            ),
      )
      .length;
  int get stoppedEquipmentCount => orders
      .where(
        (o) =>
            o.equipmentStopped &&
            ![
              OrderStatus.closed,
              OrderStatus.cancelled,
              OrderStatus.rejected,
            ].contains(o.status),
      )
      .map((o) => '${o.area}/${o.equipment}')
      .toSet()
      .length;

  final employees = const [
    Employee(
      id: 1,
      name: 'Ерлан Ахметов',
      specialty: 'Слесарь',
      grade: 5,
      brigade: 'Бригада №1',
      rating: 4.8,
    ),
    Employee(
      id: 2,
      name: 'Данияр Садыков',
      specialty: 'Электрик',
      grade: 6,
      brigade: 'Бригада №2',
      rating: 4.9,
    ),
    Employee(
      id: 3,
      name: 'Алексей Ким',
      specialty: 'Сварщик',
      grade: 5,
      brigade: 'Бригада №1',
      rating: 4.7,
    ),
    Employee(
      id: 4,
      name: 'Марат Нурланов',
      specialty: 'Слесарь',
      grade: 4,
      brigade: 'Бригада №3',
      rating: 4.6,
    ),
    Employee(
      id: 5,
      name: 'Иван Петров',
      specialty: 'Электрик',
      grade: 5,
      brigade: 'Бригада №2',
      rating: 4.5,
      onShift: false,
    ),
  ];

  late final List<WorkOrder> orders = _seed();

  void addScreenshotOrders() {
    final finished = now.subtract(const Duration(minutes: 10));
    for (final (number, apiStatus, title, equipment, work) in [
      (
        151,
        'COMPLETED',
        'Замена подшипника привода',
        'Дробилка КМД-1750',
        'Подшипник заменён. Проверены крепления и выполнен контрольный запуск. Посторонний шум устранён.',
      ),
      (
        152,
        'AI_REVIEW',
        'Плановая смазка и проверка узлов',
        'Грохот ГИС-52',
        'Выполнена смазка узлов. Проверены крепления и работа оборудования под нагрузкой.',
      ),
    ]) {
      if (orders.any((order) => order.number == number)) continue;
      orders.add(
        WorkOrder(
          number: number,
          apiStatus: apiStatus,
          title: title,
          description: title,
          equipment: equipment,
          area: 'Дробление',
          employeeId: 1,
          priority: 'Плановый',
          planned: true,
          status: OrderStatus.review,
          createdAt: finished.subtract(const Duration(minutes: 55)),
          deadline: now.add(const Duration(minutes: 60)),
          finishedAt: finished,
          completedWork: work,
          faultCode: faultCodes.first,
          materials: '${executorMaterials.last}: 0.5',
          assessment: apiStatus == 'AI_REVIEW'
              ? const ExecutionAssessment(verdict: 'Принят', score: 4.8)
              : null,
          history: [
            OrderEvent(
              title: OrderStatus.issued.label,
              status: OrderStatus.issued,
              author: masterName,
              time: finished.subtract(const Duration(minutes: 55)),
            ),
            OrderEvent(
              title: OrderStatus.working.label,
              status: OrderStatus.working,
              author: employee(1).name,
              time: finished.subtract(const Duration(minutes: 38)),
            ),
            OrderEvent(
              title: OrderStatus.review.label,
              status: OrderStatus.review,
              author: employee(1).name,
              time: finished,
            ),
          ],
        ),
      );
    }
  }

  List<WorkOrder> _seed() {
    final now = this.now;

    WorkOrder order({
      required int number,
      required String title,
      required String equipment,
      required String area,
      required int employeeId,
      required String priority,
      required OrderStatus status,
      required int deadlineMinutes,
      bool planned = false,
    }) {
      final created = now.subtract(Duration(minutes: 15 + (number % 6) * 12));

      return WorkOrder(
        number: number,
        title: title,
        description:
            'Проверить состояние оборудования, устранить неисправность '
            'и выполнить контрольный запуск.',
        area: area,
        equipment: equipment,
        employeeId: employeeId,
        priority: priority,
        deadline: now.add(Duration(minutes: deadlineMinutes)),
        createdAt: created,
        planned: planned,
        status: status,
        equipmentStopped: number == 147 || number == 148,
        beforePhotos: 1,
        afterPhotos: status == OrderStatus.review ? 1 : 0,
        completedWork: status == OrderStatus.review
            ? 'Заменено уплотнение. Соединения проверены. '
                  'При контрольном запуске течь отсутствует.'
            : '',
        faultCode: status == OrderStatus.review ? 'Г-01 · Течь масла' : '',
        materials: status == OrderStatus.review
            ? 'Уплотнение 40×60 — 1 шт.\nМасло И-40 — 0,5 л'
            : '',
        comment: number == 147 ? 'Ждём подшипник со склада' : '',
        history: [
          OrderEvent(title: 'Наряд выдан', author: 'С. Омаров', time: created),
          if (status != OrderStatus.issued)
            OrderEvent(
              title: status.label,
              author: employee(employeeId).name,
              time: created.add(const Duration(minutes: 12)),
            ),
        ],
      );
    }

    WorkOrder completedOrder({
      required int number,
      required String title,
      required String equipment,
      required String area,
      required int daysAgo,
      required int minutes,
      required double score,
      required String work,
      required String materials,
    }) {
      final finished = now.subtract(Duration(days: daysAgo));
      final started = finished.subtract(Duration(minutes: minutes));
      final created = started.subtract(const Duration(minutes: 15));
      return WorkOrder(
        number: number,
        title: title,
        description: title,
        equipment: equipment,
        area: area,
        employeeId: 1,
        priority: 'Плановый',
        planned: true,
        status: OrderStatus.closed,
        createdAt: created,
        deadline: finished.add(const Duration(minutes: 30)),
        completedWork: work,
        materials: materials,
        faultCode: faultCodes.first,
        masterScore: score,
        history: [
          OrderEvent(
            title: 'Наряд выдан',
            author: masterName,
            time: created,
            status: OrderStatus.issued,
          ),
          OrderEvent(
            title: 'Принят',
            author: employee(1).name,
            time: created.add(const Duration(minutes: 5)),
            status: OrderStatus.accepted,
          ),
          OrderEvent(
            title: 'В работе',
            author: employee(1).name,
            time: started,
            status: OrderStatus.working,
          ),
          OrderEvent(
            title: 'На проверке',
            author: employee(1).name,
            time: finished,
            status: OrderStatus.review,
          ),
          OrderEvent(
            title: 'Закрыт',
            author: masterName,
            time: finished.add(const Duration(minutes: 10)),
            status: OrderStatus.closed,
          ),
        ],
      );
    }

    return [
      order(
        number: 147,
        title: 'Замена подшипника привода',
        equipment: 'Дробилка КМД-1750',
        area: 'Дробление',
        employeeId: 1,
        priority: 'Высокий',
        status: OrderStatus.working,
        deadlineMinutes: -45,
      ),
      order(
        number: 148,
        title: 'Устранение течи масла',
        equipment: 'Насос Н-12',
        area: 'Обогащение',
        employeeId: 4,
        priority: 'Аварийный',
        status: OrderStatus.issued,
        deadlineMinutes: 50,
      ),
      order(
        number: 149,
        title: 'Проверка питания двигателя',
        equipment: 'Конвейер К-3',
        area: 'Дробление',
        employeeId: 2,
        priority: 'Высокий',
        status: OrderStatus.accepted,
        deadlineMinutes: 120,
      ),
      order(
        number: 150,
        title: 'Плановая смазка узлов',
        equipment: 'Грохот ГИС-52',
        area: 'Дробление',
        employeeId: 1,
        priority: 'Плановый',
        status: OrderStatus.queued,
        deadlineMinutes: 180,
        planned: true,
      ),
      order(
        number: 145,
        title: 'Замена уплотнения вала',
        equipment: 'Насос Н-12',
        area: 'Обогащение',
        employeeId: 4,
        priority: 'Обычный',
        status: OrderStatus.review,
        deadlineMinutes: 60,
      ),
      completedOrder(
        number: 141,
        title: 'Замена подшипника привода',
        equipment: 'Дробилка КМД-1750',
        area: 'Дробление',
        daysAgo: 1,
        minutes: 38,
        score: 4.8,
        work:
            'Подшипник заменён. Проверены крепления и выполнен контрольный запуск. Посторонний шум устранён.',
        materials: 'Подшипник — 1 шт.\nСмазка — 0,2 кг',
      ),
      completedOrder(
        number: 139,
        title: 'Плановая смазка и проверка узлов',
        equipment: 'Грохот ГИС-52',
        area: 'Дробление',
        daysAgo: 3,
        minutes: 24,
        score: 4.6,
        work:
            'Выполнена смазка узлов. Проверены крепления и работа оборудования под нагрузкой.',
        materials: 'Смазка — 0,5 кг',
      ),
      order(
        number: 143,
        title: 'Восстановление защитного кожуха',
        equipment: 'Конвейер К-3',
        area: 'Дробление',
        employeeId: 3,
        priority: 'Обычный',
        status: OrderStatus.closed,
        deadlineMinutes: -120,
      ),
    ];
  }

  Employee? sessionEmployee;

  @override
  Employee employee(int id) {
    if (sessionEmployee?.id == id) return sessionEmployee!;
    return employees.firstWhere((item) => item.id == id);
  }

  int get nextNumber {
    return orders.fold<int>(
          0,
          (maximum, order) => order.number > maximum ? order.number : maximum,
        ) +
        1;
  }

  int count(OrderStatus status) {
    return orders.where((order) => order.status == status).length;
  }

  @override
  List<WorkOrder> assignedTo(int employeeId) {
    final member = employee(employeeId);
    return orders
        .where(
          (order) => order.brigade == null
              ? order.employeeId == employeeId
              : order.brigade == member.brigade,
        )
        .toList();
  }

  String employeeStatus(Employee employee) {
    if (!employee.onShift) return 'Не на смене';

    final assigned = assignedTo(employee.id);

    final working = assigned
        .where(
          (order) =>
              order.status == OrderStatus.working ||
              order.status == OrderStatus.paused ||
              order.status == OrderStatus.rework,
        )
        .firstOrNull;

    final queued = assigned
        .where((order) => order.status == OrderStatus.queued)
        .length;

    if (working != null) {
      return 'В работе · №${working.number}'
          '${queued > 0 ? ' · очередь $queued' : ''}';
    }

    if (queued > 0) return 'В очереди · $queued';

    final assignedOrder = assigned
        .where(
          (order) =>
              order.status == OrderStatus.issued ||
              order.status == OrderStatus.accepted,
        )
        .firstOrNull;
    if (assignedOrder != null) {
      return 'Занят · назначен №${assignedOrder.number}';
    }

    return 'Свободен';
  }

  Color employeeColor(Employee employee) {
    final status = employeeStatus(employee);

    if (!employee.onShift) return const Color(0xFF94A3B8);
    if (status == 'Свободен') return const Color(0xFF059669);
    if (status.startsWith('В очереди')) {
      return const Color(0xFF2563EB);
    }

    return const Color(0xFFD97706);
  }

  void addOrder(WorkOrder order) {
    if (order.history.isEmpty) {
      order.history.add(
        OrderEvent(
          title: 'Наряд выдан: ${assignmentLabel(order)}',
          kind: OrderEventKind.issued,
          value: assignmentLabel(order),
          author: masterName,
          time: order.createdAt,
        ),
      );
    }
    orders.insert(0, order);
    _orderChanged(OrderEventKind.issued);
  }

  WorkOrder issueOrder({
    required String title,
    required String description,
    required String area,
    required String equipment,
    int? employeeId,
    String? brigade,
    required String priority,
    required bool planned,
    DateTime? deadline,
    double? normHours,
    String comment = '',
    String faultCode = '',
    bool equipmentStopped = false,
    List<OrderPhoto> photos = const [],
  }) {
    final issuedAt = now;
    if (normHours != null && (!normHours.isFinite || normHours <= 0)) {
      throw ArgumentError('Норматив должен быть больше нуля');
    }
    final assignee = brigade == null
        ? (employeeId == null ? null : employee(employeeId))
        : brigadeMembers(brigade).where((e) => e.onShift).firstOrNull;
    if (assignee == null || !assignee.onShift) {
      throw ArgumentError('Выберите исполнителя или бригаду на смене');
    }
    final dueAt = normHours == null
        ? deadline
        : issuedAt.add(Duration(minutes: (normHours * 60).round()));
    if (dueAt == null || !dueAt.isAfter(issuedAt)) {
      throw ArgumentError('Срок должен быть в будущем');
    }
    if (photos.length > 5) throw ArgumentError('Не более 5 фото');
    final order = WorkOrder(
      number: nextNumber,
      title: title,
      description: description,
      area: area,
      equipment: equipment,
      employeeId: assignee.id,
      brigade: brigade,
      priority: priority,
      planned: planned,
      createdAt: issuedAt,
      deadline: dueAt,
      normHours: normHours,
      comment: comment,
      faultCode: faultCode,
      equipmentStopped: equipmentStopped,
      beforePhotos: photos.length,
      beforeImages: photos,
    );
    addOrder(order);
    return order;
  }

  void changeStatus(
    WorkOrder order,
    OrderStatus status, {
    String reason = '',
    String author = 'Мастер · С. Омаров',
  }) {
    if (order.status == status) return;
    order.status = status;

    order.history.add(
      OrderEvent(
        title: '${status.label}${reason.isEmpty ? '' : ': $reason'}',
        kind: OrderEventKind.status,
        status: status,
        reason: reason,
        author: author,
        time: now,
      ),
    );

    _orderChanged(OrderEventKind.status);
  }

  void reassign(WorkOrder order, int employeeId) {
    if (!employee(employeeId).onShift) {
      throw ArgumentError('Сотрудник не на смене');
    }
    if (order.brigade == null && order.employeeId == employeeId) return;
    order.employeeId = employeeId;
    order.brigade = null;

    order.history.add(
      OrderEvent(
        title: 'Переназначен: ${employee(employeeId).name}',
        kind: OrderEventKind.reassigned,
        value: employee(employeeId).name,
        author: 'Мастер · С. Омаров',
        time: DateTime.now(),
      ),
    );

    _orderChanged(OrderEventKind.reassigned);
  }

  void changePriority(WorkOrder order, String priority) {
    if (order.priority == priority) return;
    order.priority = priority;

    order.history.add(
      OrderEvent(
        title: 'Приоритет изменён: $priority',
        kind: OrderEventKind.priority,
        value: priority,
        author: 'Мастер · С. Омаров',
        time: DateTime.now(),
      ),
    );

    _orderChanged(OrderEventKind.priority);
  }

  void reassignBrigade(WorkOrder order, String brigade) {
    final contact = brigadeMembers(brigade).where((e) => e.onShift).firstOrNull;
    if (contact == null) throw ArgumentError('Бригада не на смене');
    if (order.brigade == brigade) return;
    order.brigade = brigade;
    order.employeeId = contact.id;
    order.history.add(
      OrderEvent(
        title: 'Переназначен: $brigade',
        kind: OrderEventKind.reassigned,
        value: brigade,
        author: masterName,
        time: now,
      ),
    );
    _orderChanged(OrderEventKind.reassigned);
  }

  void setMasterScore(WorkOrder order, double score) {
    if (order.masterScore == score) return;
    order.masterScore = score;

    order.history.add(
      OrderEvent(
        title: 'Оценка мастера: ${score.toStringAsFixed(1)} / 5',
        kind: OrderEventKind.score,
        value: score.toStringAsFixed(1),
        author: 'Мастер · С. Омаров',
        time: DateTime.now(),
      ),
    );

    _orderChanged(OrderEventKind.score);
  }

  void changeDeadline(WorkOrder order, DateTime deadline) {
    if (!deadline.isAfter(now)) {
      throw ArgumentError('Срок должен быть в будущем');
    }
    if (order.deadline == deadline) return;
    if ([OrderStatus.closed, OrderStatus.cancelled].contains(order.status)) {
      throw StateError('Наряд завершён');
    }
    final previous =
        '${dateLabel(order.deadline)} ${timeLabel(order.deadline)}';
    final next = '${dateLabel(deadline)} ${timeLabel(deadline)}';
    order.deadline = deadline;
    order.normHours = null;
    order.history.add(
      OrderEvent(
        title: 'Срок изменён: $previous → $next',
        kind: OrderEventKind.deadline,
        value: '$previous → $next',
        author: masterName,
        time: now,
      ),
    );
    _orderChanged(OrderEventKind.deadline);
  }
}
