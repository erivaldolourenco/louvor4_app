import '../../domain/entities/notifications_page_entity.dart';
import 'notification_item_model.dart';

class NotificationsPageModel extends NotificationsPageEntity {
  const NotificationsPageModel({
    required super.items,
    required super.page,
    required super.size,
    required super.totalElements,
    required super.totalPages,
    required super.first,
    required super.last,
  });

  factory NotificationsPageModel.fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List?)
            ?.map(
              (item) => NotificationItemModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList() ??
        const <NotificationItemModel>[];

    return NotificationsPageModel(
      items: items,
      page: _toInt(json['page']),
      size: _toInt(json['size']),
      totalElements: _toInt(json['totalElements']),
      totalPages: _toInt(json['totalPages']),
      first: _toBool(json['first']),
      last: _toBool(json['last']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }
}
