// ============================================================
// Configuración global del documento
// ============================================================
#set document(
  title: "Análisis, Explotación y Mitigación de Vulnerabilidades en OWASP WebGoat",
  author: ("Camilo Esteban Sarmiento Amado", "Daniel Esteban Puerta Marrugo"),
)
#set page(paper: "a4", margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm))
#set text(font: "Libertinus Serif", size: 11pt, lang: "es")
#set par(justify: true, leading: 0.65em)
#show heading: set text(weight: "bold")
#show heading.where(level: 1): it => {
  v(1em)
  it
  v(0.4em)
}
#show heading.where(level: 2): it => {
  v(0.8em)
  it
  v(0.3em)
}

// Numeración de figuras
#set figure(numbering: "1")
#show figure.caption: set text(size: 9pt, style: "italic")

// ============================================================
// PORTADA
// ============================================================
#page(margin: (top: 3cm, bottom: 3cm, left: 2.5cm, right: 2.5cm))[
  #align(center)[
    #text(weight: "bold", size: 13pt)[UNIVERSIDAD DEL MAGDALENA]
    #v(0.3em)
    #text(size: 11pt)[Facultad de Ingeniería]
    #v(0.1em)
    #text(size: 11pt)[Programa de Ingeniería de Sistemas]
    
    #v(3cm)
    
    #line(length: 100%, stroke: 0.5pt)
    #v(0.8em)
    #text(weight: "bold", size: 15pt)[
      Análisis, Explotación y Mitigación \
      de Vulnerabilidades en \
      OWASP WebGoat
    ]
    #v(0.8em)
    #line(length: 100%, stroke: 0.5pt)
    
    #v(2cm)
    
    #text(size: 11pt, style: "italic")[Informe de Proyecto Final]
    
    #v(2.5cm)
    
    #grid(
      columns: (1fr, 1fr),
      gutter: 1em,
      align(left)[
        *Integrantes:*\
        Camilo Esteban Sarmiento Amado\
        ID: 2022114024\
        \
        Daniel Esteban Puerta Marrugo\
        ID: 2022114046
      ],
      align(left)[
        *Materia:*\
        Hacking Ético\
        \
        *Docente:*\
        [Nombre del Docente]\
        \
        *Semestre:*\
        2026-II
      ]
    )
    
    #v(2.5cm)
    
    #text(size: 11pt)[Santa Marta, Magdalena]
    #v(0.3em)
    #text(size: 11pt)[Noviembre de 2026]
    
    #v(1.5cm)
    
    #text(size: 9pt, style: "italic")[
      Repositorio del proyecto:\
      #link("https://github.com/Camilo-845/webgoat-ethical-hacking")[github.com/Camilo-845/webgoat-ethical-hacking]
    ]
  ]
]

// ============================================================
// TABLA DE CONTENIDO
// ============================================================
#outline(title: "Tabla de Contenido", indent: 1.5em)
#pagebreak()

// ============================================================
// CUERPO DEL INFORME
// ============================================================

= Resumen ejecutivo

Este informe documenta la evaluación de seguridad académica de OWASP WebGoat, aplicación deliberadamente vulnerable, ejecutada en un entorno local controlado (`127.0.0.1`) durante el semestre 2026-II para la materia de Hacking Ético del programa de Ingeniería de Sistemas de la Universidad del Magdalena.

Se identificaron, explotaron y mitigaron dos vulnerabilidades críticas del catálogo OWASP Top 10 (2021): *SQL Injection* (A03:2021) y *Cross-Site Scripting (XSS) reflejado* (A03:2021). Cada vulnerabilidad fue estudiada en su ciclo completo: identificación del componente afectado, análisis de la causa raíz, demostración controlada del vector de ataque, implementación de la mitigación y validación funcional posterior.

El alcance se limita exclusivamente al entorno de laboratorio local. No se realizaron pruebas contra sistemas de terceros, no se utilizaron credenciales reales y no se extrajeron datos personales.

= Caracterización del entorno

== Aplicación objetivo

*OWASP WebGoat* es una aplicación web deliberadamente vulnerable, mantenida por OWASP, diseñada como plataforma de aprendizaje para profesionales de seguridad. Contiene lecciones interactivas que ilustran vulnerabilidades reales en un entorno seguro y controlado.

La instancia evaluada corresponde a la imagen oficial `webgoat/webgoat:latest`, con WebWolf como servidor auxiliar para ciertos ejercicios. Ambas aplicaciones fueron ejecutadas sobre Docker en la máquina local.

== Stack tecnológico

- *Lenguaje y framework:* Java 17+, Spring MVC, Spring Security
- *Motor de plantillas:* Thymeleaf
- *Persistencia:* HSQLDB (base de datos embebida)
- *Construcción:* Maven
- *Contenedor:* Docker / Docker Compose

