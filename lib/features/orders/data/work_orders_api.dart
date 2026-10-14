import '../../../core/api/api_client.dart';
import '../models/work_order_api_models.dart';

// MARK: - Work orders list result

class WorkOrdersResult {
  const WorkOrdersResult({required this.items, required this.totalCount});

  final List<WorkOrderApiModel> items;
  final int totalCount;
}

// MARK: - Create work order input

class CreateWorkOrderInput {
  const CreateWorkOrderInput({
    required this.type,
    required this.description,
    required this.areaId,
    required this.equipmentId,
    this.assigneeId,
    this.brigadeId,
    required this.priority,
    this.normativeId,
    this.faultCodeId,
    this.deadline,
    this.comment,
    this.beforePhotoUrls = const [],
  });

  final WorkOrderType type;
  final String description;

  final int areaId;
  final int equipmentId;
  final int? assigneeId;
  final int? brigadeId;

  final WorkOrderPriority priority;

  final int? normativeId;
  final int? faultCodeId;
  final DateTime? deadline;

  final String? comment;

  final List<String> beforePhotoUrls;

  Map<String, dynamic> toJson() {
    return {
      'type': type.apiValue,
      'description': description.trim(),
      'areaId': areaId,
      'equipmentId': equipmentId,
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (brigadeId != null) 'brigadeId': brigadeId,
      'priority': priority.apiValue,
      if (normativeId != null) 'normativeId': normativeId,
      if (faultCodeId != null) 'faultCodeId': faultCodeId,
      if (deadline != null) 'deadline': deadline!.toUtc().toIso8601String(),
      if (comment != null && comment!.trim().isNotEmpty)
        'comment': comment!.trim(),
      if (beforePhotoUrls.isNotEmpty) 'beforePhotoUrls': beforePhotoUrls,
    };
  }

  void validate() {
    if (assigneeId == null && brigadeId == null) {
      throw const ApiException(
        statusCode: 400,
        message: 'Выберите исполнителя или бригаду',
      );
    }
    if (description.trim().length < 3) {
      throw const ApiException(
        statusCode: 400,
        message: 'Описание должно содержать минимум 3 символа',
      );
    }

    if (deadline == null && normativeId == null) {
      throw const ApiException(
        statusCode: 400,
        message: 'Укажите срок или норматив',
      );
    }

    if (beforePhotoUrls.length > 5) {
      throw const ApiException(
        statusCode: 400,
        message: 'Можно прикрепить не более 5 фотографий',
      );
    }
  }
}

// MARK: - Update work order input

class UpdateWorkOrderInput {
  const UpdateWorkOrderInput({
    this.type,
    this.description,
    this.areaId,
    this.equipmentId,
    this.assigneeId,
    this.priority,
    this.normativeId,
    this.deadline,
    this.comment,
  });

  final WorkOrderType? type;
  final String? description;

  final int? areaId;
  final int? equipmentId;
  final int? assigneeId;

  final WorkOrderPriority? priority;

  final int? normativeId;
  final DateTime? deadline;

  final String? comment;

  Map<String, dynamic> toJson() {
    return {
      if (type != null) 'type': type!.apiValue,
      if (description != null) 'description': description!.trim(),
      if (areaId != null) 'areaId': areaId,
      if (equipmentId != null) 'equipmentId': equipmentId,
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (priority != null) 'priority': priority!.apiValue,
      if (normativeId != null) 'normativeId': normativeId,
      if (deadline != null) 'deadline': deadline!.toUtc().toIso8601String(),
      if (comment != null) 'comment': comment!.trim(),
    };
  }
}

// MARK: - Work order action

enum WorkOrderAction {
  accept,
  queue,
  reject,
  start,
  pause,
  resume,
  complete,
  sendToRework,
  close,
  cancel;

  String get apiValue => switch (this) {
    WorkOrderAction.accept => 'ACCEPT',
    WorkOrderAction.queue => 'QUEUE',
    WorkOrderAction.reject => 'REJECT',
    WorkOrderAction.start => 'START',
    WorkOrderAction.pause => 'PAUSE',
    WorkOrderAction.resume => 'RESUME',
    WorkOrderAction.complete => 'COMPLETE',
    WorkOrderAction.sendToRework => 'SEND_TO_REWORK',
    WorkOrderAction.close => 'CLOSE',
    WorkOrderAction.cancel => 'CANCEL',
  };
}

// MARK: - Action input

class WorkOrderActionInput {
  const WorkOrderActionInput({
    required this.action,
    this.clientActionId,
    this.comment,
    this.masterScore,
    this.actualDowntimeMinutes,

    // COMPLETE fields
    this.completionText,
    this.faultCodeId,
    this.afterPhotoUrls,
    this.materialUsages,
  });

  final WorkOrderAction action;

