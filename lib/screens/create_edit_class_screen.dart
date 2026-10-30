import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Pantalla para Crear o Editar una Clase en IRON PULSE.
///
/// Si [scheduleToEdit] es null, opera en modo CREAR CLASE.
/// Si [scheduleToEdit] contiene un horario existente, opera en modo EDITAR CLASE
/// permitiendo modificar todos sus campos y eliminar la clase.
class CreateEditClassScreen extends StatefulWidget {
  final ClassScheduleModel? scheduleToEdit;

  const CreateEditClassScreen({
    super.key,
    this.scheduleToEdit,
  });

  /// Constructor de conveniencia explícito para Crear
  const CreateEditClassScreen.create({super.key}) : scheduleToEdit = null;

  /// Constructor de conveniencia explícito para Editar
  const CreateEditClassScreen.edit({
    super.key,
    required ClassScheduleModel schedule,
  }) : scheduleToEdit = schedule;

  @override
  State<CreateEditClassScreen> createState() => _CreateEditClassScreenState();
}

class _CreateEditClassScreenState extends State<CreateEditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _customInstructorController;

  late String _coverImageUrl;
  late ClassIntensity _selectedIntensity;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _maxCapacity;
  String? _selectedInstructorId;
  InstructorModel? _selectedInstructor;
  List<InstructorModel> _availableInstructors = [];
  bool _isLoadingInstructors = true;
  bool _isCustomInstructor = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEditMode => widget.scheduleToEdit != null;

  static const List<Map<String, String>> _presetCovers = [
    {
      'title': 'HIIT Morning Blast',
      'url':
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800',
    },
    {
      'title': 'CrossFit WOD',
      'url':
          'https://images.unsplash.com/photo-1534367507873-d2d7e24c797f?w=800',
    },
    {
      'title': 'Power Yoga & Flow',
      'url':
          'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
    },
    {
      'title': 'Strength & Olympic Barbell',
      'url':
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800',
    },
    {
      'title': 'Boxing & Conditioning',
      'url':
          'https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?w=800',
    },
  ];

  @override
  void initState() {
    super.initState();
    final schedule = widget.scheduleToEdit;

    _nameController = TextEditingController(
      text: schedule?.gymClass?.name ?? 'HIIT Morning Blast',
    );
    _descriptionController = TextEditingController(
      text: schedule?.gymClass?.description ??
          'High-Intensity interval training designed to boost your metabolism and build lean muscle.',
    );

    _coverImageUrl = schedule?.gymClass?.imageUrl ?? _presetCovers.first['url']!;
    _selectedIntensity = schedule?.gymClass?.intensity ?? ClassIntensity.medium;
    _imageUrlController = TextEditingController(text: _coverImageUrl);
    _customInstructorController = TextEditingController();

    _selectedDate = schedule?.startTime ?? DateTime.now().add(const Duration(days: 1));
    _startTime = schedule != null
        ? TimeOfDay.fromDateTime(schedule.startTime)
        : const TimeOfDay(hour: 7, minute: 0);
    _endTime = schedule != null
        ? TimeOfDay.fromDateTime(schedule.endTime)
        : const TimeOfDay(hour: 8, minute: 0);
    _maxCapacity = schedule?.capacity ?? 30;

    _selectedInstructorId = schedule?.instructorId;
    _selectedInstructor = schedule?.instructor;

    _loadInstructors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _customInstructorController.dispose();
    super.dispose();
  }

  Future<void> _loadInstructors() async {
    try {
      final instructors = await DatabaseService.instance.getInstructors();
      if (mounted) {
        setState(() {
          _availableInstructors = instructors;
          _isLoadingInstructors = false;

          if (_selectedInstructor == null && instructors.isNotEmpty) {
            if (_selectedInstructorId != null) {
              _selectedInstructor = instructors.firstWhere(
                (i) => i.id == _selectedInstructorId,
                orElse: () => instructors.first,
              );
            } else {
              _selectedInstructor = instructors.first;
              _selectedInstructorId = _selectedInstructor!.id;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingInstructors = false);
      }
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryCyan,
              onPrimary: Colors.black,
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
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryCyan,
              onPrimary: Colors.black,
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
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _showImagePickerSheet() {
    final urlController = TextEditingController(text: _coverImageUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Seleccionar Portada de Clase',
                style: AppTypography.style(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Portadas recomendadas:',
                style: AppTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 95,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetCovers.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final preset = _presetCovers[index];
                    final isSelected = preset['url'] == _coverImageUrl;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _coverImageUrl = preset['url']!;
                          _imageUrlController.text = preset['url']!;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryCyan
                                : const Color(0xFF2B374A),
                            width: isSelected ? 2 : 1,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(preset['url']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(15),
                            ),
                          ),
                          child: Text(
                            preset['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'O ingresa una URL personalizada:',
                style: AppTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'https://images.unsplash.com/...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFF182232),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF2B374A)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF2B374A)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primaryCyan),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final url = urlController.text.trim();
                      if (url.isNotEmpty) {
                        setState(() {
                          _coverImageUrl = url;
                          _imageUrlController.text = url;
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final effectiveImageUrl = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : _coverImageUrl;
    final instructorId = _selectedInstructor?.id ??
        (_availableInstructors.isNotEmpty ? _availableInstructors.first.id : 'inst-1');

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    var endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = startDateTime.add(const Duration(minutes: 60));
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        // Modo EDITAR
        final schedule = widget.scheduleToEdit!;
        final updated = await DatabaseService.instance.updateClassSchedule(
          scheduleId: schedule.id,
          classId: schedule.classId,
          name: name,
          description: description,
          imageUrl: effectiveImageUrl,
          instructorId: instructorId,
          startTime: startDateTime,
          endTime: endDateTime,
          capacity: _maxCapacity,
          intensity: _selectedIntensity,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF102534),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.primaryCyan, width: 1.2),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primaryCyan,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Clase "$name" actualizada correctamente.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );

        Navigator.of(context).pop(updated);
      } else {
        // Modo CREAR
        final created = await DatabaseService.instance.createClassSchedule(
          name: name,
          description: description,
          imageUrl: effectiveImageUrl,
          instructorId: instructorId,
          startTime: startDateTime,
          endTime: endDateTime,
          capacity: _maxCapacity,
          intensity: _selectedIntensity,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF102534),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.primaryCyan, width: 1.2),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primaryCyan,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Clase "$name" creada exitosamente!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );

        Navigator.of(context).pop(created);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2B1417),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFFF4D4D), width: 1.2),
          ),
          content: Text('Error al guardar la clase: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final schedule = widget.scheduleToEdit;
    if (schedule == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131924),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF2B374A), width: 1),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text(
                '¿Eliminar Clase?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar permanentemente la clase "${_nameController.text}" y su horario programado?',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await DatabaseService.instance.deleteClassSchedule(
        schedule.id,
        classId: schedule.classId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2B1417),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
          ),
          content: const Text('Clase eliminada con éxito.'),
        ),
      );

      Navigator.of(context).pop({'deleted': true, 'scheduleId': schedule.id});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2B1417),
          content: Text('Error al eliminar clase: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotsAvailable = _maxCapacity - (widget.scheduleToEdit?.confirmedBookingsCount ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Barra Superior (Cancel | Create/Edit Class | Indicador)
            _buildTopBar(),

            // 2. Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Portada de Clase (Tap to upload cover)
                      _buildCoverImageSection(),

                      const SizedBox(height: 20),

                      // Campo: Class Name
                      _buildLabel('Class Name'),
                      const SizedBox(height: 8),
                      _buildClassNameField(),

                      const SizedBox(height: 20),

                      // Campo: Instructor
                      _buildLabel('Instructor'),
                      const SizedBox(height: 8),
                      _buildInstructorSelector(),

                      const SizedBox(height: 20),

                      // Campo: Description
                      _buildLabel('Description'),
                      const SizedBox(height: 8),
                      _buildDescriptionField(),

                      const SizedBox(height: 20),

                      // Campo: Intensidad de los ejercicios (Bajo, Medio, Alto)
                      _buildLabel('Intensidad de la Clase (Intensity)'),
                      const SizedBox(height: 8),
                      _buildIntensitySelector(),

                      const SizedBox(height: 20),

                      // Campo: Date
                      _buildLabel('Date'),
                      const SizedBox(height: 8),
                      _buildDatePickerField(),

                      const SizedBox(height: 20),

                      // Campos: Start Time & End Time
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Start Time'),
                                const SizedBox(height: 8),
                                _buildTimePickerField(
                                  time: _startTime,
                                  isStart: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('End Time'),
                                const SizedBox(height: 8),
                                _buildTimePickerField(
                                  time: _endTime,
                                  isStart: false,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Campo: Max Capacity (con 25 spots available a la derecha)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel('Max Capacity'),
                          Text(
                            '$spotsAvailable spots available',
                            style: AppTypography.style(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryCyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildCapacityCounter(),

                      const SizedBox(height: 32),

                      // Botón Principal: Save Changes / Create Class
                      _buildSaveButton(),

                      // Botón Secundario: Delete Class (solo en modo edición)
                      if (_isEditMode) ...[
                        const SizedBox(height: 16),
                        _buildDeleteButton(),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES
  // ===========================================================================

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1017),
        border: Border(
          bottom: BorderSide(color: Color(0xFF192231), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Cancel
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Text(
              'Cancel',
              style: AppTypography.style(
                color: const Color(0xFF5B8CAE),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Título Centrado
          Text(
            _isEditMode ? 'Edit Class' : 'Create Class',
            style: AppTypography.style(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),

          // Espaciador balanceador
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.style(
        color: const Color(0xFF6E84A3),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildCoverImageSection() {
    final previewUrl = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : _coverImageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Tarjeta con imagen de portada y overlay
        GestureDetector(
          onTap: _showImagePickerSheet,
          child: Container(
            height: 175,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF222C3D), width: 1.2),
              image: DecorationImage(
                image: NetworkImage(previewUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.black.withValues(alpha: 0.42),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload cover',
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Vista Previa',
                        style: AppTypography.style(
                          color: AppColors.primaryCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 2. Campo explícito para URL de la imagen
        _buildLabel('Imagen Identificadora de la Clase (URL o Preset)'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131924),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF202A3B), width: 1.2),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Icon(Icons.link_rounded, color: AppColors.primaryCyan, size: 20),
              ),
              Expanded(
                child: TextFormField(
                  controller: _imageUrlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'https://images.unsplash.com/...',
                    hintStyle: TextStyle(color: Color(0xFF55657E), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (val) {
                    if (val.trim().isNotEmpty) {
                      setState(() {
                        _coverImageUrl = val.trim();
                      });
                    }
                  },
                ),
              ),
              GestureDetector(
                onTap: _showImagePickerSheet,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.collections_rounded, color: AppColors.primaryCyan, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Galería',
                        style: AppTypography.style(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 3. Mini presets rápidos de 1-toque
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _presetCovers.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = _presetCovers[index];
              final isSelected = preset['url'] == previewUrl;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _coverImageUrl = preset['url']!;
                    _imageUrlController.text = preset['url']!;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryCyan.withValues(alpha: 0.15)
                        : const Color(0xFF131924),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryCyan : const Color(0xFF222C3D),
                    ),
                  ),
                  child: Text(
                    preset['title']!,
                    style: AppTypography.style(
                      color: isSelected ? AppColors.primaryCyan : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClassNameField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131924),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF202A3B), width: 1.2),
      ),
      child: TextFormField(
        controller: _nameController,
        style: AppTypography.style(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Ingresa el nombre de la clase' : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: 'Ej. HIIT Morning Blast',
          hintStyle: const TextStyle(color: Color(0xFF55657E), fontSize: 14),
          suffixIcon: const Icon(
            Icons.open_in_full_rounded,
            color: Color(0xFF4A5A72),
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorSelector() {
    final currentSelectedValue = _isCustomInstructor
        ? 'custom'
        : (_availableInstructors.any((i) => i.id == _selectedInstructorId)
            ? _selectedInstructorId
            : (_availableInstructors.isNotEmpty ? _availableInstructors.first.id : null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131924),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF202A3B), width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: currentSelectedValue,
              dropdownColor: const Color(0xFF131924),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryCyan,
                size: 24,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              hint: Text(
                _isLoadingInstructors ? 'Cargando instructores...' : 'Selecciona un instructor',
                style: const TextStyle(color: Color(0xFF55657E), fontSize: 14),
              ),
              items: [
                ..._availableInstructors.map((instructor) {
                  return DropdownMenuItem<String>(
                    value: instructor.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            instructor.avatarUrl ??
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 30,
                              height: 30,
                              color: const Color(0xFF243248),
                              child: const Icon(Icons.person, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          instructor.name,
                          style: AppTypography.style(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                DropdownMenuItem<String>(
                  value: 'custom',
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: AppColors.primaryCyan,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ingresar otro instructor...',
                        style: AppTypography.style(
                          color: AppColors.primaryCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (newVal) {
                if (newVal == 'custom') {
                  setState(() {
                    _isCustomInstructor = true;
                  });
                } else if (newVal != null) {
                  setState(() {
                    _isCustomInstructor = false;
                    _selectedInstructorId = newVal;
                    _selectedInstructor = _availableInstructors.firstWhere((i) => i.id == newVal);
                  });
                }
              },
            ),
          ),
        ),
        if (_isCustomInstructor) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131924),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryCyan, width: 1.2),
            ),
            child: TextFormField(
              controller: _customInstructorController,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primaryCyan, size: 20),
                hintText: 'Nombre del nuevo instructor (ej. Carlos Mendoza)',
                hintStyle: TextStyle(color: Color(0xFF55657E), fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (val) {
                if (_isCustomInstructor && (val == null || val.trim().isEmpty)) {
                  return 'Por favor ingresa el nombre del instructor';
                }
                return null;
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131924),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF202A3B), width: 1.2),
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            minLines: 3,
            style: AppTypography.style(
              color: const Color(0xFFCBD5E1),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa la descripción del contenido de la clase' : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintText:
                  'Escribe los detalles y objetivos de la clase (ej. Rutina de alta intensidad por intervalos para quemar calorías, fortalecer el core y mejorar la resistencia cardiovascular. Requiere toalla y calzado deportivo)...',
              hintStyle: TextStyle(color: Color(0xFF55657E), fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntensitySelector() {
    return Row(
      children: [
        // Cuadro 1: Bajo (Low) - Verde
        Expanded(
          child: _buildIntensityBox(
            intensity: ClassIntensity.low,
            title: 'Bajo',
            subtitle: 'Low',
            color: AppColors.intensityLow,
            icon: Icons.spa_outlined,
          ),
        ),
        const SizedBox(width: 10),
        // Cuadro 2: Medio (Medium) - Azul
        Expanded(
          child: _buildIntensityBox(
            intensity: ClassIntensity.medium,
            title: 'Medio',
            subtitle: 'Medium',
            color: AppColors.intensityMedium,
            icon: Icons.bolt_rounded,
          ),
        ),
        const SizedBox(width: 10),
        // Cuadro 3: Alto (High) - Púrpura
        Expanded(
          child: _buildIntensityBox(
            intensity: ClassIntensity.high,
            title: 'Alto',
            subtitle: 'High',
            color: AppColors.intensityHigh,
            icon: Icons.local_fire_department_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildIntensityBox({
    required ClassIntensity intensity,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedIntensity == intensity;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIntensity = intensity;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : const Color(0xFF131924),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF202A3B),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono superior con círculo contenedor
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.22)
                    : const Color(0xFF1B2332),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.6)
                      : const Color(0xFF2B364A),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            // Título principal en español (Bajo, Medio, Alto)
            Text(
              title,
              style: AppTypography.style(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            // Badge / Subtítulo con el valor exacto de la base de datos (Low, Medium, High)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.25)
                    : const Color(0xFF1A2230),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                subtitle,
                style: AppTypography.style(
                  color: isSelected ? color : const Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Indicador de selección (Radio check circle)
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : const Color(0xFF475569),
                  width: isSelected ? 4.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131924),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF202A3B), width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primaryCyan,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              _formatDate(_selectedDate),
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: Color(0xFF5A6E88),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerField({
    required TimeOfDay time,
    required bool isStart,
  }) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return GestureDetector(
      onTap: () => _pickTime(isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131924),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF202A3B), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${hour.toString().padLeft(2, '0')}:$minute',
              style: AppTypography.style(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              period,
              style: AppTypography.style(
                color: const Color(0xFF6E84A3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131924),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF202A3B), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Menos (-)
          GestureDetector(
            onTap: _maxCapacity > 1
                ? () {
                    setState(() {
                      _maxCapacity--;
                    });
                  }
                : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2230),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C394E)),
              ),
              child: const Icon(
                Icons.remove_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          // Número Central
          Text(
            '$_maxCapacity',
            style: AppTypography.style(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          // Botón Más (+) en Cyan
          GestureDetector(
            onTap: () {
              setState(() {
                _maxCapacity++;
              });
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryCyan,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryCyan,
          foregroundColor: Colors.black,
          elevation: 6,
          shadowColor: AppColors.primaryCyan.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isEditMode ? 'Save Changes' : 'Create Class',
                    style: AppTypography.style(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _isDeleting ? null : _handleDelete,
        icon: _isDeleting
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFEF4444),
                ),
              )
            : const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
        label: Text(
          'Delete Class',
          style: AppTypography.style(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFEF4444),
          ),
        ),
      ),
    );
  }
}
