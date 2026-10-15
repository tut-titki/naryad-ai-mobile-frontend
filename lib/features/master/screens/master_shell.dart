import '../widgets/master_ui.dart';
import '../../orders/widgets/equipment_qr_button.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_notifications_button.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:mineral/core/api/api_services.dart';

import 'package:mineral/features/auth/widgets/auth_scope.dart';

import 'package:mineral/features/master/screens/dashboard_screen.dart';
import 'package:mineral/features/master/screens/master_profile_screen.dart';
import 'package:mineral/features/assistant/screens/master_chat_screen.dart';

import 'package:mineral/features/orders/models/work_order_api_models.dart';
import 'package:mineral/features/orders/screens/order_detail_screen.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';

import 'package:mineral/l10n/ui_localization.dart';

import 'package:mineral/shared/models/models.dart';
import 'package:mineral/shared/widgets/ui.dart';
import 'package:mineral/shared/widgets/backend_refresh_view.dart';
import 'package:mineral/shared/widgets/app_navigation.dart';
import 'package:mineral/shared/widgets/app_transition_page.dart';

// MARK: - Master Shell

class MasterShell extends StatefulWidget {
  const MasterShell({super.key, required this.api});

  final ApiServices api;

  @override
  State<MasterShell> createState() => _MasterShellState();
}

class _MasterShellState extends State<MasterShell> {
  int page = 0;
  bool _ordersBoard = false;

