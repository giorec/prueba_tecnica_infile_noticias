# Infile News App - Backend & Mobile

Este repositorio contiene el código fuente completo de la aplicación móvil de noticias "Infile News App", desarrollada bajo estrictos estándares de ciberseguridad, alineada con arquitecturas de Defensa en Profundidad y OWASP Mobile Application Security.

El proyecto está dividido en dos grandes componentes: una Web API en .NET Core para el backend y una aplicación móvil en Flutter para el frontend.

## 🚀 Arquitectura General

*   **Backend:** ASP.NET Core 8 Web API
*   **Frontend (Móvil):** Flutter (Dart) con gestión de estado BLoC/Riverpod
*   **Base de Datos:** PostgreSQL
*   **Persistencia (ORM):** Entity Framework Core
*   **Identidad y Acceso:** JWT (Access/Refresh Tokens), Argon2id (Hashing), Role-Based Access Control
*   **Integración de Noticias:** Consumo de APIs externas (MediaStack / NewsAPI)

## 🛡️ Características de Seguridad (Nivel Bancario)

Este proyecto implementa múltiples capas de seguridad para proteger los datos del usuario y la integridad del sistema:

*   **Políticas de Contraseña:** Mínimo 13 caracteres, combinando mayúsculas, minúsculas, números y caracteres especiales.
*   **Manejo Seguro de Tokens:** Los tokens de sesión se almacenan exclusivamente en medios criptográficos por hardware (`flutter_secure_storage` - Keystore/Keychain).
*   **Certificate Pinning:** Protección contra ataques Man-In-The-Middle (MITM) validando el certificado SSL del servidor en el cliente.
*   **Protección en Tiempo de Ejecución (RASP):** Detección de entornos vulnerados (Root, Jailbreak, Emuladores, Depuradores) mediante la librería `freerasp`.
*   **Biometría Criptográfica:** Uso de huella dactilar/reconocimiento facial para desencriptar credenciales almacenadas localmente, no como un simple control booleano.
*   **Cierre por Inactividad:** Sistema automático de bloqueo tras un periodo de inactividad configurable.
*   **Protección de Red:** Implementación de *Rate Limiting* en el servidor para mitigar ataques de fuerza bruta.

## ⚙️ Requisitos Previos

Asegúrate de tener instalados los siguientes componentes antes de ejecutar el proyecto:

*   [.NET 8 SDK](https://dotnet.microsoft.com/download)
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (Última versión estable)
*   [PostgreSQL](https://www.postgresql.org/download/) (Versión 14 o superior)
*   IDE recomendado: Visual Studio 2022 / JetBrains Rider (para backend) y Cursor / VS Code (para Flutter).

## 🛠️ Configuración y Despliegue

### 1. Configuración del Backend (.NET)

1.  Navega a la carpeta del proyecto de backend: `cd backend/InfileNews.API`
2.  Configura las variables de entorno en el archivo `appsettings.json` o mediante User Secrets:
    *   Cadena de conexión a la base de datos PostgreSQL (`DefaultConnection`).
    *   `JwtSettings` (Clave secreta, emisor, audiencia y tiempos de expiración).
    *   API Keys de los proveedores externos de noticias.
3.  Aplica las migraciones a la base de datos:
    ```bash
    dotnet ef database update
    ```
4.  Ejecuta la API:
    ```bash
    dotnet run
    ```
    *La documentación Swagger estará disponible en `https://localhost:<puerto>/swagger`*

### 2. Configuración del Frontend (Flutter)

1.  Navega a la carpeta de la aplicación móvil: `cd mobile/infile_news_app`
2.  Instala las dependencias del proyecto:
    ```bash
    flutter pub get
    ```
3.  Configura la URL base del backend en el archivo de entorno (ej. `.env`). Asegúrate de usar la IP local de tu máquina si pruebas en emulador (no uses `localhost`).
4.  Configura el hash SHA-256 de tu certificado SSL local para habilitar el *Certificate Pinning* en desarrollo.
5.  Ejecuta la aplicación:
    ```bash
    flutter run
    ```

## 📊 Algoritmo de Personalización de Feed

El backend incorpora un motor de afinidad híbrido. El modelo de datos registra las votaciones del usuario ("Me gusta / No me gusta") por categoría de noticia. Al consultar el feed, el algoritmo ensambla la respuesta entregando un **70% de noticias afines al perfil del usuario** y un **30% de noticias generales** para garantizar el descubrimiento orgánico de información y evitar burbujas de filtro.

## 📖 Documentación Adicional

Toda la documentación relacionada con el ciclo de vida del proyecto se gestiona de forma estructurada:
*   **Gestión y Tareas:** Azure DevOps (Repos/Boards).
*   **Documentación de API:** Autogenerada mediante Swagger/OpenAPI.
*   **Casos de Uso y Operaciones:** Disponibles en la Wiki interna del repositorio.

---
*Desarrollado para la evaluación técnica del portal de noticias Infile.*
