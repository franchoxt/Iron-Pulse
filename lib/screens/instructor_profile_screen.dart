import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de Perfil de Instructor para IRON PULSE.
///
/// Diseñada con fidelidad exacta a la referencia visual:
/// - Cabecera con imagen a pantalla completa del instructor con difuminado degradado hacia el fondo oscuro.
/// - Botones flotantes circulares superiores: retroceso a la izquierda y favoritos a la derecha.
/// - Píldoras de especialidades sobre la imagen (ej. "YOGA", "PILATES").
/// - Nombre prominente ("Sarah Jenkins") y badge verificado ("Certified Instructor").
/// - Sección "About" con la biografía completa.
/// - Fila de 3 métricas clave: "8+ YEARS EXP.", "2k+ CLASSES", "4.9 ★ RATING".
/// - Sección "Recent Reviews" con botón "View all" y reseñas detalladas.
/// - Barra inferior fija con acciones: "Message" (mensaje directo) y "Book a Private" (sesión personalizada).
class InstructorProfileScreen extends StatefulWidget {
  final InstructorModel? instructor;
  final UserProfileModel? userProfile;
  final String? instructorId;
  final String? userId;

  const InstructorProfileScreen({
    super.key,
    this.instructor,
    this.userProfile,
    this.instructorId,
    this.userId,
  });

  @override
  State<InstructorProfileScreen> createState() =>
      _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  InstructorModel? _instructor;
  bool _isLoading = true;
  bool _isFavorite = false;
  List<ClassScheduleModel> _instructorClasses = [];

  @override
  void initState() {
    super.initState();
    _loadInstructorData();
  }

