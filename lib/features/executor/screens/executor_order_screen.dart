import 'package:mineral/shared/widgets/app_bottom_sheet.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:mineral/l10n/ui_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'completion_screen.dart';
import '../widgets/order_section.dart';
import '../widgets/work_timer.dart';
import '../models/executor_order_queue.dart';
import 'package:mineral/features/executor/data/executor_repository.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:mineral/features/orders/widgets/photo_attachments.dart';
import '../models/executor_order_actions.dart';

class ExecutorOrderScreen extends StatefulWidget {
  const ExecutorOrderScreen({
    super.key,
    required this.store,
    required this.order,
    required this.employeeId,
  });
  final ExecutorRepository store;
  final WorkOrder order;
  final int employeeId;

  @override
  State<ExecutorOrderScreen> createState() => _ExecutorOrderScreenState();
}

class _ExecutorOrderScreenState extends State<ExecutorOrderScreen> {
  ExecutorRepository get store => widget.store;
  WorkOrder get order => widget.order;
  int get employeeId => widget.employeeId;
  bool _changing = false;
  bool _reasonOpen = false;
  final _comment = TextEditingController();
  late Future<List<String?>> _savedReasons;

  Future<List<String?>> _loadSavedReasons() => Future.wait([
    for (final status in [OrderStatus.paused, OrderStatus.rejected])
      store
          .restoreActionReason(employeeId, order, status)
          .catchError((Object _) => null),
  ]);

  @override
  void initState() {
    super.initState();
    _savedReasons = _loadSavedReasons();
    store.addListener(_refreshSavedReasons);
  }

  void _refreshSavedReasons() {
    final savedReasons = _loadSavedReasons();
    setState(() {
      _savedReasons = savedReasons;
    });
  }