  /// Для идемпотентности действий.
  /// Backend принимает 8–100 символов.
  final String? clientActionId;

  final String? comment;

  /// Используется мастером при CLOSE.
  final int? masterScore;

  /// Используется мастером при CLOSE.
  final int? actualDowntimeMinutes;

  /// Используется при COMPLETE.
  final String? completionText;

  /// Используется при COMPLETE.
  final int? faultCodeId;

  /// Используется при COMPLETE.
  final List<String>? afterPhotoUrls;

  /// Используется при COMPLETE.
  final List<Map<String, dynamic>>? materialUsages;

  Map<String, dynamic> toJson() {
    return {
      'action': action.apiValue,
      if (clientActionId != null && clientActionId!.trim().isNotEmpty)
        'clientActionId': clientActionId!.trim(),
      if (comment != null && comment!.trim().isNotEmpty)
        'comment': comment!.trim(),
      if (masterScore != null) 'masterScore': masterScore,
      if (actualDowntimeMinutes != null)
        'actualDowntimeMinutes': actualDowntimeMinutes,
      if (completionText != null && completionText!.trim().isNotEmpty)
        'completionText': completionText!.trim(),
      if (faultCodeId != null) 'faultCodeId': faultCodeId,
      if (afterPhotoUrls != null) 'afterPhotoUrls': afterPhotoUrls,
      if (materialUsages != null) 'materials': materialUsages,
    };
  }
}

// MARK: - Work orders API

class WorkOrdersApi {
  const WorkOrdersApi(this._client);

  final ApiClient _client;

  // MARK: List

  Future<WorkOrdersResult> getWorkOrders({
    List<WorkOrderStatus>? statuses,
    int? areaId,
    int? assigneeId,
    int? equipmentId,
    int? brigadeId,
    WorkOrderPriority? priority,
    bool overdue = false,
    int limit = 200,
    int offset = 0,
    bool compact = true,
  }) async {
    if (limit < 1 || limit > 500) {
      throw const ApiException(
        statusCode: 400,
        message: 'limit должен быть от 1 до 500',
      );
    }

    final response = await _client.get(
      '/api/work-orders',
      queryParameters: {
        if (statuses != null && statuses.isNotEmpty)
          'status': statuses.map((status) => status.apiValue).toList(),
        'areaId': ?areaId,
        'assigneeId': ?assigneeId,
        'equipmentId': ?equipmentId,
        'brigadeId': ?brigadeId,
        if (priority != null) 'priority': priority.apiValue,
        if (overdue) 'overdue': 1,
        'limit': limit,
        'offset': offset,
        'compact': compact ? 1 : 0,
      },
    );

    final raw = response.data;

    if (raw is! List) {
      throw const ApiException(
        statusCode: 500,
        message: 'Сервер вернул неверный формат списка нарядов',
      );
    }

    final items = raw
        .map((item) => WorkOrderApiModel.fromJson(_asJsonMap(item)))
        .toList(growable: false);

    return WorkOrdersResult(
      items: items,
      totalCount: response.totalCount ?? items.length,
    );
  }

  // MARK: Get by id

  Future<List<WorkOrderApiModel>> getAllWorkOrders({
    List<WorkOrderStatus>? statuses,
    bool compact = true,
    int? areaId,
    int? equipmentId,
    int? assigneeId,
    int? brigadeId,
    WorkOrderPriority? priority,
    bool overdue = false,
  }) async {
    final orders = <WorkOrderApiModel>[];
    var offset = 0;
    while (true) {
      final page = await getWorkOrders(
        statuses: statuses,
        areaId: areaId,
        equipmentId: equipmentId,
        assigneeId: assigneeId,
        brigadeId: brigadeId,
        priority: priority,
        overdue: overdue,
        limit: 500,
        offset: offset,
        compact: compact,
      );
      orders.addAll(page.items);
      if (page.items.length < 500) return orders;
      offset += page.items.length;
    }
  }

  Future<WorkOrderApiModel> getWorkOrder(int id) async {
    final response = await _client.get('/api/work-orders/$id');

    return WorkOrderApiModel.fromJson(_asJsonMap(response.data));
  }

  Future<WorkOrderBoard> getBoard({Map<String, dynamic>? filters}) async =>
      WorkOrderBoard.fromJson(
        _asJsonMap(
          (await _client.get(
            '/api/work-orders/board',
            queryParameters: filters,
          )).data,
        ),
      );

  Future<WorkOrderApiModel> addComment(
    int id, {
    required String comment,
    required String clientActionId,
  }) async {
    final response = await _client.post(
      '/api/work-orders/$id/comment',
      body: {'comment': comment.trim(), 'clientActionId': clientActionId},
    );
    return WorkOrderApiModel.fromJson(
      _asJsonMap(_asJsonMap(response.data)['order']),
    );
  }

  // MARK: Create

