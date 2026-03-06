# 📱 NutriScan — Guide de build APK Android

## 🎯 Ce que tu obtiens
Un fichier **NutriScan-v1.0-debug.apk** installable directement sur n'importe quel Android.

---

## 🛠️ Prérequis (à installer une seule fois)

### 1. Node.js 18+ 
👉 https://nodejs.org (prends la version LTS)

### 2. Java JDK 17+
👉 https://adoptium.net (Temurin 17 LTS)

### 3. Android Studio (inclut le SDK Android)
👉 https://developer.android.com/studio

Après installation d'Android Studio :
- Lance Android Studio → **SDK Manager**
- Onglet **SDK Platforms** → coche **Android 14 (API 34)**
- Onglet **SDK Tools** → coche :
  - ✅ Android SDK Build-Tools 34
  - ✅ Android SDK Platform-Tools
  - ✅ Android Emulator (optionnel)
- Clique **Apply** et attends le téléchargement

### 4. Configure les variables d'environnement

**Linux / Mac** — ajoute dans `~/.bashrc` ou `~/.zshrc` :
```bash
export ANDROID_HOME=$HOME/Android/Sdk          # Linux
# export ANDROID_HOME=$HOME/Library/Android/sdk  # Mac

export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/build-tools/34.0.0
```
Puis : `source ~/.bashrc`

**Windows** — Variables d'environnement système :
```
ANDROID_HOME = C:\Users\TON_NOM\AppData\Local\Android\Sdk
PATH += %ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools
```

---

## 🚀 Build de l'APK (3 étapes)

### Étape 1 — Extrais le ZIP
Extrais `nutriscan-apk.zip` dans un dossier, ex : `C:\nutriscan-apk\`

### Étape 2 — Lance le build

**Mac / Linux :**
```bash
cd nutriscan-apk
chmod +x scripts/build-apk.sh
./scripts/build-apk.sh
```

**Windows :**
```
Double-clique sur : scripts/build-apk.bat
```

**Ou manuellement (toutes plateformes) :**
```bash
cd nutriscan-apk
npm install
npx cap add android
npx cap sync android
cd android
./gradlew assembleDebug          # Mac/Linux
gradlew.bat assembleDebug        # Windows
```

### Étape 3 — Récupère l'APK
L'APK se trouve dans :
```
android/app/build/outputs/apk/debug/app-debug.apk
```
ou à la racine (si le script a réussi) : `NutriScan-v1.0-debug.apk`

---

## 📲 Installer l'APK sur ton téléphone

### Option A — Câble USB (le plus simple)
1. **Active le mode développeur** sur ton Android :
   - Paramètres → À propos → tape 7 fois sur "Numéro de build"
2. **Active USB Debugging** :
   - Paramètres → Options développeur → Débogage USB ✓
3. Branche le câble et lance :
```bash
adb install NutriScan-v1.0-debug.apk
```

### Option B — Transfert direct (sans PC)
1. Envoie le fichier `.apk` sur ton téléphone :
   - Par WhatsApp/Telegram, Drive, email, ou câble USB
2. Sur le téléphone :
   - **Paramètres → Sécurité → Sources inconnues** ✓
   - (ou "Installer des apps inconnues" selon Android)
3. Ouvre le gestionnaire de fichiers → trouve le `.apk` → **Installer**

### Option C — Android Studio
```bash
npx cap open android
```
Puis dans Android Studio : **Run → Run 'app'** (avec téléphone connecté)

---

## ⚡ Commandes utiles

| Commande | Action |
|----------|--------|
| `npm run setup` | Installation complète (première fois) |
| `npx cap sync android` | Sync les fichiers web vers Android |
| `npx cap open android` | Ouvre dans Android Studio |
| `adb devices` | Liste les appareils connectés |
| `adb install app.apk` | Installe l'APK via USB |
| `adb logcat` | Voir les logs de l'app |

---

## 🔧 Structure du projet

```
nutriscan-apk/
├── www/                    ← Fichiers web de l'app
│   ├── index.html          ← App principale
│   ├── manifest.json       ← Config PWA
│   └── sw.js               ← Service worker
├── android/                ← Généré par `npx cap add android`
├── android-resources/      ← Ressources Android personnalisées
│   ├── AndroidManifest.xml ← Permissions caméra/internet
│   ├── strings.xml         ← Nom de l'app
│   └── styles.xml          ← Thème sombre
├── scripts/
│   ├── build-apk.sh        ← Script Mac/Linux
│   └── build-apk.bat       ← Script Windows
├── capacitor.config.json   ← Config Capacitor
└── package.json            ← Dépendances
```

---

## ❓ Problèmes fréquents

**"ANDROID_HOME is not set"**
→ Suis la section "Configure les variables d'environnement" ci-dessus

**"SDK location not found"**
→ Lance Android Studio une fois pour finaliser l'installation du SDK

**"Gradle build failed"**
→ `npx cap open android` puis laisse Android Studio télécharger les dépendances manquantes

**"Camera permission denied" dans l'app**
→ Paramètres Android → Apps → NutriScan → Permissions → Caméra ✓

**L'app crash au démarrage**
→ `adb logcat | grep NutriScan` pour voir les erreurs

---

## 🚀 Version Release (pour distribution)

Pour générer un APK signé distribuable :
```bash
# Génère une clé de signature (une seule fois)
keytool -genkey -v -keystore nutriscan.keystore -alias nutriscan \
        -keyalg RSA -keysize 2048 -validity 10000

# Build release
cd android && ./gradlew assembleRelease
```
L'APK release se trouve dans `android/app/build/outputs/apk/release/`
