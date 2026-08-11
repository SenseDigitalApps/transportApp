# AGENTS.md — Contexto del Proyecto Query

> Archivo de contexto para agentes de código. Mantener actualizado conforme evolucione el proyecto.

---

## 1. Resumen General

**Query** es una aplicación Flutter multiplataforma (Android, iOS, Web) orientada a la gestión de clientes, tareas, registros y visualización de datos. Presenta dos flujos de autenticación diferenciados:

- **Login Clientes** (`login_clientes/`)
- **Login Equipo** (`login_equipo/`)

Además, soporta una versión simplificada llamada **Simple App** (`home_simple_app/`, `detail_simple_app/`) con configuraciones dinámicas.

El proyecto fue inicialmente generado con **FlutterFlow**, pero incluye código custom significativo en `custom_code/`, `custom_pages/`, `config/` y modificaciones en el estado global (`app_state.dart`).

---

## 2. Stack Tecnológico

| Capa | Tecnología / Paquetes |
|------|----------------------|
| Framework | Flutter (SDK >=3.0.0 <4.0.0) |
| State Management | `provider` (FFAppState como ChangeNotifier) |
| Navigation | `go_router` con `url_strategy` (path URLs) |
| Backend / API | REST custom vía `api_manager.dart` + interceptores |
| Persistencia Local | `shared_preferences`, `sqflite` |
| Firebase | `firebase_core`, `firebase_messaging`, `firebase_analytics`, `firebase_in_app_messaging` |
| Notificaciones Push | `flutter_local_notifications` + FCM |
| Imágenes / Media | `cached_network_image`, `image_picker`, `photo_view`, `video_player`, `pdfx` |
| Mapas | `google_maps_flutter`, `geolocator`, `map_launcher` |
| UI / UX | `flutter_animate`, `auto_size_text`, `font_awesome_flutter`, `percent_indicator`, `dropdown_button2` |
| Edición de Texto | `flutter_quill` + extensiones |
| WebView | `webview_flutter`, `webviewx_plus` |
| Otros | `uuid`, `intl`, `timeago`, `path_provider`, `http` |

---

## 3. Arquitectura de Carpetas

```
lib/
├── main.dart                      # Entry point: Firebase, notificaciones, theme, router
├── app_state.dart                 # Estado global (FFAppState) con SharedPreferences
├── index.dart                     # Barrel file (exports)
├── flutter_flow/                  # Utilidades del framework FlutterFlow
│   ├── flutter_flow_theme.dart    # Temas light/dark + utilidades de color
│   ├── flutter_flow_util.dart     # Helpers, extensiones, navegación
│   ├── flutter_flow_widgets.dart  # Widgets reutilizables
│   ├── nav/                       # Configuración de rutas GoRouter
│   ├── custom_functions.dart      # Funciones globales custom
│   └── ...
├── backend/
│   └── api_requests/              # Capa de API
│       ├── api_manager.dart       # Orquestador de requests
│       ├── api_calls.dart         # Definición de endpoints
│       ├── api_interceptor.dart   # Interceptor base
│       └── interceptors/          # Interceptores específicos
├── components/                    # Widgets reutilizables (UI building blocks)
├── config/
│   └── home_widget_registry.dart  # Registro de páginas de inicio dinámicas (custom home pages)
├── controllers/                   # Controladores de lógica de página
├── custom_code/                   # Código Dart completamente custom (no FlutterFlow)
│   └── PushNotificationService.dart
├── pages/                         # Pantallas / Vistas
│   ├── home/                      # Dashboard principal (equipo)
│   ├── home_client/               # Dashboard principal (cliente)
│   ├── home_simple_app/           # Home modo Simple App
│   ├── detail/                    # Detalle genérico
│   ├── detail_simple_app/         # Detalle modo Simple App
│   ├── detail_sense/              # Detalle con sensores/métricas
│   ├── detail_grouped/            # Detalle agrupado
│   ├── login_clientes/            # Login para clientes
│   ├── login_equipo/              # Login para equipo interno
│   ├── notifications/             # Centro de notificaciones
│   ├── tasks/                     # Gestión de tareas
│   ├── new_registers_modules/     # Registro de nuevos módulos
│   ├── user_register/             # Registro de usuarios
│   ├── user_settings/             # Configuración de perfil
│   ├── web_view_viewer/           # Visor WebView genérico
│   ├── web_view_support/          # WebView de soporte
│   ├── pdf_viewer/                # Visor de PDFs
│   ├── upload_sign/               # Carga de firmas (signature)
│   ├── single_page/               # Pantallas sueltas diversas
│   └── custom_pages/              # Páginas custom complejas
│       └── custom-dashboard/
├── providers/                     # Providers adicionales (no confundir con FFAppState)
├── splash_screen/                 # Pantalla de carga
└── widgets/                       # Widgets globales transversales
```

