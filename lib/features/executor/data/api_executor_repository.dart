import '../models/executor_rating_period.dart';
import 'package:mineral/core/services/photo_upload_rules.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'executor_realtime.dart';
import 'pending_action_storage.dart';
import '../models/pending_action.dart';
import 'package:uuid/uuid.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:mineral/shared/models/models.dart';
import '../models/execution_assessment.dart';
import '../models/executor_order_dto.dart';
import 'executor_api.dart';
import 'executor_repository.dart';
import 'execution_draft_storage.dart';
import '../models/executor_order_actions.dart';
import 'package:crypto/crypto.dart';

class _QueueSyncResult {
  const _QueueSyncResult(
    this.permanentErrors, [
    this.blockingError,
    this.appliedActions = const {},
  ]);

  final Map<String, ApiException> permanentErrors;
  final Object? blockingError;
  final Set<String> appliedActions;
}

class ApiExecutorRepository extends ChangeNotifier
    implements ExecutorRepository {
  ApiExecutorRepository({
    required this.api,
    ExecutionDraftStorage? draftStorage,
    PendingActionStorage? actionStorage,
  }) : draftStorage =
           draftStorage ??
           createExecutionDraftStorage(folderName: 'api_execution_drafts'),
       actionStorage =
           actionStorage ?? createPendingActionStorage(api.session.user!.id),
       _user = api.session.user ?? (throw StateError('Требуется вход'));
  final ExecutorApi api;
  final ExecutionDraftStorage draftStorage;
  final PendingActionStorage actionStorage;
  Future<_QueueSyncResult>? _syncFuture;
  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;
  Timer? _queueTimer;
  final AuthUser _user;
  ExecutorRealtime? _realtime;
  final _notification = <Map<String, dynamic>>[];
  int _notificationRevision = 0;
  Future<void>? _notificationLoading;
  final _orderVersion = <int, int>{};
  final _orderStateVersion = <int, int>{};
  final _orderUpdatedAt = <int, DateTime>{};

  void _recordOrderState(int id, [DateTime? updatedAt]) {
    _orderStateVersion[id] = (_orderStateVersion[id] ?? 0) + 1;
    if (updatedAt == null) {
      _orderUpdatedAt.remove(id);
    } else {
      _orderUpdatedAt[id] = updatedAt;
    }
  }

  DateTime? _updatedAt(ExecutorOrderDto dto) {
    final value = dto.details['updatedAt'];
    return value is String ? DateTime.tryParse(value)?.toUtc() : null;
  }

  int _nextOrderVersion(int id) {
    final version = (_orderVersion[id] ?? 0) + 1;
    _orderVersion[id] = version;
    return version;
  }

  bool _isOrderLoadCurrent(int id, int version) =>
      _sessionActive && _orderVersion[id] == version;

  WorkOrder _latestOrder(int employeeId, WorkOrder original) {
    if (!_sessionActive) {
      throw const ApiException(401, 'Сессия завершена');
    }
    final id = original.apiId;
    final current = _active[id] ?? _history[id] ?? original;
    _checkOrder(employeeId, current);
    return current;
  }

  List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notification);
  bool get _sessionActive =>
      !_disposed &&
      api.session.authenticated &&
      api.session.user?.id == _user.id;
  void startRealtime() {
    if (!_sessionActive || _realtime != null) return;

    _realtime = ExecutorRealtime(
      session: api.session,
      onConnected: _refreshAfterConnection,
      onOrderChanged: _onOrderChanged,
      onNotification: _onNotification,
    );
    _realtime!.connect();
    _queueTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_sessionActive) {
        unawaited(syncPendingActions().catchError((Object _) {}));
      }
    });
  }

  Future<void> _refreshAfterConnection() async {
    while (_loading && _sessionActive) {
      await Future<void>.delayed(Duration(milliseconds: 100));
    }
    if (!_sessionActive) return;
    int revision;
    do {
      revision = _revision;
      String? syncError;
      try {
        await syncPendingActions();
      } catch (_) {
        syncError = _error;
      }
      await refreshExecutor(_user.id);
      if (syncError != null) {
        _error = syncError;
        _notify();
      }
    } while (_sessionActive && revision != _revision);
    if (_sessionActive) {
      await loadNotification();
    }
  }

  Future<void> _onOrderChanged(Map<String, dynamic> data) async {
    if (!_sessionActive) return;
    try {
      final id = data['id'] as int;
      final existing = _active[id] ?? _history[id];

      if (data['assigneeId'] != _user.id) {
        if (existing != null) {
          _removeUnavailable(
            existing,
            const ApiException(403, "Наряд переназначен другому исполнителю."),
          );
        }
        return;
      }

      final dto = ExecutorOrderDto.fromJson(data);

      final order = _store(dto, existing: existing);
      _revision++;
      _notify();

      if (order.status == OrderStatus.closed) {
        unawaited(
          loadExecutorRating(
            _user.id,
          ).catchError((Object _) => executorRating(_user.id)),
        );
      }

      if (existing?.detailsLoaded == true) {
        await loadExecutorOrder(_user.id, order);
      } else if (order.status == OrderStatus.queued) {
        await loadExecutorOrderTime(_user.id, order);
      }
    } catch (e) {
      if (!_sessionActive) return;
      _error = e is ApiException && e.message.isNotEmpty
          ? e.message
          : 'Не удалось обновить данные. Потяните список вниз, чтобы повторить.';
      _notify();
      rethrow;
    }
  }

  void _sortNotification() {
    _notification.sort(
      (a, b) => DateTime.parse(
        b['createdAt'] as String,
      ).compareTo(DateTime.parse(a['createdAt'] as String)),
    );
    if (_notification.length > 100) {
      _notification.removeRange(100, _notification.length);
    }
  }

  void _onNotification(Map<String, dynamic> data) {
    if (!_sessionActive || data['userId'] != _user.id) return;
    final id = data['id'] as int;

    _notification.removeWhere((item) => item['id'] == id);
    _notification.add(Map<String, dynamic>.from(data));
    _notificationRevision++;
    _sortNotification();
    _notify();
  }

  Future<void> loadNotification() {
    return _notificationLoading ??= _loadNotification().whenComplete(() {
      _notificationLoading = null;
    });
  }

  Future<void> _loadNotification() async {
    while (_sessionActive) {
      final revision = _notificationRevision;
      final items = await api.loadNotification();

      if (!_sessionActive) return;
      if (revision != _notificationRevision) continue;

      _notification
        ..clear()
        ..addAll(
          items
              .where((item) => item['userId'] == _user.id)
              .map((item) => Map<String, dynamic>.from(item)),
        );
      _sortNotification();
      _notify();
      return;
    }
  }

  Future<void> markNotificationRead(int id) async {
    _checkUser(_user.id);
    if (!_notification.any(
      (item) => item['id'] == id && item['userId'] == _user.id,
    )) {
      throw const ApiException(403, 'Недостаточно прав');
    }
    await api.markNotificationRead(id);
    if (!_sessionActive) return;
    for (final item in _notification) {
      if (item['id'] == id) {
        item['isRead'] = true;
        break;
      }
    }
    _notificationRevision++;
    _notify();
  }

  final _active = <int, WorkOrder>{};
  final _history = <int, WorkOrder>{};
  final _drafts = <(int, int), ExecutionDraft>{};
  final _faultIds = <String, int>{};
  final _materialIds = <String, int>{};
  final _uploaded = <OrderPhoto, String>{};

  bool _loading = false;
  int _revision = 0;
  bool _disposed = false;
  String? _error;
  List<WorkOrder> get activeOrders => List.unmodifiable(_active.values);
  List<WorkOrder> get historyOrders => List.unmodifiable(_history.values);
  @override
  DateTime get now => DateTime.now();
  @override
  bool get isLoading => _loading;
  @override
  String? get loadError => _error;
  @override
  List<String> get executorFaultCodes => List.unmodifiable(_faultIds.keys);
  @override
  List<String> get executorMaterials => List.unmodifiable(_materialIds.keys);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _checkUser(int id) {
    if (id != _user.id ||
        api.session.user?.id != id ||
        _user.role != 'EXECUTOR') {
      throw const ApiException(403, 'Недостаточно прав');
    }
  }

  void _checkOrder(int id, WorkOrder order) {
    _checkUser(id);
    if (order.accessErrorStatus == 403 || order.accessErrorStatus == 404) {
      throw ApiException(
        order.accessErrorStatus!,
        order.accessErrorMessage ?? '',
      );
    }
    if (order.apiId == null || order.employeeId != id) {
      throw const ApiException(403, 'Недостаточно прав');
    }
  }

  void _removeUnavailable(WorkOrder order, ApiException error) {
    _nextOrderVersion(order.apiId!);
    _recordOrderState(order.apiId!);
    order.accessErrorStatus = error.status;
    order.accessErrorMessage = error.message;
    _active.remove(order.apiId);
    _history.remove(order.apiId);
    _revision++;
    _notify();
  }

  @override
  Employee employee(int id) {
    if (id != _user.id) throw StateError('Неизвестный исполнитель');
    return Employee(
      id: id,
      name: _user.fullName,
      specialty: _user.specialty,
      grade: _user.grade,
      brigade: _user.brigadeId?.toString() ?? '',
      rating: 0,
      onShift: _user.isOnShift,
    );
  }

  @override
  ExecutorRating? executorRating(
    int employeeId, {
    ExecutorRatingPeriod period = const ExecutorRatingPeriod(),
  }) {
    if (employeeId != _user.id || api.session.user?.id != employeeId) {
      return null;
    }
    return _ratings[period.key];
  }

  final _ratings = <String, ExecutorRating>{};
  final _ratingLoads = <String, Future<ExecutorRating?>>{};

  @override
  Future<ExecutorRating?> loadExecutorRating(
    int employeeId, {
    ExecutorRatingPeriod period = const ExecutorRatingPeriod(),
  }) {
    _checkUser(employeeId);
    return _ratingLoads[period.key] ??= _loadRating(employeeId, period)
        .whenComplete(() {
          _ratingLoads.remove(period.key);
        });
  }

  Future<ExecutorRating?> _loadRating(
    int employeeId,
    ExecutorRatingPeriod period,
  ) async {
    final data = await api.loadRating(period: period);
    _checkUser(employeeId);
    if (data['id'] != employeeId) {
      throw const ApiException(403, 'Недостаточно прав');
    }
    final rating = ExecutorRating.fromJson(data);
    _ratings[period.key] = rating;
    _notify();
    return rating;
  }

  Future<void> _draftOperations = Future.value();

  Future<T> _withDraftLock<T>(Future<T> Function() operation) {
    final result = _draftOperations.then((_) => operation());
    _draftOperations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  String _reportVersion(ExecutionDraft report) {
    final materialName = report.materials.keys.toList()..sort();
    final content = {
      'work': report.work,
      'faultCode': report.faultCode,
      'comment': report.comment,
      'legacyMaterials': report.legacyMaterials,
      'materials': [
        for (final name in materialName) [name, report.materials[name]],
      ],
      'photos': [
        for (final photo in report.photos)
          {'name': photo.name, 'hash': sha256.convert(photo.bytes).toString()},
      ],
    };
    return sha256.convert(utf8.encode(jsonEncode(content))).toString();
  }

  Future<void> _clearSubmittedDraft(
    int employeeId,
    int orderNumber,
    String? submittedVersion,
  ) => _withDraftLock(() async {
    if (submittedVersion == null) return;
    final key = (employeeId, orderNumber);
    final current =
        _drafts[key] ?? await draftStorage.load(employeeId, orderNumber);
    if (current == null || _reportVersion(current) != submittedVersion) {
      return;
    }

    await draftStorage.remove(employeeId, orderNumber);
    _drafts.remove(key);
  });

  @override
  List<WorkOrder> assignedTo(int employeeId) => [
    ..._active.values,
    ..._history.values,
  ].where((o) => o.employeeId == employeeId).toList();
  Future<List<ExecutorOrderDto>> _pages(String statuses) async {
    final result = <ExecutorOrderDto>[];
    while (true) {
      final page = await api.loadOrders(statuses, offset: result.length);
      result.addAll(page);
      if (page.length < 200) return result;
    }
  }

  @override
  Future<void> refreshExecutor(int employeeId) async {
    _checkUser(employeeId);
    if (_loading) return;
    final revision = _revision;
    _loading = true;
    _error = null;
    _notify();
    try {
      // Commit both lists together: a failed history request cannot erase current data.
      final results = await Future.wait<Object>([
        _pages('ISSUED,QUEUED,ACCEPTED,IN_PROGRESS,PAUSED,REWORK'),
        _pages('COMPLETED,AI_REVIEW,CLOSED,CANCELLED,REJECTED'),
        api.references('fault-codes'),
        api.references('materials'),
      ]);
      final active = results[0] as List<ExecutorOrderDto>;
      final history = results[1] as List<ExecutorOrderDto>;
      final faults = results[2] as List<Map<String, dynamic>>;
      final materials = results[3] as List<Map<String, dynamic>>;
      // Compact responses omit events; restore FIFO from server QUEUE events.
      final queued = active
          .where(
            (dto) => dto.status == 'QUEUED' && dto.assigneeId == employeeId,
          )
          .toList();
      final queueDetails = <int, ExecutorOrderDto?>{};
      for (var start = 0; start < queued.length; start += 8) {
        await Future.wait(
          queued.skip(start).take(8).map((dto) async {
            try {
              queueDetails[dto.id] = await api.loadOrder(dto.id);
            } on ApiException catch (error) {
              if (error.status != 403 && error.status != 404) rethrow;
              queueDetails[dto.id] = null;
            }
          }),
        );
      }
      final restoredActive = active
          .map(
            (dto) =>
                queueDetails.containsKey(dto.id) ? queueDetails[dto.id] : dto,
          )
          .whereType<ExecutorOrderDto>()
          .toList();
      _checkUser(employeeId);
      if (revision != _revision) return;
      for (final dto in [...restoredActive, ...history]) {
        dto.toWorkOrder();
      }
      _faultIds.clear();
      for (final f in faults) {
        _faultIds['${f['code']} · ${f['name']}'] = f['id'] as int;
      }
      _materialIds.clear();
      for (final m in materials) {
        _materialIds['${m['name']} · ${m['unit']}'] = m['id'] as int;
      }
      final old = {..._active, ..._history};
      _active.clear();
      _history.clear();
      for (final dto in [...restoredActive, ...history]) {
        if (dto.assigneeId != employeeId) continue;
        _store(dto, existing: old[dto.id]);
      }
      _hasLoaded = true;
    } catch (e) {
      _error = e is ApiException && e.message.isNotEmpty
          ? e.message
          : 'Не удалось обновить данные. Потяните список вниз, чтобы повторить.';
      rethrow;
    } finally {
      _loading = false;
      _notify();
    }
  }

  double? _decimal(Object? value) =>
      value == null ? null : double.parse('$value');
  OrderStatus _status(String value) => executorOrderStatus(value);
  WorkOrder _store(
    ExecutorOrderDto dto, {
    WorkOrder? existing,
    List<OrderPhoto>? before,
    List<OrderPhoto>? after,
  }) {
    final mapped = dto.toWorkOrder();
    final order = existing ?? _active[dto.id] ?? _history[dto.id] ?? mapped;
    order.accessErrorStatus = null;
    order.accessErrorMessage = null;
    order.title = mapped.title;
    order.description = mapped.description;
    order.area = mapped.area;
    order.equipment = mapped.equipment;
    order.employeeId = mapped.employeeId;
    order.priority = mapped.priority;
    order.deadline = mapped.deadline;
    order.planned = mapped.planned;
    order.status = mapped.status;
    order.apiStatus = dto.status;
    order.comment = mapped.comment;
    final data = dto.details;
    // Compact lists omit report fields; only supplied fields replace loaded details.
    if (data.containsKey('closedAt') || data.containsKey('completedAt')) {
      final finished = data['closedAt'] ?? data['completedAt'];
      order.finishedAt = finished == null
          ? null
          : DateTime.parse(finished as String).toLocal();
    }
    if (data.containsKey('completionText')) {
      order.completedWork = data['completionText'] as String? ?? '';
    }
    if (data.containsKey('faultCode')) {
      final fault = data['faultCode'] as Map?;
      order.faultCode = fault == null
          ? ''
          : '${fault['code']} · ${fault['name']}';
    } else if (data.containsKey('faultCodeId') && data['faultCodeId'] == null) {
      order.faultCode = '';
    }
    if (data['materialUsages'] case final List usages) {
      order.materials = usages
          .map(
            (u) =>
                '${u['material']['name']} · ${u['material']['unit']}: ${_decimal(u['quantity'])}',
          )
          .join('\n');
    }
    if (data.containsKey('normative')) {
      final normative = data['normative'] as Map?;
      order.normHours = _decimal(normative?['hours']);
    } else if (data.containsKey('normativeId') && data['normativeId'] == null) {
      order.normHours = null;
    }
    if (data.containsKey('actualDowntimeMinutes')) {
      order.downtimeMinutes = data['actualDowntimeMinutes'] as int?;
    }
    if (data['events'] case final List events) {
      order.detailsLoaded = true;
      order.history.clear();
      for (final e in events) {
        final status = e['toStatus'] == null
            ? null
            : _status(e['toStatus'] as String);
        order.history.add(
          OrderEvent(
            title: status?.label ?? e['action'] as String,
            author: (e['actor'] as Map?)?['fullName'] as String? ?? '',
            time: DateTime.parse(e['createdAt'] as String).toLocal(),
            kind: status == null ? null : OrderEventKind.status,
            status: status,
            reason: e['comment'] as String? ?? '',
          ),
        );
      }
    }
    if (data['aiAssessment'] case final Map a) {
      order.aiScore = _decimal(a['score']);
      order.masterScore = _decimal(a['masterScore']);
      order.assessment = ExecutionAssessment(
        verdict: a['verdict'] as String? ?? '',
        score: _decimal(a['score']),
        explanation: a['explanation'] as String? ?? '',
        strengths: (a['strengths'] as List?)?.join('\n') ?? '',
        improvements: (a['improvements'] as List?)?.join('\n') ?? '',
      );
      order.aiVerdict = order.assessment!.verdict;
      order.aiExplanation = order.assessment!.explanation;
    } else if (data.containsKey('aiAssessment')) {
      order.assessment = null;
      order.aiVerdict = 'Нет заключения';
      order.aiExplanation = '';
      order.aiScore = null;
      order.masterScore = null;
    }
    if (before != null) {
      order.beforeImages
        ..clear()
        ..addAll(before);
      order.beforePhotos = before.length;
    }
    if (after != null) {
      order.afterImages
        ..clear()
        ..addAll(after);
      order.afterPhotos = after.length;
    }
    _active.remove(dto.id);
    _history.remove(dto.id);
    final archived = {
      OrderStatus.closed,
      OrderStatus.cancelled,
      OrderStatus.rejected,
    }.contains(order.status);
    (archived ? _history : _active)[dto.id] = order;
    _recordOrderState(dto.id, _updatedAt(dto));
    _nextOrderVersion(dto.id);
    return order;
  }

  final _timeLoads = <int, Future<WorkOrder>>{};

  @override
  Future<WorkOrder> loadExecutorOrderTime(int employeeId, WorkOrder order) {
    _checkOrder(employeeId, order);
    if (order.detailsLoaded) return Future.value(order);
    final id = order.apiId!;
    return _timeLoads.putIfAbsent(
      id,
      () => _loadOrderTime(employeeId, order).whenComplete(() {
        _timeLoads.remove(id);
      }),
    );
  }

  Future<WorkOrder> _loadOrderTime(int employeeId, WorkOrder order) async {
    _checkOrder(employeeId, order);
    final id = order.apiId!;
    final version = _nextOrderVersion(id);
    try {
      final dto = await api.loadOrder(id);
      if (!_isOrderLoadCurrent(id, version)) {
        return _latestOrder(employeeId, order);
      }
      if (dto.assigneeId != employeeId) {
        throw const ApiException(403, "Недостаточно прав");
      }
      if (dto.details['events'] is! List) {
        throw const FormatException('Order events missing');
      }
      final result = _store(dto, existing: order);
      _notify();
      return result;
    } catch (error) {
      if (!_isOrderLoadCurrent(id, version)) {
        return _latestOrder(employeeId, order);
      }
      if (error is ApiException &&
          (error.status == 403 || error.status == 404)) {
        _removeUnavailable(order, error);
      }
      rethrow;
    }
  }

  @override
  Future<WorkOrder> loadExecutorOrder(int employeeId, WorkOrder order) async {
    _checkOrder(employeeId, order);

    final id = order.apiId!;
    final version = _nextOrderVersion(id);
    var loadingMetadata = true;

    Future<List<OrderPhoto>> photos(ExecutorOrderDto dto, String type) async {
      return Future.wait(
        ((dto.details['photos'] as List?) ?? [])
            .where((photo) => photo['type'] == type)
            .map((photo) async {
              final url = photo['fileUrl'] as String;
              final image = OrderPhoto(
                name: Uri.parse(url).path.split('/').last,
                bytes: await api.session.downloadPhoto(url),
              );

              if (type == 'AFTER' && _isOrderLoadCurrent(id, version)) {
                _uploaded[image] = url;
              }

              return image;
            }),
      );
    }

    try {
      var dto = await api.loadOrder(id);

      if (!_isOrderLoadCurrent(id, version)) {
        return _latestOrder(employeeId, order);
      }

      if (dto.assigneeId != employeeId) {
        throw const ApiException(403, 'Недостаточно прав');
      }

      loadingMetadata = false;

      List<OrderPhoto> before;
      List<OrderPhoto> after;

      try {
        before = await photos(dto, 'BEFORE');

        if (!_isOrderLoadCurrent(id, version)) {
          return _latestOrder(employeeId, order);
        }

        after = await photos(dto, 'AFTER');
      } on ApiException catch (error) {
        if (!_isOrderLoadCurrent(id, version)) {
          return _latestOrder(employeeId, order);
        }

        if (error.status != 401 && error.status != 403) {
          rethrow;
        }

        // Обновляем подписанные ссылки на фотографии.
        loadingMetadata = true;
        dto = await api.loadOrder(id);

        if (!_isOrderLoadCurrent(id, version)) {
          return _latestOrder(employeeId, order);
        }

        if (dto.assigneeId != employeeId) {
          throw const ApiException(403, 'Недостаточно прав');
        }

        loadingMetadata = false;
        before = await photos(dto, 'BEFORE');

        if (!_isOrderLoadCurrent(id, version)) {
          return _latestOrder(employeeId, order);
        }

        after = await photos(dto, 'AFTER');
      }

      // За время скачивания фото статус мог уже измениться.
      if (!_isOrderLoadCurrent(id, version)) {
        return _latestOrder(employeeId, order);
      }

      final result = _store(dto, existing: order, before: before, after: after);

      _notify();
      return result;
    } catch (error) {
      if (!_isOrderLoadCurrent(id, version)) {
        return _latestOrder(employeeId, order);
      }

      if (loadingMetadata &&
          error is ApiException &&
          (error.status == 403 || error.status == 404)) {
        _removeUnavailable(order, error);
      }

      rethrow;
    }
  }

  Future<bool> _send(
    int employeeId,
    WorkOrder order,
    Map<String, dynamic> body,
  ) async {
    _checkOrder(employeeId, order);
    final actions = await actionStorage.load();
    final same = actions.where(
      (a) =>
          a.type == 'workOrderAction' &&
          a.orderNumber == order.apiId &&
          a.payload['action'] == body['action'],
    );
    final existing = same.firstOrNull;
    final actionName = body['action'] as String;
    if (existing != null &&
        (actionName == 'PAUSE' || actionName == 'REJECT') &&
        existing.payload['comment'] != body['comment']) {
      await actionStorage.add(
        PendingAction(
          id: _reasonDraftId(employeeId, order.apiId!, actionName),
          employeeId: employeeId,
          orderNumber: order.apiId!,
          type: 'actionReasonDraft',
          payload: {'action': actionName, 'comment': body['comment']},
          createdAt: now,
        ),
      );
      _notify();
      throw ApiException(
        409,
        _user.language == 'kk'
            ? 'Алдыңғы әрекет жіберілуді күтуде. Жаңа себеп сақталды.'
            : 'Предыдущее действие ожидает отправки. Новая причина сохранена.',
      );
    }
    if (existing != null &&
        (actionName == 'PAUSE' || actionName == 'REJECT') &&
        existing.payload['comment'] == body['comment']) {
      await actionStorage.remove(
        _reasonDraftId(employeeId, order.apiId!, actionName),
      );
    }
    if (body['action'] == 'COMPLETE' &&
        existing != null &&
        existing.payload['_reportVersion'] != body['_reportVersion']) {
      throw ApiException(
        409,
        _user.language == 'kk'
            ? 'Алдыңғы есеп жіберуді күтіп тұр. '
                  'Жаңа түзетулеріңіз нобайда сақталды.'
            : 'Предыдущий отчёт ожидает подтверждения отправки. '
                  'Ваши новые правки сохранены в черновике.',
      );
    }
    final action =
        same.firstOrNull ??
        PendingAction(
          id: const Uuid().v4(),
          employeeId: employeeId,
          orderNumber: order.apiId!,
          type: 'workOrderAction',
          payload: body,
          createdAt: now,
        );
    if (same.isEmpty) {
      await actionStorage.add(action);
    }
    // An existing sync may have taken its snapshot before this action was added.
    do {
      if (!_sessionActive) throw const ApiException(403, 'Недостаточно прав');
      final result = await _runQueue();
      final ownError = result.permanentErrors[action.id];
      if (ownError != null) throw ownError;
      if (!(await actionStorage.load()).any((item) => item.id == action.id)) {
        return result.appliedActions.contains(action.id);
      }
      if (result.blockingError != null) throw result.blockingError!;
    } while ((await actionStorage.load()).any((item) => item.id == action.id));
    return false;
  }

  String _reasonDraftId(int employeeId, int orderId, String action) =>
      'reason-draft-$employeeId-$orderId-$action';

  @override
  Future<String?> restoreActionReason(
    int employeeId,
    WorkOrder order,
    OrderStatus status,
  ) async {
    _checkOrder(employeeId, order);
    final action = status == OrderStatus.paused ? 'PAUSE' : 'REJECT';
    final actions = await actionStorage.load();
    final draftId = _reasonDraftId(employeeId, order.apiId!, action);
    final draft = actions.where((item) => item.id == draftId).firstOrNull;
    if (draft != null) return draft.payload['comment'] as String?;
    final pending = actions
        .where(
          (item) =>
              item.type == 'workOrderAction' &&
              item.orderNumber == order.apiId &&
              item.payload['action'] == action,
        )
        .firstOrNull;
    return pending?.payload['comment'] as String?;
  }

  Future<_QueueSyncResult> _runQueue() =>
      _syncFuture ??= _syncQueue().whenComplete(() {
        _syncFuture = null;
      });

  Future<void> syncPendingActions() async {
    final result = await _runQueue();
    if (result.blockingError != null) throw result.blockingError!;
    if (result.permanentErrors.isNotEmpty) {
      throw result.permanentErrors.values.first;
    }
  }

  Future<_QueueSyncResult> _syncQueue() async {
    final generation = api.session.sessionGeneration;
    final actions = await actionStorage.load();
    final permanentErrors = <String, ApiException>{};
    final appliedActions = <String>{};

    bool currentSession() =>
        _sessionActive && api.session.sessionGeneration == generation;

    _QueueSyncResult interrupted() => _QueueSyncResult(
      permanentErrors,
      const ApiException(401, 'Сессия завершена'),
      appliedActions,
    );

    for (final action in actions) {
      if (!currentSession()) return interrupted();
      if (action.employeeId != _user.id) {
        return _QueueSyncResult(
          permanentErrors,
          const ApiException(403, 'Недостаточно прав'),
          appliedActions,
        );
      }
      if (action.type == 'actionReasonDraft') continue;
      if (action.type != 'workOrderAction') {
        return _QueueSyncResult(
          permanentErrors,
          StateError('Unsupported queued action'),
          appliedActions,
        );
      }
      final body = Map<String, dynamic>.from(action.payload);
      final submittedVersion = body.remove('_reportVersion') as String?;
      try {
        final photos = body.remove('_localPhotos') as List?;
        if (photos != null) {
          final urls = List<String>.from(body['afterPhotoUrls'] as List);
          for (var index = urls.length; index < photos.length; index++) {
            if (!currentSession()) return interrupted();
            final photo = photos[index] as Map;
            final url =
                photo['url'] as String? ??
                await api.upload(
                  OrderPhoto(
                    name: photo['name'] as String,
                    bytes: base64Decode(photo['bytes'] as String),
                  ),
                );
            urls.add(url);
            action.payload['afterPhotoUrls'] = List.of(urls);
            await actionStorage.add(action);
            if (!currentSession()) return interrupted();
          }
          body['afterPhotoUrls'] = urls;
        }
        if (!currentSession()) return interrupted();
        var order = _active[action.orderNumber] ?? _history[action.orderNumber];
        order ??= (await api.loadOrder(action.orderNumber)).toWorkOrder();
        if (!currentSession()) return interrupted();
        if (await _sendOnline(action.employeeId, order, body, action.id)) {
          appliedActions.add(action.id);
        }
        await actionStorage.remove(action.id);
      } on ApiException catch (e) {
        if (!currentSession()) return interrupted();
        if ({400, 403, 404, 409, 413, 422}.contains(e.status)) {
          await actionStorage.remove(action.id);
          _error = _user.language == 'kk'
              ? 'Әрекет қолданылмады: ${e.message}'
              : 'Действие не применено: ${e.message}';
          _notify();
          permanentErrors[action.id] = e;
          continue;
        }
        _error = _user.language == 'kk'
            ? 'Телефонда сақталды. Жіберуді күтіп тұр.'
            : 'Сохранено на телефоне. Ожидает отправки.';
        _notify();
        return _QueueSyncResult(permanentErrors, e, appliedActions);
      } catch (_) {
        if (!currentSession()) return interrupted();
        _error = _user.language == 'kk'
            ? 'Телефонда сақталды. Жіберуді күтіп тұр.'
            : 'Сохранено на телефоне. Ожидает отправки.';
        _notify();
        return _QueueSyncResult(
          permanentErrors,
          ApiException(0, _error!),
          appliedActions,
        );
      }
    }
    if (actions.isNotEmpty && permanentErrors.isEmpty) {
      _error = null;
      _notify();
    }
    if (!currentSession()) return interrupted();
    return _QueueSyncResult(permanentErrors, null, appliedActions);
  }

  Future<bool> _sendOnline(
    int employeeId,
    WorkOrder order,
    Map<String, dynamic> body,
    String id,
  ) async {
    _checkOrder(employeeId, order);
    final generation = api.session.sessionGeneration;
    bool currentSession() =>
        _sessionActive && api.session.sessionGeneration == generation;
    final orderId = order.apiId!;
    final stateVersion = _orderStateVersion[orderId] ?? 0;
    try {
      final response = await api.action(order.apiId!, {
        ...body,
        'clientActionId': id,
      });
      final data = Map<String, dynamic>.from(response['order'] as Map);
      if (response['assessment'] is Map) {
        data['aiAssessment'] = response['assessment'];
      }
      final dto = ExecutorOrderDto.fromJson(data);
      // Acknowledgement removes the queued action even if its snapshot is stale.
      if (!currentSession()) return false;
      _revision++;
      final current = _active[orderId] ?? _history[orderId] ?? order;
      if (current.accessErrorStatus == 403 ||
          current.accessErrorStatus == 404) {
        return false;
      }
      final responseTime = _updatedAt(dto);
      final latestTime = _orderUpdatedAt[orderId];
      if (responseTime != null &&
          latestTime != null &&
          responseTime.isBefore(latestTime)) {
        return false;
      }
      if (stateVersion != (_orderStateVersion[orderId] ?? 0) &&
          (responseTime == null ||
              latestTime == null ||
              !responseTime.isAfter(latestTime))) {
        // Equal/missing timestamps cannot establish which concurrent state is newer.
        try {
          await loadExecutorOrder(employeeId, current);
        } catch (_) {
          // Keep the confirmed state; an acknowledged action must not be retried.
        }
        return false;
      }
      final oldStatus = current.status;
      _store(dto, existing: current);
      // Action responses can omit events; preserve the timer until detail refresh succeeds.
      if (!dto.details.containsKey('events') &&
          oldStatus != current.status &&
          dto.details['updatedAt'] is String) {
        current.history.add(
          OrderEvent(
            title: current.status.label,
            author: _user.fullName,
            time: DateTime.parse(dto.details['updatedAt'] as String).toLocal(),
            status: current.status,
            kind: OrderEventKind.status,
            reason: body['comment'] as String? ?? '',
          ),
        );
      }
      _notify();
      return true;
    } on ApiException catch (e) {
      if (!currentSession()) rethrow;
      if (e.status == 409) {
        try {
          await loadExecutorOrder(employeeId, order);
        } catch (_) {
          if (order.accessErrorStatus == null) {
            order.accessErrorStatus = 409;
            order.accessErrorMessage = e.message;
            _notify();
          }
        }
      }
      if (e.status == 403 || e.status == 404) {
        _removeUnavailable(order, e);
      }
      rethrow;
    }
  }

  @override
  Future<void> executorAction(
    int employeeId,
    WorkOrder order,
    OrderStatus status, {
    String reason = '',
  }) async {
    final action = switch (status) {
      OrderStatus.accepted => 'ACCEPT',
      OrderStatus.queued => 'QUEUE',
      OrderStatus.rejected => 'REJECT',
      OrderStatus.paused => 'PAUSE',
      OrderStatus.working =>
        order.status == OrderStatus.paused ? 'RESUME' : 'START',
      _ => throw StateError('Недоступное действие исполнителя'),
    };
    _checkOrder(employeeId, order);
    if (!availableExecutorActions(order, employeeId).contains(action)) {
      throw StateError("Действие недоступно из текущего статуса");
    }
    if ((action == 'PAUSE' || action == 'REJECT') && reason.trim().isEmpty) {
      throw StateError('Укажите причину');
    }
    await _send(employeeId, order, {
      'action': action,
      if (reason.trim().isNotEmpty) 'comment': reason.trim(),
    });
    if (action == 'PAUSE' || action == 'REJECT') {
      final draftId = _reasonDraftId(employeeId, order.apiId!, action);
      final saved = (await actionStorage.load())
          .where((item) => item.id == draftId)
          .firstOrNull;
      if (saved != null && saved.payload['comment'] == reason.trim()) {
        await actionStorage.remove(draftId);
        _notify();
      }
    }
  }

  @override
  Future<void> submitExecution(
    int employeeId,
    WorkOrder order,
    ExecutionDraft report,
  ) async {
    _checkOrder(employeeId, order);
    if (!availableExecutorActions(order, employeeId).contains('COMPLETE')) {
      throw StateError('Наряд не в работе');
    }
    if (order.status != OrderStatus.working) {
      throw StateError('Наряд не в работе');
    }
    final fault = _faultIds[report.faultCode];
    if (report.work.trim().isEmpty || fault == null) {
      throw StateError('Заполните выполненные работы и шифр');
    }
    if ((!order.planned && report.photos.isEmpty) || report.photos.length > 5) {
      throw StateError('Проверьте фото после работ');
    }
    if (report.legacyMaterials.isNotEmpty) {
      throw StateError('Выберите материалы из справочника');
    }
    final materials = <Map<String, dynamic>>[];
    for (final e in report.materials.entries) {
      final id = _materialIds[e.key];
      if (id == null || !e.value.isFinite || e.value <= 0) {
        throw StateError('Проверьте материалы');
      }
      materials.add({'materialId': id, 'quantity': e.value});
    }
    for (final photo in report.photos) {
      validatePhotoSize(photo.bytes.length);
    }
    final submittedVersion = _reportVersion(report);

    await saveExecutionDraft(employeeId, order.number, report);
    final applied = await _send(employeeId, order, {
      'action': 'COMPLETE',
      '_reportVersion': submittedVersion,
      'completionText': report.work.trim(),
      'faultCodeId': fault,
      'afterPhotoUrls': <String>[],
      '_localPhotos': report.photos
          .map(
            (p) => {
              'name': p.name,
              'bytes': base64Encode(p.bytes),
              'url': _uploaded[p],
            },
          )
          .toList(),
      'materials': materials,
      if (report.comment.trim().isNotEmpty) 'comment': report.comment.trim(),
    });
    if (applied) {
      order.afterImages
        ..clear()
        ..addAll(report.photos);
      order.afterPhotos = report.photos.length;
    }
    // A cleanup failure must never turn an acknowledged COMPLETE into a second submission.
    try {
      await _clearSubmittedDraft(employeeId, order.number, submittedVersion);
    } catch (_) {
      // Сервер подтвердил отправку. Ошибка очистки не отменяет её.
    }
    _notify();
  }

  @override
  ExecutionDraft? executionDraft(int employeeId, int orderNumber) =>
      _drafts[(employeeId, orderNumber)];
  @override
  Future<ExecutionDraft?> restoreExecutionDraft(
    int employeeId,
    int orderNumber,
  ) => _withDraftLock(() async {
    _checkUser(employeeId);
    final draft =
        executionDraft(employeeId, orderNumber) ??
        await draftStorage.load(employeeId, orderNumber);

    if (draft != null) {
      _drafts[(employeeId, orderNumber)] = draft;
    }
    return draft;
  });

  @override
  Future<void> saveExecutionDraft(
    int employeeId,
    int orderNumber,
    ExecutionDraft draft,
  ) => _withDraftLock(() async {
    _checkUser(employeeId);

    await draftStorage.save(employeeId, orderNumber, draft);
    _drafts[(employeeId, orderNumber)] = draft;
  });
  @override
  Future<void> clearExecutionDraft(int employeeId, int orderNumber) =>
      _withDraftLock(() async {
        await draftStorage.remove(employeeId, orderNumber);
        _drafts.remove((employeeId, orderNumber));
      });

  @override
  void dispose() {
    _disposed = true;
    _queueTimer?.cancel();
    _realtime?.dispose();
    super.dispose();
  }
}
