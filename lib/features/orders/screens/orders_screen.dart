import '../../master/widgets/master_ui.dart';
import '../widgets/master_scope_filters.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import '../../../shared/widgets/app_refresh_indicator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../data/work_orders_api.dart';
import '../widgets/master_completion_sheet.dart';

import '../../../shared/widgets/backend_section.dart';

import 'package:mineral/core/api/api_client.dart';

import 'package:mineral/core/api/api_services.dart';

import 'package:mineral/features/orders/models/work_order_api_models.dart';

import 'package:mineral/l10n/ui_localization.dart';

import 'package:mineral/shared/models/models.dart';

import 'package:mineral/shared/widgets/ui.dart';
import '../../../core/theme/app_theme.dart';

class OrdersViewTabs extends StatelessWidget implements PreferredSizeWidget {
  const OrdersViewTabs({super.key, required this.onChanged});
  final ValueChanged<bool> onChanged;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) => TabBar(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white,
    indicatorColor: Colors.white,
    dividerColor: Colors.transparent,
    indicatorSize: TabBarIndicatorSize.tab,
    onTap: (index) => onChanged(index == 1),
    tabs: [
      for (final tab in [
        ('Список', LucideIcons.list),
        ('Канбан', LucideIcons.columns3),
      ])
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tab.$2, size: 18),
              const SizedBox(width: 8),
              Text(uiText(context, tab.$1)),
            ],
          ),
        ),
    ],
  );
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,

    required this.api,

    required this.onOrder,

    required this.onCreate,
    this.boardView,
  });

  final ApiServices api;

  final ValueChanged<WorkOrderApiModel> onOrder;

  final VoidCallback onCreate;
  final bool? boardView;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final searchController = TextEditingController();
  final _boardScrollController = ScrollController();
  final _boardViewportKey = GlobalKey();
  final _movingOrders = <int>{};
  final _submittingOrders = <int>{};
  final _actionIds = <String, String>{};
  Timer? _dragScrollTimer;
  Offset? _dragPosition;
  Timer? _boardWaitTimer;
  Completer<void>? _boardWait;

  List<WorkOrderApiModel> orders = [];

  bool loading = true;

  bool refreshing = false;

  bool board = false;

  String? error;

  int generation = 0;

  StreamSubscription<void>? subscription;

  WorkOrderStatus? statusFilter;

  WorkOrderPriority? priorityFilter;

  bool overdueOnly = false;

  Map<String, int> scope = {};

  WorkOrderBoard? boardData;

  Timer? refreshTimer;

  DateTime? lastBoardRequest;

  Future<void> refreshOrders() => loadOrders(refresh: true);

  @override
  void initState() {
    super.initState();
    board = widget.boardView ?? false;

    subscription = widget.api.realtime.changes.listen((_) {
      refreshTimer ??= Timer(const Duration(seconds: 1), () {
        refreshTimer = null;

        loadOrders(refresh: true);
      });
    });

    loadOrders();
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.boardView != null && board != widget.boardView) {
      board = widget.boardView!;
      loadOrders(refresh: true);
    }
  }

  @override
  void dispose() {
    _dragScrollTimer?.cancel();
    _cancelBoardWait();
    _boardScrollController.dispose();

    subscription?.cancel();

    refreshTimer?.cancel();

    searchController.dispose();

    super.dispose();
  }

  // MARK: Load

  Future<void> loadOrders({bool refresh = false}) async {
    final requestGeneration = ++generation;
    _cancelBoardWait();

    if (refresh) {
      setState(() {
        refreshing = true;

        error = null;
      });
    } else {
      setState(() {
        loading = true;

        error = null;
      });
    }

    try {
      final result = await widget.api.workOrders.getAllWorkOrders(
        statuses: statusFilter == null ? null : [statusFilter!],

        priority: priorityFilter,

        overdue: overdueOnly,

        areaId: scope['areaId'],

        equipmentId: scope['equipmentId'],

        assigneeId: scope['executorId'],

        brigadeId: scope['brigadeId'],
      );

      if (!mounted || requestGeneration != generation) return;

      if (board && lastBoardRequest != null) {
        final elapsed = DateTime.now().difference(lastBoardRequest!);

        if (elapsed < const Duration(seconds: 1)) {
          final wait = Completer<void>();
          _boardWait = wait;
          _boardWaitTimer = Timer(const Duration(seconds: 1) - elapsed, () {
            _boardWaitTimer = null;
            _boardWait = null;
            wait.complete();
          });
          await wait.future;
        }
      }

      if (!mounted || requestGeneration != generation) return;

      if (board) lastBoardRequest = DateTime.now();

      final boardResult = board
          ? await widget.api.workOrders.getBoard(
              filters: {
                for (final entry in scope.entries)
                  (entry.key == 'executorId' ? 'assigneeId' : entry.key):
                      entry.value,

                if (statusFilter != null) 'status': statusFilter!.apiValue,

                if (priorityFilter != null)
                  'priority': priorityFilter!.apiValue,

                if (overdueOnly) 'overdue': 1,
              },
            )
          : null;

      if (!mounted || requestGeneration != generation) return;

      setState(() {
        orders = result;

        boardData = boardResult;

        loading = false;

        refreshing = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestGeneration != generation) return;

      setState(() {
        error = e.message;

        loading = false;

        refreshing = false;
      });
    } catch (e) {
      if (!mounted || requestGeneration != generation) return;

      setState(() {
        error = backendError(context, e);

        loading = false;

        refreshing = false;
      });
    }
  }

  // MARK: Filter

  List<WorkOrderApiModel> get filteredOrders {
    final filtered = _applyFilters(orders);
    return [
      ...filtered.where((order) => !order.status.isFinished),
      ...filtered.where((order) => order.status.isFinished),
    ];
  }

  List<WorkOrderApiModel> _applyFilters(Iterable<WorkOrderApiModel> source) {
    final query = searchController.text.trim().toLowerCase();

    return source.where((order) {
      if (statusFilter != null && order.status != statusFilter) {
        return false;
      }

      if (priorityFilter != null && order.priority != priorityFilter) {
        return false;
      }

      if (overdueOnly && !order.isOverdue) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final searchText = [
        order.number,

        order.description,

        order.area.name,

        order.equipment.name,

        order.equipment.inventoryNumber,

        order.assignee.fullName,

        order.faultCode?.code,

        order.faultCode?.name,
      ].whereType<String>().join(' ').toLowerCase();

      return searchText.contains(query);
    }).toList();
  }

  int get activeFilters {
    var count = 0;

    if (statusFilter != null) count++;

    if (priorityFilter != null) count++;

    if (overdueOnly) count++;

    return count + scope.length;
  }

  // MARK: Filters

  Future<void> openFilters() async {
    WorkOrderStatus? tempStatus = statusFilter;

    WorkOrderPriority? tempPriority = priorityFilter;

    bool tempOverdue = overdueOnly;

    var tempScope = Map<String, int>.from(scope);

    final apply = await showModalBottomSheet<bool>(
      context: context,

      isScrollControlled: true,

      useSafeArea: true,

      showDragHandle: true,

      backgroundColor: Colors.white,

      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    Text(
                      uiText(context, 'Фильтры'),

                      style: const TextStyle(
                        fontSize: 22,

                        fontWeight: FontWeight.w800,

                        color: ink,
                      ),
                    ),

                    const SizedBox(height: 22),

                    DropdownButtonFormField<WorkOrderStatus?>(
                      initialValue: tempStatus,

                      isExpanded: true,

                      decoration: InputDecoration(
                        labelText: uiText(context, 'Статус'),
                      ),

                      items: [
                        DropdownMenuItem<WorkOrderStatus?>(
                          value: null,

                          child: Text(uiText(context, 'Все статусы')),
                        ),

                        for (final status in WorkOrderStatus.values)
                          DropdownMenuItem<WorkOrderStatus?>(
                            value: status,

                            child: Text(uiText(context, status.label)),
                          ),
                      ],

                      onChanged: (value) {
                        setSheetState(() {
                          tempStatus = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<WorkOrderPriority?>(
                      initialValue: tempPriority,

                      isExpanded: true,

                      decoration: InputDecoration(
                        labelText: uiText(context, 'Приоритет'),
                      ),

                      items: [
                        DropdownMenuItem<WorkOrderPriority?>(
                          value: null,

                          child: Text(uiText(context, 'Все приоритеты')),
                        ),

                        for (final priority in WorkOrderPriority.values)
                          DropdownMenuItem<WorkOrderPriority?>(
                            value: priority,

                            child: Text(uiText(context, priority.label)),
                          ),
                      ],

                      onChanged: (value) {
                        setSheetState(() {
                          tempPriority = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    MasterScopeFilters(
                      api: widget.api,

                      value: tempScope,

                      onChanged: (value) =>
                          setSheetState(() => tempScope = value),
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,

                      title: Text(uiText(context, 'Только просроченные')),

                      value: tempOverdue,

                      onChanged: (value) {
                        setSheetState(() {
                          tempOverdue = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempStatus = null;

                              tempPriority = null;

                              tempOverdue = false;

                              tempScope = {};
                            });
                          },

                          child: Text(strings(context).resetFilters),
                        ),

                        const Spacer(),

                        FilledButton(
                          onPressed: () {
                            Navigator.pop(sheetContext, true);
                          },

                          child: Text(uiText(context, 'Применить')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (apply != true || !mounted) {
      return;
    }

    setState(() {
      statusFilter = tempStatus;

      priorityFilter = tempPriority;

      overdueOnly = tempOverdue;

      scope = tempScope;
    });

    await loadOrders(refresh: true);
  }

  // MARK: UI

  static const _blue = Color(0xFF01408B);
  static const _ink = Color(0xFF172B4D);
  static const _muted = Color(0xFF637B9E);
  static const _surface = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final screen = Scaffold(
        backgroundColor: _surface,
        appBar: widget.boardView == null
            ? AppBar(
                primary: false,
                toolbarHeight: 0,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: AppColors.primary,
                flexibleSpace: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.profileHeaderGradient,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: DefaultTabController(
                    length: 2,
                    child: OrdersViewTabs(
                      onChanged: (nextBoard) {
                        if (board == nextBoard) return;
                        setState(() => board = nextBoard);
                        loadOrders(refresh: true);
                      },
                    ),
                  ),
                ),
              )
            : null,
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('orders-create-order-fab'),
          heroTag: 'orders-create-order',
          onPressed: widget.onCreate,
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          icon: const Icon(LucideIcons.plus, size: 20),
          label: Text(uiText(context, 'Новый наряд')),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final content = Padding(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width >= 1000 ? 28 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 13, color: _ink),
                          decoration: InputDecoration(
                            hintText: uiText(
                              context,
                              'Номер, работа или оборудование',
                            ),
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: _muted,
                            ),
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 19,
                              color: _muted,
                            ),
                            suffixIcon: searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: strings(context).clearSearch,
                                    icon: const Icon(LucideIcons.x, size: 18),
                                    onPressed: () =>
                                        setState(searchController.clear),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EDF4),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _blue,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Badge(
                        isLabelVisible: activeFilters > 0,
                        label: Text('$activeFilters'),
                        child: IconButton.outlined(
                          tooltip: strings(context).filters,
                          onPressed: openFilters,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(50, 50),
                            foregroundColor: _blue,
                            backgroundColor: activeFilters > 0
                                ? const Color(0xFFEAF2FE)
                                : Colors.white,
                            side: const BorderSide(color: Color(0xFFE8EDF4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            LucideIcons.slidersHorizontal,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _results()),
                ],
              ),
            );
            return constraints.hasBoundedHeight
                ? content
                : SizedBox(
                    height: MediaQuery.sizeOf(context).height,
                    child: content,
                  );
          },
        ),
      );
      return constraints.hasBoundedHeight
          ? screen
          : SizedBox(height: MediaQuery.sizeOf(context).height, child: screen);
    },
  );

  Widget _results() {
    if (!loading &&
        error == null &&
        board &&
        (boardData != null || !refreshing)) {
      return _buildBoard();
    }
    final filtered = filteredOrders;
    return AppRefreshIndicator(
      onRefresh: refreshOrders,
      isLoading: loading || (board && refreshing && boardData == null),
      child:
          loading ||
              (board && refreshing && boardData == null) ||
              error != null ||
              filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (loading || (board && refreshing && boardData == null))
                  const SizedBox(height: 160)
                else if (error != null)
                  _OrdersError(message: error!, onRetry: loadOrders)
                else
                  Panel(
                    child: Text(
                      uiText(context, 'По выбранным фильтрам нарядов нет'),
                      style: const TextStyle(color: _muted),
                    ),
                  ),
              ],
            )
          : ListView.builder(
              key: const ValueKey('orders-list'),
              padding: const EdgeInsets.only(bottom: 88),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) => ApiOrderCard(
                order: filtered[index],
                onTap: () => widget.onOrder(filtered[index]),
              ),
            ),
    );
  }

  Widget _buildBoard() {
    const columns = [
      ('Выданные', 'issued'),
      ('Принятые', 'accepted'),
      ('В работе', 'inProgress'),
      ('В очереди', 'queued'),
      ('Выполненные', 'completed'),
      ('Просроченные', 'overdue'),
    ];
    return AppRefreshIndicator(
      onRefresh: refreshOrders,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.vertical,
      child: LayoutBuilder(
        key: _boardViewportKey,
        builder: (context, constraints) => ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            key: const ValueKey('kanban-horizontal-scroll'),
            controller: _boardScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: (constraints.maxHeight - 12).clamp(0.0, double.infinity),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final column in columns)
                    _ApiKanbanColumn(
                      key: ValueKey('kanban-column-${column.$2}'),
                      columnId: column.$2,
                      title: column.$1,
                      orders: _applyFilters(
                        boardData?.columns[column.$2] ?? [],
                      ),
                      onOrder: widget.onOrder,
                      movingOrders: _movingOrders,
                      submittingOrders: _submittingOrders,
                      canAccept: (drag) =>
                          drag.columnId != column.$2 &&
                          !_movingOrders.contains(drag.order.id) &&
                          _actionForColumn(drag.order, column.$2) != null,
                      onAccept: (drag) => _moveOrder(drag.order, column.$2),
                      onDragStarted: _startDrag,
                      onDragUpdate: (details) =>
                          _dragPosition = details.globalPosition,
                      onDragEnd: _endDrag,
                      overdue: column.$2 == 'overdue',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  WorkOrderAction? _actionForColumn(WorkOrderApiModel order, String column) {
    return switch ((column, order.status)) {
      ('accepted', WorkOrderStatus.issued || WorkOrderStatus.queued) =>
        WorkOrderAction.accept,
      ('queued', WorkOrderStatus.issued) => WorkOrderAction.queue,
      (
        'inProgress',
        WorkOrderStatus.accepted ||
            WorkOrderStatus.queued ||
            WorkOrderStatus.rework,
      ) =>
        WorkOrderAction.start,
      ('inProgress', WorkOrderStatus.paused) => WorkOrderAction.resume,
      ('inProgress', WorkOrderStatus.aiReview) => WorkOrderAction.sendToRework,
      ('completed', WorkOrderStatus.inProgress) => WorkOrderAction.complete,
      _ => null,
    };
  }

  void _cancelBoardWait() {
    _boardWaitTimer?.cancel();
    _boardWaitTimer = null;
    _boardWait?.complete();
    _boardWait = null;
  }

  void _startDrag() {
    _dragScrollTimer?.cancel();
    _dragScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final position = _dragPosition;
      final box = _boardViewportKey.currentContext?.findRenderObject();
      if (position == null ||
          box is! RenderBox ||
          !_boardScrollController.hasClients) {
        return;
      }
      final local = box.globalToLocal(position);
      if (local.dy < 0 || local.dy > box.size.height) return;
      const edge = 56.0;
      final speed = local.dx < edge
          ? -12.0 * ((edge - local.dx) / edge).clamp(0.0, 1.0)
          : local.dx > box.size.width - edge
          ? 12.0 * ((local.dx - box.size.width + edge) / edge).clamp(0.0, 1.0)
          : 0.0;
      if (speed == 0) return;
      final scroll = _boardScrollController.position;
      final offset = (scroll.pixels + speed).clamp(
        scroll.minScrollExtent,
        scroll.maxScrollExtent,
      );
      if (offset != scroll.pixels) _boardScrollController.jumpTo(offset);
    });
  }

  void _endDrag(DraggableDetails _) {
    _dragScrollTimer?.cancel();
    _dragScrollTimer = null;
    _dragPosition = null;
  }

  Future<void> _moveOrder(WorkOrderApiModel order, String column) async {
    final action = _actionForColumn(order, column);
    if (action == null || _movingOrders.contains(order.id)) return;
    setState(() => _movingOrders.add(order.id));
    final actionKey = '${order.id}:${action.apiValue}';
    final clientActionId = _actionIds.putIfAbsent(
      actionKey,
      () => const Uuid().v4(),
    );
    try {
      if (action == WorkOrderAction.complete) {
        final completed = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          isDismissible: false,
          enableDrag: false,
          builder: (_) => MasterCompletionSheet(
            api: widget.api,
            order: order,
            clientActionId: clientActionId,
          ),
        );
        if (completed != true || !mounted) return;
        setState(() => _submittingOrders.add(order.id));
      } else {
        final comment = action == WorkOrderAction.sendToRework
            ? await _requestReworkReason()
            : null;
        if (!mounted ||
            (action == WorkOrderAction.sendToRework && comment == null)) {
          return;
        }
        setState(() => _submittingOrders.add(order.id));
        await widget.api.workOrders.performAction(
          order.id,
          WorkOrderActionInput(
            action: action,
            clientActionId: clientActionId,
            comment: comment,
          ),
        );
      }
      _actionIds.remove(actionKey);
      if (!mounted) return;
      widget.api.realtime.invalidate();
      refreshTimer?.cancel();
      refreshTimer = null;
      await refreshOrders();
    } catch (failure) {
      if (!mounted) return;
      if (failure is ApiException &&
          failure.statusCode >= 400 &&
          failure.statusCode < 500) {
        _actionIds.remove(actionKey);
        if (failure.statusCode == 409 || failure.statusCode == 404) {
          await refreshOrders();
          if (!mounted) return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uiText(
              context,
              failure is ApiException
                  ? failure.message
                  : 'Не удалось изменить статус. Повторите попытку.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _movingOrders.remove(order.id);
          _submittingOrders.remove(order.id);
        });
      }
    }
  }

  Future<String?> _requestReworkReason() async {
    final controller = TextEditingController();
    final form = GlobalKey<FormState>();
    final route = DialogRoute<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(uiText(context, 'Отправить на доработку')),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: uiText(context, 'Что необходимо исправить'),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? uiText(context, 'Укажите причину')
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(uiText(context, 'Отмена')),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: Text(uiText(context, 'На доработку')),
          ),
        ],
      ),
    );
    final result = await Navigator.of(context).push(route);
    await route.completed;
    controller.dispose();
    return result;
  }
}
// MARK: - API order card

