# Fuentes de lecciones mitigadas

Este directorio contiene los archivos Java relevantes extraídos del código fuente de WebGoat. Se incluyen únicamente las clases modificadas para implementar las mitigaciones y sus tests de validación.

## Estructura

```
src/
├── sqlinjection/
│   └── SqlInjectionLesson5a.java      # Mitigado con PreparedStatement
├── xss/
│   └── CrossSiteScriptingLesson5a.java # Mitigado con HtmlUtils.htmlEscape
└── test/
    ├── SqlInjectionLesson5aMitigationTest.java
    ├── SqlInjectionLesson5aTest.java
    └── CrossSiteScriptingLesson5aMitigationTest.java
```

## Cambios implementados

### SQL Injection — `SqlInjectionLesson5a.java`
- **Antes:** concatenación directa de la entrada del usuario en la cadena SQL
- **Después:** uso de `PreparedStatement` con `setString()` para separar datos de código

### XSS Reflejado — `CrossSiteScriptingLesson5a.java`
- **Antes:** valor de `field1` insertado directamente en la respuesta HTML
- **Después:** `HtmlUtils.htmlEscape(field1)` codifica los metacaracteres HTML antes de incluirlos en la salida
