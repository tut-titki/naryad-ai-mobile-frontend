import '../../../core/api/api_client.dart';
import 'references_api.dart';

/// QR hosts are independent from the authenticated API host.
String equipmentQrToken(String value) {
  final content = value.trim();
  if (content.isEmpty) {
    throw const FormatException('Invalid equipment QR');
  }
  final uri = Uri.tryParse(content);
  // Equipment links still use the last segment. Other QR payloads are accepted
  // as opaque lookup values while testing with arbitrary codes.
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (segments.isNotEmpty) return segments.last;
  }
  return content;
}

class QrEquipment {
  const QrEquipment({required this.equipment, required this.area});
  final EquipmentReference equipment;
  final AreaReference area;
}

Future<QrEquipment> resolveEquipmentQr(ApiClient client, String value) async {
  final token = equipmentQrToken(value);
  final data = (await client.get(
    '/api/equipment/qr/${Uri.encodeComponent(token)}',
  )).data;
  if (data is! Map ||
      data['area'] is! Map ||
      data['id'] is! int ||
      data['name'] is! String ||
      data['area']['id'] is! int ||
      data['area']['name'] is! String) {
    throw const ApiException(
      statusCode: 502,
      message: 'Сервер вернул неверный формат оборудования',
    );
  }
  final area = AreaReference.fromJson(
    Map<String, dynamic>.from(data['area'] as Map),
  );
  return QrEquipment(
    equipment: EquipmentReference.fromJson({
      ...Map<String, dynamic>.from(data),
      'areaId': area.id,
    }),
    area: area,
  );
}