  @override
  void didUpdateWidget(covariant ExecutorOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != store ||
        oldWidget.order != order ||
        oldWidget.employeeId != employeeId) {
      oldWidget.store.removeListener(_refreshSavedReasons);
      store.addListener(_refreshSavedReasons);
      _savedReasons = _loadSavedReasons();
    }
  }

  @override
  void dispose() {
    store.removeListener(_refreshSavedReasons);
    _comment.dispose();
    super.dispose();
  }

  Future<bool> _change(
    BuildContext context,
    OrderStatus status, {
    String reason = '',
    bool reasonForm = false,
  }) async {
    if (_changing) return false;
    setState(() => _changing = true);
    try {
      await store.executorAction(employeeId, order, status, reason: reason);
      return true;
    } catch (error) {
      if (reasonForm && error is ApiException && error.status == 400) rethrow;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException && error.message.isNotEmpty
                  ? uiText(context, error.message)
                  : error is StateError &&
                        error.message ==
                            'Сначала приостановите или завершите текущий наряд'
                  ? strings(context).finishCurrentFirst
                  : strings(context).changeStatusFailed,
            ),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  Future<void> _reload() async {
    if (_changing) return;
    setState(() => _changing = true);
    try {
      await store.loadExecutorOrder(employeeId, order);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException && error.message.isNotEmpty
                  ? uiText(context, error.message)
                  : strings(context).authNetworkError,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  Future<void> _reason(BuildContext context, OrderStatus status) async {
    if (_reasonOpen || _changing) return;
    _reasonOpen = true;
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();
    String? serverError;
    var sending = false;
    try {
      try {
        controller.text =
            await store.restoreActionReason(employeeId, order, status) ?? '';
      } catch (_) {
        // A storage error must not block entering a new reason.
      }
      if (!context.mounted) return;
      await showAppBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, updateSheet) => PopScope(
            canPop: !sending,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        uiText(
                          sheetContext,
                          status == OrderStatus.rejected
                              ? 'Причина отказа'
                              : 'Причина приостановки',
                        ),
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: key,
                        child: TextFormField(
                          controller: controller,
                          autofocus: true,
                          maxLines: 3,
                          enabled: !sending,
                          decoration: InputDecoration(
                            labelText: uiText(sheetContext, 'Причина'),
                            errorText: serverError,
                          ),
                          onChanged: (_) {
                            if (serverError != null) {
                              updateSheet(() => serverError = null);
                            }
                          },
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? uiText(sheetContext, 'Укажите причину')
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (sending)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
                              ),
                              onPressed: sending
                                  ? null
                                  : () => Navigator.pop(sheetContext),
                              child: Text(uiText(sheetContext, 'Отмена')),
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: FilledButton(
                              onPressed: sending
                                  ? null
                                  : () async {
                                      if (!key.currentState!.validate()) return;
                                      updateSheet(() {
                                        sending = true;
                                        serverError = null;
                                      });
                                      try {
                                        final success = await _change(
                                          context,
                                          status,
                                          reason: controller.text.trim(),
                                          reasonForm: true,
                                        );
                                        if (!sheetContext.mounted) return;
                                        updateSheet(() => sending = false);
                                        if (success ||
                                            order.accessErrorStatus != null ||
                                            !availableExecutorActions(
                                              order,
                                              employeeId,
                                            ).contains(
                                              status == OrderStatus.rejected
                                                  ? 'REJECT'
                                                  : 'PAUSE',
                                            )) {
                                          Navigator.pop(sheetContext);
                                        }
                                      } on ApiException catch (error) {
                                        if (sheetContext.mounted) {
                                          updateSheet(() {
                                            sending = false;
                                            serverError =
                                                error.fieldMessage('comment') ??
                                                (error.message.isNotEmpty
                                                    ? uiText(
                                                        context,
                                                        error.message,
                                                      )
                                                    : uiText(
                                                        sheetContext,
                                                        'Укажите причину',
                                                      ));
                                          });
                                        }
                                      }
                                    },
                              child: Text(uiText(sheetContext, 'Подтвердить')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      controller.dispose();
      _reasonOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final assigned = store.assignedTo(employeeId).contains(order);
      final queuePosition = ExecutorOrderQueue(
        store.assignedTo(employeeId),
      ).position(order);
      final otherWorking = store
          .assignedTo(employeeId)
          .any((o) => o != order && o.status == OrderStatus.working);
      final actions = assigned
          ? availableExecutorActions(order, employeeId)
          : const <String>{};
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(strings(context).orderNumber(order.displayNumber)),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEF0F4))),
            ),
            child: AbsorbPointer(
              absorbing: _changing,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_changing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (otherWorking &&
                      {
                        OrderStatus.accepted,
                        OrderStatus.queued,
                        OrderStatus.paused,
                        OrderStatus.rework,
                      }.contains(order.status))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        strings(context).finishCurrentFirst,
                        style: const TextStyle(color: Color(0xFF687385)),
                      ),
                    ),
                  if (!assigned || order.accessErrorStatus != null)
                    Text(
                      order.accessErrorStatus != null
                          ? (order.accessErrorMessage?.isNotEmpty == true
                                ? order.accessErrorMessage!
                                : strings(context).orderUnavailable)
                          : uiText(
                              context,
                              'Наряд переназначен другому исполнителю.',
                            ),
                    ),
                  if (order.accessErrorStatus == 409)
                    OutlinedButton(
                      onPressed: _changing ? null : _reload,
                      child: Text(strings(context).retry),
                    ),
                  if (actions.contains('ACCEPT'))
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _change(
                        context,
                        OrderStatus.accepted,
                        reason: _comment.text.trim(),
                      ),
                      icon: const Icon(LucideIcons.play, size: 18),
                      label: Text(uiText(context, 'Принять в работу')),
                    ),

                  if (actions.contains('QUEUE')) ...[
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: Color(0xFF01408B)),
                      ),
                      onPressed: () => _change(
                        context,
                        OrderStatus.queued,
                        reason: _comment.text.trim(),
                      ),
                      icon: const Icon(LucideIcons.listChecks, size: 18),
                      label: Text(uiText(context, 'Поставить в очередь')),
                    ),
                  ],

                  if (actions.contains('REJECT'))
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => _reason(context, OrderStatus.rejected),
                      child: Text(uiText(context, 'Отклонить')),
                    ),
                  if (actions.contains('START') || actions.contains('RESUME'))
                    FilledButton(
                      onPressed: otherWorking
                          ? null
                          : () => _change(context, OrderStatus.working),
                      child: Text(
                        order.status == OrderStatus.paused ||
                                order.status == OrderStatus.rework
                            ? uiText(context, 'Возобновить работу')
                            : uiText(context, 'Начать исполнение'),
                      ),
                    ),
                  if (actions.contains('PAUSE') &&
                      actions.contains('COMPLETE')) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _reason(context, OrderStatus.paused),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(60),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              textStyle: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(fontSize: 13),
                              backgroundColor: const Color(0xFFFFE6A3),
                              foregroundColor: const Color(0xFF8F5100),
                              side: BorderSide.none,
                            ),
                            icon: const Icon(Icons.pause_rounded, size: 18),
                            label: Text(uiText(context, 'Приостановить')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CompletionScreen(
                                  store: store,
                                  order: order,
                                  employeeId: employeeId,
                                ),
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(60),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              textStyle: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(fontSize: 13),
                              backgroundColor: const Color(0xFF08A45C),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: Text(uiText(context, 'Исполнено')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            FutureBuilder<List<String?>>(
              future: _savedReasons,
              builder: (context, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < 2; index++)
                    if (!actions.contains(index == 0 ? 'PAUSE' : 'REJECT') &&
                        snapshot.data?[index] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: OrderSection(
                          icon: LucideIcons.fileText,
                          title: index == 0
                              ? strings(context).pauseReason
                              : strings(context).rejectReason,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(strings(context).savedReasonNotSent),
                              const SizedBox(height: 8),
                              SelectableText(
                                snapshot.data![index]!,
                                key: ValueKey('saved-action-reason-$index'),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.settings,
                    size: 20,
                    color: Color(0xFF01408B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      executorStatusText(context, order),
                      style: const TextStyle(
                        color: Color(0xFF01408B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    LucideIcons.clock,
                    size: 18,
                    color: Color(0xFF01408B),
                  ),
                  const SizedBox(width: 6),
                  WorkTimer(order: order, store: store),
                ],
              ),
            ),
            if (queuePosition != null) ...[
              const SizedBox(height: 16),
              Text(
                strings(context).queuePosition('$queuePosition'),
                style: const TextStyle(
                  color: Color(0xFF01408B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              uiText(context, order.title),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE6EAF0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: order.beforeImages.isNotEmpty
                        ? Image.memory(
                            order.beforeImages.first.bytes,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFFEAF3FF),
                            child: const Icon(
                              LucideIcons.factory,
                              color: Color(0xFF65748B),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings(context).equipment,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8491A6),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          uiText(context, order.equipment),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          uiText(context, order.area),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF65748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE6EAF0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.clock,
                      color: Color(0xFF01408B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          uiText(context, 'Срок выполнения'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8491A6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateLabel(order.deadline)} · ${timeLabel(order.deadline)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: order.overdue
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF01408B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings(
                            context,
                          ).priorityValue(uiText(context, order.priority)),
                          style: TextStyle(
                            fontSize: 12,
                            color: order.emergency
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF65748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OrderSection(
              icon: LucideIcons.fileText,
              title: uiText(context, 'Описание неисправности'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  uiText(context, order.description),
                  style: const TextStyle(fontSize: 14, height: 1.45),
                ),
              ),
            ),
            if (order.comment.isNotEmpty) ...[
              const SizedBox(height: 20),
              OrderSection(
                icon: LucideIcons.messageSquare,
                title: uiText(context, 'Комментарий'),
                child: Text(uiText(context, order.comment)),
              ),
            ],
            if (actions.contains('ACCEPT') || actions.contains('QUEUE')) ...[
              const SizedBox(height: 18),
              OrderSection(
                icon: LucideIcons.messageSquare,
                title: strings(context).comment,
                child: TextField(
                  controller: _comment,
                  enabled: !_changing,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: strings(context).optionalComment,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8491A6),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDCE5F1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDCE5F1)),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (order.beforeImages.isNotEmpty)
              PhotoAttachments(
                title: uiText(context, 'Фото до начала работ'),
                photos: order.beforeImages,
                framed: false,
              )
            else if (!actions.contains('ACCEPT'))
              OrderSection(
                icon: Icons.camera_alt_outlined,
                title: uiText(context, 'Фото до начала работ'),
                child: Text(
                  uiText(context, 'Мастер не добавил фотографии'),
                  style: const TextStyle(color: Color(0xFF65748B)),
                ),
              ),
            if (order.history.isNotEmpty) ...[
              const SizedBox(height: 24),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  uiText(context, 'История действий'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  for (final event in order.history.reversed)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(eventText(context, event)),
                      subtitle: Text(
                        '${eventAuthor(context, event)} · ${dateLabel(event.time)} ${timeLabel(event.time)}',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}