class ApiOrderCard extends StatelessWidget {
  const ApiOrderCard({super.key, required this.order, required this.onTap});
  final WorkOrderApiModel order;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final equipment = uiText(context, order.equipment.name);
    final area = uiText(context, order.area.name);
    final assignee = order.assignee.fullName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: order.isEmergency
                ? const Color(0xFFFECACA)
                : MasterColors.line,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        uiText(context, 'НАРЯД №${order.number}'),
                        style: const TextStyle(
                          color: MasterColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _ApiStatusTag(
                        text: order.status.label,
                        color: _statusColor(order.status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  uiText(context, order.description),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MasterColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.factory,
                        size: 18,
                        color: MasterColors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$equipment · $area',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: MasterColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.userRound,
                      size: 16,
                      color: MasterColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        assignee,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MasterColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: MasterColors.line),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ApiStatusTag(
                      text: order.priority.label,
                      color: _priorityColor(order.priority),
                    ),
                    Text(
                      uiText(
                        context,
                        'До ${dateLabel(order.deadline)} ${timeLabel(order.deadline)}',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: order.isOverdue ? Colors.red : muted,
                      ),
                    ),
                    if (order.isOverdue)
                      const _ApiStatusTag(text: 'Просрочен', color: Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// MARK: - API kanban

class _KanbanOrderDrag {
  const _KanbanOrderDrag(this.order, this.columnId);
  final WorkOrderApiModel order;
  final String columnId;
}

class _ApiKanbanColumn extends StatefulWidget {
  const _ApiKanbanColumn({
    super.key,
    required this.columnId,
    required this.title,
    required this.orders,
    required this.onOrder,
    required this.movingOrders,
    required this.submittingOrders,
    required this.canAccept,
    required this.onAccept,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.overdue = false,
  });
  final String columnId;
  final String title;
  final List<WorkOrderApiModel> orders;
  final ValueChanged<WorkOrderApiModel> onOrder;
  final Set<int> movingOrders;
  final Set<int> submittingOrders;
  final bool Function(_KanbanOrderDrag) canAccept;
  final ValueChanged<_KanbanOrderDrag> onAccept;
  final VoidCallback onDragStarted;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final ValueChanged<DraggableDetails> onDragEnd;
  final bool overdue;

  @override
  State<_ApiKanbanColumn> createState() => _ApiKanbanColumnState();
}

class _ApiKanbanColumnState extends State<_ApiKanbanColumn> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DragTarget<_KanbanOrderDrag>(
    onWillAcceptWithDetails: (details) => widget.canAccept(details.data),
    onAcceptWithDetails: (details) => widget.onAccept(details.data),
    builder: (context, candidates, rejected) => Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: candidates.isEmpty
            ? const Color(0xFFEAF2FE)
            : const Color(0xFFD5E6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: candidates.isEmpty ? border : const Color(0xFF01408B),
          width: candidates.isEmpty ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: ValueKey('kanban-header-${widget.columnId}'),
            height: 40,
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.overdue
                        ? Colors.red
                        : const Color(0xFF01408B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    uiText(context, widget.title),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                Text(
                  '${widget.orders.length}',
                  style: const TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView.builder(
                key: PageStorageKey('kanban-orders-${widget.columnId}'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: widget.orders.isEmpty ? 1 : widget.orders.length,
                itemBuilder: (context, index) => widget.orders.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          uiText(context, 'Нет нарядов'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                      )
                    : _draggableCard(widget.orders[index]),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _draggableCard(WorkOrderApiModel order) {
    final moving = widget.movingOrders.contains(order.id);
    final card = ApiOrderCard(order: order, onTap: () => widget.onOrder(order));
    return LongPressDraggable<_KanbanOrderDrag>(
      key: ValueKey('kanban-drag-${widget.columnId}-${order.id}'),
      data: _KanbanOrderDrag(order, widget.columnId),
      maxSimultaneousDrags:
          moving ||
              order.status.isFinished ||
              order.status == WorkOrderStatus.completed
          ? 0
          : 1,
      onDragStarted: widget.onDragStarted,
      onDragUpdate: widget.onDragUpdate,
      onDragEnd: widget.onDragEnd,
      feedback: Material(
        elevation: 10,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(width: 252, child: IgnorePointer(child: card)),
      ),
      childWhenDragging: Opacity(
        opacity: .3,
        child: IgnorePointer(child: card),
      ),
      child: moving
          ? Stack(
              children: [
                Opacity(opacity: .45, child: IgnorePointer(child: card)),
                if (widget.submittingOrders.contains(order.id))
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            )
          : card,
    );
  }
}
// MARK: - Orders error

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        children: [
          const Icon(LucideIcons.wifiOff, size: 38, color: Colors.red),

          const SizedBox(height: 12),

          Text(message, textAlign: TextAlign.center),

          const SizedBox(height: 14),

          FilledButton.icon(
            onPressed: onRetry,

            icon: const Icon(Icons.replay),

            label: Text(uiText(context, 'Повторить')),
          ),
        ],
      ),
    );
  }
}

// MARK: - API helpers

class _ApiStatusTag extends StatelessWidget {
  const _ApiStatusTag({required this.text, required this.color});

  final String text;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),

        borderRadius: BorderRadius.circular(999),
      ),

      child: Text(
        uiText(context, text),

        style: TextStyle(
          color: color,

          fontSize: 11,

          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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
