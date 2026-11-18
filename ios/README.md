# App iOS nativa · Distribuidora Mely's

Contenedor **SwiftUI + WKWebView** para iPhone y iPad. Abre la misma aplicación web
que ya usas (catálogo, inventario, pedidos, vendedores y Supabase) dentro de una app
instalada, con ícono propio, pantalla completa, descargas por la hoja de compartir de
iOS, impresión de guías y refresco jalando hacia abajo.

> **Importante:** Apple exige un Mac con Xcode para compilar una app iOS. Este
> proyecto se entrega listo para abrir en Xcode, pero **no se puede compilar en
> Windows**. Si no tienes acceso a un Mac, usa la versión PWA que ya está publicada
> en `dist\web` (se instala desde Safari sin compilar nada).

## Requisitos

- Mac con macOS 13 o superior y **Xcode 15** o superior.
- iPhone o iPad con **iOS 15** o superior.
- Una cuenta de Apple:
  - **Apple ID gratis:** permite instalar en tu propio dispositivo. La firma dura
    **7 días** y luego hay que volver a compilar desde Xcode. Máximo 3 apps.
  - **Apple Developer Program (99 USD/año):** permite TestFlight, instalar en varios
    dispositivos sin cable y publicar en la App Store.

## 1. Publica la aplicación web

La app nativa abre una dirección HTTPS, igual que Safari. Antes de compilar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-web.ps1 -Version "1.5.1"
```

Sube `dist\DistribuidoraMelys-web.zip` o la carpeta `dist\web` a
**https://app.netlify.com/drop** (o Cloudflare Pages) y copia la dirección HTTPS.

## 2. Abre el proyecto en Xcode

1. En el Mac, abre `ios/DistribuidoraMelys.xcodeproj`.
2. Selecciona el proyecto **DistribuidoraMelys** → pestaña **Signing & Capabilities**.
3. En **Team**, elige tu Apple ID. Si no aparece, agrégalo en
   **Xcode → Settings → Accounts**.
4. Si Xcode dice que el *Bundle Identifier* ya está en uso, cámbialo por uno propio,
   por ejemplo `com.tunombre.melys`.
5. Conecta el iPhone por cable, enciéndelo y elige el dispositivo arriba.
   - En iOS 16 o superior activa **Ajustes → Privacidad y seguridad → Modo de
     desarrollador** y reinicia el teléfono.
   - Acepta **Confiar en este computador** cuando el iPhone lo pregunte.
6. Pulsa **Run** (⌘R). La app se instala y se abre.

En la primera pantalla pega la dirección HTTPS publicada y toca **Abrir la app**.
La dirección queda guardada; puedes cambiarla con el botón de ajustes (⚙︎).

### Dirección predeterminada (opcional)

Si quieres que la app abra directamente tu sitio publicado sin escribir la dirección,
edita `DistribuidoraMelys/AppConfig.swift` antes de compilar:

```swift
static let suggestedURL = "https://tu-sitio.netlify.app"
```

Solo se usa para rellenar el campo la primera vez; la dirección que el usuario
guarde en el teléfono tiene prioridad.

### Verificación del proyecto sin Mac

Desde Windows puedes comprobar que el proyecto está completo (estructura, íconos,
plist y referencias del `.pbxproj`):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\check-ios-project.ps1
```

## 3. Generar el `.ipa`

Un `.ipa` es el paquete instalable de iOS. Solo se puede compilar en macOS con
Xcode. Hay dos caminos:

### A. Con un Mac

```bash
./tools/build-ipa.sh                                 # sin firmar
TEAM_ID=XXXXXXXXXX ./tools/build-ipa.sh --signed     # firmado
```

- **Sin firmar** → `dist/DistribuidoraMelys-1.5.1-unsigned.ipa`. Se firma después con
  Sideloadly o AltStore.
- **Firmado** → `dist/DistribuidoraMelys-1.5.1.ipa`. Listo para instalar en tus
  dispositivos. Para TestFlight o App Store usa `METHOD=app-store`.

