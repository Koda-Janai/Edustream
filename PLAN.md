# Plan de desarrollo de Edustream

## Implementado en código

Edustream tiene un target de aplicación SwiftUI con los módulos Biblioteca y Cuenta. Los modelos compartidos son `Leccion` y `Perfil`. Los consumen las vistas a través del servicio común `FirebaseEdustream`. La navegación permite explorar temas, buscar por título, tema y área, filtrar por nivel, abrir detalle y lector, responder quizzes y editar el perfil. El contenido editorial incluye once microlecciones que se publican en Firestore.

La narración lee en español de México, permite pausar y continuar, y aplica al texto los rangos que emite AVFoundation. Guarda el fragmento más avanzado al progresar. El registro vincula la sesión de invitado a una credencial de correo para preservar el UID y sus datos.

## Modelo de datos e idempotencia

| Ruta | Datos | Comportamiento de un reintento |
|---|---|---|
| `lessons/{id}` | Campos de `Leccion` | El publicador crea documentos faltantes y conserva los existentes. |
| `users/{uid}/lessonProgress/{id}` | `completedAt` del servidor | Se crea una vez. La primera fecha se conserva. |
| `users/{uid}/readingProgress/{id}` | `position` | Se conserva el índice máximo incluso con solicitudes desordenadas. |
| `users/{uid}/quizAttempts/{uuid}` | `lessonId`, `answer`, `submittedAt` del servidor | Se crea una vez por tentativa. El UUID y la respuesta de un envío pendiente se guardan localmente hasta confirmación. |

Las transacciones y reglas protegen esas invariantes. Las reglas también limitan el avance a su propietario y comprueban que la lección y la respuesta existan. El perfil visible se guarda en la cuenta de Firebase Auth.

## Validación y entrega

1. Ejecutar el catálogo, las reglas y las transacciones con los emuladores locales. Ejecutar el XCTest del servicio real sin usar credenciales de producción.
2. Regenerar el proyecto Xcode, compilar y recorrer cada flujo en simulador. Probar voz, tamaño de texto y VoiceOver en un iPhone.
3. Comparar pantallas con Figma, aplicar los recursos y valores exactos aprobados y verificar la adaptación a tamaños de pantalla.
4. Revisar los proveedores de Auth y las reglas del proyecto real. Agregar el plist iOS autorizado y publicar las once lecciones. Probar con cuentas de prueba antes de distribuir una beta.

Los comandos y los requisitos de cada entorno están en el [README](README.md).
