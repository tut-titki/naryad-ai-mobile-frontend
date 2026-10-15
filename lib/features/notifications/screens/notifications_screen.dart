import '../../master/widgets/master_ui.dart';
import '../../../core/utils/enterprise_time.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_refresh_indicator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_services.dart';
import '../../auth/data/auth_session.dart' as auth;
import '../../../l10n/ui_localization.dart';
import '../../../shared/widgets/backend_section.dart';
import '../../../shared/widgets/ui.dart';
import '../data/notifications_api.dart';
import '../data/demo_notifications.dart';
import '../../../shared/models/models.dart';
import '../../executor/data/api_executor_repository.dart';
import '../../executor/data/executor_repository.dart';
import '../../executor/models/executor_order_dto.dart';
import '../../executor/screens/executor_order_loader.dart';

/// Shared notification screen with user-specific data and order navigation.
class NotificationsScreen extends StatefulWidget {
  NotificationsScreen({
    super.key,
    ApiServices? api,
    Future<List<NotificationApiModel>> Function()? load,
    Future<void> Function(int)? markRead,
    Stream<void>? changes,
    this.userId,
    this.source,
    this.snapshot,
    this.standalone = false,
    required this.onOrder,
  }) : assert(api != null || (load != null && markRead != null)),
       load = load ?? api!.notifications.getNotifications,
       markRead =
           markRead ??
           ((id) async {
             await api!.notifications.markRead(id);
           }),
       changes = changes ?? api?.realtime.changes;

