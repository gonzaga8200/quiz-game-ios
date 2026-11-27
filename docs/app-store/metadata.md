# Ficha de la App Store (borrador para revisar)

Textos para App Store Connect, en español (España). Los límites de caracteres son los de Apple.

| Campo | Valor | Límite |
| --- | --- | --- |
| Nombre | Contrarreloj: preguntas | 30 (23) |
| Subtítulo | Preguntas contra el tiempo | 30 (26) |
| Categoría principal | Juegos › Preguntas y respuestas | — |
| Categoría secundaria | Juegos › Casual | — |
| URL de soporte | https://contrarreloj-quiz.com/contacto | — |
| URL de marketing | https://contrarreloj-quiz.com | — |
| URL de la política de privacidad | **Pendiente**: la página /cookies de la web aún no cubre la app (ver abajo) | — |
| Copyright | 2026 Gonzalo Moreno Minguito | — |
| Precio | Gratis, sin compras dentro de la app | — |

Si el nombre «Contrarreloj» estuviera libre en la tienda, se puede usar solo; si no, «Contrarreloj: preguntas».

## Texto promocional (170)

Responde todas las preguntas que puedas antes de que se acabe el reloj. Arcade sin registro y modo competitivo con el mismo ranking que la web.

## Descripción (4.000)

Contrarreloj es un juego de preguntas contra el tiempo: tienes 60 segundos para acertar todas las que puedas.

ARCADE, SIN REGISTRO
Abre la app y juega. 60 segundos, dificultad aleatoria y preguntas de todas las categorías, o solo de la que elijas.

MODO COMPETITIVO
Entra con Apple o con Google y compite en el ranking. Elige 60 o 120 segundos, la dificultad (fácil, medio, difícil o aleatoria) y la categoría. Cada combinación tiene su propio ranking, el mismo que en contrarreloj-quiz.com.

CÓMO SE PUNTÚA
• Cuanto más difícil la pregunta, más puntos.
• Las rachas dan bonus: +2 con 3 aciertos seguidos, +4 con 5 y +8 con 10.
• Tienes dos pases gratis; después, pasar cuesta un punto.

MILES DE PREGUNTAS CON SU EXPLICACIÓN
Arte y literatura, historia y geografía, deportes, cine y televisión, ciencias, lengua e idiomas y música. Al terminar ves cada pregunta con la respuesta correcta y una explicación breve.

PENSADO PARA TODOS
Modo claro y oscuro, texto ampliable, VoiceOver, teclado en el iPad y sin animaciones si lo prefieres. Sin publicidad.

El modo competitivo es para mayores de 14 años: tu nombre, tu foto y tu puntuación se ven en el ranking. Puedes eliminar tu cuenta cuando quieras desde Ajustes.

## Palabras clave (100)

`trivial,quiz,cultura general,test,preguntas y respuestas,historia,ciencias,música,cine,deportes`

(95 caracteres; Apple ya indexa el nombre y el subtítulo, por eso no se repiten.)

## Novedades de la versión 1.0

Primera versión de Contrarreloj para iPhone y iPad.

## Clasificación por edad (cuestionario)

| Pregunta | Respuesta |
| --- | --- |
| Violencia, contenido sexual, lenguaje soez, drogas, terror, apuestas | Ninguno |
| Contenido médico o de tratamiento | No |
| Acceso sin restricciones a la web | No |
| Contenido generado por usuarios | Sí: nombres y fotos de perfil en el ranking, con reportar y ocultar jugadores |
| Mensajes o chat entre usuarios | No |
| Publicidad | No |
| Concursos o premios | No |

La calificación final la calcula Apple. El modo competitivo pide 14 años o más por la ley española de protección de datos; el arcade es apto para todas las edades.

## Capturas

- iPhone 6,9" (simulador iPhone 17 Pro Max) e iPad 13" (simulador iPad Pro 13 M5), modo claro y oscuro: inicio, partida, fallo con la respuesta revelada, informe, ranking y categorías.
- `scripts/screenshots.sh` las genera (Tarea 23).

## Pendiente antes de enviar

1. Pagar el Apple Developer Program y crear la app en App Store Connect con el bundle ID `com.contrarrelojquiz.app`.
2. Una URL de política de privacidad que cubra la app. Lo natural es ampliar `/cookies` de la web con el texto de `App/Content/Legal.swift` (cambio en la web).
3. Rellenar «OAuth code flow configuration» del proveedor Apple en Firebase, para que el borrado de cuenta revoque el acceso de Apple.
