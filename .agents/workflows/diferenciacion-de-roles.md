---
description: Establecer las diferencias en los roles de creacion de cuentas en la base de datos
---

"Actua como un experto en flutter y supabase.

Analiza la tabla 'Profiles'.
Necesito implementar una logica post-login que:

1. Obtenga el ID del usuario autenticado actual.

2. Realice una consulta a la tabla 'profiles' para obtener el campo 'role'.

3. Guarde este rol en un estado global (o Provider/Riverpod) para que la aplicacion sea consciente de si el usuario es 'admin' o 'cliente'. Asegurate de manejar errores si el perfil no existe.

4. Si el usuario es role: admin debe navegar a la pagina admin_dashboard_screen.dart  
"