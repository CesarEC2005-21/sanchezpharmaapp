# Solución para Error ApiException: 7 en Google Sign-In

## Problema
El error `ApiException: 7` (NETWORK_ERROR) en Google Sign-In generalmente indica un problema de configuración en Google Cloud Console.

## Soluciones

### 1. Verificar SHA-1 en Google Cloud Console

El SHA-1 del certificado de firma debe estar registrado en Google Cloud Console.

#### Obtener el SHA-1:

**Para Debug (desarrollo):**
```bash
cd android
./gradlew signingReport
```

O en Windows:
```bash
cd android
gradlew signingReport
```

Busca la línea que dice `SHA1:` en la sección `Variant: debug`

**Para Release (producción):**
Si tienes un keystore de release, usa:
```bash
keytool -list -v -keystore tu-keystore.jks -alias tu-alias
```

#### Registrar SHA-1 en Google Cloud Console:

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto
3. Ve a **APIs & Services** > **Credentials**
4. Busca tu **OAuth 2.0 Client ID** de tipo **Android**
5. Haz clic en editar
6. Agrega el SHA-1 en el campo correspondiente
7. Guarda los cambios

### 2. Verificar Package Name

El package name debe coincidir exactamente con el configurado en Google Cloud Console.

**Package name actual de tu app:**
```
com.example.sanchez_pharma
```

**Verificar en Google Cloud Console:**
1. Ve a **APIs & Services** > **Credentials**
2. Busca tu **OAuth 2.0 Client ID** de tipo **Android**
3. Verifica que el **Package name** sea exactamente: `com.example.sanchez_pharma`

### 3. Verificar que Google Sign-In API esté habilitada

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto
3. Ve a **APIs & Services** > **Library**
4. Busca "Google Sign-In API" o "Google+ API"
5. Asegúrate de que esté habilitada

### 4. Verificar conexión a Internet

Aunque el error dice "network_error", puede ser un problema de configuración. Sin embargo, verifica:
- Que tengas conexión a Internet activa
- Que Google Play Services esté actualizado en tu dispositivo
- Que no haya un firewall bloqueando las conexiones

### 5. Limpiar y reconstruir la app

```bash
flutter clean
flutter pub get
flutter run
```

### 6. Verificar Google Play Services

En el dispositivo Android:
1. Ve a **Configuración** > **Aplicaciones**
2. Busca **Google Play Services**
3. Asegúrate de que esté actualizado
4. Si no, actualízalo desde Google Play Store

## Configuración Actual

- **Package Name:** `com.example.sanchez_pharma`
- **Google Sign-In:** Configurado en `lib/presentation/screens/login_screen.dart`
- **Scopes:** `['email', 'profile']`

## Notas Importantes

1. **SHA-1 de Debug vs Release:** Necesitas registrar ambos SHA-1 si vas a usar la app en modo debug y release
2. **Tiempo de propagación:** Los cambios en Google Cloud Console pueden tardar unos minutos en aplicarse
3. **Múltiples dispositivos:** Si pruebas en diferentes dispositivos, cada uno puede tener un SHA-1 diferente si usan certificados diferentes

## Comandos Útiles

### Obtener SHA-1 rápidamente:
```bash
# Windows
cd android && gradlew signingReport

# Linux/Mac
cd android && ./gradlew signingReport
```

### Verificar configuración actual:
```bash
flutter doctor -v
```

## Si el problema persiste

1. Verifica los logs completos en Android Studio o usando `flutter run -v`
2. Revisa que el OAuth 2.0 Client ID esté correctamente configurado
3. Asegúrate de que el proyecto en Google Cloud Console sea el correcto
4. Verifica que no haya restricciones de IP o dominio en las credenciales de OAuth

