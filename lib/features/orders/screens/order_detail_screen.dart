import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:file_saver/file_saver.dart';
import 'equipment_history_screen.dart';
import '../../../shared/widgets/backend_section.dart';
import '../../../shared/widgets/backend_refresh_view.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/enterprise_time.dart';
import '../../../shared/widgets/app_refresh_indicator.dart';
import 'package:mineral/shared/models/models.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_services.dart';
import '../../../core/api/backend_document.dart';

import '../data/references_api.dart';
import '../data/work_orders_api.dart';
import '../models/work_order_api_models.dart';

import '../../../l10n/ui_localization.dart';
import '../../../shared/widgets/ui.dart';

// MARK: - Order detail

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.api,
    required this.orderId,
    this.suggestedExecutorId,
  });

  final ApiServices api;
  final int orderId;
  final int? suggestedExecutorId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  WorkOrderApiModel? order;

  bool loading = true;
  bool actionLoading = false;

  String? error;
  StreamSubscription<void>? subscription;
  int generation = 0;
  final expiredUrls = <String>{};

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  void _photoExpired(String url) {
    if (!expiredUrls.add(url)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !loading) _load();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  // MARK: Lifecycle

  @override
  void initState() {
    super.initState();
    subscription = widget.api.realtime.changes.listen((_) {
      if (!actionLoading) _load();
    });
    _load();
  }

  // MARK: Load

  Future<void> _load() async {
    final requestGeneration = ++generation;
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await widget.api.workOrders.getWorkOrder(widget.orderId);

      if (!mounted || requestGeneration != generation) return;

      setState(() {
        order = result;
        loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestGeneration != generation) return;

      setState(() {
        error = e.message;
        loading = false;
      });
    } catch (e) {
      if (!mounted || requestGeneration != generation) return;

      setState(() {
        error = backendError(context, e);
        loading = false;
      });
    }
  }

  // MARK: Run action

  Future<void> _runAction(
    Future<WorkOrderApiModel> Function() request, {
    String? successMessage,
  }) async {
    if (actionLoading) return;

    setState(() {
      actionLoading = true;
    });

    try {
      await request();

      if (!mounted) return;

      if (successMessage != null) {
        _showMessage(successMessage);
      }

      // Повторно забираем полную карточку,
      // чтобы обновить events / AI / photos / materials.
      await _load();
      widget.api.realtime.invalidate();
    } on ApiException catch (e) {
      if (!mounted) return;

      _showMessage(e.message);
      if (e.statusCode == 409) {
        await _load();
        widget.api.realtime.invalidate();
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(backendError(context, e));
    } finally {
      if (mounted) {
        setState(() {
          actionLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // MARK: Reassign

  Future<void> _reassign({int? suggestedId}) async {
    final current = order;

    if (current == null || !current.canMasterReassign) {
      return;
    }

    List<ExecutorReference> executors;

    try {
      executors = await widget.api.references.getExecutors();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      _showMessage(backendError(context, e));
      return;
    }

    if (!mounted) return;

    final suggested = executors
        .where(
          (e) =>
              e.id == suggestedId && e.isOnShift && e.id != current.assigneeId,
        )
        .firstOrNull;
    final selectedId =
        suggested?.id ??
        await showDialog<int>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(uiText(context, 'Переназначить наряд')),
              content: SizedBox(
                width: 520,
                child: executors.isEmpty
                    ? Text(uiText(context, 'Исполнители не найдены'))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: executors.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final executor = executors[index];

                          final isCurrent = executor.id == current.assignee.id;

                          return ListTile(
                            enabled: !isCurrent && executor.isOnShift,
                            leading: CircleAvatar(
                              child: Text(_initials(executor.fullName)),
                            ),
                            title: Text(executor.fullName),
                            subtitle: Text(
                              [
                                if (executor.specialty != null &&
                                    executor.specialty!.trim().isNotEmpty)
                                  uiText(context, executor.specialty!),
                                uiText(context, executor.statusLabel),
                              ].join(' · '),
                            ),
                            trailing: isCurrent
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : null,
                            onTap: isCurrent || !executor.isOnShift
                                ? null
                                : () {
                                    Navigator.pop(dialogContext, executor.id);
                                  },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(uiText(context, 'Отмена')),
                ),
              ],
            );
          },
        );

    if (selectedId == null || !mounted) {
      return;
    }

    final confirmed = await _confirm(
      title: 'Переназначить наряд?',
      message:
          '${suggested != null ? '${suggested.fullName}. ' : ''}После переназначения наряд вернётся в статус «Выдан». Новый исполнитель получит уведомление.',
      confirmText: 'Переназначить',
    );

    if (!confirmed) return;

    await _runAction(
      () => widget.api.workOrders.reassignWorkOrder(
        workOrderId: current.id,
        assigneeId: selectedId,
      ),
      successMessage: 'Исполнитель изменён',
    );
  }

  // MARK: Cancel

  Future<void> _cancelOrder() async {
    final current = order;

    if (current == null || !current.canMasterCancel) {
      return;
    }

    final comment = await _requestText(
      title: 'Отменить наряд',
      label: 'Причина отмены',
      hint: 'Можно указать причину отмены',
      required: false,
      confirmText: 'Отменить наряд',
    );

    if (comment == null) return;

    await _runAction(
      () => widget.api.workOrders.cancelWorkOrder(
        workOrderId: current.id,
        comment: comment.trim().isEmpty ? null : comment.trim(),
        clientActionId: _clientActionId('cancel'),
      ),
      successMessage: 'Наряд отменён',
    );
  }

  // MARK: Send to rework

  Future<void> _sendToRework() async {
    final current = order;

    if (current == null || current.status != WorkOrderStatus.aiReview) {
      return;
    }

    final comment = await _requestText(
      title: 'Отправить на доработку',
      label: 'Что необходимо исправить',
      hint: 'Комментарий исполнителю',
      required: false,
      confirmText: 'На доработку',
    );

    if (comment == null) return;

    await _runAction(
      () => widget.api.workOrders.sendToRework(
        workOrderId: current.id,
        comment: comment.trim().isEmpty ? null : comment.trim(),
        clientActionId: _clientActionId('rework'),
      ),
      successMessage: 'Наряд отправлен на доработку',
    );
  }

  // MARK: Close

  Future<void> _closeOrder() async {
    final current = order;

    if (current == null || current.status != WorkOrderStatus.aiReview) {
      return;
    }

    final result = await showDialog<_CloseResult>(
      context: context,
      builder: (dialogContext) {
        return _CloseOrderDialog(
          initialScore:
              (current.aiAssessment?.masterScore ??
                      current.aiAssessment?.score ??
                      5)
                  .round()
                  .clamp(1, 5),
        );
      },
    );

    if (result == null) {
      return;
    }

    await _runAction(
      () => widget.api.workOrders.closeWorkOrder(
        workOrderId: current.id,
        masterScore: result.score,
        comment: result.comment.trim().isEmpty ? null : result.comment.trim(),
        actualDowntimeMinutes: result.downtimeMinutes,
        clientActionId: _clientActionId('close'),
      ),
      successMessage: 'Наряд закрыт',
    );
  }

  // MARK: Edit

  Future<void> _editOrder() async {
    final current = order;

    if (current == null || !current.canMasterEdit) {
      return;
    }

    final result = await showDialog<_EditOrderResult>(
      context: context,
      builder: (dialogContext) {
        return _EditOrderDialog(order: current);
      },
    );

    if (result == null) {
      return;
    }

    await _runAction(
      () => widget.api.workOrders.updateWorkOrder(
        current.id,
        UpdateWorkOrderInput(
          description: result.description,
          priority: result.priority,
          deadline: result.deadline,
          comment: result.comment,
        ),
      ),
      successMessage: 'Наряд обновлён',
    );
  }

  // MARK: Dialog helpers

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(uiText(context, title)),
          content: Text(uiText(context, message)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(uiText(context, 'Отмена')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(uiText(context, confirmText)),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<String?> _requestText({
    required String title,
    required String label,
    required String hint,
    required bool required,
    required String confirmText,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final route = DialogRoute<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(uiText(context, title)),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: uiText(context, label),
                  hintText: uiText(context, hint),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (required && (value == null || value.trim().isEmpty)) {
                    return uiText(context, 'Заполните поле');
                  }

                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(uiText(context, 'Отмена')),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(dialogContext, controller.text);
              },
              child: Text(uiText(context, confirmText)),
            ),
          ],
        );
      },
    );

    final result = await Navigator.of(context, rootNavigator: true).push(route);
    // The dialog field remains mounted until the reverse transition completes.
    await route.completed;
    controller.dispose();

    return result;
  }

  // MARK: Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: border)),
        title: Text(
          order == null
              ? uiText(context, 'Наряд')
              : '${uiText(context, 'Наряд')} №${order!.number}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: uiText(context, 'Отчёт по наряду'),
            icon: const Icon(Icons.summarize_outlined, color: brand),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(uiText(dialogContext, 'Отчёт по наряду')),
                content: SizedBox(
                  width: 640,
                  child: BackendRefreshView(
                    child: BackendSection<BackendDocument>(
                      load: () =>
                          widget.api.reports.getWorkOrder(widget.orderId),
                      builder: (context, document) =>
                          BackendDocumentView(document: document),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(uiText(dialogContext, 'Закрыть')),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: backendText(context, 'Отчёт PDF', 'PDF есебі'),
            icon: const Icon(Icons.file_download_outlined, color: brand),
            onPressed: order == null || actionLoading ? null : _exportOrder,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading && order == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return BackendRefreshView(
        onRefresh: _load,
        child: _ErrorState(message: error!, onRetry: _load),
      );
    }

    final current = order;

    if (current == null) {
      return BackendRefreshView(
        onRefresh: _load,
        child: _ErrorState(message: 'Наряд не найден', onRetry: _load),
      );
    }

    return Stack(
      children: [
        AppRefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(current),

                    const SizedBox(height: 16),

                    _buildActions(current),

                    const SizedBox(height: 16),

                    _buildDescription(current),

                    const SizedBox(height: 16),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final desktop = constraints.maxWidth >= 850;

                        if (!desktop) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildMainInformation(current),
                              const SizedBox(height: 16),
                              _buildSideInformation(current),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildMainInformation(current),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSideInformation(current)),
                          ],
                        );
                      },
                    ),

                    if (current.completionText != null ||
                        current.timing != null ||
                        current.actualDowntimeMinutes != null ||
                        current.downtime != null) ...[
                      const SizedBox(height: 20),
                      _buildExecutionReport(current),
                    ],

                    if (current.aiAssessment != null) ...[
                      const SizedBox(height: 16),
                      _buildAiAssessment(current),
                    ],

                    if (current.photos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPhotos(current),
                    ],

                    if (current.materialUsages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildMaterials(current),
                    ],

                    const SizedBox(height: 16),

                    _buildHistory(current),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (actionLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.08),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  // MARK: Header

  Widget _buildHeader(WorkOrderApiModel order) => _SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.precision_manufacturing_outlined,
                color: brand,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uiText(context, order.equipment.name),
                    style: const TextStyle(
                      color: ink,
                      fontSize: 20,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    uiText(context, order.area.name),
                    style: const TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DetailTag(
              text: order.status.label,
              color: _statusColor(order.status),
            ),
            _DetailTag(
              text: order.priority.label,
              color: _priorityColor(order.priority),
            ),
            if (order.isOverdue)
              const _DetailTag(text: 'Просрочен', color: Color(0xFFDC2626)),
          ],
        ),
      ],
    ),
  );

  Widget _buildDescription(WorkOrderApiModel order) => _SectionCard(
    title: 'Описание работ',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          uiText(context, order.description),
          style: const TextStyle(color: ink, fontSize: 15, height: 1.55),
        ),
        if (order.comment != null && order.comment!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.comment_outlined, size: 18, color: brand),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    uiText(context, order.comment!),
                    style: const TextStyle(
                      color: ink,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
  // MARK: Actions

  Widget _buildActions(WorkOrderApiModel order) {
    return _SectionCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttons = <Widget>[
            if (order.status == WorkOrderStatus.aiReview)
              FilledButton.icon(
                onPressed: actionLoading ? null : _closeOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF01408B),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(uiText(context, 'Принять и закрыть')),
              ),
            if (order.status == WorkOrderStatus.aiReview)
              OutlinedButton.icon(
                onPressed: actionLoading ? null : _sendToRework,
                icon: const Icon(Icons.replay),
                label: Text(uiText(context, 'На доработку')),
              ),
            OutlinedButton.icon(
              onPressed: actionLoading ? null : _addComment,
              icon: const Icon(Icons.comment_outlined),
              label: Text(
                backendText(
                  context,
                  'Добавить комментарий',
                  'Түсініктеме қосу',
                ),
              ),
            ),
            if (widget.suggestedExecutorId != null &&
                widget.suggestedExecutorId != order.assigneeId &&
                order.canMasterReassign)
              OutlinedButton.icon(
                onPressed: actionLoading
                    ? null
                    : () => _reassign(suggestedId: widget.suggestedExecutorId),
                icon: const Icon(Icons.person_add_alt),
                label: Text(
                  backendText(
                    context,
                    'Переназначить по предложению',
                    'Ұсыныс бойынша қайта тағайындау',
                  ),
                ),
              ),
            if (order.canMasterEdit)
              OutlinedButton.icon(
                onPressed: actionLoading ? null : _editOrder,
                icon: const Icon(Icons.edit_outlined),
                label: Text(uiText(context, 'Изменить')),
              ),

            if (order.canMasterReassign)
              OutlinedButton.icon(
                onPressed: actionLoading ? null : _reassign,
                icon: const Icon(Icons.person_add_alt_outlined),
                label: Text(uiText(context, 'Переназначить')),
              ),

            if (order.canMasterCancel)
              TextButton.icon(
                onPressed: actionLoading ? null : _cancelOrder,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(uiText(context, 'Отменить наряд')),
              ),
          ];
          final width = constraints.maxWidth;
          final columns = width >= 760
              ? 3
              : width >= 300
              ? 2
              : 1;
          final buttonWidth = (width - (columns - 1) * 10) / columns;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final button in buttons)
                SizedBox(
                  width: buttonWidth,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 60),
                    child: OutlinedButtonTheme(
                      data: OutlinedButtonThemeData(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brand,
                          backgroundColor: const Color(0xFFF8FAFD),
                          side: const BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          minimumSize: const Size(48, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      child: button,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // MARK: Main information

  Widget _buildMainInformation(WorkOrderApiModel order) {
    return _SectionCard(
      title: 'Информация о работе',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.factory_outlined,
            label: 'Участок',
            value: order.area.name,
          ),
          _InfoRow(
            icon: Icons.precision_manufacturing_outlined,
            label: 'Оборудование',
            value: [order.equipment.name, order.equipment.inventoryNumber]
                .whereType<String>()
                .where((value) => value.trim().isNotEmpty)
                .join(' · ')
                .ifEmpty('Не указано'),
          ),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Исполнитель',
            value: order.assignee.fullName,
          ),
          if (order.brigadeName != null)
            _InfoRow(
              icon: Icons.groups_outlined,
              label: 'Бригада',
              value: order.brigadeName!,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.history),
              label: Text(
                backendText(context, 'История оборудования', 'Жабдық тарихы'),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EquipmentHistoryScreen(
                    api: widget.api,
                    equipmentId: order.equipmentId,
                  ),
                ),
              ),
            ),
          ),
          _InfoRow(
            icon: Icons.build_outlined,
            label: 'Тип',
            value: order.type.label,
          ),
          if (order.faultCode != null)
            _InfoRow(
              icon: Icons.warning_amber_outlined,
              label: 'Неисправность',
              value: [order.faultCode?.code, order.faultCode?.name]
                  .whereType<String>()
                  .where((value) => value.trim().isNotEmpty)
                  .join(' · '),
            ),
        ],
      ),
    );
  }

  // MARK: Side information

  Widget _buildSideInformation(WorkOrderApiModel order) {
    return _SectionCard(
      title: 'Сроки',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Создан',
            value: _dateTime(order.createdAt),
          ),

          _InfoRow(
            icon: Icons.event_outlined,
            label: 'Срок',
            value: _dateTime(order.deadline),
            valueColor: order.isOverdue ? Colors.red : null,
          ),

          if (order.acceptedAt != null)
            _InfoRow(
              icon: Icons.thumb_up_alt_outlined,
              label: 'Принят',
              value: _dateTime(order.acceptedAt!),
            ),

          if (order.startedAt != null)
            _InfoRow(
              icon: Icons.play_arrow_outlined,
              label: 'Начат',
              value: _dateTime(order.startedAt!),
            ),

          if (order.completedAt != null)
            _InfoRow(
              icon: Icons.task_alt,
              label: 'Выполнен',
              value: _dateTime(order.completedAt!),
            ),

          if (order.closedAt != null)
            _InfoRow(
              icon: Icons.verified_outlined,
              label: 'Закрыт',
              value: _dateTime(order.closedAt!),
            ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    final text = await _requestText(
      title: 'Добавить комментарий',
      label: 'Комментарий',
      hint: 'Комментарий к наряду',
      required: true,
      confirmText: 'Добавить',
    );
    if (text == null || !mounted) return;
    await _runAction(
      () => widget.api.workOrders.addComment(
        widget.orderId,
        comment: text,
        clientActionId: const Uuid().v4(),
      ),
    );
  }

  Future<void> _exportOrder() async {
    if (actionLoading) return;
    setState(() => actionLoading = true);
    try {
      final bytes = await widget.api.reports.exportWorkOrder(widget.orderId);
      if (!mounted) return;
      await FileSaver.instance.saveAs(
        name: 'mineral-order-${widget.orderId}',
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
    } catch (error) {
      if (mounted) _showMessage(backendError(context, error));
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Widget _buildExecutionReport(WorkOrderApiModel order) {
    final timing = order.timing;
    return _SectionCard(
      title: backendText(context, 'Результат выполнения', 'Орындалу нәтижесі'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (order.completionText != null) Text(order.completionText!),
          if (order.actualDowntimeMinutes != null)
            _InfoRow(
              icon: Icons.factory_outlined,
              label: 'Фактический простой',
              value:
                  '${order.actualDowntimeMinutes} ${backendText(context, 'мин', 'мин')}',
            ),
          if (timing?.normativeHours != null)
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Норматив',
              value:
                  '${timing!.normativeHours} ${backendText(context, 'ч', 'сағ')}',
            ),
          if (timing?.actualHours != null)
            _InfoRow(
              icon: Icons.timer,
              label: 'Фактическое время',
              value:
                  '${timing!.actualHours} ${backendText(context, 'ч', 'сағ')}',
            ),
          if (timing?.vsNormativePercent != null)
            _InfoRow(
              icon: Icons.percent,
              label: 'Время к нормативу',
              value: '${timing!.vsNormativePercent}%',
            ),
          if (timing?.deadlineMet != null)
            _InfoRow(
              icon: Icons.event_available,
              label: 'Срок соблюдён',
              value: backendText(
                context,
                timing!.deadlineMet! ? 'Да' : 'Нет',
                timing.deadlineMet! ? 'Иә' : 'Жоқ',
              ),
            ),
          if (timing?.overdueMinutes != null)
            _InfoRow(
              icon: Icons.schedule,
              label: 'Просрочка',
              value:
                  '${timing!.overdueMinutes} ${backendText(context, 'мин', 'мин')}',
            ),
          if (order.downtime != null)
            BackendDocumentView(
              document: BackendDocument.fromJson(order.downtime),
            ),
        ],
      ),
    );
  }

  // MARK: AI

  Widget _buildAiAssessment(WorkOrderApiModel order) {
    final assessment = order.aiAssessment!;

    return _SectionCard(
      title: 'ИИ-проверка выполнения',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (assessment.needsMasterReview)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFFFFF7ED),
                child: Text(
                  backendText(
                    context,
                    'Нужна проверка мастером',
                    'Шебердің тексеруі қажет',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DetailTag(
                text: _aiVerdictLabel(assessment.verdict),
                color: _aiVerdictColor(assessment.verdict),
              ),

              if (assessment.score != null)
                _DetailTag(
                  text: 'Оценка ИИ: ${assessment.score}',
                  color: brand,
                ),

              if (assessment.confidence != null)
                _DetailTag(
                  text:
                      'Уверенность: ${(assessment.confidence! * 100).round()}%',
                  color: assessment.confidence! < 0.5
                      ? Colors.orange
                      : Colors.green,
                ),
            ],
          ),

          if (assessment.explanation != null &&
              assessment.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              assessment.explanation!,
              style: const TextStyle(color: ink, height: 1.5),
            ),
          ],

          if (assessment.strengths.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              uiText(context, 'Что выполнено хорошо'),
              style: TextStyle(fontWeight: FontWeight.w700, color: ink),
            ),
            const SizedBox(height: 8),
            for (final item in assessment.strengths)
              _BulletText(
                text: item,
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
          ],

          if (assessment.improvements.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              uiText(context, 'Что можно улучшить'),
              style: TextStyle(fontWeight: FontWeight.w700, color: ink),
            ),
            const SizedBox(height: 8),
            for (final item in assessment.improvements)
              _BulletText(
                text: item,
                icon: Icons.info_outline,
                color: Colors.orange,
              ),
          ],

          if (assessment.photoComment != null &&
              assessment.photoComment!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    assessment.confidence != null &&
                        assessment.confidence! < 0.5
                    ? const Color(0xFFFFF7ED)
                    : background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.photo_outlined,
                    color:
                        assessment.confidence != null &&
                            assessment.confidence! < 0.5
                        ? Colors.orange
                        : muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(assessment.photoComment!)),
                ],
              ),
            ),
          ],

          if (assessment.masterScore != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              uiText(context, 'Оценка мастера: ${assessment.masterScore}/5'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (assessment.masterComment != null &&
                assessment.masterComment!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(assessment.masterComment!),
            ],
          ],
        ],
      ),
    );
  }

  // MARK: Photos

  Widget _buildPhotos(WorkOrderApiModel order) {
    final before = order.beforePhotos;
    final after = order.afterPhotos;

    return _SectionCard(
      title: 'Фотофиксация',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (before.isNotEmpty) ...[
            Text(
              uiText(context, 'До выполнения'),
              style: TextStyle(fontWeight: FontWeight.w700, color: ink),
            ),
            const SizedBox(height: 12),
            _PhotoGrid(
              photos: before,
              apiBaseUrl: widget.api.baseUrl,
              onExpired: _photoExpired,
            ),
          ],

          if (before.isNotEmpty && after.isNotEmpty) const SizedBox(height: 24),

          if (after.isNotEmpty) ...[
            Text(
              uiText(context, 'После выполнения'),
              style: TextStyle(fontWeight: FontWeight.w700, color: ink),
            ),
            const SizedBox(height: 12),
            _PhotoGrid(
              photos: after,
              apiBaseUrl: widget.api.baseUrl,
              onExpired: _photoExpired,
            ),
          ],
        ],
      ),
    );
  }

  // MARK: Materials

  Widget _buildMaterials(WorkOrderApiModel order) {
    return _SectionCard(
      title: 'Использованные материалы',
      child: Column(
        children: [
          for (var index = 0; index < order.materialUsages.length; index++) ...[
            _MaterialRow(usage: order.materialUsages[index]),
            if (index != order.materialUsages.length - 1)
              const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  // MARK: History

  Widget _buildHistory(WorkOrderApiModel order) {
    final events = [...order.events]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _SectionCard(
      title: 'История наряда',
      child: events.isEmpty
          ? Text(
              uiText(context, 'История пока отсутствует'),
              style: TextStyle(color: muted),
            )
          : Column(
              children: [
                for (var index = 0; index < events.length; index++)
                  _EventRow(
                    event: events[index],
                    last: index == events.length - 1,
                  ),
              ],
            ),
    );
  }

  // MARK: Helpers

  String _clientActionId(String action) {
    final now = DateTime.now().microsecondsSinceEpoch;

    return 'master-$action-${widget.orderId}-$now';
  }

  String _dateTime(DateTime value) => enterpriseDateTimeLabel(value);

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// MARK: - Close dialog

class _CloseResult {
  const _CloseResult({
    required this.score,
    required this.comment,
    required this.downtimeMinutes,
  });

  final int score;
  final String comment;
  final int? downtimeMinutes;
}

class _CloseOrderDialog extends StatefulWidget {
  const _CloseOrderDialog({required this.initialScore});

  final int initialScore;

  @override
  State<_CloseOrderDialog> createState() => _CloseOrderDialogState();
}

class _CloseOrderDialogState extends State<_CloseOrderDialog> {
  final commentController = TextEditingController();

  final downtimeController = TextEditingController();

  late int score;

  @override
  void initState() {
    super.initState();
    score = widget.initialScore;
  }

  @override
  void dispose() {
    commentController.dispose();
    downtimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(uiText(context, 'Принять работу')),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              uiText(context, 'Оценка мастера'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                for (var value = 1; value <= 5; value++)
                  IconButton(
                    tooltip: '$value',
                    onPressed: () {
                      setState(() {
                        score = value;
                      });
                    },
                    icon: Icon(
                      value <= score ? Icons.star : Icons.star_border,
                      color: value <= score ? Colors.amber : muted,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: commentController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: uiText(context, 'Комментарий мастера'),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: downtimeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: uiText(context, 'Фактический простой, мин'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(uiText(context, 'Отмена')),
        ),
        FilledButton.icon(
          onPressed: () {
            final downtimeText = downtimeController.text.trim();

            final downtime = downtimeText.isEmpty
                ? null
                : int.tryParse(downtimeText);

            if (downtimeText.isNotEmpty && downtime == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(uiText(context, 'Введите простой в минутах')),
                ),
              );
              return;
            }

            if (downtime != null && downtime < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    uiText(context, 'Простой не может быть отрицательным'),
                  ),
                ),
              );
              return;
            }

            Navigator.pop(
              context,
              _CloseResult(
                score: score,
                comment: commentController.text.trim(),
                downtimeMinutes: downtime,
              ),
            );
          },
          icon: const Icon(Icons.check),
          label: Text(uiText(context, 'Закрыть наряд')),
        ),
      ],
    );
  }
}

// MARK: - Edit dialog

class _EditOrderResult {
  const _EditOrderResult({
    required this.description,
    required this.priority,
    required this.deadline,
    required this.comment,
  });

  final String description;
  final WorkOrderPriority priority;
  final DateTime? deadline;
  final String? comment;
}

class _EditOrderDialog extends StatefulWidget {
  const _EditOrderDialog({required this.order});

  final WorkOrderApiModel order;

  @override
  State<_EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<_EditOrderDialog> {
  late final TextEditingController descriptionController;

  late final TextEditingController commentController;

  late WorkOrderPriority priority;

  DateTime? deadline;

  @override
  void initState() {
    super.initState();

    descriptionController = TextEditingController(
      text: widget.order.description,
    );

    commentController = TextEditingController(text: widget.order.comment ?? '');

    priority = widget.order.priority;
    deadline = widget.order.deadline.toLocal();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();

    final current = deadline ?? now.add(const Duration(hours: 2));
    final firstDate = DateUtils.dateOnly(now.subtract(const Duration(days: 1)));
    final lastDate = DateUtils.dateOnly(now.add(const Duration(days: 365 * 2)));
    final savedDate = DateUtils.dateOnly(current.toLocal());
    final initialDate = savedDate.isBefore(firstDate)
        ? firstDate
        : savedDate.isAfter(lastDate)
        ? lastDate
        : savedDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (time == null || !mounted) {
      return;
    }

    setState(() {
      deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(uiText(context, 'Изменить наряд')),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: descriptionController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: uiText(context, 'Описание работы'),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<WorkOrderPriority>(
                initialValue: priority,
                decoration: InputDecoration(
                  labelText: uiText(context, 'Приоритет'),
                ),
                items: [
                  for (final item in WorkOrderPriority.values)
                    DropdownMenuItem(
                      value: item,
                      child: Text(uiText(context, item.label)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    priority = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _selectDeadline,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  deadline == null
                      ? uiText(context, 'Выбрать срок')
                      : '${dateLabel(deadline!)} · '
                            '${timeLabel(deadline!)}',
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: commentController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: uiText(context, 'Комментарий'),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(uiText(context, 'Отмена')),
        ),
        FilledButton(
          onPressed: () {
            final description = descriptionController.text.trim();

            if (description.length < 3) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    uiText(
                      context,
                      'Описание должно содержать минимум 3 символа',
                    ),
                  ),
                ),
              );
              return;
            }

            Navigator.pop(
              context,
              _EditOrderResult(
                description: description,
                priority: priority,
                deadline: deadline?.toUtc(),
                comment: commentController.text.trim(),
              ),
            );
          },
          child: Text(uiText(context, 'Сохранить')),
        ),
      ],
    );
  }
}

// MARK: - Section card

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF01408B);
    const line = Color(0xFFE7ECF3);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Container(
                  width: 3,
                  height: 19,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    uiText(context, title!),
                    style: const TextStyle(
                      color: Color(0xFF172B4D),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
          const SizedBox(height: 18),
          const Divider(height: 1, color: line),
        ],
      ),
    );
  }
}