  bool _loggingOut = false;
  final _reportsKey = GlobalKey<ReportsScreenState>();
  final _reportExporting = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _reportExporting.dispose();
    super.dispose();
  }

  Widget _exportAction(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _reportExporting,
    builder: (context, busy, _) => busy
        ? const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : PopupMenuButton<String>(
            tooltip: strings(context).exportReport,
            icon: Icon(
              LucideIcons.download,
              color: page == 0 ? brand : Colors.white,
            ),
            onSelected: (format) => _reportsKey.currentState?.export(format),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pdf',
                child: Text(strings(context).exportPdf),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Text(strings(context).exportExcel),
              ),
            ],
          ),
  );

  // MARK: - Logout

  Future<void> _logout() async {
    final session = AuthScope.maybeOf(context);

    if (session == null || _loggingOut) {
      return;
    }

    setState(() {
      _loggingOut = true;
    });

    try {
      await session.logout();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings(context).authNetworkError)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loggingOut = false;
        });
      }
    }
  }

  // MARK: - Navigation

  static const labels = ['Обзор смены', 'Наряды', 'Отчёты', 'Чат', 'Профиль'];

  // MARK: - Backend order

  Future<void> openOrder(WorkOrderApiModel order) => openOrderId(order.id);

  Future<void> openOrderId(int id) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(api: widget.api, orderId: id),
      ),
    );
    if (mounted) widget.api.realtime.invalidate();
  }
  // MARK: - Create order

  Future<void> createOrder() async {
    final created = await Navigator.push<int>(
      context,
      MaterialPageRoute<int>(
        builder: (_) => CreateOrderScreen(api: widget.api),
      ),
    );

    if (!mounted || created == null) {
      return;
    }

    widget.api.realtime.invalidate();
    // После создания переходим в реальные наряды.
    //
    // OrdersScreen при следующем создании экземпляра
    // выполнит GET /api/work-orders.
    setState(() {
      page = 1;
    });
    await openOrderId(created);
  }

  // MARK: - Notifications

  void openNotifications() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          api: widget.api,
          onOrder: openOrderId,
          standalone: true,
        ),
      ),
    );
  }

  PreferredSizeWidget _ordersTabs() => PreferredSize(
    preferredSize: const Size.fromHeight(48),
    child: DefaultTabController(
      length: 2,
      initialIndex: _ordersBoard ? 1 : 0,
      child: OrdersViewTabs(
        onChanged: (board) {
          if (_ordersBoard != board) setState(() => _ordersBoard = board);
        },
      ),
    ),
  );

  // MARK: - Build

  @override
  Widget build(BuildContext context) {
    return MasterTheme(
      child: Builder(
        builder: (context) {
          final desktop = MediaQuery.sizeOf(context).width >= 1000;

          final content = switch (page) {
            0 => DashboardScreen(api: widget.api, onOrder: openOrder),

            1 => OrdersScreen(
              api: widget.api,
              onOrder: openOrder,
              onCreate: createOrder,
              boardView: _ordersBoard,
            ),

            2 => ReportsScreen(
              key: _reportsKey,
              api: widget.api,
              onExportingChanged: (busy) {
                if (mounted) _reportExporting.value = busy;
              },
            ),

            3 => MasterChatScreen(api: widget.api),

            _ => MasterProfileScreen(
              api: widget.api,
              onLogout: _logout,
              loggingOut: _loggingOut,
            ),
          };

          return Scaffold(
            backgroundColor: page == 4 ? const Color(0xFFF5F7FB) : null,
            floatingActionButton: page == 0
                ? FloatingActionButton.extended(
                    key: const ValueKey('master-create-order-fab'),
                    heroTag: 'master-create-order',
                    onPressed: createOrder,
                    backgroundColor: const Color(0xFF01408B),
                    foregroundColor: Colors.white,
                    icon: const Icon(LucideIcons.plus, size: 20),
                    label: Text(uiText(context, 'Создать наряд')),
                  )
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            // MARK: Mobile app bar
            appBar: desktop
                ? null
                : AppBar(
                    centerTitle: false,
                    backgroundColor: page != 0
                        ? AppColors.primary
                        : Colors.white,
                    foregroundColor: page != 0
                        ? Colors.white
                        : const Color(0xFF172B4D),
                    flexibleSpace: page != 0
                        ? SizedBox.expand(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.profileHeaderGradient,
                              ),
                            ),
                          )
                        : null,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    titleSpacing: 16,
                    bottom: page == 1 ? _ordersTabs() : null,
                    systemOverlayStyle: page != 0
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark,
                    shape: page != 0
                        ? null
                        : const Border(bottom: BorderSide(color: border)),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          uiText(context, labels[page]),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: page != 0
                                ? Colors.white
                                : const Color(0xFF172B4D),
                          ),
                        ),
                        if (page == 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            uiText(
                              context,
                              'Текущие показатели и наряды смены',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      EquipmentQrButton(
                        api: widget.api,
                        color: page == 0 ? null : Colors.white,
                      ),
                      if (page == 2) _exportAction(context),
                      AppNotificationsButton(
                        onPressed: openNotifications,
                        color: page == 0 ? null : Colors.white,
                      ),
                    ],
                  ),

            // MARK: Mobile navigation
            bottomNavigationBar: desktop
                ? null
                : AppNavigation(
                    items: AppNavigationItems.master,
                    selectedIndex: page,
                    onDestinationSelected: (value) =>
                        setState(() => page = value),
                  ),

            // MARK: Main layout
            body: Row(
              children: [
                // MARK: Desktop sidebar
                if (desktop)
                  Container(
                    width: 240,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(right: BorderSide(color: border)),
                    ),
                    child: Material(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                            child: Image.asset(
                              'assets/logo_blue.png',
                              width: 192,
                              height: 96,
                              fit: BoxFit.contain,
                              semanticLabel: uiText(
                                context,
                                'Костанайские минералы',
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Text(
                              uiText(context, 'УПРАВЛЕНИЕ СМЕНОЙ'),
                              style: const TextStyle(
                                color: muted,
                                fontSize: 10,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ),

                          for (var index = 0; index < labels.length; index++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              child: ListTile(
                                selected: page == index,
                                selectedColor: brand,
                                selectedTileColor: lightBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Icon(
                                  AppNavigationItems.master[index].$1,
                                ),
                                title: Text(
                                  uiText(context, labels[index]),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    page = index;
                                  });
                                },
                              ),
                            ),

                          const Spacer(),

                          ListTile(
                            onTap: () => setState(() => page = 4),
                            leading: CircleAvatar(
                              backgroundColor: background,
                              child: Text(
                                uiText(
                                  context,
                                  AuthScope.maybeOf(context)?.user?.fullName
                                          .split(' ')
                                          .where((p) => p.isNotEmpty)
                                          .take(2)
                                          .map((p) => p[0])
                                          .join() ??
                                      '',
                                ),
                                style: const TextStyle(color: brand),
                              ),
                            ),
                            title: Text(
                              uiText(
                                context,
                                AuthScope.maybeOf(context)?.user?.fullName ??
                                    uiText(context, 'Мастер смены'),
                              ),
                            ),
                            subtitle: Text(uiText(context, 'Мастер смены')),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                // MARK: Content
                Expanded(
                  child: Column(
                    children: [
                      // MARK: Desktop header
                      if (desktop)
                        Container(
                          decoration: BoxDecoration(
                            color: (page == 4 || page == 1)
                                ? null
                                : Colors.white,
                            gradient: (page == 4 || page == 1)
                                ? AppColors.profileHeaderGradient
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      uiText(context, labels[page]),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: (page == 4 || page == 1)
                                            ? Colors.white
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      uiText(
                                        context,
                                        page == 0
                                            ? 'Текущие показатели и наряды смены'
                                            : 'Мастер смены',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: (page == 4 || page == 1)
                                            ? const Color(0xFFC8DDF5)
                                            : muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                uiText(context, dateLabel(DateTime.now())),
                                style: TextStyle(
                                  color: (page == 4 || page == 1)
                                      ? const Color(0xFFC8DDF5)
                                      : muted,
                                ),
                              ),

                              const SizedBox(width: 14),

                              if (page == 2) _exportAction(context),
                              EquipmentQrButton(
                                api: widget.api,
                                color: (page == 4 || page == 1)
                                    ? Colors.white
                                    : null,
                              ),

                              AppNotificationsButton(
                                onPressed: openNotifications,
                                color: (page == 4 || page == 1)
                                    ? Colors.white
                                    : null,
                              ),
                            ],
                          ),
                        ),

                      if (desktop && page == 1)
                        Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.profileHeaderGradient,
                          ),
                          child: _ordersTabs(),
                        ),

                      // MARK: Page
                      Expanded(
                        child: AppTransitionPage(
                          page: page,
                          child: page == 1 || page == 3
                              ? content
                              : BackendRefreshView(
                                  padding: page == 4
                                      ? EdgeInsets.zero
                                      : EdgeInsets.fromLTRB(
                                          desktop ? 28 : 16,
                                          desktop ? 28 : 16,
                                          desktop ? 28 : 16,
                                          page == 0 ? 96 : (desktop ? 28 : 16),
                                        ),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 1400,
                                      ),
                                      child: content,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
