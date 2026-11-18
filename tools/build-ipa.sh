#!/usr/bin/env bash
# =========================================================================
# Distribuidora Mely's · genera el .ipa de iOS
# -------------------------------------------------------------------------
# Requiere macOS con Xcode 15 o superior.
#
# Uso:
#   ./tools/build-ipa.sh
#       Genera un .ipa SIN FIRMAR. Sirve para firmarlo en Windows con
#       Sideloadly o AltStore usando una cuenta de Apple gratuita.
#
#   TEAM_ID=XXXXXXXXXX ./tools/build-ipa.sh --signed
#       Genera un .ipa FIRMADO y listo para instalar o subir a TestFlight.
#       Necesita un certificado de Apple Developer en el Mac.
#       Opcional: METHOD=development | ad-hoc | app-store | enterprise
#
# Resultado: dist/DistribuidoraMelys-<version>[-unsigned].ipa
# =========================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS="$ROOT/ios"
PROJECT="$IOS/DistribuidoraMelys.xcodeproj"
SCHEME="DistribuidoraMelys"
BUILD="$IOS/build"
DIST="$ROOT/dist"
VERSION="1.5.1"

MODE="unsigned"
if [[ "${1:-}" == "--signed" ]]; then
  MODE="signed"
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: este script necesita macOS con Xcode." >&2
  echo "En Windows usa: powershell -ExecutionPolicy Bypass -File tools\\build-ipa.ps1" >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "ERROR: falta xcodebuild. Instala Xcode desde la App Store." >&2
  exit 1
fi

mkdir -p "$DIST"
rm -rf "$BUILD"
mkdir -p "$BUILD"

echo "==> Archivando $SCHEME (modo: $MODE)"
if [[ "$MODE" == "unsigned" ]]; then
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphoneos \
    -derivedDataPath "$BUILD/DerivedData" \
    -archivePath "$BUILD/$SCHEME.xcarchive" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    archive

  APP="$BUILD/$SCHEME.xcarchive/Products/Applications/$SCHEME.app"
  if [[ ! -d "$APP" ]]; then
    echo "ERROR: no se generó $APP" >&2
    exit 1
  fi

  rm -rf "$BUILD/Payload"
  mkdir -p "$BUILD/Payload"
  cp -R "$APP" "$BUILD/Payload/"
  OUT="$DIST/DistribuidoraMelys-$VERSION-unsigned.ipa"
  ditto -c -k --sequesterRsrc --keepParent "$BUILD/Payload" "$OUT"
else
  : "${TEAM_ID:?Define TEAM_ID=XXXXXXXXXX (Apple Developer → Membership)}"
  METHOD="${METHOD:-development}"

  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphoneos \
    -derivedDataPath "$BUILD/DerivedData" \
    -archivePath "$BUILD/$SCHEME.xcarchive" \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    archive

  cat > "$BUILD/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>$METHOD</string>
  <key>teamID</key>
  <string>$TEAM_ID</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>compileBitcode</key>
  <false/>
  <key>destination</key>
  <string>export</string>
</dict>
</plist>
PLIST

  rm -rf "$BUILD/export"
  xcodebuild \
    -exportArchive \
    -archivePath "$BUILD/$SCHEME.xcarchive" \
    -exportOptionsPlist "$BUILD/ExportOptions.plist" \
    -exportPath "$BUILD/export" \
    -allowProvisioningUpdates

  OUT="$DIST/DistribuidoraMelys-$VERSION.ipa"
  cp "$BUILD/export/$SCHEME.ipa" "$OUT"
fi

echo ""
echo "IPA generado: $OUT"
ls -lh "$OUT"
echo ""
if [[ "$MODE" == "unsigned" ]]; then
  echo "Fírmalo e instálalo en Windows con Sideloadly (https://sideloadly.io):"
  echo "  1. Conecta el iPhone y confía en el equipo."
  echo "  2. Arrastra el .ipa a Sideloadly y escribe tu Apple ID."
  echo "  3. En el iPhone: Ajustes → General → VPN y gestión de dispositivos → Confiar."
  echo "La firma gratuita dura 7 días; Sideloadly la renueva."
fi
