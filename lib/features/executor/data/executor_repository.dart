import 'package:mineral/features/executor/models/executor_rating_period.dart';
import 'package:flutter/foundation.dart';
import '../models/execution_assessment.dart';
import 'package:mineral/shared/models/models.dart';

/// UI contract. DemoStore implements it today; an API adapter can replace it.
abstract interface class ExecutorRepository implements Listenable {
  DateTime get now;
  bool get isLoading;
  String? get loadError;
  List<String> get executorFaultCodes;
  List<String> get executorMaterials;
  Employee employee(int id);
  ExecutorRating? executorRating(
    int employeeId, {
    ExecutorRatingPeriod period = const ExecutorRatingPeriod(),
  });
  Future<ExecutorRating?> loadExecutorRating(
    int employeeId, {
    ExecutorRatingPeriod period = const ExecutorRatingPeriod(),
  });
  List<WorkOrder> assignedTo(int employeeId);
  Future<void> refreshExecutor(int employeeId);
  Future<WorkOrder> loadExecutorOrder(int employeeId, WorkOrder order);
  Future<WorkOrder> loadExecutorOrderTime(int employeeId, WorkOrder order);
  Future<void> executorAction(
    int employeeId,
    WorkOrder order,
    OrderStatus status, {
    String reason = '',
  });
  Future<String?> restoreActionReason(
    int employeeId,
    WorkOrder order,
    OrderStatus status,
  );
  Future<void> submitExecution(
    int employeeId,
    WorkOrder order,
    ExecutionDraft report,
  );
  ExecutionDraft? executionDraft(int employeeId, int orderNumber);
  Future<ExecutionDraft?> restoreExecutionDraft(
    int employeeId,
    int orderNumber,
  );
  Future<void> saveExecutionDraft(
    int employeeId,
    int orderNumber,
    ExecutionDraft draft,
  );
  Future<void> clearExecutionDraft(int employeeId, int orderNumber);
}

class ExecutionDraft {
  ExecutionDraft({
    this.work = '',
    this.faultCode = '',
    this.comment = '',
    this.legacyMaterials = '',
    Map<String, double> materials = const {},
    List<OrderPhoto> photos = const [],
  }) : materials = Map.unmodifiable(materials),
       photos = List.unmodifiable(photos);
  final String work;
  final String faultCode;
  final String comment;
  final String legacyMaterials;
  final Map<String, double> materials;
  final List<OrderPhoto> photos;
}
