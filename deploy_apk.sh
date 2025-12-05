#!/bin/bash
# Script de automatización para Linux/Mac
# Uso: ./deploy_apk.sh

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 Iniciando despliegue automático de APK...${NC}"

# ============================================
# CONFIGURACIÓN - AJUSTA ESTOS VALORES
# ============================================
PYTHONANYWHERE_USER="nxlsxx"
PYTHONANYWHERE_HOST="ssh.pythonanywhere.com"
REMOTE_PATH="/home/nxlsxx/mysite/static/downloads"
# Nota: El backend está en PythonAnywhere, no en el proyecto local

# ============================================
# PASO 1: Leer versión del pubspec.yaml
# ============================================
echo -e "\n${YELLOW}📖 Leyendo versión del pubspec.yaml...${NC}"

VERSION=$(grep -E "^version:" pubspec.yaml | sed -E 's/version: ([0-9]+\.[0-9]+\.[0-9]+)\+[0-9]+/\1/')
BUILD=$(grep -E "^version:" pubspec.yaml | sed -E 's/version: [0-9]+\.[0-9]+\.[0-9]+\+([0-9]+)/\1/')

if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ No se pudo leer la versión del pubspec.yaml${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Versión encontrada: $VERSION (build $BUILD)${NC}"

# ============================================
# PASO 2: Generar APK
# ============================================
echo -e "\n${YELLOW}🔨 Generando APK...${NC}"

flutter build apk --release

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al generar el APK${NC}"
    exit 1
fi

echo -e "${GREEN}✅ APK generado correctamente${NC}"

# ============================================
# PASO 3: Renombrar APK
# ============================================
echo -e "\n${YELLOW}📝 Renombrando APK...${NC}"

SOURCE_APK="build/app/outputs/flutter-apk/app-release.apk"
TARGET_APK="sanchezpharmaapp-v$VERSION.apk"

if [ -f "$SOURCE_APK" ]; then
    cp "$SOURCE_APK" "$TARGET_APK"
    echo -e "${GREEN}✅ APK renombrado: $TARGET_APK${NC}"
    
    # Obtener tamaño del APK
    APK_SIZE=$(stat -f%z "$TARGET_APK" 2>/dev/null || stat -c%s "$TARGET_APK" 2>/dev/null)
    APK_SIZE_MB=$(echo "scale=2; $APK_SIZE / 1048576" | bc)
    echo -e "${YELLOW}   Tamaño: ${APK_SIZE_MB} MB ($APK_SIZE bytes)${NC}"
else
    echo -e "${RED}❌ No se encontró el APK generado${NC}"
    exit 1
fi

# ============================================
# PASO 4: Subir APK a PythonAnywhere (vía SCP)
# ============================================
echo -e "\n${YELLOW}📤 Subiendo APK a PythonAnywhere...${NC}"
echo -e "${YELLOW}   Usuario: $PYTHONANYWHERE_USER${NC}"
echo -e "${YELLOW}   Host: $PYTHONANYWHERE_HOST${NC}"
echo -e "${YELLOW}   Destino: $REMOTE_PATH${NC}"

REMOTE_FILE="$PYTHONANYWHERE_USER@$PYTHONANYWHERE_HOST:$REMOTE_PATH/$TARGET_APK"

echo -e "${YELLOW}   Subiendo archivo...${NC}"
scp "$TARGET_APK" "$REMOTE_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ APK subido correctamente${NC}"
else
    echo -e "${RED}❌ Error al subir el APK. Verifica tus credenciales SSH.${NC}"
    echo -e "${YELLOW}   Puedes subirlo manualmente a: $REMOTE_PATH${NC}"
fi

# ============================================
# PASO 5: Instrucciones para actualizar backend
# ============================================
echo -e "\n${YELLOW}⚙️  Información para actualizar backend en PythonAnywhere...${NC}"
echo -e "${YELLOW}   El backend está en PythonAnywhere, actualiza manualmente:${NC}"
echo -e "\n${YELLOW}   📝 Edita el archivo de rutas en PythonAnywhere:${NC}"
echo -e "${YELLOW}      Busca la línea: LATEST_VERSION = \"X.X.X\"${NC}"
echo -e "${GREEN}      Cámbiala a:     LATEST_VERSION = \"$VERSION\"${NC}"
echo -e "\n${YELLOW}   📏 Actualiza el tamaño del APK:${NC}"
echo -e "${YELLOW}      Busca la línea: APK_SIZE = XXXXXXX${NC}"
echo -e "${GREEN}      Cámbiala a:     APK_SIZE = $APK_SIZE  # ${APK_SIZE_MB} MB${NC}"
echo -e "\n${YELLOW}   🔄 Después de editar, reinicia el servidor en PythonAnywhere${NC}"

# ============================================
# RESUMEN
# ============================================
echo -e "\n${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ DESPLIEGUE COMPLETADO${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Versión: $VERSION${NC}"
echo -e "${YELLOW}APK: $TARGET_APK${NC}"
echo -e "${YELLOW}Tamaño: ${APK_SIZE_MB} MB${NC}"
echo -e "${YELLOW}URL: https://nxlsxx.pythonanywhere.com/static/downloads/$TARGET_APK${NC}"
echo -e "\n${YELLOW}📋 Próximos pasos:${NC}"
echo -e "${YELLOW}   1. Ve a PythonAnywhere → Files${NC}"
echo -e "${YELLOW}   2. Edita tu archivo de rutas (ej: rutas.txt o app.py)${NC}"
echo -e "${YELLOW}   3. Actualiza LATEST_VERSION = \"$VERSION\"${NC}"
echo -e "${YELLOW}   4. Actualiza APK_SIZE = $APK_SIZE${NC}"
echo -e "${YELLOW}   5. Reinicia el servidor en PythonAnywhere${NC}"
echo -e "${YELLOW}   6. Verifica la URL del APK en el navegador${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

