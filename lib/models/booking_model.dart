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
    return BookingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scheduleId: json['schedule_id'] as String,
      status: BookingStatus.fromString(json['status'] as String?),
      isPresent: json['is_present'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      schedule: json['class_schedules'] != null
          ? ClassScheduleModel.fromJson(
              json['class_schedules'] as Map<String, dynamic>)
          : null,
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
