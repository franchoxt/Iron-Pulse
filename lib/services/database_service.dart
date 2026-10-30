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
  final List<BookingModel> _sessionBookings = [];

  /// Limpia la caché y reservas temporales de la sesión al cerrar sesión
  void clearSessionData() {
    _sessionBookings.clear();
  }

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
        // 0. Si ya existe una reserva para este usuario y sesión, retornarla directamente
        final existingUserBooking = await client
            .from('bookings')
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
                classes ( id, name, description, image_url, intensity, duration_minutes, base_price ),
                instructors ( id, name, avatar_url, bio, rating )
              )
            ''')
            .eq('user_id', user.id)
            .eq('schedule_id', validScheduleId)
            .maybeSingle();

        if (existingUserBooking != null) {
          final model = BookingModel.fromJson(Map<String, dynamic>.from(existingUserBooking));
          _sessionBookings.removeWhere((b) => b.scheduleId == validScheduleId);
          _sessionBookings.insert(0, model);
          return model;
        }

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
                classes ( id, name, description, image_url, intensity, duration_minutes, base_price ),
                instructors ( id, name, avatar_url, bio, rating )
              )
            ''')
            .single();

        final model = BookingModel.fromJson(Map<String, dynamic>.from(inserted));
        _sessionBookings.removeWhere((b) => b.scheduleId == validScheduleId);
        _sessionBookings.insert(0, model);
        return model;
      } catch (e) {
        if (e.toString().contains('bookings_user_id_schedule_id_key') ||
            e.toString().contains('23505') ||
            e.toString().contains('duplicate key')) {
          final existing = await client
              .from('bookings')
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
                  classes ( id, name, description, image_url, intensity, duration_minutes, base_price ),
                  instructors ( id, name, avatar_url, bio, rating )
                )
              ''')
              .eq('user_id', user.id)
              .eq('schedule_id', validScheduleId)
              .maybeSingle();
          if (existing != null) {
            final model = BookingModel.fromJson(Map<String, dynamic>.from(existing));
            _sessionBookings.removeWhere((b) => b.scheduleId == validScheduleId);
            _sessionBookings.insert(0, model);
            return model;
          }
        }
        debugPrint('Error en reserva remota: $e');
      }
    }

    // Modo local / sesión fallback
    ClassScheduleModel? matchedSchedule;
    try {
      final allSchedules = await getSchedules();
      matchedSchedule = allSchedules.firstWhere((s) => s.id == validScheduleId);
    } catch (_) {}
    matchedSchedule ??= _demoSchedules.firstWhere(
      (s) => s.id == validScheduleId,
      orElse: () => _demoSchedules.first,
    );

    final localBooking = BookingModel(
      id: 'session-booking-${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id ?? 'athlete-user',
      scheduleId: validScheduleId,
      status: BookingStatus.confirmed,
      isPresent: false,
      createdAt: DateTime.now(),
      schedule: matchedSchedule,
    );
    _sessionBookings.removeWhere((b) => b.scheduleId == validScheduleId);
    _sessionBookings.insert(0, localBooking);

    return localBooking;
  }

  /// Verifica si el usuario actual ya tiene reservada una sesión específica
  Future<bool> isUserBooked(String scheduleId) async {
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

    // 1. Verificar primero en reservas activas de sesión
    final inSession = _sessionBookings.any(
      (b) => (b.scheduleId == validScheduleId || b.id == validScheduleId) && b.status != BookingStatus.cancelled,
    );
    if (inSession) return true;

    // 2. Verificar en Supabase
    final client = _client;
    final user = AuthService.instance.currentUser;
    if (client != null && user != null) {
      try {
        final existing = await client
            .from('bookings')
            .select('id')
            .eq('user_id', user.id)
            .eq('schedule_id', validScheduleId)
            .maybeSingle();
        return existing != null;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Cancelar una reserva
  Future<bool> cancelBooking(String bookingOrScheduleId) async {
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

    // Remover de reservas de sesión
    _sessionBookings.removeWhere(
      (b) => b.id == targetId || b.scheduleId == targetId,
    );

    final client = _client;
    final user = AuthService.instance.currentUser;
    if (client != null && user != null) {
      try {
        await client
            .from('bookings')
            .delete()
            .or('id.eq.$targetId,schedule_id.eq.$targetId')
            .eq('user_id', user.id);
        return true;
      } catch (e) {
        debugPrint('Error cancelando reserva: $e');
        return false;
      }
    }
    return true;
  }

  /// Obtiene todas las reservaciones del usuario actual desde Supabase (tabla 'bookings')
  Future<List<BookingModel>> getUserBookings({String? userId}) async {
    final client = _client;
    final currentUserId = userId ?? AuthService.instance.currentUser?.id;
    final List<BookingModel> result = [];

    if (client != null && currentUserId != null) {
      try {
        final data = await client
            .from('bookings')
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
                classes (
                  id,
                  name,
                  description,
                  image_url,
                  category_id,
                  intensity,
                  duration_minutes,
                  base_price
                ),
                instructors (
                  id,
                  name,
                  avatar_url,
                  bio,
                  rating
                )
              )
            ''')
            .eq('user_id', currentUserId)
            .order('created_at', ascending: false);

        for (final item in (data as List)) {
          try {
            final b = BookingModel.fromJson(Map<String, dynamic>.from(item as Map));
            result.add(b);
          } catch (err) {
            debugPrint('Error parseando reserva de Supabase: $err');
          }
        }
      } catch (e) {
        debugPrint('Error cargando reservas de usuario desde Supabase: $e');
      }
    }

    // Fusionar con las reservas creadas en la sesión actual
    for (final sessionBooking in _sessionBookings) {
      final exists = result.any(
        (b) => b.scheduleId == sessionBooking.scheduleId || b.id == sessionBooking.id,
      );
      if (!exists && sessionBooking.status != BookingStatus.cancelled) {
        result.insert(0, sessionBooking);
      }
    }

    // Si existen reservas reales del usuario, devolverlas
    if (result.isNotEmpty) {
      return result;
    }

    return _getDemoBookings();
  }

  List<BookingModel> _getDemoBookings() {
    final now = DateTime.now();
    final today8am = DateTime(now.year, now.month, now.day, 8, 0);
    final today630pm = DateTime(now.year, now.month, now.day, 18, 30);
    final nextWed = now.add(const Duration(days: 2));
    final nextWed7am = DateTime(nextWed.year, nextWed.month, nextWed.day, 7, 0);
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterday10am = DateTime(yesterday.year, yesterday.month, yesterday.day, 10, 0);
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final threeDaysAgo5pm = DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day, 17, 0);

    return [
      BookingModel(
        id: 'booking-demo-1',
        userId: 'demo-user',
        scheduleId: '11111111-1111-1111-1111-111111111111',
        status: BookingStatus.confirmed,
        isPresent: false,
        createdAt: now.subtract(const Duration(days: 1)),
        schedule: ClassScheduleModel(
          id: '11111111-1111-1111-1111-111111111111',
          classId: 'class-hiit',
          startTime: today8am,
          endTime: today8am.add(const Duration(minutes: 45)),
          capacity: 20,
          locationName: 'Room A • Main Studio',
          gymClass: const GymClassModel(
            id: 'class-hiit',
            name: 'HIIT Intensity',
            description: 'Circuito de alta intensidad enfocado en quema de calorías y aceleración metabólica.',
            imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
            intensity: ClassIntensity.high,
            durationMinutes: 45,
            basePrice: 25.0,
          ),
          instructor: const InstructorModel(
            id: 'inst-alex',
            name: 'Alex Cross',
            avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
            bio: 'Especialista en entrenamiento HIIT y acondicionamiento cardiovascular.',
            rating: 4.9,
          ),
        ),
      ),
      BookingModel(
        id: 'booking-demo-2',
        userId: 'demo-user',
        scheduleId: '22222222-2222-2222-2222-222222222222',
        status: BookingStatus.waitlist,
        isPresent: false,
        createdAt: now.subtract(const Duration(hours: 12)),
        schedule: ClassScheduleModel(
          id: '22222222-2222-2222-2222-222222222222',
          classId: 'class-yoga',
          startTime: today630pm,
          endTime: today630pm.add(const Duration(minutes: 60)),
          capacity: 15,
          locationName: 'Room B • Quiet Zone',
          gymClass: const GymClassModel(
            id: 'class-yoga',
            name: 'Sunset Yoga',
            description: 'Secuencia relajante para mejorar flexibilidad, equilibrio y recuperación muscular.',
            imageUrl: 'https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=800',
            intensity: ClassIntensity.low,
            durationMinutes: 60,
            basePrice: 20.0,
          ),
          instructor: const InstructorModel(
            id: 'inst-sarah-j',
            name: 'Sarah Jenkins',
            avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
            bio: 'Instructora certificada de Vinyasa y Hatha Yoga.',
            rating: 5.0,
          ),
        ),
      ),
      BookingModel(
        id: 'booking-demo-3',
        userId: 'demo-user',
        scheduleId: '33333333-3333-3333-3333-333333333333',
        status: BookingStatus.confirmed,
        isPresent: false,
        createdAt: now.subtract(const Duration(days: 2)),
        schedule: ClassScheduleModel(
          id: '33333333-3333-3333-3333-333333333333',
          classId: 'class-crossfit',
          startTime: nextWed7am,
          endTime: nextWed7am.add(const Duration(minutes: 60)),
          capacity: 18,
          locationName: 'Box 1 • Outdoor Area',
          gymClass: const GymClassModel(
            id: 'class-crossfit',
            name: 'CrossFit Advanced',
            description: 'WOD desafiante con levantamientos olímpicos, gimnásticos y trabajo en equipo.',
            imageUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800',
            intensity: ClassIntensity.high,
            durationMinutes: 60,
            basePrice: 30.0,
          ),
          instructor: const InstructorModel(
            id: 'inst-mike',
            name: 'Mike T.',
            avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
            bio: 'Head Coach de CrossFit Level 3.',
            rating: 4.8,
          ),
        ),
      ),
      // Historial (Clases pasadas)
      BookingModel(
        id: 'booking-demo-4',
        userId: 'demo-user',
        scheduleId: '44444444-4444-4444-4444-444444444444',
        status: BookingStatus.confirmed,
        isPresent: true,
        createdAt: yesterday.subtract(const Duration(days: 1)),
        schedule: ClassScheduleModel(
          id: '44444444-4444-4444-4444-444444444444',
          classId: 'class-power',
          startTime: yesterday10am,
          endTime: yesterday10am.add(const Duration(minutes: 45)),
          capacity: 15,
          locationName: 'Main Arena • Studio A',
          gymClass: const GymClassModel(
            id: 'class-power',
            name: 'Power Circuit',
            description: 'Sesión metabólica con intervalos de fuerza y acondicionamiento.',
            imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800',
            intensity: ClassIntensity.medium,
            durationMinutes: 45,
            basePrice: 22.0,
          ),
          instructor: const InstructorModel(
            id: 'inst-elena',
            name: 'Elena Rostova',
            avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
            bio: 'Especialista en movilidad y fuerza funcional.',
            rating: 5.0,
          ),
        ),
      ),
      BookingModel(
        id: 'booking-demo-5',
        userId: 'demo-user',
        scheduleId: '55555555-5555-5555-5555-555555555555',
        status: BookingStatus.cancelled,
        isPresent: false,
        createdAt: threeDaysAgo.subtract(const Duration(days: 1)),
        schedule: ClassScheduleModel(
          id: '55555555-5555-5555-5555-555555555555',
          classId: 'class-mobility',
          startTime: threeDaysAgo5pm,
          endTime: threeDaysAgo5pm.add(const Duration(minutes: 50)),
          capacity: 15,
          locationName: 'Studio B',
          gymClass: const GymClassModel(
            id: 'class-mobility',
            name: 'Mobility Flow',
            description: 'Liberación miofascial y estiramientos profundos.',
            imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
            intensity: ClassIntensity.low,
            durationMinutes: 50,
            basePrice: 18.0,
          ),
          instructor: const InstructorModel(
            id: 'inst-carlos',
            name: 'Carlos Vega',
            avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
            bio: 'Especialista en rehabilitación y movilidad articular.',
            rating: 4.8,
          ),
        ),
      ),
    ];
  }

  /// Check-in de estudiantes (Gestión de presencia por el Admin o Instructor)
  Future<void> checkInStudent({
    required String bookingId,
    required bool isPresent,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        await client
            .from('bookings')
            .update({'is_present': isPresent})
            .eq('id', bookingId);
      } catch (e) {
        debugPrint('Aviso actualizando is_present en Supabase: $e');
      }
    }
  }

  /// Actualiza el estado de una reserva (confirmed, waitlist, cancelled)
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        await client
            .from('bookings')
            .update({'status': status})
            .eq('id', bookingId);
      } catch (e) {
        debugPrint('Aviso actualizando status de reserva: $e');
      }
    }
  }

  /// Obtiene los estudiantes/reservas para una sesión específica con datos de perfiles
  Future<List<Map<String, dynamic>>> getRosterForSchedule(String scheduleId) async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('bookings')
            .select('''
              id,
              user_id,
              schedule_id,
              status,
              is_present,
              created_at,
              profiles (
                id,
                full_name,
                avatar_url,
                role
              )
            ''')
            .eq('schedule_id', scheduleId)
            .order('created_at', ascending: true);

        if (data.isNotEmpty) {
          final List<Map<String, dynamic>> roster = [];
          int waitlistCounter = 1;
          for (final item in data) {
            final profile = item['profiles'] as Map<String, dynamic>?;
            final statusStr = item['status'] as String? ?? 'confirmed';
            final isWaitlist = statusStr.toLowerCase() == 'waitlist';
            final waitlistNumber = isWaitlist ? waitlistCounter++ : null;

            final fullName = profile?['full_name'] as String? ?? 'Atleta';
            roster.add({
              'id': item['id'] as String,
              'userId': item['user_id'] as String,
              'name': fullName,
              'email': '${fullName.toLowerCase().replaceAll(' ', '.')}@ironpulse.fit',
              'avatar': profile?['avatar_url'] as String? ?? '',
              'status': statusStr,
              'waitlistNumber': waitlistNumber,
              'isPresent': item['is_present'] as bool? ?? false,
            });
          }
          return roster;
        }
      } catch (e) {
        debugPrint('Aviso obteniendo roster de sesión desde Supabase: $e');
      }
    }
    return [];
  }

  /// Agrega un nuevo estudiante a la sesión en Supabase
  Future<Map<String, dynamic>?> addStudentToSchedule({
    required String scheduleId,
    required String fullName,
    required String email,
    required String status,
    bool isPresent = false,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        // Crear un id único
        final bookingId = '00000000-0000-0000-0000-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}';
        final userId = '00000000-0000-0000-0000-${(DateTime.now().millisecondsSinceEpoch + 1).toString().padLeft(12, '0').substring(0, 12)}';

        await client.from('bookings').insert({
          'id': bookingId,
          'user_id': userId,
          'schedule_id': scheduleId,
          'status': status,
          'is_present': isPresent,
        });

        return {
          'id': bookingId,
          'userId': userId,
          'name': fullName,
          'email': email,
          'status': status,
          'isPresent': isPresent,
          'avatar': '',
        };
      } catch (e) {
        debugPrint('Aviso insertando reserva en Supabase: $e');
      }
    }
    return null;
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

  /// Actualiza datos del perfil del usuario (nombre y/o avatarUrl) en Supabase.
  Future<bool> updateUserProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final client = _client;
    final user = AuthService.instance.currentUser;
    if (client != null && user != null) {
      try {
        final Map<String, dynamic> updates = {
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (fullName != null && fullName.isNotEmpty) updates['full_name'] = fullName;
        if (avatarUrl != null && avatarUrl.isNotEmpty) updates['avatar_url'] = avatarUrl;

        await client.from('profiles').update(updates).eq('id', user.id);
        return true;
      } catch (e) {
        debugPrint('Error actualizando perfil en Supabase: $e');
      }
    }
    return false;
  }

  /// Actualiza el rol de un usuario en Supabase (tabla 'profiles', 'instructors' y auth metadata)
  /// Permite asignar: 'admin', 'client' o 'instructor'
  Future<bool> updateUserRole({
    required String userId,
    required String newRole,
    String? userName,
    String? userAvatar,
  }) async {
    final client = _client;
    if (client == null) return false;

    final currentAuthUser = AuthService.instance.currentUser;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

    String targetId = userId;

    // 1. Resolver targetId si no es un UUID válido (ej. viene de mocks o placeholders)
    if (!uuidRegex.hasMatch(targetId)) {
      if (currentAuthUser != null && (userName == 'Admin' || userName == currentAuthUser.userMetadata?['full_name'])) {
        targetId = currentAuthUser.id;
      } else if (userName != null && userName.isNotEmpty) {
        try {
          final match = await client
              .from('profiles')
              .select('id')
              .ilike('full_name', '%$userName%')
              .limit(1);
          final list = match as List;
          if (list.isNotEmpty && list.first['id'] != null) {
            targetId = list.first['id'] as String;
          }
        } catch (_) {}
      }
    }

    if (!uuidRegex.hasMatch(targetId) && currentAuthUser != null) {
      targetId = currentAuthUser.id;
    }

    bool updated = false;

    // 2. Gestión de la tabla 'instructors':
    if (userName != null && userName.isNotEmpty) {
      try {
        if (newRole == 'instructor') {
          // Si el rol es instructor, verificar si ya está en tabla instructors
          final existing = await client
              .from('instructors')
              .select('id')
              .ilike('name', userName)
              .limit(1);
          final list = existing as List;
          if (list.isEmpty) {
            await client.from('instructors').insert({
              'name': userName,
              'avatar_url': userAvatar ?? '',
              'bio': 'Instructor Iron Pulse',
              'rating': 5.0,
            });
            debugPrint('Instructor $userName insertado en tabla instructors ✓');
          }
          updated = true;
        } else {
          // Si el rol ya no es instructor, remover de tabla instructors para mantener consistencia
          await client.from('instructors').delete().ilike('name', userName);
          debugPrint('Instructor $userName removido de tabla instructors ✓');
        }
      } catch (e) {
        debugPrint('Aviso gestionando tabla instructors: $e');
      }
    }

    // 3. Gestión de la tabla 'profiles':
    if (uuidRegex.hasMatch(targetId)) {
      try {
        // Intentar actualizar directamente
        final updateRes = await client.from('profiles').update({
          'role': newRole,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', targetId).select();

        final updatedList = updateRes as List;
        if (updatedList.isNotEmpty) {
          updated = true;
          debugPrint('Rol actualizado en profiles: ${updatedList.first}');
        } else if (currentAuthUser != null && currentAuthUser.id == targetId) {
          // Si no existía el registro para el usuario autenticado, crearlo mediante upsert
          final upsertRes = await client.from('profiles').upsert({
            'id': targetId,
            if (userName != null && userName.isNotEmpty) 'full_name': userName,
            if (userAvatar != null && userAvatar.isNotEmpty) 'avatar_url': userAvatar,
            'role': newRole,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).select();
          debugPrint('Perfil creado/actualizado con upsert: $upsertRes');
          updated = true;
        }
      } catch (e) {
        debugPrint('Aviso al actualizar profiles con $newRole: $e');
        // Si PostgreSQL restringe el enum user_role a ('admin', 'client') y newRole es 'instructor'
        if (newRole == 'instructor') {
          try {
            await client.from('profiles').update({
              'role': 'client',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            }).eq('id', targetId);
            updated = true;
          } catch (e2) {
            debugPrint('Error en fallback profiles: $e2');
          }
        }
      }

      // 4. Si el usuario modificado es el usuario actual, actualizar metadata de Supabase Auth
      if (currentAuthUser != null && currentAuthUser.id == targetId) {
        try {
          await client.auth.updateUser(
            UserAttributes(data: {'role': newRole}),
          );
          debugPrint('Auth metadata actualizada a role=$newRole ✓');
          updated = true;
        } catch (e) {
          debugPrint('Aviso actualizando auth metadata: $e');
        }
      }
    }

    return updated;
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
  // 6. INSTRUCTORES & CONTEOS PARA EL PORTAL ADMIN
  // ===========================================================================
  /// Conteo de usuarios registrados en la tabla 'profiles'
  Future<int> getRegisteredUsersCount() async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client.from('profiles').select('id');
        final list = data as List;
        if (list.isNotEmpty) return list.length;
      } catch (e) {
        debugPrint('Error obteniendo conteo de usuarios en Supabase: $e');
      }
    }
    return 24; // Fallback demo
  }

  /// Conteo de administradores registrados en la tabla 'profiles' (role = 'admin')
  Future<int> getAdminsCount() async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('profiles')
            .select('id')
            .eq('role', 'admin');
        final list = data as List;
        return list.length;
      } catch (e) {
        debugPrint('Error obteniendo conteo de administradores en Supabase: $e');
      }
    }
    return 1; // Fallback demo
  }

  /// Conteo de instructores registrados en la tabla 'instructors'
  Future<int> getInstructorsCount() async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client.from('instructors').select('id');
        final list = data as List;
        if (list.isNotEmpty) return list.length;
      } catch (e) {
        debugPrint('Error obteniendo conteo de instructores en Supabase: $e');
      }
    }
    final instructors = await getInstructors();
    return instructors.isNotEmpty ? instructors.length : 18;
  }

  /// Conteo de categorías creadas de deportes disponibles en 'categories'
  Future<int> getCategoriesCount() async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client.from('categories').select('id, name');
        final list = (data as List)
            .where((c) => c['name'] != 'All Classes' && c['id'] != 'all')
            .toList();
        if (list.isNotEmpty) return list.length;
      } catch (e) {
        debugPrint('Error obteniendo conteo de categorías en Supabase: $e');
      }
    }
    final cats = await getCategories();
    final realCats =
        cats.where((c) => c.id != 'all' && c.name != 'All Classes').toList();
    return realCats.isNotEmpty ? realCats.length : 6;
  }

  /// Lista de perfiles registrados en Supabase
  Future<List<UserProfileModel>> getRegisteredProfiles() async {
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('profiles')
            .select()
            .order('full_name', ascending: true);
        final list = data as List;
        if (list.isNotEmpty) {
          return list
              .map((e) => UserProfileModel.fromJson(e))
              .toList();
        }
      } catch (e) {
        debugPrint('Error obteniendo lista de perfiles en Supabase: $e');
      }
    }
    return [];
  }

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
        rethrow;
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
        rethrow;
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

  /// Actualiza específicamente el horario (start_time, end_time) y el instructor asignado de una sesión
  Future<ClassScheduleModel> updateScheduleTimeAndInstructor({
    required String scheduleId,
    required DateTime startTime,
    required DateTime endTime,
    required String instructorId,
    String? locationName,
  }) async {
    final client = _client;
    final durationMinutes = endTime.difference(startTime).inMinutes;

    if (client != null) {
      try {
        final data = await client
            .from('class_schedules')
            .update({
              'instructor_id': instructorId,
              'start_time': startTime.toUtc().toIso8601String(),
              'end_time': endTime.toUtc().toIso8601String(),
              'location_name': ?locationName,
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

        // Actualizar duración si class_id existe
        if (durationMinutes > 0 && data['class_id'] != null) {
          try {
            await client
                .from('classes')
                .update({'duration_minutes': durationMinutes})
                .eq('id', data['class_id']);
          } catch (_) {}
        }

        final updatedModel = ClassScheduleModel.fromJson(data);
        final idx = _demoSchedules.indexWhere((s) => s.id == scheduleId);
        if (idx >= 0) {
          _demoSchedules[idx] = updatedModel;
        }
        return updatedModel;
      } catch (e) {
        debugPrint('Error actualizando horario e instructor en Supabase: $e');
      }
    }

    // Modo local / demo fallback
    final idx = _demoSchedules.indexWhere((s) => s.id == scheduleId);
    final allInst = await getInstructors();
    final inst = allInst.firstWhere(
      (i) => i.id == instructorId,
      orElse: () => allInst.first,
    );

    if (idx >= 0) {
      final existing = _demoSchedules[idx];
      final updatedGymClass = existing.gymClass?.copyWith(
        durationMinutes: durationMinutes > 0 ? durationMinutes : existing.gymClass?.durationMinutes,
      ) ?? existing.gymClass;

      final updated = existing.copyWith(
        startTime: startTime,
        endTime: endTime,
        instructorId: instructorId,
        instructor: inst,
        locationName: locationName ?? existing.locationName,
        gymClass: updatedGymClass,
      );
      _demoSchedules[idx] = updated;
      return updated;
    }

    throw Exception('Horario no encontrado para ID $scheduleId');
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
    // 1. Clase Pasada (Finalizada hoy más temprano)
    ClassScheduleModel(
      id: 'sched-past-1',
      classId: 'class-past-1',
      startTime: DateTime.now().subtract(const Duration(hours: 4)),
      endTime: DateTime.now().subtract(const Duration(hours: 3)),
      capacity: 18,
      locationName: 'Arena Central • Zone A',
      confirmedBookingsCount: 18,
      gymClass: const GymClassModel(
        id: 'class-past-1',
        name: 'HIIT Morning Blast: Full Cardio',
        description:
            'Sesión matutina intensa con intervalos funcionales y kettlebells.',
        imageUrl:
            'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
        categoryId: 'cat-hiit',
        intensity: ClassIntensity.high,
        durationMinutes: 60,
        basePrice: 22.0,
      ),
      instructor: const InstructorModel(
        id: 'e1111111-1111-1111-1111-111111111111',
        name: 'Alex Johnson',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        bio: 'HIIT & Performance Head Coach',
        rating: 4.9,
      ),
    ),
    // 2. Clase Pasada (Ayer)
    ClassScheduleModel(
      id: 'sched-past-2',
      classId: 'class-past-2',
      startTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      endTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      capacity: 15,
      locationName: 'Box 2 • Olympic Weightlifting',
      confirmedBookingsCount: 15,
      gymClass: const GymClassModel(
        id: 'class-past-2',
        name: 'Olympic Lifting & Power Snatch',
        description:
            'Técnica de arranque y envión con cargas progresivas y barra olímpica.',
        imageUrl:
            'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800',
        categoryId: 'cat-crossfit',
        intensity: ClassIntensity.high,
        durationMinutes: 60,
        basePrice: 25.0,
      ),
      instructor: const InstructorModel(
        id: 'e4444444-4444-4444-4444-444444444444',
        name: 'Marcus Vance',
        avatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        bio: 'Head Coach de CrossFit y levantamiento olímpico',
        rating: 4.9,
      ),
    ),
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

