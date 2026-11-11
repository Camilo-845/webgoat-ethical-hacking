# Proyecto final de Hacking Ético — OWASP WebGoat

Proyecto académico sobre una instancia local de OWASP WebGoat. Todas las pruebas deben ejecutarse únicamente contra `127.0.0.1`.

## Estado y alcance

La guía académica solicita cuatro vulnerabilidades. Este repositorio documenta dos:

1. Inyección SQL.
2. Cross-Site Scripting reflejado.

**La entrega de solo dos vulnerabilidades requiere autorización del docente.**

## Estructura

- `informe.typ`: informe técnico en Typst.
- `integrantes.md`: registro de aportes del equipo.
- `webgoat-source/`: fuente y pruebas de la versión modificada.
- `evidence/`: evidencias HTTP y capturas.
- `scripts/`: automatización de comprobaciones y capturas.
- `Dockerfile.mitigado`: imagen de la versión mitigada.
- `docker-compose.mitigado.yml`: ejecución aislada de la versión mitigada.

## Versión vulnerable oficial

```bash
sudo docker run --name webgoat-vulnerable \
  -p 127.0.0.1:8080:8080 -p 127.0.0.1:9090:9090 \
  webgoat/webgoat:latest
```

## Compilar y ejecutar la versión mitigada

La fuente requiere Java 25. El JAR no debe ejecutarse con Java 21.

```bash
cd webgoat-source
./mvnw -DskipTests package
cd ..
sudo docker compose -f docker-compose.mitigado.yml up --build
```

La versión mitigada queda disponible en:

- WebGoat: `http://127.0.0.1:8081/WebGoat`
- WebWolf: `http://127.0.0.1:9091/WebWolf`

## Pruebas automatizadas

```bash
cd webgoat-source
./mvnw -Dtest=SqlInjectionLesson5aMitigationTest,CrossSiteScriptingLesson5aMitigationTest test
```

## Capturas headless

Chromium debe estar instalado. Las capturas deben conservar su fecha real y no contener contraseñas, cookies, tokens ni datos personales.

```bash
bash scripts/capture_headless.sh
```

Las capturas de validación posterior deben generarse contra el puerto `8081` cuando el contenedor mitigado esté activo. No se deben fabricar ni fechar retroactivamente.

## Informe

```bash
typst compile informe.typ informe.pdf
```

## Repositorio remoto

Antes de entregar, crear un repositorio privado o autorizado y añadir su URL en este README y en `informe.typ`. No subir secretos ni credenciales.
