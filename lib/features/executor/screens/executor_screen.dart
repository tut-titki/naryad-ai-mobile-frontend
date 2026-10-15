import 'package:mineral/shared/widgets/app_transition_page.dart';

import 'executor_history_screen.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_notifications_button.dart';
import '../../../shared/widgets/app_refresh_indicator.dart';
import 'dart:async';
import '../widgets/executor_greeting.dart';
import '../widgets/executor_history_tile.dart';
import '../models/executor_order_queue.dart';
import 'executor_order_loader.dart';
import 'executor_profile_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'package:mineral/l10n/ui_localization.dart';
import 'package:mineral/features/executor/data/executor_repository.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:mineral/shared/widgets/app_navigation.dart';

class ExecutorScreen extends StatefulWidget {
  final ExecutorRepository store;
  final int employeeId;
  final bool refreshOnOpen;

  const ExecutorScreen({
    super.key,
    required this.store,
    required this.employeeId,
    this.refreshOnOpen = true,
  });

  @override
  State<ExecutorScreen> createState() => _ExecutorScreenState();
}

class _ExecutorScreenState extends State<ExecutorScreen> {
  int _page = 0;
  String _query = '';
  String? _refreshError;

  Future<void> _refresh() async {
    try {
      await store.refreshExecutor(employeeId);
      if (mounted) setState(() => _refreshError = null);
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _refreshError = error is ApiException && error.message.isNotEmpty
              ? uiText(context, error.message)
              : strings(context).refreshFailed,
        );
      }
    }
  }

  Timer? _greetingTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.refreshOnOpen) unawaited(_refresh());
    });
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  ExecutorRepository get store => widget.store;
  int get employeeId => widget.employeeId;

  void _openOrder(WorkOrder order) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ExecutorOrderLoader(
        store: store,
        order: order,
        employeeId: employeeId,
        showResult: _page == 1 ? true : null,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final employee = store.employee(employeeId);
    final currentPage = _page;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: _page != 0 ? const Color(0xFF01408B) : Colors.white,
        flexibleSpace: _page != 0
            ? const SizedBox.expand(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF01408B), Color(0xFF0A57A3)],
                    ),
                  ),
                ),
              )
            : null,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: _page != 0
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleSpacing: _page == 2 ? 24 : null,
        scrolledUnderElevation: 0,
        title: Text(
          [
            uiText(context, 'Мои наряды'),
            uiText(context, 'История нарядов'),
            uiText(context, 'Профиль'),
          ][_page],
          style: TextStyle(
            color: _page != 0 ? Colors.white : const Color(0xFF172033),
          ),
        ),
        actions: [
          AppNotificationsButton(
            color: _page != 0 ? Colors.white : null,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => NotificationsScreen.forUser(
                  context: context,
                  repository: store,
                  userId: employeeId,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppNavigation(
        items: AppNavigationItems.executor,
        selectedIndex: _page,
        onDestinationSelected: (value) => setState(() => _page = value),
      ),
      body: AppTransitionPage(
        page: _page,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            if (currentPage == 2) {
              return ExecutorProfileScreen(
                store: store,
                employeeId: employeeId,
              );
            }
            if (store.loadError != null &&
                store.assignedTo(employeeId).isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(uiText(context, _refreshError ?? store.loadError!)),
                    TextButton(
                      onPressed: _refresh,
                      child: Text(uiText(context, 'Повторить')),
                    ),
                  ],
                ),
              );
            }
            if (currentPage == 1) {
              return ExecutorHistoryScreen(
                orders: store.assignedTo(employeeId),
                now: store.now,
                onRefresh: _refresh,
                onOpen: _openOrder,
                loadTime: (order) =>
                    store.loadExecutorOrderTime(employeeId, order),
                error: _refreshError ?? store.loadError,
                isLoading:
                    store.isLoading && store.assignedTo(employeeId).isEmpty,
              );
            }
            final orders = store.assignedTo(employeeId).where((order) {
              final archived = {
                OrderStatus.closed,
                OrderStatus.cancelled,
                OrderStatus.rejected,
              }.contains(order.status);
              return currentPage == 1 ? archived : !archived;
            }).toList();
            orders.sort((a, b) {
              if (currentPage == 1) {
                return (b.finishedAt ?? b.createdAt).compareTo(
                  a.finishedAt ?? a.createdAt,
                );
              }
              return ExecutorOrderQueue.compare(a, b);
            });

            final queue = ExecutorOrderQueue(orders);
            final visible = orders
                .where(
                  (o) =>
                      ('${o.displayNumber} ${o.title} ${o.equipment} ${uiText(context, o.title)} ${uiText(context, o.equipment)}'
                          .toLowerCase()
                          .contains(_query.trim().toLowerCase())),
                )
                .toList();
            return AppRefreshIndicator(
              onRefresh: _refresh,
              isLoading:
                  store.isLoading && store.assignedTo(employeeId).isEmpty,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (currentPage == 0)
                    ExecutorGreeting(
                      employee: employee,
                      time: store.now,
                      orders: store.assignedTo(employeeId),
                    )
                  else
                    Text(
                      uiText(
                        context,
                        'Завершённые, отменённые и отклонённые наряды',
                      ),
                      style: const TextStyle(
                        color: Color(0xFF687385),
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (store.loadError != null || _refreshError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        uiText(context, store.loadError ?? _refreshError!),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE5E8ED)),
                      ),
                      hintText: uiText(
                        context,
                        'Поиск по номеру или оборудованию',
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 19,
                        color: Color(0xFF637B9E),
                      ),
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF637B9E),
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    Text(
                      orders.isNotEmpty
                          ? uiText(
                              context,
                              'По вашему запросу ничего не найдено',
                            )
                          : currentPage == 1
                          ? uiText(context, 'История пока пуста')
                          : uiText(context, 'Нет активных нарядов'),
                    ),
                  if (currentPage == 1)
                    for (final order in visible) ...[
                      ExecutorHistoryTile(
                        order: order,
                        now: store.now,
                        onTap: () => _openOrder(order),
                      ),
                      const SizedBox(height: 10),
                    ]
                  else ...[
                    for (final status in [
                      OrderStatus.working,
                      OrderStatus.paused,
                      OrderStatus.issued,
                      OrderStatus.accepted,
                      OrderStatus.rework,
                      OrderStatus.queued,
                      OrderStatus.review,
                    ])
                      if (visible.any((o) => o.status == status)) ...[
                        _section(uiText(context, status.label), status.color),
                        for (final order in visible.where(
                          (o) => o.status == status,
                        )) ...[
                          _OrderTile(
                            order: order,
                            queuePosition: queue.position(order),
                            now: store.now,
                            onTap: () => _openOrder(order),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    if (_query.trim().isEmpty &&
                        store
                            .assignedTo(employeeId)
                            .any((o) => o.status == OrderStatus.closed)) ...[
                      _section(
                        uiText(context, 'Завершено'),
                        const Color(0xFF059669),
                        onTap: () => setState(() => _page = 1),
                      ),
                      for (final order
                          in (store
                                  .assignedTo(employeeId)
                                  .where((o) => o.status == OrderStatus.closed)
                                  .toList()
                                ..sort(
                                  (a, b) =>
                                      (b.history.isEmpty
                                              ? b.createdAt
                                              : b.history.last.time)
                                          .compareTo(
                                            a.history.isEmpty
                                                ? a.createdAt
                                                : a.history.last.time,
                                          ),
                                ))
                              .take(2)) ...[
                        ExecutorHistoryTile(
                          compact: true,
                          loadTime: () =>
                              store.loadExecutorOrderTime(employeeId, order),
                          order: order,
                          now: store.now,
                          onTap: () => _openOrder(order),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _section(String title, Color color, {VoidCallback? onTap}) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF01408B),
            ),
            child: Text(
              strings(context).all,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    ),
  );
}

class _OrderTile extends StatelessWidget {
  final WorkOrder order;
  final VoidCallback onTap;
  final int? queuePosition;
  final DateTime now;
  const _OrderTile({
    required this.order,
    required this.onTap,
    this.queuePosition,
    required this.now,
  });

  String _overdueLabel(BuildContext context) {
    final seconds = now.difference(order.deadline).inSeconds;
    final totalMinutes = seconds <= 0 ? 1 : (seconds + 59) ~/ 60;
    final days = totalMinutes ~/ 1440;
    final hours = (totalMinutes % 1440) ~/ 60;
    final minutes = totalMinutes % 60;
    final kk = Localizations.localeOf(context).languageCode == 'kk';

    final parts = [
      if (days > 0) '$days ${kk ? 'күн' : 'д'}',
      if (hours > 0) '$hours ${kk ? 'сағ' : 'ч'}',
      if (minutes > 0) '$minutes мин',
    ];
    final duration = parts.join(' ');
    return kk ? 'Мерзімі $duration өтті' : 'Просрочен на $duration';
  }

  @override
  Widget build(BuildContext context) {
    final overdue = order.isOverdue(now);
    final alert = overdue || order.emergency;
    final accent = alert ? const Color(0xFFDC2626) : const Color(0xFF01408B);
    final statusColor = order.status == OrderStatus.paused
        ? const Color(0xFFB86A08)
        : order.status.color;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: alert ? const Color(0xFFFFE7EA) : const Color(0xFFE6EDF5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: overdue
                ? const Border(
                    left: BorderSide(width: 3, color: Color(0xFFDC2626)),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (order.status == OrderStatus.paused) ...[
                            Icon(
                              LucideIcons.pause,
                              size: 13,
                              color: statusColor,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Flexible(
                            child: Text(
                              executorStatusText(context, order),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      strings(context).orderNumber(order.displayNumber),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF344866),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  uiText(context, order.title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${uiText(context, order.equipment)} · ${uiText(context, order.area)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: Color(0xFF7A8597),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        uiText(context, order.priority),
                        style: TextStyle(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.calendarDays,
                          size: 14,
                          color: Color(0xFF01408B),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${dateLabel(order.deadline)} · ${timeLabel(order.deadline)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: overdue ? accent : const Color(0xFF637B9E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (queuePosition != null)
                      Text(
                        strings(context).queuePosition('$queuePosition'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF01408B),
                        ),
                      ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 7),
                  child: Divider(height: 1, color: Color(0xFFE8EDF4)),
                ),
                Row(
                  children: [
                    if (overdue) ...[
                      Icon(LucideIcons.timer, size: 15, color: accent),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          _overdueLabel(context),
                          style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Text(
                          strings(context).openOrder,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF637B9E),
                          ),
                        ),
                      ),
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
