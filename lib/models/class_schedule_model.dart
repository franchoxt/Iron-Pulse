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

  /// Indica si la sesión ya finalizó (su horario ha pasado)
  bool get isPast {
    return DateTime.now().isAfter(endTime);
  }

  /// Indica si la clase ya comenzó
  bool get hasStarted {
    return DateTime.now().isAfter(startTime);
  }

  /// Nombre de la clase asociada
  String get className => gymClass?.name ?? 'Clase';

  /// Nombre del instructor asignado
  String get instructorName => instructor?.name ?? 'Instructor';

  /// Rango de horario formateado (HH:MM - HH:MM)
  String get timeRangeStr {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMin = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMin = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMin - $endHour:$endMin';
  }

  ClassScheduleModel copyWith({
    String? id,
    String? classId,
    String? instructorId,
    DateTime? startTime,
    DateTime? endTime,
    int? capacity,
    String? locationName,
    bool? isLive,
    GymClassModel? gymClass,
    InstructorModel? instructor,
    int? confirmedBookingsCount,
  }) {
    return ClassScheduleModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      instructorId: instructorId ?? this.instructorId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      capacity: capacity ?? this.capacity,
      locationName: locationName ?? this.locationName,
      isLive: isLive ?? this.isLive,
      gymClass: gymClass ?? this.gymClass,
      instructor: instructor ?? this.instructor,
      confirmedBookingsCount:
          confirmedBookingsCount ?? this.confirmedBookingsCount,
    );
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

    GymClassModel? parsedGymClass;
    final rawClass = json['classes'];
    if (rawClass != null) {
      if (rawClass is Map) {
        parsedGymClass = GymClassModel.fromJson(Map<String, dynamic>.from(rawClass));
      } else if (rawClass is List && rawClass.isNotEmpty) {
        final first = rawClass.first;
        if (first is Map) {
          parsedGymClass = GymClassModel.fromJson(Map<String, dynamic>.from(first));
        }
      }
    }

    InstructorModel? parsedInstructor;
    final rawInstructor = json['instructors'];
    if (rawInstructor != null) {
      if (rawInstructor is Map) {
        parsedInstructor = InstructorModel.fromJson(Map<String, dynamic>.from(rawInstructor));
      } else if (rawInstructor is List && rawInstructor.isNotEmpty) {
        final first = rawInstructor.first;
        if (first is Map) {
          parsedInstructor = InstructorModel.fromJson(Map<String, dynamic>.from(first));
        }
      }
    }

    return ClassScheduleModel(
      id: json['id'] as String? ?? 'sched-${DateTime.now().millisecondsSinceEpoch}',
      classId: json['class_id'] as String? ?? '',
      instructorId: json['instructor_id'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String).toLocal()
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String).toLocal()
          : DateTime.now().add(const Duration(minutes: 60)),
      capacity: json['capacity'] as int? ?? 20,
      locationName: json['location_name'] as String?,
      isLive: json['is_live'] as bool? ?? false,
      gymClass: parsedGymClass,
      instructor: parsedInstructor,
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