  Future<WorkOrderApiModel> createWorkOrder(
    CreateWorkOrderInput input, {
    required String creationkey,
  }) async {
    input.validate();

    final response = await _client.post(
      '/api/work-orders',
      headers: {'Idempotency-Key': creationkey},
      body: input.toJson(),
    );

    return WorkOrderApiModel.fromJson(_asJsonMap(response.data));
  }

  Future<WorkOrderApiModel> createWorkOrderFromSnapshot(
    Map<String, dynamic> payload, {
    required String creationKey,
  }) async {
    if (creationKey.trim().isEmpty) {
      throw ArgumentError.value(
        creationKey,
        'creationKey',
        'Must not be empty',
      );
    }
    final response = await _client.post(
      '/api/work-orders',
      headers: {'Idempotency-Key': creationKey},
      body: payload,
    );
    return WorkOrderApiModel.fromJson(_asJsonMap(response.data));
  }

  // MARK: Update

  Future<WorkOrderApiModel> updateWorkOrder(
    int id,
    UpdateWorkOrderInput input,
  ) async {
    final body = input.toJson();

    if (body.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'Нет данных для изменения наряда',
      );
    }

    final response = await _client.patch('/api/work-orders/$id', body: body);

    return WorkOrderApiModel.fromJson(_asJsonMap(response.data));
  }

  // MARK: Reassign

  Future<WorkOrderApiModel> reassignWorkOrder({
    required int workOrderId,
    required int assigneeId,
  }) async {
    final response = await _client.post(
      '/api/work-orders/$workOrderId/reassign',
      body: {'assigneeId': assigneeId},
    );

    return WorkOrderApiModel.fromJson(_asJsonMap(response.data));
  }

  // MARK: Action

  Future<WorkOrderApiModel> performAction(
    int workOrderId,
    WorkOrderActionInput input,
  ) async {
    _validateAction(input);

    final response = await _client.post(
      '/api/work-orders/$workOrderId/action',
      body: input.toJson(),
      timeout: input.action == WorkOrderAction.complete
          ? const Duration(seconds: 250)
          : const Duration(seconds: 30),
    );

    final result = _asJsonMap(response.data);
    return WorkOrderApiModel.fromJson(_asJsonMap(result['order'] ?? result));
  }

  // MARK: Master actions

  Future<WorkOrderApiModel> sendToRework({
    required int workOrderId,
    String? comment,
    String? clientActionId,
  }) {
    return performAction(
      workOrderId,
      WorkOrderActionInput(
        action: WorkOrderAction.sendToRework,
        comment: comment,
        clientActionId: clientActionId,
      ),
    );
  }

  Future<WorkOrderApiModel> closeWorkOrder({
    required int workOrderId,
    int? masterScore,
    String? comment,
    int? actualDowntimeMinutes,
    String? clientActionId,
  }) {
    return performAction(
      workOrderId,
      WorkOrderActionInput(
        action: WorkOrderAction.close,
        masterScore: masterScore,
        comment: comment,
        actualDowntimeMinutes: actualDowntimeMinutes,
        clientActionId: clientActionId,
      ),
    );
  }

  Future<WorkOrderApiModel> cancelWorkOrder({
    required int workOrderId,
    String? comment,
    String? clientActionId,
  }) {
    return performAction(
      workOrderId,
      WorkOrderActionInput(
        action: WorkOrderAction.cancel,
        comment: comment,
        clientActionId: clientActionId,
      ),
    );
  }

  // MARK: Validation

  void _validateAction(WorkOrderActionInput input) {
    final clientActionId = input.clientActionId?.trim();

    if (clientActionId != null &&
        clientActionId.isNotEmpty &&
        (clientActionId.length < 8 || clientActionId.length > 100)) {
      throw const ApiException(
        statusCode: 400,
        message: 'clientActionId должен содержать от 8 до 100 символов',
      );
    }

    if (input.action == WorkOrderAction.reject &&
        (input.comment == null || input.comment!.trim().isEmpty)) {
      throw const ApiException(
        statusCode: 400,
        message: 'Укажите причину отклонения наряда',
      );
    }

    if (input.action == WorkOrderAction.pause &&
        (input.comment == null || input.comment!.trim().isEmpty)) {
      throw const ApiException(
        statusCode: 400,
        message: 'Укажите причину приостановки работ',
      );
    }

    if (input.action == WorkOrderAction.close &&
        input.masterScore != null &&
        (input.masterScore! < 1 || input.masterScore! > 5)) {
      throw const ApiException(
        statusCode: 400,
        message: 'Оценка мастера должна быть от 1 до 5',
      );
    }
  }
}

// MARK: - Helpers

Map<String, dynamic> _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  throw const ApiException(
    statusCode: 500,
    message: 'Сервер вернул неверный формат данных',
  );
}
