# Capturas headless

Estas capturas deben generarse contra `127.0.0.1` y conservar la fecha real de ejecución.
No deben incluir contraseñas, tokens, cookies ni datos personales.

El script `scripts/capture_headless.sh` requiere Chromium y captura las pantallas públicas
de login y de la aplicación. Las pruebas de las lecciones requieren una sesión creada por
el usuario y no deben automatizar credenciales reales.
