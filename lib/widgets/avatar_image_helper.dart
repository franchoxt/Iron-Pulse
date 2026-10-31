import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

/// Utilidad y Widget para la gestión de avatares y fotos de perfil en IRON PULSE.
/// Soporta:
/// 1. Carga desde galería local del dispositivo (`image_picker`).
/// 2. Captura con cámara.
/// 3. URLs remotas (HTTP / HTTPS).
/// 4. Imágenes en base64 / Data URI.
/// 5. Fallback elegante con inicial del usuario o icono deportivo.
class AvatarImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Resuelve un ImageProvider adecuado según el tipo de origen
  static ImageProvider? getAvatarImageProvider(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    final clean = source.trim();

    // 1. Data URI / Base64
    if (clean.startsWith('data:image')) {
      try {
        final commaIdx = clean.indexOf(',');
        final base64Str = commaIdx != -1 ? clean.substring(commaIdx + 1) : clean;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {}
    }

    // 2. URL de red HTTP/HTTPS
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return NetworkImage(clean);
    }

    // 3. Archivo local del dispositivo (elegido de la galería)
    try {
      final file = File(clean);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}

    // Fallback si parece una ruta local
    if (clean.startsWith('/') || clean.contains(Platform.pathSeparator) || clean.startsWith('file:')) {
      final path = clean.replaceFirst('file://', '');
      return FileImage(File(path));
    }

    return NetworkImage(clean);
  }

  /// Selecciona una foto desde la galería del dispositivo
  static Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image?.path;
    } catch (e) {
      debugPrint('Error seleccionando imagen de galería: $e');
      return null;
    }
  }

  /// Captura una foto usando la cámara del dispositivo
  static Future<String?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image?.path;
    } catch (e) {
      debugPrint('Error capturando foto con cámara: $e');
      return null;
    }
  }

  /// Modal estilizado para cambiar foto de perfil con opciones (Galería, Cámara, URL)
  static void showChangePhotoBottomSheet({
    required BuildContext context,
    required ValueChanged<String> onPhotoSelected,
    String? currentUrl,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141C26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF222C3D), width: 1),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra superior de arrastre
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Cambiar Foto de Perfil',
                  style: AppTypography.style(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elige una imagen desde tu dispositivo o toma una nueva foto.',
                  style: AppTypography.style(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),

                // Opción 1: Elegir de la Galería
                _buildActionTile(
                  context: ctx,
                  icon: Icons.photo_library_rounded,
                  title: 'Elegir de la Galería',
                  subtitle: 'Selecciona una foto guardada en tu dispositivo',
                  color: const Color(0xFF00BCEB),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final path = await pickFromGallery();
                    if (path != null && path.isNotEmpty) {
                      onPhotoSelected(path);
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Opción 2: Tomar Foto con Cámara
                _buildActionTile(
                  context: ctx,
                  icon: Icons.camera_alt_rounded,
                  title: 'Tomar Foto',
                  subtitle: 'Usa la cámara de tu teléfono para una nueva foto',
                  color: const Color(0xFF22C55E),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final path = await pickFromCamera();
                    if (path != null && path.isNotEmpty) {
                      onPhotoSelected(path);
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Opción 3: Introducir URL web
                _buildActionTile(
                  context: ctx,
                  icon: Icons.link_rounded,
                  title: 'Introducir Enlace / URL',
                  subtitle: 'Usa una imagen pública de internet',
                  color: const Color(0xFFA855F7),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showUrlInputDialog(context, onPhotoSelected, currentUrl);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2433),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.style(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 14),
          ],
        ),
      ),
    );
  }

  static void _showUrlInputDialog(
    BuildContext context,
    ValueChanged<String> onPhotoSelected,
    String? currentUrl,
  ) {
    final controller = TextEditingController(text: currentUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161E28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'URL de Imagen',
          style: AppTypography.style(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'https://images.unsplash.com/...',
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
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCEB)),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onPhotoSelected(text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