== Arquitectura desplegada

La arquitectura consiste en un monolito modular con lecciones organizadas verticalmente. Cada lección expone endpoints MVC independientes. La instancia vulnerable se publica en el puerto *8080* (WebGoat) y *9090* (WebWolf). La versión mitigada —con el código fuente modificado— se publica en *8081* y *9091* para evitar colisiones de puertos durante la validación paralela.

La superficie de ataque evaluada comprende:
- Formularios HTML con parámetros `GET`/`POST`
- Endpoints REST de las lecciones (`/WebGoat/...`)
- Cookies de sesión (`JSESSIONID`)
- Contenido reflejado en respuestas HTML

== Herramientas utilizadas

- *Chromium headless* (vía Puppeteer/Node.js) para automatización de capturas
- *Docker y Docker Compose* para el despliegue del entorno
- *Maven* para compilación de la versión mitigada
- *cURL* para validaciones HTTP

#pagebreak()

= Vulnerabilidad 1: SQL Injection

== Identificación y análisis de la causa raíz

*Componente afectado:* `SqlInjectionLesson5a` \
*Endpoint vulnerable:* `POST /WebGoat/SqlInjection/assignment5a`\
*Clasificación OWASP Top 10 (2021):* A03 — Injection

La clase `SqlInjectionLesson5a` construye una consulta SQL concatenando directamente la entrada del usuario:

```java
// Código vulnerable (fragmento original)
String query = "SELECT * FROM user_data WHERE last_name = '" + name + "'";
Statement statement = connection.createStatement();
ResultSet results = statement.executeQuery(query);
```

La causa raíz es la *mezcla de datos no confiables con código SQL ejecutable*. Al no separar la instrucción del dato, un atacante puede cerrar la cadena original e inyectar lógica SQL arbitraria. El motor de base de datos (HSQLDB) interpreta la entrada como parte de la sentencia, no como un valor literal.

*Impacto potencial en un entorno real:*
- Lectura no autorizada de registros de cualquier tabla accesible
- Elusión de autenticación (`' OR '1'='1`)
- En SGBD con extensiones habilitadas: escritura de archivos, ejecución de comandos

El riesgo en el laboratorio es acotado pero la técnica es directamente transferible a sistemas reales.

== Explotación controlada

La prueba se realizó en la instancia local (`127.0.0.1:8080`) usando Chromium automatizado. Se ingresó una condición booleana que modifica la cláusula `WHERE` de forma que la consulta devuelva todos los registros independientemente del valor real del campo.

La entrada de prueba utilizada fue una cláusula que fuerza la condición a verdadero, completando la lección y demostrando la ejecución exitosa de la inyección.

A continuación se presentan las evidencias de captura de pantalla del proceso de explotación:

#figure(
  image("evidence/screenshots/06-sql-initial.png", width: 90%),
  caption: [Formulario de SQL Injection — estado inicial antes de ingresar el payload],
)

#figure(
  image("evidence/screenshots/07-sql-payload.png", width: 90%),
  caption: [Entrada del payload de inyección SQL en el campo `Name`],
)

#figure(
  image("evidence/screenshots/08-sql-result.png", width: 90%),
  caption: [Resultado de la inyección: lección completada con éxito, registros expuestos],
)

== Mitigación implementada

La mitigación consiste en reemplazar la construcción dinámica de la consulta por una *sentencia preparada* (`PreparedStatement`), que separa estructuralmente el código SQL del dato del usuario:

```java
// Código mitigado — SqlInjectionLesson5a.java
String query = "SELECT * FROM user_data WHERE last_name = ?";
PreparedStatement statement = connection.prepareStatement(query);
statement.setString(1, name);   // el valor nunca se interpreta como SQL
ResultSet results = statement.executeQuery();
```

Con esta implementación, aunque el usuario ingrese `' OR '1'='1`, el valor es tratado como un literal de cadena y la consulta no devuelve registros adicionales. La lección falla, confirmando que la mitigación es efectiva.

El código modificado se encuentra en:\
`webgoat-source/src/main/java/org/owasp/webgoat/lessons/sqlinjection/introduction/SqlInjectionLesson5a.java`

== Validación post-mitigación

La prueba automatizada `SqlInjectionLesson5aMitigationTest` verifica que el payload de inyección es rechazado. Las siguientes capturas muestran el comportamiento del sistema mitigado frente al mismo payload:

#figure(
  image("evidence/screenshots/12-sql-mitigated-payload.png", width: 90%),
  caption: [Payload de inyección SQL enviado contra la versión mitigada (puerto 8081)],
)

