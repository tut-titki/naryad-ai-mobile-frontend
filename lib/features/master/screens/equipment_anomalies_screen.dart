import '../widgets/master_ui.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_services.dart';
import '../../../core/api/backend_document.dart';
import '../../../l10n/ui_localization.dart';
import '../../../shared/widgets/backend_refresh_view.dart';
import '../../../shared/widgets/backend_section.dart';
import '../widgets/dashboard_data.dart';

class EquipmentAnomaliesScreen extends StatelessWidget {
  const EquipmentAnomaliesScreen({super.key, required this.api});
  final ApiServices api;

  @override
  Widget build(BuildContext context) => MasterScaffold(
    appBar: AppBar(
      title: Text(uiText(context, 'Аномалии оборудования')),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF172B4D),
      surfaceTintColor: Colors.transparent,
    ),
    body: BackendRefreshView(
      padding: const EdgeInsets.all(16),
      child: BackendSection<BackendDocument>(
        load: api.analytics.getAnomalies,
        changes: api.realtime.changes,
        builder: (context, data) => MasterSection(
          title: uiText(context, 'Аномалии оборудования'),
          icon: Icons.insights_outlined,
          child: DashboardInsights(document: data, forecast: false),
        ),
      ),
    ),
  );
}
