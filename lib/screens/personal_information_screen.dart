import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_session_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de Información Personal / Edit Profile para IRON PULSE.
///
/// Reproduce con fidelidad el diseño de la imagen:
/// - Barra superior con botón circular de retroceso y título "Edit Profile".
/// - Avatar centrado con anillo teal oscuro y superposición con icono de cámara + "EDIT PHOTO".
/// - Selector/modal para cambiar la foto de perfil (avatares fitness predeterminados o URL).
/// - Campos de formulario con diseño estilizado:
///   • FULL NAME
///   • EMAIL ADDRESS
///   • PHONE NUMBER
///   • DATE OF BIRTH (con selector de fecha e icono de calendario)
/// - Botón inferior de acción "Save Changes" en Cyan vibrante.
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;

  DateTime? _selectedDate;
  String? _avatarUrl;
  bool _isSaving = false;

  // Lista de avatares fitness predeterminados
  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', // Javier atleta
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', // Atleta femenina
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400', // Retrato deportivo
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400', // Fitness pro
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400', // CrossFit atleta
    'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400', // Gimnasio entrenamiento
  ];

  @override
  void initState() {
    super.initState();
    final userSession = UserSessionService.instance;
    final currentUser = AuthService.instance.currentUser;
    final meta = currentUser?.userMetadata;

    // Nombre completo inicial
    final initialName =
        userSession.displayName.isNotEmpty &&
            userSession.displayName != 'Atleta' &&
            userSession.displayName != 'Admin'
        ? userSession.displayName
        : 'Javier Mendez';

    // Email inicial
    final initialEmail =
        currentUser?.email?.isNotEmpty == true
            ? currentUser!.email!
            : 'javier.mendez@example.com';

    // Teléfono inicial (de metadata o fallback exacto al diseño)
    final initialPhone =
        (meta?['phone_number'] as String?)?.isNotEmpty == true
            ? (meta!['phone_number'] as String)
            : '+1 (555) 012-3456';

    // Fecha de nacimiento inicial (de metadata o fallback exacto al diseño "March 12, 1994")
    final rawDob = meta?['date_of_birth'] as String?;
    if (rawDob != null && rawDob.isNotEmpty) {
      _selectedDate = DateTime.tryParse(rawDob);
    }
    _selectedDate ??= DateTime(1994, 3, 12);

    _nameController = TextEditingController(text: initialName);
    _emailController = TextEditingController(text: initialEmail);
    _phoneController = TextEditingController(text: initialPhone);
    _dobController = TextEditingController(
      text: _formatDateToDisplay(_selectedDate!),
    );

    _avatarUrl = userSession.profile?.avatarUrl ?? _presetAvatars[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  String _formatDateToDisplay(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthName = months[date.month - 1];
    return '$monthName ${date.day}, ${date.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1994, 3, 12),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00BCEB),
              onPrimary: Colors.white,
              surface: Color(0xFF131924),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF131924),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = _formatDateToDisplay(picked);
      });
    }
  }

  void _showChangePhotoModal() {
    final urlController = TextEditingController();
    String tempSelected = _avatarUrl ?? _presetAvatars[0];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF131924),
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
                  width: 40,
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
                    'Cambiar Foto de Perfil',
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Selecciona un avatar o escribe una URL:',
                style: AppTypography.style(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Vista previa
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00BCEB),
                      width: 2.4,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(
                      tempSelected,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF161E28),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF00BCEB),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Grid de avatares predeterminados
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetAvatars.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final url = _presetAvatars[index];
                    final isSelected = tempSelected == url;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          tempSelected = url;
                          urlController.clear();
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00BCEB)
                                : const Color(0xFF222C3D),
                            width: isSelected ? 2.5 : 1.2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Campo para URL personalizada
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'O pega aquí el enlace de tu foto...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF161E28),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF222C3D)),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF00BCEB)),
                    onPressed: () {
                      if (urlController.text.trim().isNotEmpty) {
                        setModalState(() {
                          tempSelected = urlController.text.trim();
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón Aplicar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCEB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _avatarUrl = tempSelected;
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text(
                    'Aplicar Foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();
    final avatarToSave = _avatarUrl ?? _presetAvatars[0];
    final dobIso = _selectedDate?.toIso8601String();

    try {
      // 1. Actualizar en Supabase profiles (full_name, avatar_url)
      final success = await DatabaseService.instance.updateUserProfile(
        fullName: newName,
        avatarUrl: avatarToSave,
      );

      // 2. Actualizar estado local reactivo
      UserSessionService.instance.updateProfileLocally(
        fullName: newName,
        avatarUrl: avatarToSave,
      );

      // 3. Guardar metadatos en Supabase auth si está disponible
      if (SupabaseConfig.isConfigured) {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': newName,
                'phone_number': newPhone,
                'date_of_birth': ?dobIso,
              },
            ),
          );
        } catch (e) {
          debugPrint('Aviso al guardar metadata en Supabase auth: $e');
        }
      }

      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF131924),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00BCEB), width: 1.2),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00BCEB),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Perfil actualizado con éxito.'
                      : 'Cambios guardados localmente.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Error al guardar cambios: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Barra superior: Botón Atrás circular + Título "Edit Profile"
            _buildHeader(),

            // 2. Contenido desplazable con Formulario
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),

                      // Avatar centrado con overlay "EDIT PHOTO"
                      _buildAvatarSection(),

                      const SizedBox(height: 32),

                      // Campo 1: FULL NAME
                      _buildFormField(
                        label: 'FULL NAME',
                        child: TextFormField(
                          controller: _nameController,
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _inputDecoration(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre no puede estar vacío';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Campo 2: EMAIL ADDRESS
                      _buildFormField(
                        label: 'EMAIL ADDRESS',
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _inputDecoration(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Campo 3: PHONE NUMBER
                      _buildFormField(
                        label: 'PHONE NUMBER',
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: _inputDecoration(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Campo 4: DATE OF BIRTH
                      _buildFormField(
                        label: 'DATE OF BIRTH',
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(16),
                          child: IgnorePointer(
                            child: TextFormField(
                              controller: _dobController,
                              style: AppTypography.style(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _inputDecoration(
                                suffixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Botón inferior fijo "Save Changes"
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES
  // ===========================================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Botón circular de retroceso
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF161E28),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF222E3E),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Título de la pantalla
          Text(
            'Edit Profile',
            style: AppTypography.style(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: GestureDetector(
        onTap: _showChangePhotoModal,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anillo exterior color teal oscuro como en la imagen
            Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0F3B46),
                  width: 3.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.network(
                    _avatarUrl ?? _presetAvatars[0],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF161E28),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF00BCEB),
                        size: 54,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Overlay semitransparente con icono de cámara y texto "EDIT PHOTO"
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.42),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EDIT PHOTO',
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.style(
            color: const Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF161E28),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF222E3E), width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF222E3E), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00BCEB), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BCEB),
            elevation: 4,
            shadowColor: const Color(0xFF00BCEB).withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: _isSaving ? null : _saveChanges,
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Save Changes',
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
