import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

/// Servicio central de datos para IRON PULSE
/// Conecta las 7 tablas de Supabase con fallback local si las tablas aún no están creadas.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  SupabaseClient? get _client {
    if (SupabaseConfig.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ===========================================================================
  // 1. CATEGORÍAS
  // ===========================================================================
  Future<List<CategoryModel>> getCategories() async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('categories')
            .select()
            .order('name', ascending: true);
        return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Aviso: usando categorías demo ($e)');
      }
    }
    return _demoCategories;
  }

  // ===========================================================================
  // 2. HORARIOS Y SESIONES (Con cálculo de cupos en tiempo real)
  // ===========================================================================
  Future<List<ClassScheduleModel>> getSchedules({String? categoryId}) async {
    final client = _client;
    if (client != null) {
      try {
        var query = client.from('class_schedules').select('''
          id,
          class_id,
          instructor_id,
          start_time,
          end_time,
          capacity,
          location_name,
          is_live,
          classes:class_id (
            id,
            name,
            description,
            image_url,
            category_id,
            intensity,
            duration_minutes,
            base_price,
            categories:category_id ( id, name, icon_url )
          ),
          instructors:instructor_id (
            id,
            name,
            avatar_url,
            bio,
            rating
          ),
          bookings (
            id,
            status
          )
        ''');

        final data = await query.order('start_time', ascending: true);
        final list = (data as List)
            .map((e) => ClassScheduleModel.fromJson(e))
            .toList();

        if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
          return list
              .where((s) => s.gymClass?.categoryId == categoryId)
              .toList();
        }
        return list;
      } catch (e) {
        debugPrint('Aviso: usando horarios demo ($e)');
      }
    }

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      return _demoSchedules
          .where((s) => s.gymClass?.categoryId == categoryId)
          .toList();
    }
    return _demoSchedules;
  }

  // ===========================================================================
  // 3. RESERVAS (Bookings & Check-in)
  // ===========================================================================
  Future<BookingModel> bookClass({required String scheduleId}) async {
    final client = _client;
    final user = AuthService.instance.currentUser;

    // Sanitizar ID: Si no es un UUID válido (ej. viene de mocks como feat_1), mapearlo a uno real
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    String validScheduleId = scheduleId;
    if (!uuidRegex.hasMatch(scheduleId)) {
      if (scheduleId.contains('2')) {
        validScheduleId = '22222222-2222-2222-2222-222222222222';
      } else if (scheduleId.contains('3')) {
        validScheduleId = '33333333-3333-3333-3333-333333333333';
      } else {
        validScheduleId = '11111111-1111-1111-1111-111111111111';
      }
    }

    if (client != null && user != null) {
      try {
        // 1. Verificar cupos actuales
        final existingBookings = await client
            .from('bookings')
            .select('id, status')
            .eq('schedule_id', validScheduleId)
            .eq('status', 'confirmed');

        final scheduleData = await client
            .from('class_schedules')
            .select('capacity')
            .eq('id', validScheduleId)
            .single();

        final capacity = scheduleData['capacity'] as int? ?? 15;
        final confirmedCount = (existingBookings as List).length;

        // Si no hay cupos disponibles, pasa a waitlist (Lista de espera)
        final status = confirmedCount >= capacity
            ? BookingStatus.waitlist
            : BookingStatus.confirmed;

        final inserted = await client
            .from('bookings')
            .insert({
              'user_id': user.id,
              'schedule_id': validScheduleId,
              'status': status.toDbString(),
              'is_present': false,
            })
            .select('''
              id,
              user_id,
              schedule_id,
              status,
              is_present,
              created_at,
              class_schedules (
                id,
                class_id,
                instructor_id,
                start_time,
                end_time,
                capacity,
                location_name,
                is_live,
                classes ( id, name, description, image_url, intensity, duration_minutes, base_price )
              )
            ''')
            .single();

        return BookingModel.fromJson(inserted);
      } catch (e) {
        debugPrint('Error en reserva remota: $e');
        rethrow;
      }
    }

    // Modo local / demo
    return BookingModel(
      id: 'demo-booking-${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id ?? 'demo-user',
      scheduleId: validScheduleId,
      status: BookingStatus.confirmed,
      isPresent: false,
      createdAt: DateTime.now(),
    );
  }

  /// Cancelar una reserva
  Future<void> cancelBooking(String bookingOrScheduleId) async {
    final client = _client;
    final user = AuthService.instance.currentUser;
    if (client != null && user != null) {
      try {
        final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
        String targetId = bookingOrScheduleId;
        if (!uuidRegex.hasMatch(targetId)) {
          if (targetId.contains('2')) {
            targetId = '22222222-2222-2222-2222-222222222222';
          } else if (targetId.contains('3')) {
            targetId = '33333333-3333-3333-3333-333333333333';
          } else {
            targetId = '11111111-1111-1111-1111-111111111111';
          }
        }
        await client
            .from('bookings')
            .delete()
            .or('id.eq.$targetId,schedule_id.eq.$targetId')
            .eq('user_id', user.id);
      } catch (_) {}
    }
  }

  /// Check-in de estudiantes (Gestión de presencia por el Admin o Instructor)
  Future<void> checkInStudent({
    required String bookingId,
    required bool isPresent,
  }) async {
    final client = _client;
    if (client != null) {
      await client
          .from('bookings')
          .update({'is_present': isPresent})
          .eq('id', bookingId);
    }
  }

  // ===========================================================================
  // 4. PERFIL DE USUARIO
  // ===========================================================================
  Future<UserProfileModel?> getCurrentProfile() async {
    final client = _client;
    final user = AuthService.instance.currentUser;
    if (client != null && user != null) {
      try {
        final data = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          return UserProfileModel.fromJson(data);
        }
      } catch (e) {
        debugPrint('Error obteniendo perfil: $e');
      }
    }
    return null;
  }

  /// Asegura la existencia del perfil en la tabla 'profiles' con su respectivo rol.
  /// Por defecto se le asigna automáticamente el rol de cliente (UserRole.client).
  Future<UserProfileModel?> ensureUserProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    UserRole role = UserRole.client,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final existing = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (existing != null) {
          return UserProfileModel.fromJson(existing);
        }

        final inserted = await client
            .from('profiles')
            .insert({
              'id': userId,
              if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
              if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
              'role': role.toDbString(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .select()
            .single();

        return UserProfileModel.fromJson(inserted);
      } catch (e) {
        debugPrint('Aviso al asegurar perfil en Supabase: $e');
      }
    }
    return null;
  }

  // ===========================================================================
  // 5. ESTADÍSTICAS DEL PORTAL ADMIN (Occupancy Rate & Happening Now)
  // ===========================================================================
  Future<Map<String, dynamic>> getAdminStats() async {
    final schedules = await getSchedules();
    int totalCapacity = 0;
    int totalConfirmed = 0;
    int liveNowCount = 0;

    for (var s in schedules) {
      totalCapacity += s.capacity;
      totalConfirmed += s.confirmedBookingsCount;
      if (s.happeningNow || s.isLive) {
        liveNowCount++;
      }
    }

    final double occupancyRate = totalCapacity > 0
        ? (totalConfirmed / totalCapacity) * 100
        : 0.0;

    return {
      'occupancyRate': occupancyRate.toStringAsFixed(1),
      'totalCapacity': totalCapacity,
      'totalConfirmed': totalConfirmed,
      'happeningNowCount': liveNowCount,
    };
  }

  // ===========================================================================
  // 6. INSTRUCTORES
  // ===========================================================================
  Future<List<InstructorModel>> getInstructors() async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('instructors')
            .select()
            .order('name', ascending: true);
        final list = (data as List).map((e) => InstructorModel.fromJson(e)).toList();
        if (list.isNotEmpty) return list;
      } catch (e) {
        debugPrint('Aviso: usando instructores demo ($e)');
      }
    }
    return _demoInstructors;
  }

  // ===========================================================================
  // 7. CREACIÓN, EDICIÓN Y ELIMINACIÓN DE CLASES Y HORARIOS (Admin)
  // ===========================================================================
  Future<ClassScheduleModel> createClassSchedule({
    required String name,
    required String description,
    required String imageUrl,
    required String instructorId,
    required DateTime startTime,
    required DateTime endTime,
    required int capacity,
    String? categoryId,
    ClassIntensity intensity = ClassIntensity.high,
  }) async {
    final client = _client;
    final durationMinutes = endTime.difference(startTime).inMinutes;

    if (client != null) {
      try {
        // 1. Insertar la clase (classes)
        final insertedClass = await client
            .from('classes')
            .insert({
              'name': name,
              'description': description,
              'image_url': imageUrl,
              'duration_minutes': durationMinutes > 0 ? durationMinutes : 60,
              'intensity': intensity.toDbString(),
              if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all')
                'category_id': categoryId,
            })
            .select()
            .single();

        final classId = insertedClass['id'] as String;

        // 2. Insertar el horario (class_schedules)
        final insertedSchedule = await client
            .from('class_schedules')
            .insert({
              'class_id': classId,
              'instructor_id': instructorId,
              'start_time': startTime.toUtc().toIso8601String(),
              'end_time': endTime.toUtc().toIso8601String(),
              'capacity': capacity,
              'location_name': 'Main Studio',
              'is_live': false,
            })
            .select('''
              id,
              class_id,
              instructor_id,
              start_time,
              end_time,
              capacity,
              location_name,
              is_live,
              classes:class_id ( id, name, description, image_url, category_id, intensity, duration_minutes, base_price ),
              instructors:instructor_id ( id, name, avatar_url, bio, rating )
            ''')
            .single();

        return ClassScheduleModel.fromJson(insertedSchedule);
      } catch (e) {
        debugPrint('Error creando clase en Supabase: $e');
      }
    }

    // Modo local / demo
    final newId = 'sched-local-${DateTime.now().millisecondsSinceEpoch}';
    final newClassId = 'class-local-${DateTime.now().millisecondsSinceEpoch}';
    final instructor = _demoInstructors.firstWhere(
      (inst) => inst.id == instructorId,
      orElse: () => _demoInstructors.first,
    );

    final newSchedule = ClassScheduleModel(
      id: newId,
      classId: newClassId,
      instructorId: instructorId,
      startTime: startTime,
      endTime: endTime,
      capacity: capacity,
      locationName: 'Main Studio',
      confirmedBookingsCount: 0,
      instructor: instructor,
      gymClass: GymClassModel(
        id: newClassId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        durationMinutes: durationMinutes > 0 ? durationMinutes : 60,
        intensity: intensity,
        categoryId: categoryId,
      ),
    );

    _demoSchedules.insert(0, newSchedule);
    return newSchedule;
  }

  Future<ClassScheduleModel> updateClassSchedule({
    required String scheduleId,
    required String classId,
    required String name,
    required String description,
    required String imageUrl,
    required String instructorId,
    required DateTime startTime,
    required DateTime endTime,
    required int capacity,
    String? categoryId,
    ClassIntensity intensity = ClassIntensity.high,
  }) async {
    final client = _client;
    final durationMinutes = endTime.difference(startTime).inMinutes;

    if (client != null) {
      try {
        // 1. Actualizar la clase (classes)
        await client.from('classes').update({
          'name': name,
          'description': description,
          'image_url': imageUrl,
          'duration_minutes': durationMinutes > 0 ? durationMinutes : 60,
          'intensity': intensity.toDbString(),
          if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all')
            'category_id': categoryId,
        }).eq('id', classId);

        // 2. Actualizar el horario (class_schedules)
        final updatedSchedule = await client
            .from('class_schedules')
            .update({
              'instructor_id': instructorId,
              'start_time': startTime.toUtc().toIso8601String(),
              'end_time': endTime.toUtc().toIso8601String(),
              'capacity': capacity,
            })
            .eq('id', scheduleId)
            .select('''
              id,
              class_id,
              instructor_id,
              start_time,
              end_time,
              capacity,
              location_name,
              is_live,
              classes:class_id ( id, name, description, image_url, category_id, intensity, duration_minutes, base_price ),
              instructors:instructor_id ( id, name, avatar_url, bio, rating )
            ''')
            .single();

        return ClassScheduleModel.fromJson(updatedSchedule);
      } catch (e) {
        debugPrint('Error actualizando clase en Supabase: $e');
      }
    }

    // Modo local / demo
    final instructor = _demoInstructors.firstWhere(
      (inst) => inst.id == instructorId,
      orElse: () => _demoInstructors.first,
    );

    final updated = ClassScheduleModel(
      id: scheduleId,
      classId: classId,
      instructorId: instructorId,
      startTime: startTime,
      endTime: endTime,
      capacity: capacity,
      locationName: 'Main Studio',
      instructor: instructor,
      gymClass: GymClassModel(
        id: classId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        durationMinutes: durationMinutes > 0 ? durationMinutes : 60,
        intensity: intensity,
        categoryId: categoryId,
      ),
    );

    final index = _demoSchedules.indexWhere((s) => s.id == scheduleId);
    if (index >= 0) {
      _demoSchedules[index] = updated;
    }
    return updated;
  }

  Future<void> deleteClassSchedule(String scheduleId, {String? classId}) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('class_schedules').delete().eq('id', scheduleId);
        if (classId != null && classId.isNotEmpty) {
          await client.from('classes').delete().eq('id', classId);
        }
      } catch (e) {
        debugPrint('Error eliminando clase en Supabase: $e');
      }
    }
    _demoSchedules.removeWhere((s) => s.id == scheduleId);
  }


  // ===========================================================================
  // DATOS DEMO (Fallback de alta calidad alineado con las reglas)
  // ===========================================================================
  static final List<CategoryModel> _demoCategories = [
    const CategoryModel(id: 'all', name: 'All Classes', iconUrl: 'grid'),
    const CategoryModel(id: 'cat-strength', name: 'Strength', iconUrl: 'barbell'),
    const CategoryModel(id: 'cat-hiit', name: 'Cardio / HIIT', iconUrl: 'flame'),
    const CategoryModel(id: 'cat-yoga', name: 'Power Yoga', iconUrl: 'sparkles'),
    const CategoryModel(id: 'cat-crossfit', name: 'CrossFit', iconUrl: 'activity'),
  ];

  static final List<ClassScheduleModel> _demoSchedules = [
    ClassScheduleModel(
      id: 'sched-1',
      classId: 'class-1',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      capacity: 16,
      locationName: 'Main Arena / Box 1',
      confirmedBookingsCount: 14, // 2 cupos libres
      gymClass: const GymClassModel(
        id: 'class-1',
        name: 'CrossFit WOD: Iron Beast',
        description:
            'Sesión de máxima potencia con barra olímpica, kettlebells y remadoras.',
        imageUrl:
            'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800',
        categoryId: 'cat-crossfit',
        intensity: ClassIntensity.high,
        durationMinutes: 60,
        basePrice: 25.0,
      ),
      instructor: const InstructorModel(
        id: 'inst-1',
        name: 'Marcus Vance',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        bio: 'Head Coach de CrossFit',
        rating: 4.9,
      ),
    ),
    ClassScheduleModel(
      id: 'sched-2',
      classId: 'class-2',
      startTime: DateTime.now().add(const Duration(hours: 3)),
      endTime: DateTime.now().add(const Duration(hours: 3, minutes: 50)),
      capacity: 12,
      locationName: 'Zen Studio / Sala A',
      confirmedBookingsCount: 12, // Llena -> Waitlist
      gymClass: const GymClassModel(
        id: 'class-2',
        name: 'Power Yoga & Mobility Flow',
        description:
            'Activación fascial y secuencia fluida de vinyasa dinámica.',
        imageUrl:
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        categoryId: 'cat-yoga',
        intensity: ClassIntensity.low,
        durationMinutes: 50,
        basePrice: 18.0,
      ),
      instructor: const InstructorModel(
        id: 'inst-2',
        name: 'Elena Rostova',
        avatarUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
        bio: 'Especialista en movilidad y control corporal',
        rating: 5.0,
      ),
    ),
    ClassScheduleModel(
      id: 'sched-3',
      classId: 'class-3',
      startTime: DateTime.now().add(const Duration(hours: 5)),
      endTime: DateTime.now().add(const Duration(hours: 5, minutes: 45)),
      capacity: 20,
      locationName: 'Pulse HIIT Floor',
      confirmedBookingsCount: 8, // 12 cupos libres
      gymClass: const GymClassModel(
        id: 'class-3',
        name: 'HIIT Pulse 45: Pure Sweat',
        description:
            'Intervalos de alta intensidad para maximizar el consumo de oxígeno.',
        imageUrl:
            'https://images.unsplash.com/photo-1601422407692-ec4eeec1d9b3?w=800',
        categoryId: 'cat-hiit',
        intensity: ClassIntensity.medium,
        durationMinutes: 45,
        basePrice: 20.0,
      ),
      instructor: const InstructorModel(
        id: 'inst-3',
        name: 'Carlos Vega',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        bio: 'Master trainer de intervalos aeróbicos',
        rating: 4.8,
      ),
    ),
  ];

  static final List<InstructorModel> _demoInstructors = [
    const InstructorModel(
      id: 'e1111111-1111-1111-1111-111111111111',
      name: 'Alex Johnson',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      bio: 'HIIT & Performance Head Coach',
      rating: 4.9,
    ),
    const InstructorModel(
      id: 'e2222222-2222-2222-2222-222222222222',
      name: 'Elena Rostova',
      avatarUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      bio: 'Especialista en movilidad y Yoga dinámico',
      rating: 5.0,
    ),
    const InstructorModel(
      id: 'e3333333-3333-3333-3333-333333333333',
      name: 'Carlos Vega',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      bio: 'Master trainer de intervalos de alta potencia',
      rating: 4.8,
    ),
    const InstructorModel(
      id: 'e4444444-4444-4444-4444-444444444444',
      name: 'Marcus Vance',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      bio: 'Head Coach de CrossFit y levantamiento olímpico',
      rating: 4.9,
    ),
  ];
}