### B. Sin Mac: GitHub Actions + Sideloadly

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build-ipa.ps1
```

Ese comando genera `dist\DistribuidoraMelys-ios.zip`, que contiene el proyecto y el
flujo `.github/workflows/ios-ipa.yml`. Luego:

1. Descomprime el ZIP y súbelo a un repositorio nuevo en **github.com**
   (Add file → Upload files).
2. Abre **Actions → Compilar IPA (iOS) → Run workflow**. Tarda 3–6 minutos.
3. Descarga el artefacto **DistribuidoraMelys-unsigned-ipa**.
4. Instala **Sideloadly** (https://sideloadly.io) en Windows, conecta el iPhone y
   arrastra el `.ipa`. Escribe tu Apple ID.
5. En el iPhone: **Ajustes → General → VPN y gestión de dispositivos → Confiar**.

La firma con Apple ID gratuito dura **7 días**; Sideloadly la renueva sin volver a
compilar.

## 4. Instalar en el iPhone sin cable

Con una cuenta **gratuita** la app solo se puede instalar desde Xcode. Con una cuenta
**de pago**:

1. **Product → Archive**.
2. **Distribute App → Ad Hoc** (para tus dispositivos registrados) o **TestFlight**
   (para otras personas).
3. Sigue el asistente y envía la app.

## Actualizaciones

- **Cambios en la web** (productos, diseño, funciones): vuelve a ejecutar
  `tools\build-web.ps1`, sube los archivos al mismo hosting y abre la app. No hay que
  recompilar ni reinstalar la app nativa.
- **Cambios en el código nativo** (ícono, nombre, permisos): recompila y vuelve a
  instalar desde Xcode.

## Dónde quedan los datos

- La app usa el almacenamiento de WKWebView para el origen HTTPS publicado
  (IndexedDB, igual que Safari). Los 200 productos y sus fotos quedan en el teléfono.
- **Cambiar la dirección cambia el origen** y, por lo tanto, los datos locales que ve
  la app. Antes de cambiarla, descarga un respaldo en **Configuración → Datos y
  respaldo**. La copia central en Supabase no se pierde.
- Si borras la app, se borran los datos locales de ese origen. Supabase conserva la
  copia central; puedes volver a iniciar sesión y sincronizar.

## Firma gratuita y vencimiento

Con Apple ID gratis la firma vence a los **7 días** y la app deja de abrir. Para
renovarla, conecta el iPhone al Mac y ejecuta **Run** otra vez. Para uso continuo sin
renovar cada semana necesitas el Apple Developer Program.

## App Store

Una app que solo muestra una página web puede ser rechazada por la regla **4.2**
(minimum functionality) de Apple. Para uso interno de la distribuidora conviene
**TestFlight**, **Ad Hoc** o **Apple Business Manager**. Si el objetivo es publicarla
en la App Store, hay que agregar funciones nativas (notificaciones, cámara, archivos,
etc.) además del contenedor web.

## Problemas frecuentes

| Síntoma | Solución |
|---|---|
| *Untrusted Developer* al abrir | Ajustes → General → VPN y gestión de dispositivos → confiar en tu Apple ID. |
| *Unable to install* | El Bundle Identifier está repetido. Cámbialo en Signing & Capabilities. |
| Pantalla en blanco | Verifica que la URL abra en Safari, que sea HTTPS y que haya internet. |
| La app dejó de abrir después de unos días | La firma gratuita venció. Vuelve a ejecutar desde Xcode. |
| No descarga un CSV o una foto | Toca el botón otra vez; se abre la hoja de compartir para guardar en Archivos. |
| No imprime | Configura una impresora AirPrint o elige **Guardar como PDF** en la hoja de impresión. |

## Estructura

```
ios/
  DistribuidoraMelys.xcodeproj/       Proyecto listo para Xcode
  project.yml                         Alternativa para regenerar con XcodeGen
  DistribuidoraMelys/
    DistribuidoraMelysApp.swift       Punto de entrada SwiftUI
    ContentView.swift                 Pantalla de conexión, ajustes y error
    WebView.swift                     WKWebView, descargas, impresión y puente JS
    AppConfig.swift                   Validación y guardado de la URL
    Info.plist                        Permisos, orientaciones y pantalla de inicio
    Assets.xcassets/                  Ícono de la app y colores
tools/build-ipa.sh                    Compila el .ipa en macOS
tools/build-ipa.ps1                   Prepara el ZIP para GitHub Actions
.github/workflows/ios-ipa.yml         Compila el .ipa sin firmar en la nube
```

## Alternativa sin Mac

1. **PWA:** publica `dist\web` y en Safari usa **Compartir → Añadir a pantalla de
   inicio**. Funciona sin internet y no necesita Xcode ni cuenta de Apple.
2. **`.ipa` con GitHub Actions:** ejecuta `tools\build-ipa.ps1`, sube el ZIP a GitHub,
   corre el flujo **Compilar IPA** y firma el resultado con **Sideloadly** en Windows
   (ver la sección 3).
