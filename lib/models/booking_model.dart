import 'enums.dart';
import 'class_schedule_model.dart';

/// Reserva de un usuario para una sesión específica
class BookingModel {
  final String id;
  final String userId;
  final String scheduleId;
  final BookingStatus status;
  final bool isPresent;
  final DateTime createdAt;

  // Sesión asociada
  final ClassScheduleModel? schedule;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.scheduleId,
    this.status = BookingStatus.confirmed,
    this.isPresent = false,
    required this.createdAt,
    this.schedule,
  });

  BookingModel copyWith({
    String? id,
    String? userId,
    String? scheduleId,
    BookingStatus? status,
    bool? isPresent,
    DateTime? createdAt,
    ClassScheduleModel? schedule,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduleId: scheduleId ?? this.scheduleId,
      status: status ?? this.status,
      isPresent: isPresent ?? this.isPresent,
      createdAt: createdAt ?? this.createdAt,
      schedule: schedule ?? this.schedule,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    ClassScheduleModel? parsedSchedule;
    final rawSchedule = json['class_schedules'];
    if (rawSchedule != null) {
      if (rawSchedule is Map) {
        parsedSchedule = ClassScheduleModel.fromJson(
          Map<String, dynamic>.from(rawSchedule),
        );
      } else if (rawSchedule is List && rawSchedule.isNotEmpty) {
        final first = rawSchedule.first;
        if (first is Map) {
          parsedSchedule = ClassScheduleModel.fromJson(
            Map<String, dynamic>.from(first),
          );
        }
      }
    }

    return BookingModel(
      id: json['id'] as String? ?? 'booking-${DateTime.now().millisecondsSinceEpoch}',
      userId: json['user_id'] as String? ?? '',
      scheduleId: json['schedule_id'] as String? ?? '',
      status: BookingStatus.fromString(json['status'] as String?),
      isPresent: json['is_present'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      schedule: parsedSchedule,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'schedule_id': scheduleId,
      'status': status.toDbString(),
      'is_present': isPresent,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
