# Contrarreloj para iOS: app nativa con paridad con la web

Estado: aprobado por el autor el 27-11-2026. Proyecto: diseño completo.

## Intención

Llevar Contrarreloj (https://contrarreloj-quiz.com, repo `gonzaga8200/quiz-game`) al iPhone y al
iPad como app 100 % nativa, con las mismas reglas, las mismas preguntas y el mismo ranking que la
web. Un jugador debe poder jugar en el móvil y en la web y ver las mismas preguntas, puntuar igual
y competir en las mismas tablas. La app tiene que estar lista para pasar la revisión de la App
Store cuando el autor active la cuenta de pago de Apple.

## Objetivos

- Paridad funcional con la web (inventario más abajo): arcade, competitivo, informe, ranking,
  categorías, contacto, redes, privacidad y aviso legal.
- Misma lógica de juego, comprobada con tests de paridad contra el `core/` de TypeScript.
- Mismo proyecto Firebase (`contrarreloj-quiz`): mismas colecciones y mismas reglas.
- Analítica con Firebase Analytics en la misma propiedad GA4 que la web, con los eventos de la web
  más los propios de la app.
- Cumplir las Human Interface Guidelines (HIG) y las App Store Review Guidelines: Sign in with
  Apple, borrado de cuenta, Privacy Manifest, accesibilidad.

## No objetivos

- Android, Apple Watch, widgets, Game Center, notificaciones push, compras.
- Unir una cuenta de Apple y otra de Google del mismo jugador (cuentas separadas en esta versión).
- Cambiar la web. La única excepción aprobada es la PR #93 (borrado de entradas propias).
- Mover la puntuación a un servidor (sigue en el cliente, como en la web; ver limitaciones).

## Anti-objetivos (sería un fracaso aunque funcione)

- Que una partida en iOS puntúe distinto que la misma partida en la web.
- Escribir en Firestore algo que la web no sepa leer o que las reglas rechacen.
- WebViews, frameworks híbridos o ejecutar el JavaScript de la web dentro de la app.
- Medir algo antes de que el jugador acepte, o enviar datos personales a Analytics.
- Agotar la cuota gratuita de lecturas de Firestore por descargar el banco de preguntas.
- Subir a Git el `GoogleService-Info.plist` o cualquier credencial.

## Restricciones y decisiones ya tomadas

| Tema | Decisión |
|---|---|
| Repo | `gonzaga8200/quiz-game-ios`, **público**, licencia "todos los derechos reservados" igual que la web |
| Bundle ID | `com.contrarrelojquiz.app` (ya registrado en Firebase como "Contrarreloj iOS") |
| Plataforma | Swift + SwiftUI, iOS 17 mínimo, universal iPhone/iPad |
| Login | Apple y Google. Proveedor Apple ya activado en Firebase |
| Borrado de cuenta | Depende de la PR #93 (`allow delete` del propio uid) |
| Analytics | Firebase vinculado a la propiedad GA4 de la web (ID 565441368) |
| Caché de preguntas | 24 h + comprobación del recuento + banco empaquetado de respaldo |
| Cuenta Apple | Gratuita por ahora: sin Sign in with Apple real, TestFlight ni App Store hasta pagar |
| Idioma | Español; textos en String Catalog para poder localizar |
| Entorno | Xcode 26.6 vía `DEVELOPER_DIR`; simuladores iOS 26.x |

## Enfoques considerados

**Lógica de juego**

1. **Port 1:1 a Swift en un paquete local, con tests de paridad (elegido).** Nativo, rápido y
   testeable. El riesgo de que el port diverja se cubre con fixtures generados por el `core/` de
   TypeScript con semilla fija: el port Swift debe reproducirlos exactamente.
2. Ejecutar el `core/` de TypeScript en JavaScriptCore. Reutiliza el código tal cual, pero es un
   enfoque híbrido (lo excluye el encargo) y complica la concurrencia y la depuración.
3. Lógica compartida con Kotlin Multiplatform. Obligaría a reescribir también la web; fuera de
   alcance.

**Navegación**

1. **`TabView` con cuatro pestañas (elegido):** Jugar, Categorías, Ranking y Ajustes. Es lo
   esperable en iOS y da sitio a lo que en la web está en el menú y el pie.
2. Una sola pila como la web (inicio con botones). Menos idiomático y esconde Ajustes y Categorías.

**Proyecto Xcode**

1. **XcodeGen (`project.yml`) y el `.xcodeproj` generado también en Git (elegido).** Proyecto
   reproducible, revisable en PR y sin conflictos en `project.pbxproj`; se abre en Xcode sin
   instalar nada. Requiere instalar `xcodegen` con Homebrew (pendiente de OK).
2. Escribir `project.pbxproj` a mano. Frágil y difícil de revisar.

## Arquitectura

```
quiz-game-ios/
  project.yml                  XcodeGen: targets, settings, paquetes SPM
  Contrarreloj.xcodeproj       generado, en Git
  Packages/ContrarrelojCore/   Swift package sin Firebase ni UI: port de core/
    Sources/ContrarrelojCore   constants, filters, categories, rng, selection, game,
                               report, celebration, combo, showcase, schema
    Tests/                     Swift Testing + fixtures de paridad
  App/
    ContrarrelojApp.swift      punto de entrada, composición de dependencias
    Features/                  Home, Setup, Game, Report, Ranking, Categories, Settings,
                               SignIn, Consent, Legal
    Data/                      protocolos + implementaciones Firebase y falsas
    Design/                    colores, tipografía, reloj de bolsillo, componentes
    Resources/                 Assets, Localizable.xcstrings, fuentes, questions.json,
                               PrivacyInfo.xcprivacy
  Tests/                       unitarios de la app (Swift Testing)
  UITests/                     XCUITest con servicios falsos
  IntegrationTests/            contra los emuladores de Firebase
  Tools/parity/                script que genera los fixtures desde el core TS de la web
  Tools/sync-questions.sh      copia y valida data/questions de la web en questions.json
  Config/                      Secrets.example.xcconfig (el real, ignorado por Git)
  docs/                        specs, plan, metadatos App Store, capturas
```

- **Patrón:** MVVM con `@Observable`. Las vistas no conocen Firebase: hablan con protocolos
  (`QuestionRepository`, `RankingStore`, `AuthService`, `AnalyticsService`, `MailComposer`,
  `SoundPlayer`) inyectados desde la raíz. Cada protocolo tiene una implementación real y una falsa
  (previews, tests unitarios y de UI).
- **Concurrencia:** Swift 6 language mode, concurrencia estricta completa, aislamiento por defecto
  `MainActor` en el target de la app. Decodificar el banco (≈1,7 MB) y mapear documentos de
  Firestore fuera del hilo principal. `async/await` en todo; sin warnings en código propio
  (`SWIFT_TREAT_WARNINGS_AS_ERRORS` para nuestros targets).
- **Dependencias (SPM):** Firebase iOS SDK (Auth, Firestore, Analytics sin IDFA / sin AdSupport) y
  GoogleSignIn-iOS. Sign in with Apple con `AuthenticationServices`.
- **Sin Firebase configurado** (sin `GoogleService-Info.plist`, p. ej. en CI o en un clon nuevo) la
  app funciona como la web sin variables: arcade con el banco empaquetado y sin competitivo ni
  ranking. Así el CI compila y prueba sin secretos.
- **Configuración:** `Config/GoogleService-Info.plist` y `Config/Secrets.xcconfig`
  (`GOOGLE_REVERSED_CLIENT_ID` para el URL scheme de Google) están fuera de Git; hay plantillas
  `*.example` y un script que genera el `xcconfig` desde el `plist`. Una fase de build copia el
  `plist` al bundle solo si existe.

## Lógica de juego (ContrarrelojCore)

Port literal de `core/` de la web (fuente de verdad: `constants.ts`, `filters.ts`,
`categories.ts`, `rng.ts`, `selection.ts`, `game.ts`, `report.ts`, `celebration.ts`, `combo.ts`,
`showcase.ts`, `schema.ts`). No se porta `validation.ts` (herramienta de la web).

- Mismas constantes: puntos 3/5/7/10/15; penalización por fallo 2/1/0/0/0 con suelo en 0
  (se registra lo realmente descontado); combos +2/+4/+8 a 3/5/10; 2 pases gratis y luego −1;
  pasar no rompe la racha; 64 tablas de ranking (2 tiempos × 4 filtros × 8 opciones de categoría);
  celebración por puntos por minuto 150/90/45/15; `MAX_POINTS_PER_CORRECT = 17`; top 50.
- Misma máquina de estados (`ready → question → feedback → … → finished`), el reloj sigue durante
  el feedback, la pregunta abierta al llegar a 0 se descarta, fin `exhausted` si se acaba la cola.
- Misma cola: filtro por dificultad, Fisher-Yates, menos vistas primero comparando dentro de cada
  dificultad, reparto (nunca 2 seguidas de la misma categoría; en Aleatorio no más de 2 de la misma
  dificultad) y opciones barajadas.
- **Detalles que la paridad exige:** `mulberry32` con aritmética `UInt32` con desbordamiento
  (equivalente a `Math.imul` y `>>>`) y división entre 4294967296 en `Double`; ordenación
  **estable** explícita donde la web usa `Array.sort` (la de Swift no lo garantiza); mismo orden de
  consumo del generador aleatorio (primero se baraja el grupo y después las opciones de cada
  pregunta, en el orden de la cola).
- En producción el generador es `SystemRandomNumberGenerator` adaptado a `() -> Double`; en tests,
  `mulberry32`. El reloj es inyectable (`ContinuousClock` en la app, reloj manual en tests).
- Validación de documentos: la equivalente al esquema zod (`QuestionSchema`,
  `RankingEntrySchema`): un documento mal formado se descarta, igual que en la web.

## Datos

**Preguntas** (`questions`, solo `status == active`)
1. Al cargar: si hay caché en disco (`Application Support`, JSON con `savedAt`) de menos de 24 h,
   se hace una consulta de recuento (`count()` de activas, ≈3 lecturas). Si coincide con el número
   guardado, se usa la caché; si no, se descarga el banco entero.
2. Sin caché válida: descarga completa con tiempo límite de 6 s (como la web).
3. Si Firestore falla, no responde o devuelve 0 preguntas: la caché en disco aunque tenga más de
   24 h (suele ser más reciente que el banco empaquetado); si no hay caché, el banco empaquetado
   (`Resources/questions.json`, generado por `Tools/sync-questions.sh` desde `data/questions/` de
   la web y validado). Se juega siempre. Si falla solo la consulta de recuento (sin conexión) y la
   caché tiene menos de 24 h, se usa la caché sin más.
- Firestore con caché en memoria (sin persistencia en disco), como la web: la caché propia de
  preguntas es explícita y la del ranking no debe servir datos viejos sin avisar.

**Ranking** (`rankings/{board}/entries/{uid}`)
- Mismas operaciones y semántica que `app/utils/ranking-service.ts`: 0 puntos no se guarda; leer
  la mejor marca del jugador; guardar solo si mejora (`createdAt` = `FieldValue.serverTimestamp()`);
  puesto = jugadores con más puntos (`count()`) + 1; top 50 por puntos descendente.
- Mismo documento que `toScoreSubmission`: nombre recortado a 60 caracteres o "Jugador"; foto solo
  si es `https://` y ≤ 500 caracteres, si no `null`; `category` solo si la partida fue de una
  categoría. Los campos y tipos deben pasar las reglas (enteros `Int64`, no `Double`).
- Caché en memoria de 60 s por tabla; tirar para recargar la ignora.

**Preferencias locales** (`UserDefaults`, mismas claves que la web)
- `contrarreloj.seen.v1`: memoria de preguntas vistas, misma semántica (se guarda al terminar, al
  salir de la partida y al pasar la app a segundo plano; olvida ids que ya no están en el banco).
- `contrarreloj.muted`: sonido.
- `contrarreloj.consent`: decisión de analítica con versión y fecha; se vuelve a preguntar a los
  24 meses.
- `contrarreloj.hiddenPlayers`: jugadores ocultos en este dispositivo (ver moderación).

## Autenticación y cuenta

- **Google:** GoogleSignIn → credencial de Firebase. Nombre y foto de Google.
- **Apple:** `ASAuthorizationAppleIDProvider` con nonce SHA-256 → credencial de Firebase. Apple
  solo da el nombre la primera vez: se guarda en el perfil de Firebase (`displayName`). Sin foto.
- Pantalla de entrada (hoja): botón oficial de Apple y botón de Google con el mismo peso, y el aviso
  de la web: mayores de 14 años, nombre y puntuación visibles en el ranking, enlace a privacidad.
- Errores: mismo criterio que `auth-errors.ts` (cancelar no muestra nada; sin red; genérico).
- **Eliminar cuenta** (Ajustes): pantalla que explica qué se borra → confirmar → reautenticar con
  el mismo proveedor → borrar con un `WriteBatch` las entradas del jugador en las 64 tablas → si es
  Apple, revocar el token (`revokeToken(withAuthorizationCode:)`) → si es Google, `disconnect` →
  borrar el usuario de Firebase → volver al Inicio sin sesión. Si un paso falla, se informa y se
  puede reintentar sin dejar la cuenta a medias (las entradas se borran antes que el usuario).
  Requiere la PR #93 publicada; hasta entonces el borrado en producción falla con
  `permission-denied` y la app lo explica. La revocación de Apple necesita la configuración
  "OAuth code flow" en Firebase, que llega al pagar la cuenta de Apple: si falla por falta de
  configuración, se registra y el borrado continúa.

## Pantallas (web → iOS)

| Web | iOS |
|---|---|
| Inicio | Pestaña **Jugar**: reloj de bolsillo animado, título, lema, "Jugar arcade", "Modo competitivo" (o "Entrar" si no hay sesión), usuario con avatar, "Síguenos" |
| Competitivo | Hoja/pantalla de configuración: tiempo, dificultad (con pistas), categoría, resumen "Juegas por el ranking de…", Empezar |
| Partida | Pantalla completa: HUD (reloj, mm:ss, urgente < 10 s, puntos con "−N", racha con llama ≥ 3 y aviso al romperse, pista de combo), tarjeta (cinta y etiqueta de categoría, 5 marcas de dificultad, 4 opciones A–D con sus colores), feedback de 600 ms, sello "¡Fallo!", Pasar (pases gratis / coste), reportar (pausa el reloj), sonido, banner de racha y confeti, salir con confirmación |
| Informe | Emoji y título por nivel, puntos, contexto, resultado del ranking, recuento, desglose, pregunta a pregunta, Jugar de nuevo, Compartir, Volver |
| Ranking | Pestaña **Ranking**: tiempo y dificultad (segmentados), categoría (menú), top 50 con puesto (empates), avatar o inicial, "Tú" resaltado, estados de carga/vacío/error/sin conexión |
| Preguntas y categoría | Pestaña **Categorías**: 7 categorías con color, texto y recuento, "Jugar con todas"; detalle con intro, recuento, 20 preguntas con respuesta (misma selección estable) y "Jugar con preguntas de X" (arcade de una categoría) |
| Contacto, Social Media, Cookies, Aviso legal, pie | Pestaña **Ajustes**: Cuenta (sesión, cerrar, eliminar), Sonido, Estadísticas (consentimiento), Contacto (3 motivos → correo), Síguenos (Instagram, X), Privacidad, Aviso legal, versión y © |
| Banner de cookies | Tarjeta no bloqueante al primer arranque con "Aceptar" y "Rechazar" del mismo tamaño y enlace a Privacidad |

- Textos: los de la web, literalmente, en `Localizable.xcstrings` (plurales "punto/puntos",
  "pase/pases" con variaciones del catálogo). Fuentes de los textos: `app/pages`,
  `app/components`, `app/content` (categorías, legal, redes, SEO no aplica).
- Privacidad y aviso legal: versión para la app del contenido de `/cookies` y `/aviso-legal`
  (UserDefaults en lugar de localStorage, Firebase Analytics en lugar de cookies de GA).
- Correo (contacto y reportar pregunta): `MFMailComposeViewController` si hay cuenta de correo; si
  no, `mailto:`; si tampoco, la dirección con botón de copiar. Mismo asunto y cuerpo que
  `app/utils/feedback.ts`.
- Compartir: hoja de compartir (`UIActivityViewController`) con el texto de `shareText` y la URL
  de `shareUrl` (página de la categoría o inicio). Solo si la partida puntuó.

## Diseño (HIG)

- Misma identidad visual: nogal, pergamino, oro, tinta; colores de categoría y de respuestas A–D de
  `app/assets/css/main.css`. **Modo oscuro = nogal** (como la web); **modo claro = pergamino** como
  fondo con tinta, y la tarjeta de pregunta en pergamino en ambos. Colores definidos en el catálogo
  de assets con variante clara y oscura; contraste de texto ≥ 4,5:1 comprobado en los dos modos.
- Fuentes Playfair Display y Atkinson Hyperlegible Next (OFL) empaquetadas, escaladas con Dynamic
  Type (`relativeTo:`) hasta los tamaños de accesibilidad; los diseños pasan a una columna cuando
  no caben.
- Reloj de bolsillo dibujado en SwiftUI (caja, anilla, corona, marcas, números romanos, aguja y
  arco del tiempo), recreando el SVG de `ClockFace.vue`.
- SF Symbols para iconos (bandera, altavoz, llama, check, cruz, trofeo, engranaje…).
- iPhone: vertical y horizontal. iPad: todas las orientaciones y Split View; en anchura regular la
  partida usa dos columnas (tarjeta a la izquierda, reloj y marcador a la derecha) como el
  escritorio de la web.
- Teclado físico (iPad): 1–4 / A–D responden, P pasa, como en la web.
- Sonidos: las mismas notas de `app/utils/audio.ts` sintetizadas con `AVAudioEngine`, sin
  ficheros; sesión de audio `.ambient` (respeta el modo silencio y no corta la música).
- Hápticos con `sensoryFeedback`: acierto, fallo, racha.
- Reduce Motion: sin temblor, pulso urgente, confeti ni animación del reloj de portada; colores,
  iconos y textos se mantienen. Hápticos también se omiten (como la vibración en la web).
- Icono de app: el reloj de bolsillo sobre nogal (1024 px; variantes oscura y tintada). Pantalla de
  lanzamiento: color nogal.

## Accesibilidad

- Etiquetas de VoiceOver en todos los controles (p. ej. "Respuesta A: París"; "Pasar pregunta. Te
  quedan 2 pases gratis.").
- Anuncios equivalentes a la región `aria-live` de la web: resultado de cada respuesta, coste de
  pasar, "Quedan 30 segundos" y "Quedan 10 segundos". El foco va a la pregunta nueva.
- El resultado nunca depende solo del color: iconos y texto.
- Objetivos táctiles ≥ 44 pt; Large Content Viewer en la barra de pestañas.

## Robustez

- Cada pantalla con datos tiene estados de carga, vacío, error con reintentar y sin conexión
  (`NWPathMonitor`).
- La partida no se pausa al pasar a segundo plano (igual que la web: el reloj es de tiempo real),
  pero la memoria de preguntas vistas se guarda en ese momento.
- Tiempos límite: 6 s para las preguntas; 10 s para operaciones del ranking, con reintento.
- Nada pesado en el hilo principal (decodificación, mapeo, síntesis de audio).

## Moderación del ranking (Guideline 1.2)

Los nombres y fotos del ranking los pone cada jugador en su cuenta de Google o Apple. Para cumplir
la norma sobre contenido de usuarios, cada fila del ranking (salvo la propia) tiene un menú con
**"Reportar jugador"** (correo con tabla, nombre y uid) y **"Ocultar jugador"** (lo esconde en este
dispositivo; se puede deshacer en Ajustes). El contacto está publicado en Ajustes.

## Analítica

- Firebase Analytics, **desactivado por defecto** (`FIREBASE_ANALYTICS_COLLECTION_ENABLED = NO`,
  señales de publicidad denegadas siempre, sin IDFA ni IDFV). "Aceptar" activa la recogida y
  concede solo `analytics_storage`; "Rechazar" o retirarlo la desactiva y llama a
  `resetAnalyticsData()`. Sin `setUserID`: nunca se envían nombre, correo ni uid.
- **App Tracking Transparency no se usa:** no hay seguimiento entre apps ni IDFA.
- Eventos:

| Evento | Parámetros | Origen |
|---|---|---|
| `screen_view` | `screen_name`, `screen_class` | equivale a `page_view` de la web |
| `login_click` | `method` (`google`/`apple`) | web |
| `login_success` | `method` | web |
| `login_error` | `method`, `error_code` | web |
| `share` | `method` (`native`/`copy`), `content_type` = `game_result`, `mode` | web |
| `game_start` | `mode`, `duration`, `difficulty`, `category` (o `all`) | app |
| `game_end` | los de `game_start` + `points`, `correct`, `wrong`, `skipped`, `best_streak`, `finish_reason` | app |
| `question_report` | `category`, `difficulty` | app |
| `account_deleted` | `method` | app |

## Privacidad y cumplimiento

- `PrivacyInfo.xcprivacy`: `NSPrivacyTracking = false`, sin dominios de seguimiento. Datos
  recogidos: nombre, correo y uid (vinculados, funcionalidad de la app: cuenta y ranking),
  contenido de juego (puntuaciones, vinculado, funcionalidad), interacción con el producto (no
  vinculado, analítica, solo con consentimiento). APIs con motivo declarado: `UserDefaults`
  (CA92.1) y las de tiempo del sistema que se usen. Los SDK de Firebase traen su propio manifiesto.
- Sin permisos del sistema (cámara, ubicación…): no hace falta ningún texto de permiso.
- Etiquetas de privacidad de App Store Connect y metadatos (nombre, subtítulo, descripción,
  palabras clave, categoría Juegos › Preguntas y respuestas, clasificación por edad, URL de soporte,
  notas para el revisor) en `docs/app-store/`.

## Verificación

- **Unitarios (Swift Testing):** todo `ContrarrelojCore` + la capa de app que tiene lógica
  (ranking service, cachés, memoria de vistas, consentimiento, errores de auth, textos de compartir
  y correo, formatos).
- **Paridad con la web:** `Tools/parity` importa el `core/` de TypeScript desde una copia local del
  repo web (solo lectura) y genera fixtures JSON con semillas fijas: colas, barajados de opciones,
  partidas guionizadas (respuestas, pases, reloj manual), informes, celebración, ids de tabla y
  selección de categorías. Los fixtures se guardan en el repo iOS y los tests Swift exigen
  igualdad exacta.
- **UI (XCUITest)** con servicios falsos y banco pequeño: arcade completo hasta el informe,
  competitivo (sesión falsa) con resultado de ranking, ranking con filtros y estados, categorías →
  detalle → jugar, Ajustes (consentimiento, cerrar sesión, eliminar cuenta), reportar pregunta
  (pausa). En iPhone 17 Pro y iPad Pro 13" del simulador.
- **Capturas** de cada flujo en iPhone y iPad, modo claro y oscuro y un tamaño de texto de
  accesibilidad (`xcrun simctl io … screenshot`).
- **Integración con los emuladores de Firebase** (Auth + Firestore con las reglas de la rama de la
  PR #93): iniciar sesión con una cuenta falsa, guardar una puntuación, comprobar que la web local
  apuntando al mismo emulador la muestra en su ranking, y borrar la cuenta. Requiere JDK 21
  (pendiente de OK para instalarlo).
- **Producción, solo lectura:** cargar el banco real en el simulador y comparar número e ids con
  lo que carga la web.
- **Analítica:** simulador con `-FIRDebugEnabled`; se comprueba en los logs que los eventos se
  registran y se envían. Ver que llegan a DebugView/GA4 necesita al autor.
- **CI:** GitHub Actions en macOS para cada PR: compilar, tests unitarios y de UI (sin
  `GoogleService-Info.plist`).

## Forma de trabajo

- Repo nuevo con `README` (configuración, Firebase, scripts, arquitectura, tests), `.gitignore` de
  Xcode, `LICENSE` como la web. Commits pequeños con Conventional Commits.
- Primer commit en `main` (esqueleto y este documento); el desarrollo va en una rama y se entrega en
  una PR que fusiona el autor.
- No se toca el repo web (salvo la PR #93 ya abierta) ni la configuración de Firebase sin preguntar.

## Lo que queda al constructor

Nombres de tipos y ficheros, estructura interna de cada vista, animaciones concretas (dentro de lo
descrito), forma exacta de los fixtures, versión concreta de los SDK, diseño exacto del icono (se
enseña antes de cerrarlo), textos de la ficha de la App Store y textos adaptados de Privacidad y
Aviso legal (se enseñan antes de cerrarlos: son textos legales).

## Pendiente del autor (no bloquea la construcción)

- Fusionar la PR #93 y publicar una release de la web, para que el borrado funcione en producción.
- Pagar el Apple Developer Program para probar Sign in with Apple, TestFlight y publicar; después,
  rellenar "OAuth code flow configuration" del proveedor Apple en Firebase.
- Una URL de política de privacidad que cubra la app para App Store Connect (lo natural es ampliar
  `/cookies` de la web: cambio en la web, más adelante).
- Comprobar en App Store Connect que el nombre "Contrarreloj" está libre.

## Limitaciones conocidas (heredadas de la web)

- La puntuación se calcula en el cliente; las reglas limitan el daño pero no prueban que la partida
  se jugó.
- Cuota de lecturas de Firestore: con el banco actual (≈2.800 preguntas) cada descarga completa
  cuesta ≈2.800 lecturas de 50.000 diarias. La solución de fondo es publicar el banco como fichero
  estático (cambio en la web).
- Las fotos del ranking se cargan desde los servidores de Google.
