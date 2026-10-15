import '../widgets/master_ui.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_services.dart';
import '../../../core/api/backend_document.dart';
import '../../../shared/widgets/backend_refresh_view.dart';
import '../../../shared/widgets/backend_section.dart';
import '../widgets/dashboard_data.dart';

class EquipmentFailureForecastScreen extends StatelessWidget {
  const EquipmentFailureForecastScreen({super.key, required this.api});
  final ApiServices api;

  @override
  Widget build(BuildContext context) => MasterScaffold(
    appBar: AppBar(
      title: Text(
        backendText(
          context,
          'Прогноз отказов · 30 дней',
          'Ақаулар болжамы · 30 күн',
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF172B4D),
      surfaceTintColor: Colors.transparent,
    ),
    body: BackendRefreshView(
      padding: const EdgeInsets.all(16),
      child: BackendSection<BackendDocument>(
        load: () => api.analytics.getFailureForecast(),
        changes: api.realtime.changes,
        builder: (context, data) => MasterSection(
          title: backendText(
            context,
            'Прогноз отказов · 30 дней',
            'Ақаулар болжамы · 30 күн',
          ),
          icon: Icons.query_stats,
          child: DashboardInsights(document: data, forecast: true),
        ),
      ),
    ),
  );
}
