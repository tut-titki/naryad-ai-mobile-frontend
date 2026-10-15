import 'package:mineral/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_scope.dart';
import '../../../core/api/api_services.dart';
import '../../../core/services/photo_picker_service.dart';
import '../../../shared/widgets/backend_section.dart';
import '../../../l10n/ui_localization.dart';
import '../../references/data/reference_storage.dart';
import '../../auth/widgets/auth_scope.dart';
import '../data/equipment_qr_api.dart';
import '../screens/equipment_qr_scanner.dart';
import '../screens/equipment_history_screen.dart';
import '../screens/order_screens.dart';

class EquipmentQrButton extends StatelessWidget {
  const EquipmentQrButton({super.key, this.api, this.color});
  final ApiServices? api;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    if (AuthScope.maybeOf(context)?.user?.role != 'MASTER') {
      return const SizedBox.shrink();
    }
    final services = api ?? ApiScope.maybeOf(context);
    if (services == null) return const SizedBox.shrink();
    return IconButton(
      key: const ValueKey('scan-equipment-qr'),
      tooltip: backendText(
        context,
        'Сканировать QR оборудования',
        'Жабдық QR кодын сканерлеу',
      ),
      color: color,
      icon: const Icon(Icons.qr_code_scanner),
      onPressed: () => scanEquipmentQr(context, services),
    );
  }
}

Future<void> scanEquipmentQr(BuildContext context, ApiServices api) async {
  if (AuthScope.maybeOf(context)?.user?.role != 'MASTER') return;
  final value = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => const EquipmentQrScanner()),
  );
  if (!context.mounted || value == null) return;
  await showEquipmentQrSheet(context, api, value);
}

Future<void> showEquipmentQrSheet(
  BuildContext context,
  ApiServices api,
  String value, {
  PhotoPickerService? photoPicker,
  ReferenceStorage? draftStorage,
}) async {
  if (AuthScope.maybeOf(context)?.user?.role != 'MASTER') return;
  final equipment = await showAppBottomSheet<QrEquipment>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _EquipmentQrSheet(api: api, value: value),
  );
  if (!context.mounted || equipment == null) return;
  final created = await Navigator.push<int>(
    context,
    MaterialPageRoute(
      builder: (_) => CreateOrderScreen(
        api: api,
        photoPicker: photoPicker,
        draftStorage: draftStorage,
        initialEquipment: equipment.equipment,
        initialArea: equipment.area,
        lockEquipment: true,
      ),
    ),
  );
  if (created != null) api.realtime.invalidate();
}

class _EquipmentQrSheet extends StatefulWidget {
  const _EquipmentQrSheet({required this.api, required this.value});
  final ApiServices api;
  final String value;
  @override
  State<_EquipmentQrSheet> createState() => _EquipmentQrSheetState();
}

class _EquipmentQrSheetState extends State<_EquipmentQrSheet> {
  QrEquipment? _equipment;
  Object? _error;
  bool _loading = true;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await resolveEquipmentQr(widget.api.client, widget.value);
      if (mounted) setState(() => _equipment = result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveQr() async {
    setState(() => _saving = true);
    try {
      final id = _equipment!.equipment.id;
      final bytes = await widget.api.client.getBytes(
        '/api/equipment/$id/qr.png',
      );
      await FileSaver.instance.saveAs(
        name: 'equipment-$id-qr',
        bytes: bytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(backendError(context, error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null) ...[
            Text(
              _error is FormatException ||
                      (_error is ApiException &&
                          (_error as ApiException).statusCode == 404)
                  ? backendText(
                      context,
                      'Оборудование по этому QR не найдено',
                      'Бұл QR бойынша жабдық табылмады',
                    )
                  : backendError(context, _error!),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: Text(backendText(context, 'Повторить', 'Қайталау')),
            ),
          ] else if (_equipment != null) ...[
            const Icon(Icons.precision_manufacturing_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              uiText(context, _equipment!.equipment.name),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${backendText(context, 'Участок', 'Учаске')}: ${uiText(context, _equipment!.area.name)}',
            ),
            if (_equipment!.equipment.inventoryNumber != null)
              Text(_equipment!.equipment.inventoryNumber!),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('qr-create-order'),
              onPressed: () => Navigator.pop(context, _equipment),
              icon: const Icon(Icons.add),
              label: Text(backendText(context, 'Выдать наряд', 'Наряд беру')),
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EquipmentHistoryScreen(
                    api: widget.api,
                    equipmentId: _equipment!.equipment.id,
                  ),
                ),
              ),
              icon: const Icon(Icons.history),
              label: Text(
                backendText(context, 'История оборудования', 'Жабдық тарихы'),
              ),
            ),
            TextButton.icon(
              onPressed: _saving ? null : _saveQr,
              icon: const Icon(Icons.download),
              label: Text(
                backendText(
                  context,
                  'Скачать QR для печати',
                  'Басып шығару үшін QR жүктеу',
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
