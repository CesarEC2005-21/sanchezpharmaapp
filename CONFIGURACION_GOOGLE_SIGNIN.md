# Configuración de Google Sign-In

## Cómo obtener el Client ID de Google OAuth 2.0

### Paso 1: Ir a Google Cloud Console
1. Ve a: https://console.cloud.google.com/
2. Crea un nuevo proyecto o selecciona uno existente

### Paso 2: Habilitar Google Sign-In API
1. En el menú lateral, ve a "APIs & Services" > "Library"
2. Busca "Google Sign-In API" o "Google+ API"
3. Haz clic en "Enable"

### Paso 3: Crear Credenciales OAuth 2.0
1. Ve a "APIs & Services" > "Credentials"
2. Haz clic en "Create Credentials" > "OAuth client ID"
3. Si es la primera vez, configura la pantalla de consentimiento OAuth:
   - Tipo de aplicación: Externa
   - Nombre de la app: Sánchez Pharma
   - Email de soporte: tu email
   - Guarda y continúa

### Paso 4: Crear OAuth Client ID para Web
1. Tipo de aplicación: **Web application**
2. Nombre: Sánchez Pharma Web
3. Authorized JavaScript origins:
   - `http://localhost:8080` (para desarrollo local)
   - `https://tu-dominio.com` (para producción)
4. Authorized redirect URIs:
   - `http://localhost:8080` (para desarrollo local)
   - `https://tu-dominio.com` (para producción)
5. Haz clic en "Create"
6. **Copia el Client ID** (formato: `xxxxx.apps.googleusercontent.com`)

### Paso 5: Configurar en la aplicación

#### Opción A: Meta tag en HTML (Recomendado para Web)
Edita `web/index.html` y reemplaza `TU_CLIENT_ID_AQUI` con tu Client ID:
```html
<meta name="google-signin-client_id" content="TU_CLIENT_ID_AQUI.apps.googleusercontent.com">
```

#### Opción B: En el código (Alternativa)
Edita `lib/presentation/screens/login_screen.dart` y descomenta la línea:
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  clientId: 'TU_CLIENT_ID_AQUI.apps.googleusercontent.com',
);
```

### Paso 6: Para Android (si compilas para Android)
1. En Google Cloud Console, crea otro OAuth Client ID
2. Tipo: **Android**
3. Nombre del paquete: `com.example.sanchez_pharma` (o el que uses)
4. SHA-1 certificate fingerprint: Obténlo con:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
5. Agrega el Client ID en `android/app/build.gradle` o en el código

### Paso 7: Para iOS (si compilas para iOS)
1. En Google Cloud Console, crea otro OAuth Client ID
2. Tipo: **iOS**
3. Bundle ID: El de tu app iOS
4. Agrega el Client ID en `ios/Runner/Info.plist` o en el código

## Nota Importante
- El Client ID de Google Maps es diferente al de Google Sign-In
- Necesitas crear credenciales OAuth 2.0 separadas para Google Sign-In
- El Client ID debe ser del tipo "Web application" para que funcione en Flutter Web

## Prueba Rápida (Desarrollo)
Para desarrollo local, puedes usar:
- Origen autorizado: `http://localhost:8080`
- Redirect URI: `http://localhost:8080`