// MARK: - Info row

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF01408B)),
          const SizedBox(width: 11),
          Expanded(
            flex: 3,
            child: Text(
              uiText(context, label),
              style: const TextStyle(
                color: Color(0xFF7A8597),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              uiText(context, value),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF172B4D),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Tag

class _DetailTag extends StatelessWidget {
  const _DetailTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        uiText(context, text),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// MARK: - Photos

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.apiBaseUrl,
    required this.onExpired,
  });

  final List<WorkOrderPhoto> photos;
  final String apiBaseUrl;
  final ValueChanged<String> onExpired;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, index) {
            final photo = photos[index];

            final url = _absoluteUrl(apiBaseUrl, photo.fileUrl);

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: background,
                child: InkWell(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          child: Stack(
                            children: [
                              InteractiveViewer(
                                child: Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    if (error is NetworkImageLoadException &&
                                        error.statusCode == 401) {
                                      onExpired(url);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (dialogContext.mounted) {
                                              Navigator.of(dialogContext).pop();
                                            }
                                          });
                                    }
                                    return const SizedBox(
                                      width: 500,
                                      height: 400,
                                      child: ColoredBox(
                                        color: Colors.white,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 50,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      if (error is NetworkImageLoadException &&
                          error.statusCode == 401) {
                        onExpired(url);
                      }
                      return const Center(
                        child: Icon(Icons.broken_image_outlined, color: muted),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// MARK: - Material

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.usage});

  final WorkOrderMaterialUsage usage;

  @override
  Widget build(BuildContext context) {
    final material = usage.material;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: brand,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              uiText(context, material?.name ?? 'Материал'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              [
                usage.quantity.toString(),
                if (material != null) uiText(context, material.unit),
              ].join(' '),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: brand,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Event

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.last});

  final WorkOrderEvent event;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.circle, size: 8, color: brand),
                  ),
                ),
                if (!last) Expanded(child: Container(width: 1, color: border)),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 2, 0, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uiText(context, _eventActionLabel(event.action)),
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      [
                        if (event.actor != null) event.actor!.fullName,
                        _formatEventDate(event.createdAt),
                      ].join(' · '),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),

                    if (event.fromStatus != null || event.toStatus != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${uiText(context, event.fromStatus?.label ?? '—')} → '
                        '${uiText(context, event.toStatus?.label ?? '—')}',
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ],

                    if (event.comment != null &&
                        event.comment!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        uiText(context, event.comment!),
                        style: const TextStyle(height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Bullet

class _BulletText extends StatelessWidget {
  const _BulletText({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              uiText(context, text),
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Error

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: muted),
            const SizedBox(height: 16),
            Text(uiText(context, message), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay),
              label: Text(uiText(context, 'Повторить')),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Helpers

Color _statusColor(WorkOrderStatus status) {
  return switch (status) {
    WorkOrderStatus.issued => const Color(0xFF2563EB),
    WorkOrderStatus.queued => const Color(0xFF7C3AED),
    WorkOrderStatus.accepted => const Color(0xFF0284C7),
    WorkOrderStatus.inProgress => const Color(0xFFF59E0B),
    WorkOrderStatus.paused => const Color(0xFF64748B),
    WorkOrderStatus.completed => const Color(0xFF0D9488),
    WorkOrderStatus.aiReview => const Color(0xFF7C3AED),
    WorkOrderStatus.rework => const Color(0xFFEA580C),
    WorkOrderStatus.closed => const Color(0xFF059669),
    WorkOrderStatus.rejected => const Color(0xFFDC2626),
    WorkOrderStatus.cancelled => const Color(0xFF64748B),
  };
}

Color _priorityColor(WorkOrderPriority priority) {
  return switch (priority) {
    WorkOrderPriority.emergency => const Color(0xFFDC2626),
    WorkOrderPriority.high => const Color(0xFFEA580C),
    WorkOrderPriority.normal => const Color(0xFF2563EB),
    WorkOrderPriority.planned => const Color(0xFF64748B),
  };
}

String _aiVerdictLabel(AiAssessmentVerdict verdict) {
  return switch (verdict) {
    AiAssessmentVerdict.accepted => 'ИИ: принято',

    AiAssessmentVerdict.acceptedWithComments => 'ИИ: принято с замечаниями',

    AiAssessmentVerdict.reworkRequired => 'ИИ: нужна доработка',

    AiAssessmentVerdict.unknown => 'ИИ: результат неизвестен',
  };
}

Color _aiVerdictColor(AiAssessmentVerdict verdict) {
  return switch (verdict) {
    AiAssessmentVerdict.accepted => const Color(0xFF059669),

    AiAssessmentVerdict.acceptedWithComments => const Color(0xFFF59E0B),

    AiAssessmentVerdict.reworkRequired => const Color(0xFFDC2626),

    AiAssessmentVerdict.unknown => const Color(0xFF64748B),
  };
}

String _eventActionLabel(WorkOrderEventAction action) {
  return switch (action) {
    WorkOrderEventAction.create => 'Наряд создан',
    WorkOrderEventAction.accept => 'Наряд принят',
    WorkOrderEventAction.queue => 'Добавлен в очередь',
    WorkOrderEventAction.reject => 'Наряд отклонён',
    WorkOrderEventAction.start => 'Работа начата',
    WorkOrderEventAction.pause => 'Работа приостановлена',
    WorkOrderEventAction.resume => 'Работа продолжена',
    WorkOrderEventAction.complete => 'Работа выполнена',
    WorkOrderEventAction.aiReview => 'Передан на проверку',
    WorkOrderEventAction.sendToRework => 'Отправлен на доработку',
    WorkOrderEventAction.close => 'Наряд закрыт',
    WorkOrderEventAction.cancel => 'Наряд отменён',
    WorkOrderEventAction.edit => 'Наряд изменён',
    WorkOrderEventAction.reassign => 'Исполнитель изменён',
    WorkOrderEventAction.comment => 'Добавлен комментарий',
    WorkOrderEventAction.unknown => 'Событие',
  };
}

String _formatEventDate(DateTime value) => enterpriseDateTimeLabel(value);

String _absoluteUrl(String baseUrl, String url) {
  final value = url.trim();

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  final base = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;

  final path = value.startsWith('/') ? value : '/$value';

  return '$base$path';
}

extension _StringFallback on String {
  String ifEmpty(String fallback) {
    return trim().isEmpty ? fallback : this;
  }
}
