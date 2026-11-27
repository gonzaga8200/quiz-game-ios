import Foundation

/// Who is behind the game (the web's app/content/legal.ts) and the app's versions of the web's
/// privacy policy (/cookies) and legal notice (/aviso-legal), adapted to the app: device storage
/// instead of cookies, Firebase Analytics instead of the Google tag, Apple as a sign-in option and
/// account deletion inside the app.
enum Legal {
    static let holder = "Gonzalo Moreno Minguito"
    static let owner = "Gonzalo Moreno Minguito (titular del proyecto, gonzaga8200 en GitHub)"
    static let domain = "contrarreloj-quiz.com"
    static let copyrightYear = 2026
    static let lastUpdated = "27 de noviembre de 2026"
    static var copyright: String { "© \(copyrightYear) \(holder)" }
}

struct LegalSection: Identifiable {
    let heading: String
    let paragraphs: [String]
    var id: String { heading }
}

enum LegalTexts {
    static let privacy: [LegalSection] = [
        LegalSection(heading: "Quién es el responsable", paragraphs: [
            "\(Legal.owner). Puedes escribirnos a \(AppLinks.contactEmail).",
        ]),
        LegalSection(heading: "Qué guardamos en tu dispositivo", paragraphs: [
            "Contrarreloj guarda en tu dispositivo lo imprescindible para funcionar. Lo que no es imprescindible, la analítica, solo se activa si la aceptas.",
            "Sesión de Firebase Authentication (llavero del dispositivo): mantener tu sesión iniciada con Apple o con Google. Imprescindible; dura hasta que cierres sesión o elimines tu cuenta.",
            "contrarreloj.consent: recordar si aceptaste o rechazaste la analítica. Imprescindible; 24 meses.",
            "contrarreloj.muted: recordar que has silenciado el sonido. Preferencia que tú eliges; hasta que la cambies.",
            "Copia de las preguntas: guardarlas un día para no volver a descargarlas en cada partida. Imprescindible; 24 horas.",
            "contrarreloj.seen.v1: recordar qué preguntas has visto en este dispositivo para repetirlas lo menos posible. Solo guarda los identificadores de las preguntas y cuántas veces se han mostrado; no se envía a ningún sitio.",
            "contrarreloj.hiddenPlayers: los jugadores del ranking que has decidido ocultar. Solo en este dispositivo.",
            "Identificador de Firebase Analytics: distinguir instalaciones y medir el uso del juego de forma estadística. Solo si aceptas la analítica.",
            "Todo lo que se guarda solo en tu dispositivo se borra al desinstalar la app.",
        ]),
        LegalSection(heading: "Iniciar sesión con Apple o con Google", paragraphs: [
            "El modo competitivo requiere iniciar sesión con tu Apple ID o con tu cuenta de Google mediante Firebase Authentication. Es necesario para prestar el servicio que solicitas, por eso no depende de que aceptes la analítica.",
            "Recibimos tu nombre, tu correo electrónico, un identificador de usuario y, con Google, tu foto de perfil. Con Apple puedes ocultar tu correo, y Apple solo nos da tu nombre la primera vez que entras. Firebase Authentication guarda estos datos para gestionar tu cuenta. Solo el nombre, la foto y las puntuaciones se publican en el ranking: el correo no se muestra ni se usa para nada más. No recibimos tu contraseña.",
        ]),
        LegalSection(heading: "Datos que se publican en el ranking", paragraphs: [
            "Si juegas en modo competitivo guardamos tu identificador, tu nombre, tu foto de perfil (si tu cuenta tiene) y tus resultados (puntos, aciertos, fallos, preguntas pasadas, tiempo, dificultad y categoría). Tu nombre, tu foto y tu puntuación son visibles públicamente en el ranking, también en la web. El modo arcade no guarda nada de esto.",
            "Las fotos de perfil se cargan desde los servidores de Google, que pueden recibir tu dirección IP cuando se muestran.",
            "Base legal: la ejecución del servicio que solicitas al jugar en modo competitivo. Los datos se conservan mientras mantengas tu cuenta. Puedes eliminar tu cuenta y todas tus puntuaciones cuando quieras desde Ajustes › Eliminar cuenta. También puedes ejercer tus derechos de acceso, rectificación, supresión, oposición, limitación y portabilidad escribiendo al contacto indicado arriba. Si crees que no hemos tratado bien tus datos, puedes reclamar ante la Agencia Española de Protección de Datos.",
            "Menores: el modo competitivo es solo para mayores de 14 años, la edad a partir de la cual en España se puede consentir el tratamiento de datos personales. Si eres más joven, puedes jugar en modo arcade, que no guarda ningún dato tuyo.",
        ]),
        LegalSection(heading: "Alojamiento y transferencias", paragraphs: [
            "Los datos del ranking y de las preguntas se guardan en Firestore, en la región europea (eur3). Es un servicio de Google, que actúa como encargado del tratamiento. Google puede tratar datos fuera del Espacio Económico Europeo, por ejemplo en Estados Unidos, con las garantías que indica en sus condiciones de tratamiento de datos.",
        ]),
        LegalSection(heading: "Contacto y reportes", paragraphs: [
            "El contacto, el reporte de una pregunta y el reporte de un jugador no envían nada desde la app: abren tu propio correo con el texto preparado y decides tú si lo envías. Ese correo sale de tu cuenta y llega a la nuestra como cualquier otro mensaje. Lo que recibamos se usa solo para atender tu mensaje.",
        ]),
        LegalSection(heading: "Analítica con Firebase Analytics", paragraphs: [
            "Solo si aceptas medimos qué pantallas se ven, cómo empiezan y terminan las partidas, si el inicio de sesión funciona o falla y si se comparte un resultado. No enviamos tu nombre, tu correo ni tu identificador de usuario, no usamos el identificador de publicidad (IDFA) y no te seguimos en otras apps ni webs: por eso la app no te pide permiso de seguimiento.",
            "La analítica está desactivada por defecto. Si rechazas o cambias de opinión, dejamos de medir y borramos el identificador de analítica de este dispositivo. Las señales de publicidad están siempre desactivadas.",
            "Puedes cambiar tu elección cuando quieras en Ajustes › Estadísticas de uso.",
        ]),
        LegalSection(heading: "Más información", paragraphs: [
            "Política de privacidad de Google: https://policies.google.com/privacy",
            "Política de privacidad de Apple: https://www.apple.com/es/legal/privacy/",
        ]),
    ]

