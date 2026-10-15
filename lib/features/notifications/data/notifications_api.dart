import '../../../core/api/api_client.dart';

class NotificationApiModel {
  const NotificationApiModel({
    required this.id,
    required this.userId,
    this.workOrderId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });
  NotificationApiModel.fromJson(Map<String, dynamic> json)
    : id = (json['id'] as num).toInt(),
      userId = (json['userId'] as num).toInt(),
      workOrderId = (json['workOrderId'] as num?)?.toInt(),
      type = json['type'] as String,
      title = json['title'] as String,
      message = json['message'] as String? ?? '',
      isRead = json['isRead'] as bool,
      createdAt = DateTime.parse(json['createdAt'] as String);
  final int id, userId;
  final int? workOrderId;
  final String type, title, message;
  final bool isRead;
  final DateTime createdAt;
  NotificationApiModel asRead() => NotificationApiModel(
    id: id,
    userId: userId,
    workOrderId: workOrderId,
    type: type,
    title: title,
    message: message,
    isRead: true,
    createdAt: createdAt,
  );
  bool get isOverdue =>
      type.startsWith('OVERDUE') || type.startsWith('LONG_OVERDUE');

  String get overdueCategory => type.replaceFirst(RegExp(r'_\d+$'), '');
}

class NotificationsApi {
  const NotificationsApi(this._client);
  final ApiClient _client;

  Future<List<NotificationApiModel>> getNotifications() async {
    final response = await _client.get('/api/notifications');
    if (response.data is! List) {
      throw const ApiException(
        statusCode: 502,
        message: 'Сервер вернул неверный формат уведомлений',
      );
    }
    final items = (response.data as List)
        .map(
          (item) => NotificationApiModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(100).toList();
  }

  Future<int> markRead(int id) async {
    final response = await _client.patch('/api/notifications/$id/read');
    if (response.data is! Map ||
        response.data['updated'] is! int ||
        response.data['updated'] != 1) {
      throw const ApiException(
        statusCode: 502,
        message: 'Сервер не подтвердил прочтение уведомления',
      );
    }
    return (response.data['updated'] as num).toInt();
  }
}
