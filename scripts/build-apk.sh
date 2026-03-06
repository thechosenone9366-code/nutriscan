#!/bin/bash
# ============================================================
#  NutriScan — Script de build APK automatique
#  Lance ce script sur ton PC depuis le dossier nutriscan-apk/
#  Usage : chmod +x build-apk.sh && ./build-apk.sh
# ============================================================

set -e  # Arrête si une erreur

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}╔════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║   NutriScan — Build APK Android    ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════╝${NC}"
echo ""

# ── 1. Vérifie les prérequis ──────────────────────────────────
echo -e "${YELLOW}[1/7] Vérification des prérequis...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js non trouvé. Télécharge : https://nodejs.org${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Node.js $(node --version)${NC}"

if ! command -v java &> /dev/null; then
    echo -e "${RED}✗ Java (JDK 17+) requis. Télécharge : https://adoptium.net${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Java $(java -version 2>&1 | head -1)${NC}"

if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    echo ""
    echo -e "${YELLOW}⚠ ANDROID_HOME non défini.${NC}"
    echo -e "  Télécharge Android Studio : ${CYAN}https://developer.android.com/studio${NC}"
    echo -e "  Puis installe SDK via : SDK Manager → SDK Tools → Build Tools 34+"
    echo ""
    echo -e "  Ou définis manuellement (Linux/Mac) :"
    echo -e "  ${CYAN}export ANDROID_HOME=\$HOME/Android/Sdk${NC}"
    echo -e "  ${CYAN}export PATH=\$PATH:\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools${NC}"
    echo ""
    read -p "Continuer quand même ? (l'APK sera généré via Android Studio) [o/N] " answer
    if [[ "$answer" != "o" && "$answer" != "O" ]]; then
        exit 0
    fi
fi

# ── 2. Installe les dépendances npm ──────────────────────────
echo ""
echo -e "${YELLOW}[2/7] Installation des dépendances npm...${NC}"
npm install
echo -e "${GREEN}✓ Dépendances installées${NC}"

# ── 3. Ajoute la plateforme Android ──────────────────────────
echo ""
echo -e "${YELLOW}[3/7] Ajout de la plateforme Android...${NC}"
if [ -d "android" ]; then
    echo -e "  Le dossier android/ existe déjà, skip."
else
    npx cap add android
    echo -e "${GREEN}✓ Plateforme Android ajoutée${NC}"
fi

# ── 4. Copie les ressources personnalisées ───────────────────
echo ""
echo -e "${YELLOW}[4/7] Application des ressources Android...${NC}"

# Manifest
if [ -f "android-resources/AndroidManifest.xml" ]; then
    cp android-resources/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
    echo -e "${GREEN}✓ AndroidManifest.xml appliqué${NC}"
fi

# Strings
if [ -f "android-resources/strings.xml" ]; then
    cp android-resources/strings.xml android/app/src/main/res/values/strings.xml
    echo -e "${GREEN}✓ strings.xml appliqué${NC}"
fi

# Styles
if [ -f "android-resources/styles.xml" ]; then
    cp android-resources/styles.xml android/app/src/main/res/values/styles.xml
    echo -e "${GREEN}✓ styles.xml appliqué${NC}"
fi

# Icônes
generate_icon() {
    src="www/icon-512.png"
    size=$1
    dest=$2
    mkdir -p $(dirname $dest)
    if command -v convert &> /dev/null; then
        convert "$src" -resize "${size}x${size}" "$dest" 2>/dev/null && \
            echo -e "${GREEN}  ✓ Icône ${size}x${size}${NC}"
    elif command -v python3 &> /dev/null; then
        python3 -c "
from PIL import Image
img = Image.open('$src').resize(($size,$size), Image.LANCZOS)
img.save('$dest')
print('  ✓ Icône ${size}x${size}')
" 2>/dev/null || echo -e "  ⚠ Icône ${size} non générée (PIL manquant)"
    fi
}

echo -e "  Génération des icônes Android..."
generate_icon 48  "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
generate_icon 72  "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
generate_icon 96  "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
generate_icon 144 "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
generate_icon 192 "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

# Rond
generate_icon 48  "android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png"
generate_icon 72  "android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png"
generate_icon 96  "android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png"
generate_icon 144 "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png"
generate_icon 192 "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png"

# ── 5. Sync Capacitor ────────────────────────────────────────
echo ""
echo -e "${YELLOW}[5/7] Synchronisation Capacitor...${NC}"
npx cap sync android
echo -e "${GREEN}✓ Sync terminé${NC}"

# ── 6. Build APK ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[6/7] Compilation de l'APK...${NC}"
echo -e "  (Cette étape peut prendre 3-5 minutes la première fois)"
echo ""

cd android
chmod +x gradlew

if ./gradlew assembleDebug --no-daemon 2>&1 | tee /tmp/gradle_build.log | grep -E "BUILD|error:|Error" ; then
    cd ..
    APK_PATH=$(find android/app/build/outputs/apk/debug/ -name "*.apk" 2>/dev/null | head -1)
    
    if [ -f "$APK_PATH" ]; then
        # Rename
        cp "$APK_PATH" "NutriScan-v1.0-debug.apk"
        SIZE=$(du -sh "NutriScan-v1.0-debug.apk" | cut -f1)
        
        echo ""
        echo -e "${GREEN}${BOLD}╔══════════════════════════════════════╗${NC}"
        echo -e "${GREEN}${BOLD}║   ✅  APK GÉNÉRÉ AVEC SUCCÈS !       ║${NC}"
        echo -e "${GREEN}${BOLD}╚══════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  📦 Fichier : ${BOLD}NutriScan-v1.0-debug.apk${NC}"
        echo -e "  📏 Taille  : ${SIZE}"
        echo ""
        echo -e "${YELLOW}[7/7] Installation sur ton téléphone :${NC}"
        echo ""
        echo -e "  ${BOLD}Option A — USB :${NC}"
        echo -e "  1. Connecte ton téléphone en USB"
        echo -e "  2. Active le mode développeur + USB Debugging"
        echo -e "  3. Lance : ${CYAN}adb install NutriScan-v1.0-debug.apk${NC}"
        echo ""
        echo -e "  ${BOLD}Option B — Direct téléphone :${NC}"
        echo -e "  1. Envoie le fichier .apk sur ton téléphone"
        echo -e "  2. Paramètres → Sécurité → Sources inconnues ✓"
        echo -e "  3. Ouvre le fichier .apk et installe"
        echo ""
    else
        echo -e "${RED}✗ APK non trouvé après build${NC}"
        cat /tmp/gradle_build.log | tail -30
    fi
else
    cd ..
    echo ""
    echo -e "${YELLOW}Build incomplet — Ouvre avec Android Studio :${NC}"
    echo -e "  ${CYAN}npx cap open android${NC}"
    echo -e "  Build → Build Bundle(s) / APK(s) → Build APK(s)"
fi
