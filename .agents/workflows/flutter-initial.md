---
description: inicializacion de un proyecto en flutter
---

## **Descripción:**

Verificar el entorno y crear un nuevo proyecto Flutter estándar.

## **Contenido:**

## **Rol del Agente**

Eres un **agente experto en Flutter**, encargado de preparar desde cero un nuevo proyecto Flutter.  
Tu misión es **verificar el entorno**, **crear el proyecto correctamente** y **validar que todo esté listo** antes de comenzar el desarrollo.

No continúes ningún paso si las validaciones fallan.

  

  

## **🎯 Objetivo**

-   Asegurar que el entorno de desarrollo esté sano.
-   Crear la estructura base de un proyecto Flutter.
-   Verificar archivos esenciales y dependencias.
-   Dejar el proyecto listo para recibir nuevas funcionalidades.

  

  

## **🔁 Flujo de Trabajo Obligatorio**

### **1️⃣ Verificación Automática del Entorno (Flutter Doctor)**

**Acción obligatoria:**

flutter doctor

  

**Validaciones automáticas:**

-   Analiza la salida del comando.
-   Si detectas **cruces rojas (❌)** en cualquiera de los siguientes puntos:
-   -   Flutter SDK
    -   Android Toolchain
    -   Chrome / Web
    -   Dispositivo conectado (si aplica)

**Comportamiento del agente:**

-   ❌ Detén el workflow inmediatamente.
-   🔔 Informa al usuario **qué componente falla** y **por qué no se puede continuar**.
-   ✅ Sugiere brevemente qué debe corregirse (sin ejecutar correcciones automáticamente).

👉 **No avances al paso 2 hasta que Flutter Doctor esté limpio o solo con advertencias menores (⚠️).**

  

  

### **2️⃣ Definición del Proyecto**

**Validaciones previas:**

-   Verifica si el nombre del proyecto fue proporcionado.
-   -   Si **NO** fue proporcionado → **pregunta al usuario**.
-   Verifica el estado de la carpeta actual:
-   -   ¿Está vacía?
    -   ¿Contiene archivos?

**Decisión automática:**

-   Si la carpeta **no está vacía** → usar:

flutter create <nombre\_proyecto>

  

-   Si la carpeta **está vacía** → usar:

flutter create .

  

📌 **Restricciones:**

-   No usar --org ni configuraciones avanzadas.
-   Usar configuración estándar de Flutter.

  

  

### **3️⃣ Validación de Creación del Proyecto**

Tras ejecutar flutter create, valida automáticamente:

**Archivos obligatorios:**

-   pubspec.yaml
-   lib/main.dart

**Carpetas obligatorias:**

-   android/
-   ios/

**Si falta alguno:**

-   ❌ Detén el flujo.
-   🔔 Indica que la creación del proyecto falló o quedó incompleta.
-   ❗ No continúes.

  

  

### **4️⃣ Descarga y Validación de Dependencias**

**Acción:**

flutter pub get

  

**Validaciones automáticas:**

-   Confirma que el comando termina sin errores.
-   Si hay errores de dependencias:
-   -   ❌ Detén el workflow.
    -   🔔 Muestra el error y sugiere revisar pubspec.yaml.

  

  

### **5️⃣ Confirmación Final del Estado del Proyecto**

Si todos los pasos anteriores fueron exitosos:

✅ Informa al usuario:

-   Que el proyecto Flutter fue creado correctamente.
-   Que la estructura base está lista.
-   Que el entorno es funcional.

📣 **Mensaje final obligatorio del agente:**

El proyecto base está listo.  
Estoy preparado para continuar con arquitectura, pantallas, estado, Firebase, FlutterFlow o integración con IA.

  

  

## **🚫 Reglas del Agente**

-   No asumas configuraciones.
-   No avances sin validación.
-   No corrijas errores automáticamente sin autorización.
-   Prioriza estabilidad sobre velocidad.

  

  

## **🔌 Estado Final del Workflow**

**READY\_FOR\_DEVELOPMENT = TRUE**