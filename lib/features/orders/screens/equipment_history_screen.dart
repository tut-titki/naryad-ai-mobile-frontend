import '../../master/widgets/master_ui.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_services.dart';
import '../../../core/api/backend_document.dart';
import '../../../shared/widgets/backend_section.dart';
import '../../../shared/widgets/backend_refresh_view.dart';
import '../../../shared/widgets/ui.dart';
import 'order_detail_screen.dart';

class EquipmentHistoryScreen extends StatelessWidget {
  const EquipmentHistoryScreen({
    super.key,
    required this.api,
    required this.equipmentId,
  });
  final ApiServices api;
  final int equipmentId;
  @override
  Widget build(BuildContext context) => MasterScaffold(
    appBar: AppBar(
      title: Text(
        backendText(context, 'История оборудования', 'Жабдық тарихы'),
      ),
    ),
    body: BackendRefreshView(
      padding: const EdgeInsets.all(16),
      child: BackendSection<BackendDocument>(
        load: () async => BackendDocument.fromJson(
          (await api.client.get('/api/equipment/$equipmentId/history')).data,
        ),
        changes: api.realtime.changes,
        builder: (context, data) {
          if (data.value == null) {
            return Text(
              backendText(
                context,
                'Оборудование не найдено',
                'Жабдық табылмады',
              ),
            );
          }
          if (data.value is! Map) return BackendDocumentView(document: data);
          final equipment = data.value as Map;
          final orders = equipment['orders'] is List
              ? equipment['orders'] as List
              : const [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeading('${equipment['name'] ?? '—'}'),
              if (equipment['inventoryNumber'] != null)
                Text('${equipment['inventoryNumber']}'),
              if (equipment['area'] is Map)
                Text('${equipment['area']['name'] ?? '—'}'),
              const SizedBox(height: 20),
              if (orders.isEmpty)
                Text(
                  backendText(
                    context,
                    'История ремонтов пуста',
                    'Жөндеу тарихы бос',
                  ),
                ),
              for (final order in orders.whereType<Map>())
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MasterSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${order['number'] ?? '—'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        BackendDocumentView(
                          document: BackendDocument.fromJson({
                            for (final key in [
                              'description',
                              'status',
                              'createdAt',
                              'completedAt',
                              'closedAt',
                              'faultCode',
                              'completionText',
                              'aiAssessment',
                              'actualDowntimeMinutes',
                              'downtime',
                              'materialUsages',
                            ])
                              if (order[key] != null) key: order[key],
                          }),
                        ),
                        if (order['id'] is int)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.assignment_outlined),
                              label: Text(
                                backendText(
                                  context,
                                  'Открыть наряд',
                                  'Нарядты ашу',
                                ),
                              ),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => OrderDetailScreen(
                                    api: api,
                                    orderId: order['id'] as int,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
