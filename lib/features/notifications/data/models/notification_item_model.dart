import '../../domain/entities/notification_item_entity.dart';
import '../../domain/entities/notification_type.dart';

class NotificationItemModel extends NotificationItemEntity {
  const NotificationItemModel({
    required super.id,
    required super.type,
    required super.userId,
    required super.title,
    required super.message,
    required super.eventParticipantId,
    required super.dataJson,
    required super.isRead,
    required super.createdAt,
    required super.readAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: _readString(json['id']),
      type: notificationTypeFromString(json['type']?.toString()),
      userId: _readString(json['userId']),
      title: _readString(json['title']),
      message: _readString(json['message']),
      eventParticipantId: _normalizeOptionalValue(json['eventParticipantId']),
      dataJson: _normalizeOptionalValue(json['dataJson']),
      isRead: _parseBool(json['isRead']),
      createdAt: _parseDate(json['createdAt']),
      readAt: _parseNullableDate(json['readAt']),
    );
  }

  static String _readString(dynamic value) {
    return _normalizeOptionalValue(value) ?? '';
  }

  static String? _normalizeOptionalValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  static DateTime _parseDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed ?? DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    final raw = _normalizeOptionalValue(value);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
