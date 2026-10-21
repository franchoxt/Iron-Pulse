---
trigger: always_on
---

IRON PULSE - Guía de Estilo y Reglas de Diseño

Este documento define las reglas visuales y estructurales para la aplicación IRON PULSE. Cualquier nueva página o componente debe seguir estas directrices para mantener la consistencia de la marca.

1. Identidad Visual y Concepto

IRON PULSE es una plataforma de fitness de alto rendimiento. El diseño debe transmitir energía, limpieza, modernidad y profesionalismo.

Enfoque: Mobile-First (Diseño optimizado para dispositivos móviles).

Estética: Bordes muy redondeados, alto contraste, iconografía clara y espacios generosos.

2. Paleta de Colores

Colores Principales

Azul Primario (Acción): #3B82F6 (Blue-500) - Utilizado para botones principales, estados activos y elementos destacados.

Fondo de Aplicación (Light): #F8FAFC (Slate-50) - Un gris casi blanco para limpieza visual.

Fondo de Aplicación (Dark): #0F172A (Slate-900).

Colores de Estado

Éxito / Confirmado: #22C55E (Green-500).

Alerta / Espera: #F59E0B (Amber-500).

Error / Cancelado: #EF4444 (Red-500).

Intensidad Alta: #7C3AED (Violet-600).

Texto

Primario: #1E293B (Slate-800) para títulos.

Secundario: #64748B (Slate-500) para descripciones y subtítulos.

3. Tipografía

Fuente: Sin-Serif moderna (Preferiblemente Inter, Roboto o SF Pro).

Títulos (Headings):

Peso: Bold (700) o ExtraBold (800).

Tracking: Ligeramente ajustado (-0.02em).

Cuerpo (Body):

Peso: Regular (400) o Medium (500).

Tamaño base: 16px.

4. Componentes Clave

A. Tarjetas (Cards)

Bordes: rounded-3xl (aproximadamente 24px).

Sombra: shadow-sm o shadow-md muy sutil (color de sombra: rgba(0,0,0,0.05)).

Padding: p-4 o p-6 según el contenido.

B. Botones

Principales: Fondo azul, texto blanco, bordes redondeados (rounded-2xl), altura mínima de 48px para facilitar el toque táctil.

Secundarios/Chips: Fondo gris claro (Slate-100), texto oscuro, bordes redondos (rounded-full).

C. Navegación

Barra Superior: Título centrado o alineado a la izquierda con botón de "Atrás" minimalista.

Barra Inferior (Bottom Nav): 4 a 5 iconos máximo. Icono activo en color Azul Primario, inactivos en Slate-400.

5. Iconografía

Librería: Lucide React o Phosphor Icons.

Estilo: Trazo (Outline) con grosor de 2px.

Uso: Siempre acompañados de texto o en contextos muy claros para evitar confusión.

6. Layout y Espaciado

Márgenes Laterales: px-4 o px-6.

Espaciado Vertical: Usar escala de 4 (4px, 8px, 16px, 24px, 32px).

Listas: Los elementos de lista deben tener un separador sutil o un espacio de 12px entre ellos.

7. Reglas Específicas de UX

Feedback Inmediato: Cada acción (clic en reserva, check-in) debe mostrar un cambio de estado visual o un mensaje de confirmación.

Jerarquía Visual: Los precios y horarios deben destacar sobre la descripción de la clase.

Imágenes: Usar fotos de alta calidad con un ligero overlay oscuro si llevan texto encima para asegurar la legibilidad.

8. Glosario de Intensidades

Low: Chip Verde.

Medium: Chip Azul/Naranja.

High: Chip Púrpura/Rojo.