    static let legalNotice: [LegalSection] = [
        LegalSection(heading: "Titular", paragraphs: [
            "\(Legal.owner).",
            "Nombre de dominio: \(Legal.domain). Contacto: \(AppLinks.contactEmail).",
            "Contrarreloj es un juego de preguntas gratuito, sin publicidad y sin ánimo comercial. Para saber cómo tratamos tus datos y qué guardamos en tu dispositivo, consulta la política de privacidad.",
        ]),
        LegalSection(heading: "Propiedad intelectual", paragraphs: [
            "\(Legal.copyright). Todos los derechos reservados.",
            "El nombre Contrarreloj, su diseño, sus textos, sus ilustraciones, su código y el conjunto de preguntas y explicaciones del juego son obra de \(Legal.holder), que conserva su autoría. No se permite copiar, reproducir, modificar ni distribuir la app o sus contenidos, ni presentarlos como propios, sin autorización previa y por escrito del titular. Sí puedes jugar, compartir tus resultados y citar fragmentos breves indicando la fuente.",
            "Los componentes de terceros, como Firebase, Google Sign-In o las fuentes Playfair Display y Atkinson Hyperlegible Next, conservan sus propias licencias. Los nombres y marcas de terceros que aparezcan, como Apple o Google, pertenecen a sus respectivos titulares.",
        ]),
        LegalSection(heading: "Condiciones de uso", paragraphs: [
            "Puedes jugar gratis y sin registro. El modo competitivo requiere iniciar sesión con Apple o con Google y publica tu nombre, tu foto y tu puntuación en el ranking; es solo para mayores de 14 años. Te pedimos que no uses la app para falsear el ranking, sobrecargar el servicio o intentar acceder a lo que no es público.",
            "Las preguntas se revisan con cuidado, pero pueden contener errores o quedarse desfasadas. El juego se ofrece tal cual, sin garantías, y no nos hacemos responsables de los daños que pudieran derivarse de su uso o de una interrupción del servicio.",
        ]),
        LegalSection(heading: "Errores y contenidos", paragraphs: [
            "Si encuentras una pregunta incorrecta, un jugador con un nombre o una foto inapropiados, un contenido que vulnera tus derechos o cualquier otro problema, avísanos desde la propia app o por el contacto indicado arriba y lo revisaremos lo antes posible.",
        ]),
        LegalSection(heading: "Legislación aplicable", paragraphs: [
            "Esta app se rige por la legislación española. Para cualquier conflicto serán competentes los juzgados y tribunales que correspondan según la normativa vigente.",
        ]),
    ]
}
