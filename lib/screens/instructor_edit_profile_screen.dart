import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_image_helper.dart';
import '../widgets/neon_button.dart';
import 'instructor_profile_screen.dart';

/// Pantalla de Edición y Autogestión del Perfil del Instructor.
///
/// Diseñada con la estética exacta de IRON PULSE (Mobile-First):
/// 1. Top bar con logo IRON PULSE y badge de rol INSTRUCTOR.
/// 2. Hero background oscuro con luces de gimnasio y gradiente suave.
/// 3. Gran tipografía: "Add Instructor Profile." con acento cian.
/// 4. Campos de formulario: Full Name, Professional Bio, Years of Experience.
/// 5. Chips interactivos de Specialties (tags seleccionables con '+' y '✕').
/// 6. Foto de perfil interactiva y vista previa pública.
/// 7. Guardado en Supabase (`instructors` y `profiles`) con feedback visual inmediato.
class InstructorEditProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const InstructorEditProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<InstructorEditProfileScreen> createState() =>
      _InstructorEditProfileScreenState();
}

class _InstructorEditProfileScreenState
    extends State<InstructorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _avatarController;
  late TextEditingController _experienceController;
  late TextEditingController _certificationController;

  List<String> _selectedSpecialties = ['Yoga', 'CrossFit'];
  bool _isLoading = true;
  bool _isSaving = false;
  InstructorModel? _currentInstructor;

  final List<String> _availableSpecialties = [
    'Yoga',
    'CrossFit',
    'Boxing',
    'Pilates',
    'HIIT',
    'Strength',
    'Cardio',
    'Mobility',
    'Cycling',
    'Kettlebell',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _avatarController = TextEditingController();
    _experienceController = TextEditingController();
    _certificationController = TextEditingController();
    _loadInstructorData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _avatarController.dispose();
    _experienceController.dispose();
    _certificationController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructorData() async {
    setState(() => _isLoading = true);
    final user = UserSessionService.instance.profile;
    final userName = UserSessionService.instance.displayName;
    final userId = UserSessionService.instance.userId;

    final dummyProfile =
        user ??
        UserProfileModel(
          id: userId.isNotEmpty ? userId : 'inst-me',
          fullName: userName,
          role: UserRole.instructor,
        );

    final instructor = await DatabaseService.instance.getInstructorForProfile(
      dummyProfile,
    );

    if (mounted) {
      setState(() {
        _currentInstructor = instructor;
        _nameController.text = instructor.name;
        _bioController.text = instructor.bio ?? '';
        _avatarController.text = instructor.avatarUrl ?? '';
        _experienceController.text = instructor.yearsExperience;
        _certificationController.text = instructor.certification;
        if (instructor.specialties.isNotEmpty) {
          _selectedSpecialties = List.from(instructor.specialties);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final instructorId =
        _currentInstructor?.id ?? UserSessionService.instance.userId;

    try {
      final updated = await DatabaseService.instance
          .updateInstructorSelfProfile(
            instructorId: instructorId,
            name: _nameController.text.trim(),
            bio: _bioController.text.trim(),
            avatarUrl: _avatarController.text.trim(),
            specialties: _selectedSpecialties,
            yearsExperience: _experienceController.text.trim(),
            certification: _certificationController.text.trim(),
          );

      _currentInstructor = updated;
      UserSessionService.instance.updateProfileLocally(
        fullName: updated.name,
        avatarUrl: updated.avatarUrl,
      );

      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF102534),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF00BCEB), width: 1.2),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF00BCEB),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Profile updated successfully! ✓',
                  style: AppTypography.style(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _previewPublicProfile() {
    if (_currentInstructor == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstructorProfileScreen(instructor: _currentInstructor),
      ),
    );
  }

  void _pickNewAvatar() {
    AvatarImageHelper.showChangePhotoBottomSheet(
      context: context,
      currentUrl: _avatarController.text,
      onPhotoSelected: (newPathOrUrl) {
        setState(() {
          _avatarController.text = newPathOrUrl;
        });
      },
    );
  }

  void _showAddCustomSpecialtyDialog() {
    final customCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161E28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nueva Especialidad',
          style: AppTypography.style(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: customCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ej. Calistenia, Spinning...',
            hintStyle: const TextStyle(color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFF0C1017),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF222C3D)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCEB),
            ),
            onPressed: () {
              final text = customCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (!_availableSpecialties.contains(text)) {
                    _availableSpecialties.add(text);
                  }
                  if (!_selectedSpecialties.contains(text)) {
                    _selectedSpecialties.add(text);
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Agregar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BCEB)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: Stack(
        children: [
          // 1. Hero Background Image con luces de gimnasio
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 310,
            child: Image.network(
              'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=1000',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: const Color(0xFF141C26)),
            ),
          ),

          // 2. Gradiente Oscuro de integración suave
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    const Color(0xFF0C1017).withValues(alpha: 0.85),
                    const Color(0xFF0C1017),
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 3. Contenido Scrolleable del Formulario
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: Logo IRON PULSE + Badge INSTRUCTOR
                    _buildTopHeader(),

                    const SizedBox(height: 32),

                    // Título Principal
                    _buildMainTitle(),

                    const SizedBox(height: 22),

                    // Foto de Perfil Centrada debajo del Título (Galería/Cámara)
                    _buildTopAvatarPickerSection(),

                    const SizedBox(height: 26),

                    // Campo 1: Full Name
                    _buildLabel('Full Name'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _nameController,
                      hintText: 'e.g. Sarah Connor',
                      suffixIcon: Icons.person_outline_rounded,
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // Campo 2: Professional Bio
                    _buildLabel('Professional Bio'),
                    const SizedBox(height: 8),
                    _buildTextareaField(
                      controller: _bioController,
                      hintText:
                          'Brief description of experience and philosophy...',
                      suffixIcon: Icons.article_outlined,
                    ),

                    const SizedBox(height: 20),

                    // Campo 3: Years of Experience
                    _buildLabel('Years of Experience'),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _experienceController,
                      hintText: 'e.g. 5',
                      suffixIcon: Icons.workspace_premium_outlined,
                      keyboardType: TextInputType.text,
                    ),

                    const SizedBox(height: 20),

                    // Campo 4: Specialties
                    _buildLabel('Specialties'),
                    const SizedBox(height: 10),
                    _buildSpecialtiesSection(),

                    const SizedBox(height: 32),

                    // Botón Principal: SAVE PROFILE
                    NeonButton(
                      text: 'SAVE PROFILE',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isSaving,
                      onPressed: _saveChanges,
                    ),

                    const SizedBox(height: 14),

                    // Botón Secundario: Vista Previa Pública
                    GestureDetector(
                      onTap: _previewPublicProfile,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCEB)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00BCEB)
                                .withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.visibility_outlined,
                              color: Color(0xFF00BCEB),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PREVIEW PUBLIC PROFILE',
                              style: AppTypography.style(
                                color: const Color(0xFF00BCEB),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Cerrar Sesión
                    Center(
                      child: TextButton.icon(
                        onPressed: () =>
                            AuthService.instance.showLogoutDialog(context),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFEF4444),
                          size: 17,
                        ),
                        label: Text(
                          'Cerrar Sesión',
                          style: AppTypography.style(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES DE DISEÑO
  // ===========================================================================

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo Circular + Marca IRON PULSE
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCEB).withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00BCEB).withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: Color(0xFF00BCEB),
                  size: 17,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'IRON PULSE',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),

        // Badge INSTRUCTOR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCEB).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00BCEB).withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_rounded,
                size: 13,
                color: Color(0xFF00BCEB),
              ),
              const SizedBox(width: 5),
              Text(
                'INSTRUCTOR',
                style: AppTypography.style(
                  color: const Color(0xFF00BCEB),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.style(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -0.6,
            ),
            children: const [
              TextSpan(
                text: 'Add Instructor\n',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'Profile.',
                style: TextStyle(color: Color(0xFF00BCEB)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a new profile for the team.',
          style: AppTypography.style(
            color: const Color(0xFF94A3B8),
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.style(
        color: Colors.white,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222C3D), width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTypography.style(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF556477),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: InputBorder.none,
          suffixIcon: Icon(
            suffixIcon,
            color: const Color(0xFF64748B),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTextareaField({
    required TextEditingController controller,
    required String hintText,
    required IconData suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141C26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222C3D), width: 1.2),
      ),
      child: Stack(
        children: [
          TextFormField(
            controller: controller,
            minLines: 4,
            maxLines: 6,
            style: AppTypography.style(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF556477),
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 46, 16),
              border: InputBorder.none,
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: Icon(suffixIcon, color: const Color(0xFF64748B), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // 1. Chips Seleccionados (Cian con '✕')
        ..._selectedSpecialties.map((spec) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSpecialties.remove(spec);
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCEB).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF00BCEB), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spec,
                    style: AppTypography.style(
                      color: const Color(0xFF00BCEB),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF00BCEB),
                    size: 14,
                  ),
                ],
              ),
            ),
          );
        }),

        // 2. Chips Disponibles no seleccionados (Gris con '+')
        ..._availableSpecialties
            .where((spec) => !_selectedSpecialties.contains(spec))
            .map((spec) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSpecialties.add(spec);
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141C26),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF222C3D),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        spec,
                        style: AppTypography.style(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF64748B),
                        size: 15,
                      ),
                    ],
                  ),
                ),
              );
            }),

        // 3. Botón para agregar especialidad personalizada
        GestureDetector(
          onTap: _showAddCustomSpecialtyDialog,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161E28),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF00BCEB).withValues(alpha: 0.35),
                style: BorderStyle.solid,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFF00BCEB),
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  'Custom',
                  style: AppTypography.style(
                    color: const Color(0xFF00BCEB),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopAvatarPickerSection() {
    final avatarSource = _avatarController.text.trim();
    final imageProvider = AvatarImageHelper.getAvatarImageProvider(
      avatarSource,
    );

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickNewAvatar,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Anillo exterior con resplandor suave en cian
                Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00BCEB),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BCEB).withValues(alpha: 0.22),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFF161E28),
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : 'I',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                ),

                // Badge de Cámara en la esquina inferior derecha
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCEB),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0C1017),
                        width: 2.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickNewAvatar,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCEB).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00BCEB).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF00BCEB),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cambiar Foto (Galería o Cámara)',
                    style: AppTypography.style(
                      color: const Color(0xFF00BCEB),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
