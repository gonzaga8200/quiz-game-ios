# Etiquetas de privacidad (App Store Connect › Privacidad de la app)

Coinciden con `App/Resources/PrivacyInfo.xcprivacy`. Comprueba al rellenarlas la guía de Firebase
sobre los datos que recogen sus SDK.

**¿Se usan datos para rastrearte?** No. No hay IDFA, ni ATT, ni datos compartidos con terceros
para publicidad.

## Datos vinculados a ti (solo modo competitivo)

| Tipo | Uso | Por qué |
| --- | --- | --- |
| Información de contacto › Nombre | Funcionalidad de la app | Se muestra en el ranking |
| Información de contacto › Correo electrónico | Funcionalidad de la app | Lo recibe Firebase Authentication; no se muestra ni se usa para nada más |
| Identificadores › ID de usuario | Funcionalidad de la app | Una entrada por jugador y tabla |
| Contenido del usuario › Contenido de juego | Funcionalidad de la app | Puntuaciones del ranking |
| Contenido del usuario › Otro contenido | Funcionalidad de la app | Enlace a la foto de perfil de Google |

## Datos no vinculados a ti (solo si el jugador acepta la analítica)

| Tipo | Uso |
| --- | --- |
| Datos de uso › Interacción con el producto | Analítica |
| Identificadores › ID del dispositivo (identificador de instancia de Firebase) | Analítica |
| Ubicación › Ubicación aproximada (la deduce Google Analytics de la IP) | Analítica |