  Future<void> _loadInstructorData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.instructor != null) {
        _instructor = widget.instructor;
      } else if (widget.userProfile != null) {
        _instructor = await DatabaseService.instance.getInstructorForProfile(
          widget.userProfile!,
        );
      } else if (widget.instructorId != null) {
        final all = await DatabaseService.instance.getInstructors();
        _instructor = all.firstWhere(
          (i) => i.id == widget.instructorId,
          orElse: () => all.first,
        );
      } else if (widget.userId != null) {
        final profiles = await DatabaseService.instance.getRegisteredProfiles();
        final p = profiles.firstWhere(
          (prof) => prof.id == widget.userId,
          orElse: () => profiles.first,
        );
        _instructor = await DatabaseService.instance.getInstructorForProfile(p);
      } else {
        final all = await DatabaseService.instance.getInstructors();
        _instructor = all.first;
      }

      // Cargar clases asignadas a este instructor si existen
      if (_instructor != null) {
        final schedules = await DatabaseService.instance.getSchedules();
        final nameLower = _instructor!.name.toLowerCase();
        _instructorClasses = schedules.where((s) {
          final instName = s.instructor?.name.toLowerCase() ?? '';
          return s.instructorId == _instructor!.id ||
              instName == nameLower ||
              instName.contains(nameLower.split(' ').first);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error cargando instructor: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? '¡${_instructor?.name ?? "Instructor"} añadido a tus favoritos!'
              : 'Eliminado de tus favoritos',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _isFavorite
            ? const Color(0xFF00BCEB)
            : const Color(0xFF334155),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showMessageSheet() {
    final textController = TextEditingController();
    final instructorName = _instructor?.name ?? 'el instructor';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF111722),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF222C3D), width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      _instructor?.avatarUrl ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mensaje para $instructorName',
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Consulta dudas, técnica o disponibilidad privada',
                          style: AppTypography.style(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: textController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Escribe tu mensaje aquí...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF161F2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF243044)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF00BCEB)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final message = textController.text.trim();
                    if (message.isEmpty) return;
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Mensaje enviado con éxito a $instructorName',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFF22C55E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Enviar Mensaje',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCEB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookPrivateSheet() {
    final instructorName = _instructor?.name ?? 'el instructor';
    String selectedSessionType = '1-on-1 Mindfulness & Posture (60 min)';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '10:00 AM';

    final sessionTypes = [
      '1-on-1 Mindfulness & Posture (60 min)',
      'Private Vinyasa Flow (45 min)',
      'Breathwork & Core Conditioning (60 min)',
      'Personal Fitness Assessment (30 min)',
    ];

    final availableHours = [
      '08:00 AM',
      '10:00 AM',
      '02:30 PM',
      '05:00 PM',
      '06:30 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF111722),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF222C3D), width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reservar Sesión Privada',
                        style: AppTypography.style(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sesión personalizada con $instructorName',
                        style: AppTypography.style(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10283F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00BCEB).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '\$45.00',
                      style: AppTypography.style(
                        color: const Color(0xFF00BCEB),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tipo de Sesión
              Text(
                'TIPO DE SESIÓN',
                style: AppTypography.style(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF243044)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSessionType,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF161F2E),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF00BCEB),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    items: sessionTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedSessionType = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Horarios disponibles
              Text(
                'HORARIO PREFERIDO',
                style: AppTypography.style(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: availableHours.map((time) {
                    final isSel = selectedTime == time;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedTime = time),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF00BCEB)
                              : const Color(0xFF161F2E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFF00BCEB)
                                : const Color(0xFF243044),
                          ),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isSel
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                            fontSize: 12.5,
                            fontWeight: isSel
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Botón Confirmar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '¡Sesión privada reservada con $instructorName para las $selectedTime!',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFF22C55E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCEB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Confirmar Reserva Privada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllReviewsSheet() {
    final reviews = _instructor?.reviews ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF111722),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF222C3D), width: 1.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reseñas de Alumnos',
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final rev = reviews[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E28),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF222C3D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(
                                rev.authorAvatar ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rev.authorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    rev.timeAgo,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rev.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          rev.comment,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C1017),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCEB)),
        ),
      );
    }

    final instructor =
        _instructor ??
        const InstructorModel(
          id: 'default',
          name: 'Sarah Jenkins',
          avatarUrl:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800',
          bio: 'With over 8 years of dedicated practice, Sarah brings a calming yet challenging approach to her sessions. She believes in the power of mindful movement to transform both body and mind. Her classes focus on alignment, breathwork, and building core strength.',
          rating: 4.9,
          specialties: ['YOGA', 'PILATES'],
          yearsExperience: '8+',
          classesCount: '2k+',
          certification: 'Certified Instructor',
        );

    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = (screenHeight * 0.48).clamp(380.0, 480.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: Stack(
        children: [
          // ===================================================================
          // CONTENIDO CON DESPLAZAMIENTO SUAVE
          // ===================================================================
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HERO HEADER: Foto con degradados y chips
                _buildHeroHeader(instructor, headerHeight),

                const SizedBox(height: 14),

                // 2. SECCIÓN ABOUT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: AppTypography.style(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        instructor.bio ??
                            'With over 8 years of dedicated practice, ${instructor.name} brings a calming yet challenging approach to her sessions. She believes in the power of mindful movement to transform both body and mind. Her classes focus on alignment, breathwork, and building core strength.',
                        style: AppTypography.style(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. FILA DE 3 TARJETAS DE MÉTRICAS (8+ YEARS EXP. | 2k+ CLASSES | 4.9 RATING)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsRow(instructor),
                ),

                const SizedBox(height: 26),

                // 4. SECCIÓN RECENT REVIEWS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRecentReviewsSection(instructor),
                ),

                // 5. CLASES PROGRAMADAS DEL INSTRUCTOR (Si tiene)
                if (_instructorClasses.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildUpcomingClassesSection(),
                  ),
                ],
              ],
            ),
          ),

          // ===================================================================
          // BOTONES FLOTANTES SUPERIORES (Atrás y Favorito)
          // ===================================================================
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 18,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón Atrás
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0x660F172A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // Botón Favorito
                GestureDetector(
                  onTap: _toggleFavorite,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0x660F172A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      color: _isFavorite
                          ? const Color(0xFFEF4444)
                          : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // BARRA DE ACCIONES INFERIOR FIJA (Message | Book a Private)
          // ===================================================================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. HERO HEADER (Foto grande, degradado y chips de especialidad)
  // ===========================================================================
  Widget _buildHeroHeader(InstructorModel instructor, double height) {
    final avatar =
        instructor.avatarUrl ??
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800';

    final specialties = instructor.specialties.isNotEmpty
        ? instructor.specialties
        : ['YOGA', 'PILATES'];

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo con recorte suave
          Image.network(
            avatar,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1E293B),
              child: const Icon(Icons.person, color: Colors.white24, size: 80),
            ),
          ),

          // Degradado superior para contraste de botones
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Degradado inferior profundo para fundir la foto con el fondo oscuro
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: height * 0.70,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.40, 0.75, 1.0],
                  colors: [
                    Colors.transparent,
                    Color(0x990A0D14),
                    Color(0xFA0A0D14),
                    Color(0xFF0A0D14),
                  ],
                ),
              ),
            ),
          ),

          // Información sobrepuesta sobre la parte inferior de la imagen
          Positioned(
            bottom: 8,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Píldoras de Especialidad (YOGA, PILATES, etc.)
                Row(
                  children: [
                    for (int i = 0; i < specialties.length; i++) ...[
                      _buildSpecialtyChip(specialties[i], isPrimary: i == 0),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // Nombre del Instructor (Sarah Jenkins)
                Text(
                  instructor.name,
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 6),

                // Badge verificado: Checkmark cian + Certified Instructor
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF00BCEB),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      instructor.certification,
                      style: AppTypography.style(
                        color: const Color(0xFF94A3B8),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyChip(String label, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary
            ? const Color(0xFF00BCEB)
            : const Color(0xFF10283F).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary
              ? const Color(0xFF00BCEB)
              : const Color(0xFF00BCEB).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: isPrimary ? Colors.white : const Color(0xFF00BCEB),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. FILA DE 3 TARJETAS DE MÉTRICAS (8+ YEARS EXP. | 2k+ CLASSES | 4.9 RATING)
  // ===========================================================================
  Widget _buildStatsRow(InstructorModel instructor) {
    return Row(
      children: [
        // 1. Años de Experiencia
        Expanded(
          child: _buildStatCard(
            topContent: Text(
              instructor.yearsExperience,
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            label: 'YEARS EXP.',
          ),
        ),

        const SizedBox(width: 12),

        // 2. Total de Clases
        Expanded(
          child: _buildStatCard(
            topContent: Text(
              instructor.classesCount,
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            label: 'CLASSES',
          ),
        ),

        const SizedBox(width: 12),

        // 3. Calificación con Estrella
        Expanded(
          child: _buildStatCard(
            topContent: Text(
              instructor.rating.toStringAsFixed(1),
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            label: 'RATING',
            showStar: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Widget topContent,
    required String label,
    bool showStar = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222836), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          topContent,
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showStar) ...[
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 13,
                ),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: AppTypography.style(
                  color: const Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. SECCIÓN RECENT REVIEWS
  // ===========================================================================
  Widget _buildRecentReviewsSection(InstructorModel instructor) {
    final reviews = instructor.reviews.isNotEmpty
        ? instructor.reviews
        : const [
            InstructorReviewModel(
              id: 'rev-def-1',
              authorName: 'Elena Gomez',
              authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
              rating: 5.0,
              comment: 'Sarah is the best instructor! Her posture alignment cues and energy completely changed my flow.',
              timeAgo: '2 days ago',
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Reviews',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: _showAllReviewsSheet,
              behavior: HitTestBehavior.opaque,
              child: Text(
                'View all',
                style: AppTypography.style(
                  color: const Color(0xFF00BCEB),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Mostrar la reseña destacada más reciente
        for (final rev in reviews.take(2)) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141923),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF222836), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFF1E293B),
                      backgroundImage: NetworkImage(
                        rev.authorAvatar ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rev.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            rev.timeAgo,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rev.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  rev.comment,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 4. CLASES ASIGNADAS AL INSTRUCTOR
  // ===========================================================================
  Widget _buildUpcomingClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próximas Clases',
          style: AppTypography.style(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        for (final schedule in _instructorClasses.take(3)) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF141923),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF222836)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10283F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFF00BCEB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.className,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${schedule.timeRangeStr} • ${schedule.locationName ?? "Studio A"}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCEB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00BCEB).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'Ver Sesión',
                    style: TextStyle(
                      color: Color(0xFF00BCEB),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 5. BARRA INFERIOR FIJA (Message | Book a Private)
  // ===========================================================================
  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1017).withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E2638), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón Izquierdo: Message
          GestureDetector(
            onTap: _showMessageSheet,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF161E28),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2B3648), width: 1.2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón Derecho: Book a Private (Cyan Vibrante)
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _showBookPrivateSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCEB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Book a Private',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
