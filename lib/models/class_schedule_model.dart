import 'gym_class_model.dart';
import 'instructor_model.dart';

/// Instancia / Horario específico de una clase
class ClassScheduleModel {
  final String id;
  final String classId;
  final String? instructorId;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final String? locationName;
  final bool isLive;

  // Relaciones cargadas
  final GymClassModel? gymClass;
  final InstructorModel? instructor;
  final int confirmedBookingsCount;

  const ClassScheduleModel({
    required this.id,
    required this.classId,
    this.instructorId,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.locationName,
    this.isLive = false,
    this.gymClass,
    this.instructor,
    this.confirmedBookingsCount = 0,
  });

  /// Cupos disponibles calculados en tiempo real: capacity - bookings confirmados
  int get availableSpots {
    final spots = capacity - confirmedBookingsCount;
    return spots > 0 ? spots : 0;
  }

  /// Indica si la sesión está llena y pasa a lista de espera
  bool get isFull => availableSpots <= 0;

  /// Indica si la sesión está ocurriendo en este momento
  bool get happeningNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  factory ClassScheduleModel.fromJson(Map<String, dynamic> json) {
    // Cálculo de bookings confirmados si vienen agregados
    int bookingsCount = 0;
    if (json['bookings'] is List) {
      final list = json['bookings'] as List;
      bookingsCount = list.where((b) => b['status'] == 'confirmed').length;
    } else if (json['bookings_count'] != null) {
      bookingsCount = (json['bookings_count'] as num).toInt();
    }

    return ClassScheduleModel(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      instructorId: json['instructor_id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      capacity: json['capacity'] as int? ?? 20,
      locationName: json['location_name'] as String?,
      isLive: json['is_live'] as bool? ?? false,
      gymClass: json['classes'] != null
          ? GymClassModel.fromJson(json['classes'] as Map<String, dynamic>)
          : null,
      instructor: json['instructors'] != null
          ? InstructorModel.fromJson(json['instructors'] as Map<String, dynamic>)
          : null,
      confirmedBookingsCount: bookingsCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'instructor_id': instructorId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'capacity': capacity,
      'location_name': locationName,
      'is_live': isLive,
    };
  }
}
