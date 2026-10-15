import '../widgets/master_ui.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_services.dart';
import '../../../core/api/backend_document.dart';
import '../../analytics/data/analytics_api.dart';
import '../../orders/data/references_api.dart';
import '../../orders/models/work_order_api_models.dart';
import '../../orders/screens/orders_screen.dart';
import '../../../l10n/ui_localization.dart';
import '../../../shared/widgets/backend_section.dart';
import '../widgets/dashboard_data.dart';
import 'equipment_anomalies_screen.dart';
import 'equipment_failure_forecast_screen.dart';

export '../../orders/screens/orders_screen.dart';
export '../../team/screens/team_screen.dart';
export '../../assistant/screens/ai_screen.dart';
export '../../notifications/screens/notifications_screen.dart';
export '../../reports/screens/reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.api, required this.onOrder});

  final ApiServices api;
  final ValueChanged<WorkOrderApiModel> onOrder;

  static const _blue = Color(0xFF01408B);
  static const _ink = Color(0xFF172B4D);
  static const _muted = Color(0xFF637B9E);
  static const _background = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _shiftCounters(),
          const SizedBox(height: 12),

          _sectionTitle(context, 'Требуют внимания', LucideIcons.alertTriangle),
          const SizedBox(height: 12),

          BackendSection<List<WorkOrderApiModel>>(
            load: api.workOrders.getAllWorkOrders,
            changes: api.realtime.changes,
            builder: (context, orders) {
              final urgent =
                  orders
                      .where(
                        (order) =>
                            order.isOverdue ||
                            order.waitingForMasterReview ||
                            (order.isEmergency &&
                                order.status == WorkOrderStatus.issued),
                      )
                      .toList()
                    ..sort(compareAttentionOrders);

              if (urgent.isEmpty) {
                return _emptySection(
                  LucideIcons.badgeCheck,
                  uiText(context, 'Нет нарядов, требующих внимания'),
                );
              }

              return Column(
                children: [
                  for (final order in urgent.take(3)) ...[
                    ApiOrderCard(order: order, onTap: () => onOrder(order)),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          _sectionTitle(context, 'Команда на смене', LucideIcons.users),
          const SizedBox(height: 12),

          BackendSection<List<ExecutorReference>>(
            load: api.references.getExecutors,
            changes: api.realtime.changes,
            builder: (context, employees) {
              final shift = employees
                  .where((employee) => employee.isOnShift)
                  .toList();

              if (shift.isEmpty) {
                return _emptySection(
                  LucideIcons.users,
                  backendText(
                    context,
                    'На смене нет исполнителей',
                    'Ауысымда орындаушылар жоқ',
                  ),
                );
              }

              return _surface(
                padding: const EdgeInsets.all(12),
                child: ShiftTeamList(executors: shift),
              );
            },
          ),

          const SizedBox(height: 20),
          _sectionTitle(
            context,
            'Аналитика смены',
            LucideIcons.chartNoAxesCombined,
          ),
          const SizedBox(height: 12),

          BackendSection<DashboardAnalytics>(
            load: api.analytics.getDashboard,
            changes: api.realtime.changes,
            builder: (context, data) => LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;

                final equipment = _surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _innerHeading(
                        uiText(context, 'Частые отказы'),
                        LucideIcons.wrench,
                      ),
                      const SizedBox(height: 14),
                      EquipmentFailuresList(document: data.topEquipment),
                    ],
                  ),
                );

                final executors = _surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _innerHeading(
                        uiText(context, 'Рейтинг исполнителей'),
                        LucideIcons.award,
                      ),
                      const SizedBox(height: 14),
                      ExecutorRankingList(document: data.topExecutors),
                    ],
                  ),
                );

                if (compact) {
                  return Column(
                    children: [
                      equipment,
                      const SizedBox(height: 12),
                      executors,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: equipment),
                    const SizedBox(width: 14),
                    Expanded(child: executors),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          _sectionTitle(context, 'Прогноз и мониторинг', LucideIcons.activity),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final forecast = _analyticsPanel(
                context,
                backendText(
                  context,
                  'Прогноз отказов · 30 дней',
                  'Ақаулар болжамы · 30 күн',
                ),
                LucideIcons.calendarDays,
                () => api.analytics.getFailureForecast(),
                forecast: true,
              );

              final anomalies = _analyticsPanel(
                context,
                uiText(context, 'Аномалии оборудования'),
                LucideIcons.alertTriangle,
                api.analytics.getAnomalies,
              );

              if (constraints.maxWidth < 680) {
                return Column(
                  children: [forecast, const SizedBox(height: 12), anomalies],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: forecast),
                  const SizedBox(width: 14),
                  Expanded(child: anomalies),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _shiftCounters() => BackendSection<WorkOrderBoard>(
    load: api.workOrders.getBoard,
    changes: api.realtime.changes,
    refreshInterval: const Duration(seconds: 1),
    builder: (context, board) => ShiftCounters(counters: board.counters),
  );
  Widget _analyticsPanel(
    BuildContext context,
    String title,
    IconData icon,
    Future<BackendDocument> Function() load, {
    bool forecast = false,
  }) {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _innerHeading(title, icon),
          const SizedBox(height: 14),
          BackendSection<BackendDocument>(
            load: load,
            changes: api.realtime.changes,
            builder: (context, data) => DashboardInsights(
              document: data,
              forecast: forecast,
              maxItems: 5,
            ),
          ),
          ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => forecast
                        ? EquipmentFailureForecastScreen(api: api)
                        : EquipmentAnomaliesScreen(api: api),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(
                  forecast
                      ? backendText(context, 'Весь прогноз', 'Толық болжам')
                      : backendText(
                          context,
                          'Все аномалии',
                          'Барлық аномалиялар',
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 19, color: _blue),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            uiText(context, title),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _innerHeading(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _blue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _surface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) => MasterSurface(padding: padding, child: child);

  Widget _emptySection(IconData icon, String message) {
    return _surface(
      child: Row(
        children: [
          Icon(icon, color: _muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