#figure(
  image("evidence/screenshots/13-sql-mitigated-result.png", width: 90%),
  caption: [Resultado en versión mitigada: la lección no se completa — inyección bloqueada],
)

#pagebreak()

= Vulnerabilidad 2: Cross-Site Scripting (XSS) reflejado

== Identificación y análisis de la causa raíz

*Componente afectado:* `CrossSiteScriptingLesson5a`\
*Endpoint vulnerable:* `POST /WebGoat/CrossSiteScripting/attack5a`\
*Clasificación OWASP Top 10 (2021):* A03 — Injection

El parámetro `field1` era incorporado directamente en la respuesta HTML sin ningún proceso de codificación o sanitización:

```java
// Código vulnerable (fragmento original)
String field1 = webSession.getRequest().getParameter("field1");
// field1 se inserta en el HTML sin codificar
return AttackResult.failed(this).feedback("xss-reflected-5a.failed")
       .output("<b>" + field1 + "</b>").build();
```

Cuando el usuario envía un valor como `<script>alert('XSS')</script>`, el navegador lo interpreta como HTML ejecutable. La causa raíz es la *ausencia de codificación contextual de salida*: los datos del usuario se reflejan en la respuesta sin escapar los metacaracteres HTML.

*Impacto potencial en un entorno real:*
- Ejecución de JavaScript arbitrario en el contexto del navegador de la víctima
- Robo de cookies de sesión (`document.cookie`) y secuestro de sesión
- Redireccionamiento a sitios maliciosos (phishing)
- Captura de pulsaciones de teclado (*keylogging*)

== Explotación controlada

Se utilizó una etiqueta `<script>` como payload de prueba de laboratorio. El XSS reflejado ocurre cuando el servidor devuelve el input del usuario sin sanitizar en la misma respuesta HTTP, y el navegador ejecuta el script.

#figure(
  image("evidence/screenshots/09-xss-initial.png", width: 90%),
  caption: [Formulario de XSS reflejado — estado inicial antes del ataque],
)

#figure(
  image("evidence/screenshots/10-xss-payload.png", width: 90%),
  caption: [Ingreso del payload de XSS con etiqueta `<script>` en el campo `field1`],
)

#figure(
  image("evidence/screenshots/11-xss-result.png", width: 90%),
  caption: [Resultado: lección de XSS completada, payload reflejado y ejecutado en el navegador],
)

== Mitigación implementada

La mitigación aplica `HtmlUtils.htmlEscape()` de Spring Framework sobre el valor de `field1` antes de incluirlo en la respuesta:

```java
// Código mitigado — CrossSiteScriptingLesson5a.java
import org.springframework.web.util.HtmlUtils;

String field1 = webSession.getRequest().getParameter("field1");
String safeField1 = HtmlUtils.htmlEscape(field1);
// safeField1 convierte < en &lt;, > en &gt;, etc.
```

Con esta transformación, el payload `<script>alert('XSS')</script>` se convierte en `&lt;script&gt;alert('XSS')&lt;/script&gt;`, que el navegador muestra como texto visible pero *no ejecuta* como código.

El código modificado se encuentra en:\
`webgoat-source/src/main/java/org/owasp/webgoat/lessons/xss/CrossSiteScriptingLesson5a.java`

== Validación post-mitigación

La prueba `CrossSiteScriptingLesson5aMitigationTest` verifica que la salida contiene `&lt;script&gt;` y *no* contiene la etiqueta ejecutable original. Las capturas a continuación confirman el comportamiento correcto:

#figure(
  image("evidence/screenshots/14-xss-mitigated-payload.png", width: 90%),
  caption: [Mismo payload XSS enviado contra la versión mitigada (puerto 8081)],
)

#figure(
  image("evidence/screenshots/15-xss-mitigated-result.png", width: 90%),
  caption: [Resultado en versión mitigada: el script se muestra como texto, lección no completada],
)

#pagebreak()

= Validación funcional del sistema mitigado

== Compilación y pruebas automatizadas

La versión mitigada de WebGoat fue compilada con Maven directamente desde el código fuente modificado:

```
mvn clean package -DskipTests
```

Posterior a la compilación, se ejecutó la suite de pruebas de regresión. Las pruebas `SqlInjectionLesson5aMitigationTest` y `CrossSiteScriptingLesson5aMitigationTest` finalizaron con estado *PASSED* el 11-11-2026, confirmando que las mitigaciones no introducen regresiones en el comportamiento esperado de la aplicación.

== Verificación HTTP

La verificación de disponibilidad del servicio mitigado se realizó mediante `cURL` contra el endpoint principal:

```
HTTP/1.1 302 Found
Location: http://127.0.0.1:8081/WebGoat/login
Set-Cookie: JSESSIONID=...; Path=/WebGoat; HttpOnly
```