  factory NotificationsScreen.forUser({
    Key? key,
    required BuildContext context,
    required ExecutorRepository repository,
    required int userId,
  }) {
    Future<void> openOrder(int id) async {
      WorkOrder? order;
      if (repository is ApiExecutorRepository) {
        final dto = await repository.api.loadOrder(id);
        if (dto.assigneeId != userId) {
          throw const auth.ApiException(403, 'Это не ваш наряд');
        }
        order = dto.toWorkOrder();
      } else {
        for (final item in repository.assignedTo(userId)) {
          if (item.number == id) {
            order = item;
            break;
          }
        }
      }
      if (!context.mounted) return;
      if (order == null) throw const auth.ApiException(404, 'Наряд не найден');
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ExecutorOrderLoader(
            store: repository,
            order: order!,
            employeeId: userId,
          ),
        ),
      );
    }

    if (repository is ApiExecutorRepository) {
      List<NotificationApiModel> snapshot() =>
          repository.notifications.map(NotificationApiModel.fromJson).toList();
      return NotificationsScreen(
        key: key,
        userId: userId,
        standalone: true,
        source: repository,
        snapshot: snapshot,
        load: () async {
          await repository.loadNotification();
          return snapshot();
        },
        markRead: repository.markNotificationRead,
        onOrder: openOrder,
      );
    }
    List<NotificationApiModel> snapshot() =>
        DemoNotifications.items(context, repository, userId);
    return NotificationsScreen(
      key: key,
      userId: userId,
      standalone: true,
      source: repository,
      snapshot: snapshot,
      load: () async => snapshot(),
      markRead: (id) => DemoNotifications.markRead(repository, id),
      onOrder: openOrder,
    );
  }

  final int? userId;
  final Future<List<NotificationApiModel>> Function() load;
  final Future<void> Function(int) markRead;
  final FutureOr<void> Function(int) onOrder;
  final Stream<void>? changes;
  final Listenable? source;
  final List<NotificationApiModel> Function()? snapshot;
  final bool standalone;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _pending = <int>{};
  final _expanded = <int>{};
  bool _readingAll = false;
  final _read = <int>{};
  final _optimisticRead = <int>{};
  List<NotificationApiModel> _items = [];
  StreamSubscription<void>? _subscription;
  int _generation = 0;
  bool _loading = true;
  Object? _error;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _items = _normalize(widget.snapshot?.call() ?? []);
    _subscribe();
    unawaited(_refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_locale != null && _locale != locale) unawaited(_refresh());
    _locale = locale;
  }

  void _subscribe() {
    _subscription = widget.changes?.listen((_) => unawaited(_refresh()));
    widget.source?.addListener(_sourceChanged);
  }

  @override
  void didUpdateWidget(NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.changes != widget.changes) {
      oldWidget.source?.removeListener(_sourceChanged);
      unawaited(_subscription?.cancel());
      _read.clear();
      _optimisticRead.clear();
      _items = [];
      _subscribe();
      unawaited(_refresh());
    }
  }

  List<NotificationApiModel> _normalize(List<NotificationApiModel> items) {
    final unique = <int, NotificationApiModel>{};
    for (final item in items) {
      if (widget.userId != null && item.userId != widget.userId) continue;
      unique[item.id] = _read.contains(item.id) ? item.asRead() : item;
    }
    final sorted = unique.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(100).toList();
  }

  void _sourceChanged() {
    final snapshot = widget.snapshot;
    if (!mounted || snapshot == null) return;
    setState(() => _items = _normalize(snapshot()));
  }

  String _errorText(Object error) => error is auth.ApiException
      ? uiText(context, error.message)
      : backendError(context, error);

  Future<void> _refresh() async {
    if (!mounted) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.load();
      if (mounted && generation == _generation) {
        setState(() => _items = _normalize(widget.snapshot?.call() ?? items));
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _readAll() async {
    if (_readingAll || _pending.isNotEmpty) return;
    final unread = _items.where((item) => !item.isRead).toList();
    if (unread.isEmpty) return;
    setState(() {
      _readingAll = true;
      _optimisticRead.addAll(unread.map((item) => item.id));
    });
    Object? failure;
    try {
      for (final item in unread) {
        try {
          await widget.markRead(item.id);
          if (!mounted) return;
          _read.add(item.id);
          setState(() {
            _optimisticRead.remove(item.id);
            _items = _normalize(_items);
          });
        } catch (error) {
          failure = error;
          if (mounted) setState(() => _optimisticRead.remove(item.id));
        }
      }
      if (!mounted) return;
      await _refresh();
      if (mounted && failure != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(failure))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _readingAll = false;
          _optimisticRead.removeAll(unread.map((item) => item.id));
        });
      }
    }
  }

  Future<void> _open(NotificationApiModel item) async {
    if (_readingAll || _pending.contains(item.id)) return;
    setState(() => _pending.add(item.id));
    try {
      if (!item.isRead) {
        try {
          await widget.markRead(item.id);
          if (!mounted) return;
          _read.add(item.id);
          setState(() => _items = _normalize(_items));
          await _refresh();
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_errorText(error))));
          }
        }
      }
      if (mounted && item.workOrderId != null) {
        await widget.onOrder(item.workOrderId!);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _pending.remove(item.id));
    }
  }

  IconData _icon(NotificationApiModel item) {
    if (item.isOverdue) return Icons.warning_amber_rounded;
    return switch (item.type) {
      'NEW_ORDER' => Icons.assignment_outlined,
      'BRIGADE_ORDER' => Icons.groups_outlined,
      'DEADLINE_REMINDER' => Icons.timer_outlined,
      'NOT_ACCEPTED' => Icons.hourglass_empty,
      'WEEKLY_AI_SUMMARY' => Icons.auto_awesome_outlined,
      _ => LucideIcons.bell,
    };
  }

  Widget _tile(NotificationApiModel item) {
    final isRead = item.isRead || _optimisticRead.contains(item.id);
    final color = item.isOverdue ? const Color(0xFFDC2626) : brand;
    final busy = _pending.contains(item.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFDCE4EE)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy || _readingAll ? null : () => _open(item),
          child: Padding(
            padding: EdgeInsets.all(widget.source == null ? 14 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: item.isOverdue
                        ? const Color(0xFFFFF1F0)
                        : const Color(0xFFEAF3FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_icon(item), color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: const Color(0xFF172033),
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                      if (item.message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() {
                            if (!_expanded.add(item.id)) {
                              _expanded.remove(item.id);
                            }
                          }),
                          child: Text(
                            item.message,
                            maxLines: _expanded.contains(item.id) ? null : 2,
                            overflow: _expanded.contains(item.id)
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7A8597),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        DateFormat(
                          'dd.MM.yyyy HH:mm',
                        ).format(enterpriseTime(item.createdAt)),
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    if (!isRead)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 5, bottom: 8),
                        decoration: const BoxDecoration(
                          color: brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (item.workOrderId != null)
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Color(0xFF7A8597),
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

  Widget _readAllButton() => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Tooltip(
      message: backendText(
        context,
        'Прочитать все',
        'Барлығын оқылған деп белгілеу',
      ),
      child: TextButton.icon(
        onPressed:
            _readingAll ||
                _loading ||
                _pending.isNotEmpty ||
                !_items.any((item) => !item.isRead)
            ? null
            : _readAll,
        style: TextButton.styleFrom(
          foregroundColor: brand,
          backgroundColor: const Color(0xFFEAF3FC),
          disabledForegroundColor: const Color(0xFF7A8597),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.done_all_rounded, size: 18),
        label: Text(
          backendText(context, 'Прочитать все', 'Барлығын оқу'),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.standalone)
          PageHeading(
            'Центр уведомлений',
            action: _readAllButton(),
            subtitle: backendText(
              context,
              'Последние уведомления смены',
              'Ауысымның соңғы хабарландырулары',
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BackendError(
              message: _errorText(_error!),
              onRetry: _refresh,
            ),
          ),
        if (!_loading && _error == null && _items.isEmpty)
          Panel(child: Text(uiText(context, 'Новых уведомлений нет'))),
        for (final item in _items) _tile(item),
      ],
    );
    if (!widget.standalone) return content;
    return MasterScaffold(
      enabled: widget.source == null,
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(
          uiText(context, 'Уведомления'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titleSpacing: 0,
        actions: [_readAllButton()],
      ),
      body: AppRefreshIndicator(
        onRefresh: _refresh,
        isLoading: _loading && _items.isEmpty,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [content],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.source?.removeListener(_sourceChanged);
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
