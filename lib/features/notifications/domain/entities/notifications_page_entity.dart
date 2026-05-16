import 'package:equatable/equatable.dart';

import 'notification_item_entity.dart';

class NotificationsPageEntity extends Equatable {
  final List<NotificationItemEntity> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  const NotificationsPageEntity({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  @override
  List<Object?> get props => [
    items,
    page,
    size,
    totalElements,
    totalPages,
    first,
    last,
  ];
}