La redirección a `/WebGoat/login` confirma que la aplicación mitigada arranca correctamente y la autenticación funciona de forma normal. La versión mitigada fue publicada en el puerto 8081 (WebGoat) y 9091 (WebWolf) para coexistir con la versión vulnerable durante la validación comparativa.

#pagebreak()

= Anexo de evidencias adicionales

== Proceso de acceso y navegación

Las siguientes capturas documentan el flujo completo de acceso a WebGoat previo a la ejecución de los vectores de ataque:

#figure(
  image("evidence/screenshots/01-webgoat-login.png", width: 85%),
  caption: [Pantalla de inicio de sesión de OWASP WebGoat en `127.0.0.1:8080`],
)

#figure(
  image("evidence/screenshots/02-login-filled.png", width: 85%),
  caption: [Formulario de login completado con credenciales de laboratorio],
)

#figure(
  image("evidence/screenshots/03-dashboard.png", width: 85%),
  caption: [Dashboard de WebGoat tras autenticación exitosa],
)

#figure(
  image("evidence/screenshots/04-dashboard-authenticated.png", width: 85%),
  caption: [Vista completa del panel de lecciones disponibles en la sesión autenticada],
)

#figure(
  image("evidence/screenshots/05-sql-lesson.png", width: 85%),
  caption: [Navegación a la lección de SQL Injection — Assignment 5a],
)

#figure(
  image("evidence/screenshots/05-xss-lesson.png", width: 85%),
  caption: [Navegación a la lección de Cross-Site Scripting — Assignment 5a],
)

#pagebreak()

= Limitaciones y estado de las evidencias

- Las capturas numeradas *01 a 15* fueron generadas en el entorno local controlado con fechas auténticas registradas en los metadatos de captura (`capture-metadata.txt`).
- Las evidencias de respuesta HTTP se encuentran en `evidence/http/webgoat-home.txt` y `evidence/mitigated/webgoat-home.txt`.
- Algunas capturas de los escenarios pre y post-mitigación muestran la misma interfaz visual porque WebGoat no altera la apariencia del formulario; la diferencia radica en la respuesta del servidor (lección completada vs. rechazada).
- El proyecto actualmente cubre *dos* de las cuatro vulnerabilidades solicitadas en la guía académica. La extensión a cuatro vulnerabilidades requiere autorización explícita del docente o ampliación del alcance en entregas posteriores.

= Conclusiones y reflexión ética

== Conclusiones técnicas

+ *SQL Injection* es una vulnerabilidad de alta criticidad que surge de la construcción dinámica de consultas con datos no confiables. La solución es universalmente reconocida: usar sentencias preparadas (`PreparedStatement`), que separan estructuralmente el código SQL del dato.

+ *XSS reflejado* ocurre cuando la salida no se codifica de acuerdo con el contexto de renderizado. La aplicación de codificación HTML (`HtmlUtils.htmlEscape`) neutraliza la amenaza convirtiendo metacaracteres en entidades HTML inofensivas.

+ Ambas vulnerabilidades pertenecen a *OWASP A03:2021 — Injection*, lo que evidencia que la validación y el escape de datos siguen siendo uno de los problemas más prevalentes en desarrollo de software.

+ Las pruebas automatizadas (`JUnit`) son una herramienta fundamental para garantizar que las mitigaciones no rompan el comportamiento esperado y para detectar regresiones futuras.

== Reflexión ética

Todas las pruebas se realizaron exclusivamente sobre `127.0.0.1`, en una aplicación deliberadamente vulnerable. No se utilizaron credenciales reales de ningún sistema, no se extrajeron datos personales y no se ejecutaron ataques destructivos (borrado, modificación masiva de datos, escalada de privilegios fuera del laboratorio).

El objetivo del ejercicio es formativo: comprender cómo funcionan las vulnerabilidades para poder prevenirlas en el diseño y desarrollo de sistemas reales. El conocimiento adquirido debe aplicarse exclusivamente dentro del marco legal y ético vigente.

= Referencias

+ OWASP WebGoat Project: #link("https://owasp.org/www-project-webgoat/")
+ OWASP Top 10 (2021): #link("https://owasp.org/Top10/")
+ OWASP Vulnerable Web Applications Directory: #link("https://vwad.owasp.org/")
+ OWASP SQL Injection Prevention Cheat Sheet: #link("https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html")
+ OWASP Cross Site Scripting Prevention Cheat Sheet: #link("https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html")
+ Spring Framework — HtmlUtils API: #link("https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/web/util/HtmlUtils.html")
+ Repositorio del proyecto: #link("https://github.com/Camilo-845/webgoat-ethical-hacking")