---

## 4. Estado Global (FFAppState)

Archivo: `lib/app_state.dart`

- Singleton ChangeNotifier persistido en `SharedPreferences`.
- Prefijos de clave en prefs: `ff_`.
- Campos principales:
  - Autenticación: `token`, `refreshToken`, `clientId`, `organizacion`, `role`, `permissions`, `modulesPermissions`
  - Usuario: `id`, `username`, `email`, `fullName`, `avatar`, `shortname`
  - UI: `logoLink`, `fondoLink`, `loaderLogo`, `customHomePage`
  - Simple App: `simpleApp`, `simpleAppRole`, `simpleAppSlugModule`, `simpleAppSlugFecha`, `simpleAppSlugFormato`, etc.
  - Contadores: `unreadNotifications`, `pendingTasks`
  - Listas dinámicas: `moduleList`, `recientes`, `roleGroups`, `idAndNameList`, `textoControlador`

> **Regla de oro:** Siempre que se modifique un campo que afecte la UI, usar `update(() { ... })` para notificar listeners.

---

## 5. Navegación

- **Router:** `go_router` configurado en `flutter_flow/nav/`.
- **Estrategia de URL:** `usePathUrlStrategy()` habilitado (sin `#` en web).
- **Páginas de inicio dinámicas:** Se registran en `HomeWidgetRegistry` (`config/home_widget_registry.dart`). Actualmente registrada: `custom-dashboard` → `CustomDashboardWidget`.
- **Deep links / Notificaciones:** Las notificaciones push FCM navegan a `PushNotificationService.fixedRoute`.

---

## 6. Backend & API

- **Manager:** `backend/api_requests/api_manager.dart`
- **Calls:** `backend/api_requests/api_calls.dart`
- **Interceptores:**
  - `api_interceptor.dart`: Interceptor base
  - `interceptor.dart`: Helpers
  - `interceptors/`: Implementaciones específicas (por ejemplo, auth, logging)
- **Streaming:** Soporte de respuestas stream vía `get_streamed_response.dart`

---

## 7. Firebase & Notificaciones Push

Archivo clave: `custom_code/PushNotificationService.dart`

- **FCM:** Configurado para background, foreground y cold start.
- **Handler background:** `PushNotificationService.backgroundHandler`
- **Analytics:** Instancia de `FirebaseAnalytics` inicializada en `main.dart`
- **Local notifications:** Usa `flutter_local_notifications` para mostrar notificaciones locales cuando la app está en foreground.

---

## 8. Assets

Configurados en `pubspec.yaml`:

```yaml
assets:
  - assets/fonts/
  - assets/images/
  - assets/videos/
  - assets/audios/
  - assets/lottie_animations/
  - assets/rive_animations/
  - assets/pdfs/
```

Icono de launcher: `assets/images/app_launcher_icon.png`

---

## 9. Convenciones de Código

- **Estilo:** FlutterFlow genera código con estilo propio; el código custom debe mantener consistencia.
- **Widgets:** Cada página típicamente tiene un archivo `*_widget.dart` y opcionalmente `*_model.dart`.
- **Nombres de archivos:** snake_case para archivos, PascalCase para clases.
- **Colores / Temas:** Usar `FlutterFlowTheme.of(context)` en lugar de colores hardcodeados.
- **Imports:** Preferir imports relativos dentro de `lib/`.

---

## 10. Notas Importantes para Agentes

1. **No eliminar** archivos dentro de `flutter_flow/` a menos que se esté migrando completamente del framework base.
2. **Simple App** depende fuertemente de los campos `simpleApp*` en `FFAppState`. Modificar con precaución.
3. **Notificaciones:** Cualquier cambio en el router puede romper el deep linking de FCM. Validar en `main.dart`.
4. **Persistencia:** `FFAppState` guarda automáticamente en `SharedPreferences`. No es necesario llamar `prefs.set*` manualmente fuera de los setters.
5. **Registro de páginas custom:** Si se crea una nueva home page dinámica, registrarla en `HomeWidgetRegistry` y en `main.dart`.
6. **Dependencias:** El proyecto tiene muchas dependencias nativas (Firebase, Maps, Camera, etc.). Al agregar nuevas, verificar compatibilidad con Android/iOS/Web.

---

## 11. Próximos Pasos Sugeridos (para pulir)

- Documentar endpoints de API específicos.
- Mapear flujo de autenticación (login → refresh token → logout).
- Documentar lógica de permisos (`permissions`, `modulesPermissions`, `roleGroups`).
- Definir arquitectura de datos para Simple App y sus slugs dinámicos.
- Registrar cualquier secreto o config nativa (Firebase options, API keys) que deba manejarse por flavor/environment.
