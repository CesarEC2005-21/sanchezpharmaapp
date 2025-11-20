# Arquitectura de Sánchez Pharma App

## 📁 Estructura de Carpetas

```
lib/
├── core/                       # Núcleo de la aplicación
│   ├── constants/             # Constantes globales
│   │   └── api_constants.dart # URLs y endpoints de la API
│   └── utils/                 # Utilidades
│       └── shared_prefs_helper.dart # Manejo de SharedPreferences
│
├── data/                      # Capa de datos
│   ├── api/                   # Servicios API con Retrofit
│   │   ├── api_service.dart   # Definición de endpoints
│   │   ├── api_service.g.dart # Código generado por Retrofit
│   │   └── dio_client.dart    # Configuración de Dio
│   └── models/                # Modelos de datos
│       ├── user_model.dart    # Modelo de usuario
│       ├── login_request.dart # Modelo de petición de login
│       ├── login_response.dart# Modelo de respuesta de login
│       └── *.g.dart           # Archivos generados por json_serializable
│
├── presentation/              # Capa de presentación
│   ├── screens/              # Pantallas de la app
│   │   ├── login_screen.dart # Pantalla de inicio de sesión
│   │   └── dashboard_screen.dart # Dashboard principal
│   └── widgets/              # Widgets reutilizables
│       └── custom_drawer.dart # Menú hamburguesa personalizado
│
└── main.dart                 # Punto de entrada de la app
```

## 🏗️ Arquitectura

La aplicación sigue una arquitectura por capas:

### 1. **Core Layer** (Núcleo)
- **Constantes**: URLs de la API, endpoints, configuraciones globales
- **Utilidades**: Helpers para SharedPreferences, formatters, etc.

### 2. **Data Layer** (Capa de Datos)
- **API Service**: Usando Retrofit para las llamadas HTTP
- **Models**: Modelos de datos con serialización JSON automática
- **Dio Client**: Cliente HTTP configurado con interceptores

### 3. **Presentation Layer** (Capa de Presentación)
- **Screens**: Pantallas completas de la aplicación
- **Widgets**: Componentes UI reutilizables

## 🔑 Características Implementadas

### ✅ Login
- Pantalla de login con validación de campos
- Integración con API Flask usando Retrofit
- Almacenamiento seguro de token JWT
- Manejo de errores y feedback visual

### ✅ Dashboard
- Pantalla principal post-login
- Menú hamburguesa (drawer) personalizado
- Cards de acceso rápido a módulos
- Botón de cerrar sesión

### ✅ Autenticación
- Persistencia de sesión con SharedPreferences
- Splash screen que verifica autenticación
- Interceptor Dio para agregar token automáticamente
- Logout con limpieza de datos locales

## 🔧 Tecnologías Utilizadas

- **Flutter**: Framework principal
- **Retrofit**: Cliente HTTP type-safe
- **Dio**: Cliente HTTP con interceptores
- **json_serializable**: Serialización JSON automática
- **shared_preferences**: Almacenamiento local
- **flutter_spinkit**: Indicadores de carga

## 🚀 Cómo Usar

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Generar código (si se modifican modelos o API)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Ejecutar la aplicación
```bash
flutter run
```

## 🔐 API Integration

La aplicación se conecta a la API Flask en:
- **Base URL**: `https://nxlsxx.pythonanywhere.com`
- **Login Endpoint**: `/api_login`

### Endpoints Configurados:
- `POST /api_login` - Iniciar sesión
- `POST /api_logout` - Cerrar sesión
- `GET /usuarios_sanchezpharma` - Listar usuarios
- `POST /registrar_usuario_sanchezpharma` - Registrar usuario

## 📝 Flujo de Autenticación

1. Usuario ingresa credenciales en `LoginScreen`
2. Se envía petición POST a `/api_login` usando Retrofit
3. Si es exitoso, se guarda token y datos de usuario en SharedPreferences
4. Se navega a `DashboardScreen`
5. Todas las peticiones subsiguientes incluyen el token automáticamente
6. Al cerrar sesión, se limpia SharedPreferences y se vuelve a Login

## 🎨 Diseño

- **Material Design 3**: UI moderna y consistente
- **Gradientes**: Efectos visuales atractivos
- **Responsive**: Adaptable a diferentes tamaños de pantalla
- **Iconografía**: Icons de Material para mejor UX

## 🔄 Próximos Pasos

- [ ] Implementar módulo de Usuarios
- [ ] Implementar módulo de Inventario
- [ ] Implementar módulo de Ventas
- [ ] Implementar módulo de Reportes
- [ ] Agregar manejo de estados con Provider/Bloc
- [ ] Agregar tests unitarios
- [ ] Agregar tests de integración

## 👨‍💻 Desarrollo

Para agregar nuevos endpoints:

1. Actualiza `api_constants.dart` con el nuevo endpoint
2. Agrega el método en `api_service.dart`
3. Ejecuta build_runner para regenerar código
4. Usa el servicio en tus screens

```dart
final dio = DioClient.createDio();
final apiService = ApiService(dio);
final response = await apiService.tuNuevoEndpoint();
```

