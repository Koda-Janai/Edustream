# Edustream

Aplicación iOS en SwiftUI. Biblioteca vive en el target Edustream y comparte sus modelos y su servicio Firebase. Ofrece 11 temas, destacados, búsqueda por título, tema o área, filtro por nivel, lector con voz y resaltado, quizzes, perfil y avance guardado. [Referencia visual en Figma](https://www.figma.com/design/aTMtzR7Ppk6f9Iya5Gyuo2/Programaci%C3%B3nFigmaMatenme?node-id=0-1&p=f)

## Ubicación de los archivos Swift

| Ruta | Responsabilidad |
|---|---|
| [App/EdustreamApp.swift](App/EdustreamApp.swift) | Inicialización, sesión y navegación Inicio–Perfil |
| [App/Models/Leccion.swift](App/Models/Leccion.swift) | Modelo compartido de las lecciones que consulta Firestore |
| [App/Models/Perfil.swift](App/Models/Perfil.swift) | Identidad usada por la sesión y las vistas de cuenta |
| [App/Models/IntentoPendiente.swift](App/Models/IntentoPendiente.swift) | ID y respuesta de un envío pendiente de confirmación |
| [App/Services/FirebaseEdustream.swift](App/Services/FirebaseEdustream.swift) | Auth, catálogo y operaciones de progreso |
| [App/Services/FirebaseEmulador.swift](App/Services/FirebaseEmulador.swift) | Configuración local exclusiva de Debug |
| [App/Services/BibliotecaNarracion.swift](App/Services/BibliotecaNarracion.swift) | Síntesis, pausa y rangos de resaltado |
| [App/Biblioteca/BibliotecaView.swift](App/Biblioteca/BibliotecaView.swift) | Temas, destacados, búsqueda y filtro |
| [App/Biblioteca/BibliotecaTemaView.swift](App/Biblioteca/BibliotecaTemaView.swift) | Lecciones y quiz de un tema |
| [App/Biblioteca/BibliotecaDetalleView.swift](App/Biblioteca/BibliotecaDetalleView.swift) | Práctica, recurso visual y finalización |
| [App/Biblioteca/BibliotecaLecturaView.swift](App/Biblioteca/BibliotecaLecturaView.swift) | Narración por fragmento y reanudación de lectura |
| [App/Biblioteca/BibliotecaQuizView.swift](App/Biblioteca/BibliotecaQuizView.swift) | Quizzes por tema o generales y reintento de respuesta |
| [App/Biblioteca/EstiloEdustream.swift](App/Biblioteca/EstiloEdustream.swift) | Colores, iconos y tarjetas |
| [App/Cuenta/PerfilView.swift](App/Cuenta/PerfilView.swift) | Sesión, perfil y total de lecciones completadas |
| [App/Cuenta/AccesoView.swift](App/Cuenta/AccesoView.swift) | Acceso, registro y recuperación por correo |
| [App/Cuenta/EditarPerfilView.swift](App/Cuenta/EditarPerfilView.swift) | Actualización del nombre visible |
| [iOSTests/FirebaseEdustreamTests.swift](iOSTests/FirebaseEdustreamTests.swift) | Integración de FirebaseEdustream con emuladores reales |

**Dependencias de la app.** iOS 17 o posterior, SwiftUI, Foundation, Observation, Combine, AVFoundation y el SDK oficial Firebase Apple (Core, Auth y Firestore). Swift Package Manager resuelve Firebase desde [project.yml](project.yml). Para generar el proyecto se usa XcodeGen en macOS. Ajusta la versión de Xcode a los requisitos del SDK Firebase resuelto. [Configuración oficial en Apple](https://firebase.google.com/docs/ios/setup)

## Ejecutar con el emulador

Instala Node, npm y un JDK compatible con Firebase CLI. Desde esta carpeta:

```sh
npm install --no-save --no-package-lock firebase @firebase/rules-unit-testing firebase-tools firebase-admin
npx firebase emulators:start --only auth,firestore --project demo-edustream
```

En otra terminal, publica el catálogo local y genera el proyecto:

```sh
node Firebase/publicar.mjs --emulador --apply
xcodegen generate
open Edustream.xcodeproj
```

Para usar la app de forma manual contra el emulador, abre **Edit Scheme → Run → Arguments**, activa la variable `EDUSTREAM_EMULADOR=1` y ejecuta la configuración Debug en un simulador. En Release se ignora esa variable. Si quieres ejecutar las pruebas del servicio Swift, usa **Product → Test** con el emulador y el catálogo local disponibles. La prueba crea su propia sesión en `demo-edustream` y conecta exclusivamente con localhost. [Emulador de Firestore](https://firebase.google.com/docs/emulator-suite/connect_firestore) · [Emulador de Authentication](https://firebase.google.com/docs/emulator-suite/connect_auth)

## Conectar con Edustream real

1. Registra o localiza el target iOS dentro de `edustream-ab036`. Usa en `project.yml` el identificador de esa app iOS. El valor `mx.udg.edustream` es provisional.
2. Descarga su `GoogleService-Info.plist` y colócalo en `App/GoogleService-Info.plist`. Regenera el proyecto. Edustream valida que el plist corresponda al Bundle ID y a `edustream-ab036`.
3. En Firebase Auth habilita **Anónimo** y **Correo electrónico/contraseña**. Al registrar a un invitado, la app vincula el correo con el mismo UID. Iniciar sesión en una cuenta ya existente cambia al avance de esa cuenta.
4. Confirma que existe Cloud Firestore en modo nativo. Prueba y revisa [Firebase/firestore.rules](Firebase/firestore.rules). Si ya existen reglas de otros módulos, incorpora solo las rutas correspondientes y verifica que ninguna regla coincidente conceda permisos más amplios. La publicación del archivo completo sustituye las reglas activas.
5. Con credenciales de aplicación predeterminadas autorizadas para escribir en ese proyecto, ejecuta `node Firebase/publicar.mjs` para ver el destino y `node Firebase/publicar.mjs --apply` para crear los documentos editoriales faltantes. El comando puede repetirse y conserva los documentos preexistentes. Revisa manualmente las lecciones existentes si necesitas aplicar una nueva revisión editorial. También puedes publicar los documentos de [lecciones.json](Firebase/lecciones.json) desde la consola usando su `id` como nombre del documento y excluyéndolo de los campos.
6. Para probar el proyecto real, ejecuta Edustream con la variable del emulador desactivada. El catálogo procede de Firestore o de su caché. Los archivos editoriales quedan fuera del bundle. Las transacciones requieren conexión. La app ofrece reintentos y el quiz conserva localmente el identificador del envío pendiente entre aperturas.

## Pruebas en Codemagic

En [Codemagic](https://codemagic.io/app/6afd04fe29849db4c9eed0c9/settings), elige **Start new build**, la rama `main` y **Edustream · pruebas iOS**. El flujo usa el simulador con firma local y el proyecto emulado `demo-edustream`. [Resultado de la ejecución verificada](https://codemagic.io/app/6afd04fe29849db4c9eed0c9/build/6afd09abd133a39c4a12788d)

## Pruebas locales

```sh
node --test Tests/catalogo.test.cjs
node --check Tests/firestore.test.mjs
node --check Firebase/publicar.mjs
```

Con el emulador manual detenido, ejecuta las pruebas de reglas y concurrencia en una instancia temporal. La suite inicializa su catálogo de prueba y limpia únicamente la base emulada `demo-edustream`.

```sh
npx firebase emulators:exec --project demo-edustream --only firestore "node --test Tests/firestore.test.mjs"
```

En Xcode, con Auth y Firestore emulados, verifica el test del servicio Swift y luego recorre Inicio → tema → lección → lector → quiz. Comprueba búsqueda sin tildes, cambio de nivel, regreso sin voz en segundo plano, pausa y resaltado con caracteres Unicode, y restauración del fragmento más avanzado. Envía una respuesta con la red interrumpida, reabre la lección y verifica que el mismo intento sigue pendiente. Registra al invitado, vuelve a acceder con el mismo correo y verifica que se conserva su avance. Comprueba perfil, restablecimiento de contraseña, VoiceOver y texto grande.

**Estado de verificación.** Pasaron 3 pruebas locales de catálogo y vista previa y 4 pruebas de transacciones y permisos en Firestore Emulator 1.22.0. También se aplicó el publicador dos veces al emulador: la primera creó 11 lecciones y la segunda conservó las 11 sin crear duplicados. Codemagic compiló la app y ejecutó las 3 pruebas de catálogo, las 4 pruebas de Firestore y el XCTest del servicio Swift en un simulador de iPhone. La revisión manual de la interfaz y el audio sigue pendiente. No se cambiaron las reglas ni se publicó contenido en el proyecto Firebase real.

**Decisiones de diseño.** Acceso por correo y perfil con nombre visible y correo. El prototipo visual se tradujo a componentes nativos con acentos por tema, iconos SF Symbols y diagramas textuales. Las portadas fotográficas, HEX y tipografía exactos requieren los recursos o valores de las capas de Figma y una comparación en iPhone.
