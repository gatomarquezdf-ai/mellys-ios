# Distribuidora Mely's · Plataforma de ventas de moquetas termoformadas

Sistema para administrar el negocio con **50 vendedores** (`V001` a `V050`) desde
computador, tablet o celular. Incluye catálogo con fotos/precios/stock, pedidos con
aprobación de la administradora, comisiones, adelantos, reservas, ventas locales y
guías de envío con **BUS, Servientrega y Laar Courier**.

La información se guarda en una **base central Supabase** y cada equipo conserva una
copia local para seguir trabajando sin internet. La app arranca limpia: configuración y
catálogo de ejemplo, **sin vendedores ni ventas de demostración**.

**Versión actual: 1.5.1** (APK `versionCode` 7). El esquema de Supabase sigue en
**SQL 1.4.0**: esta actualización no requiere volver a ejecutar `db/cloud.sql`.

### Novedades 1.5.1

- **App iOS nativa:** nuevo proyecto **SwiftUI + WKWebView** en `ios\` listo para
  abrir en Xcode. Incluye ícono propio, pantalla para pegar la dirección HTTPS,
  ajustes, descargas por la hoja de compartir de iOS, impresión de guías y refresco
  jalando hacia abajo. Ver `ios\README.md`.
- **La web reconoce el contenedor iOS:** cuando la app corre dentro de la app nativa,
  las descargas, la impresión y la detección de "app instalada" usan el puente de
  iOS (`MelysIOS`) en lugar de las funciones del navegador.
- **Pantallas de inicio para iPhone/iPad:** la PWA instalada desde Safari abre con
  el fondo de la marca, el ícono y el nombre, sin el destello blanco inicial. Se
  generan con `tools\make-ios-splash.ps1` y se publican en `splash\`.
- **Generación del `.ipa` automatizada:** `tools\build-ipa.ps1` prepara el paquete
  para compilar el `.ipa` en GitHub Actions y firmarlo en Windows con Sideloadly,
  sin necesidad de un Mac. También está `tools\build-ipa.sh` para macOS.
- Sin cambios en la base de datos ni en el flujo de trabajo: Android y la PWA
  siguen funcionando igual.

### Novedades 1.5.0

- **Funciona en iPhone/iPad como app instalable (PWA):** se publica la carpeta
  `dist\web` en un hosting con HTTPS y se instala desde Safari con
  **Compartir → Añadir a pantalla de inicio**. Incluye ícono, pantalla completa,
  service worker y funcionamiento sin internet.
- **Mucho más espacio para el inventario:** los datos y las fotos ahora se guardan
  en **IndexedDB** (cuota de cientos de MB o GB, según el equipo). localStorage
  queda solo como respaldo y migración automática de la versión anterior.
- **Catálogos de 200 productos o más:** con fotos de 720 px cada producto ocupa
  unos 60–70 KB, así que 200 productos con foto rondan los 13 MB, muy por debajo
  de la cuota de IndexedDB. El catálogo y el inventario cargan de a 24 productos
  con el botón **Ver más productos**, para que el teléfono siga rápido.
- **Importar productos desde CSV:** en **Inventario** están los botones
  **Plantilla** (archivo de ejemplo con las columnas) e **Importar CSV**. Se pueden
  cargar 200 productos de una vez; si el SKU ya existe se actualiza y si no, se crea.
  Las columnas son SKU, Producto, Categoría, Precio, Costo, Stock, Stock mínimo,
  % Comisión, Comisión fija y Activo. Las fotos se agregan después en cada producto.
- **Fotos más livianas:** las nuevas fotos de producto se guardan a 720 px y las
  referencias a 640 px. En **Configuración → Datos y respaldo** hay un botón
  **Optimizar fotos** que recomprime las fotos existentes sin borrarlas.
- **Panel de espacio:** muestra el almacenamiento usado, la cuota estimada del
  dispositivo, cuántas fotos hay y cuánto ocupan, y permite **Proteger datos** para
  que el teléfono no borre la copia local.
- **Descargas en iPhone:** los respaldos, CSV e imágenes usan la hoja de compartir
  de iOS (guardar en Archivos, Fotos o enviar por WhatsApp) cuando está disponible.
- **Instalación guiada:** la tarjeta **Instalar en iPhone / iPad** explica los pasos
  y advierte si la página no está en HTTPS.
- El **APK de Android conserva la misma firma**, por lo que se actualiza encima de
  la versión instalada sin desinstalar.

### Novedades 1.4.0

- **La administradora recibe los pedidos de sus vendedores**: la app ahora avisa cuando
  la nube tiene **menos vendedores que este equipo** o **ningún pedido** de este equipo, y
  ofrece el botón **Subir datos de este equipo** (no borra nada de la nube).
- Al iniciar sesión la administradora, si este equipo tiene más vendedores que la nube o
  la nube no tiene pedidos y este equipo sí, se suben primero las tablas locales y luego
  se sincroniza todo.
- El vendedor ve un **aviso ámbar** si está registrando pedidos sin la base central:
  esos pedidos se guardan solo en su celular y la administradora no los recibe.
- Si el catálogo local está desactualizado, la base central **busca el producto por
  nombre** antes de descartar un ítem del pedido.
- La base central ya no descarta pedidos de vendedor cuando no reconoce ningún producto:
  los guarda con los ítems solicitados y devuelve un aviso.
- Nuevos contadores en **Configuración → Base de datos central**: vendedores en la nube,
  vendedores en este equipo, pedidos en la nube, pedidos del portal, último pedido
  recibido y versión del SQL.

### Novedades 1.3.0

- El vendedor registra pedidos con el **mismo formulario de la administradora**: elige
  producto y cantidad del catálogo real.
- El pedido del vendedor muestra **comisión generada** y **valor a facturar**, y al
  aprobarse **descuenta stock** (salvo productos **bajo pedido**).
- La administradora puede **eliminar pedidos**; si estaban aprobados, el stock se
  devuelve y se eliminan sus guías.
- **Impresión de guías de envío** con nombre, cédula, teléfono, ciudad y dirección
  desde el navegador o el APK Android.
- **Visor de imágenes**: clic para ampliar y botón para descargar en catálogo,
  inventario, pedidos, portal y guías.
- Productos **bajo pedido** desde catálogo o inventario.

---

## 1. Puesta en marcha (una sola vez)

### 1.1 Ejecutar el script de la base central

1. Entra a <https://supabase.com/dashboard/project/birzafoxmxvqtxigtlef/sql/new>.
2. Abre el archivo **`db/cloud.sql`**, copia **todo** su contenido y pégalo en el editor.
3. Pulsa **Run**.

El script es **idempotente**: se puede ejecutar varias veces sin borrar datos. Crea las
tablas, las funciones seguras, las secuencias y los permisos. Si aparece el error
`PGRST202` o el aviso *«Falta ejecutar el script db/cloud.sql»*, el script aún no se ha
ejecutado en ese proyecto.

Para confirmar que quedó la versión correcta, entra como administradora a
**Configuración → Base de datos central**: debe mostrar **Versión del SQL: 1.4.0**.
Si dice *sin dato* o una versión anterior, ejecuta el script otra vez (las versiones
anteriores guardan los pedidos de los vendedores sin productos ni comisión).

> Sin este paso la app solo permite **modo local**. La conexión central no funcionará.

### 1.2 Datos de conexión

La URL y la clave **publishable/anon** están en `assets/cloud-config.js`:

```js
window.MELYS_CLOUD = {
  url: 'https://birzafoxmxvqtxigtlef.supabase.co',
  key: 'sb_publishable_...'
};
```

- Usa únicamente la clave **publishable/anon**. **Nunca** pongas la clave
  `service_role` ni la contraseña de la base en la app: ambas omiten los permisos.
- Si cambias de proyecto Supabase, actualiza ese archivo y vuelve a compilar el APK.

### 1.3 Abrir la aplicación

**Navegador (computador o tablet):**

```powershell
powershell -ExecutionPolicy Bypass -File tools\serve.ps1 -Port 8765
```

Abre <http://127.0.0.1:8765>. Desde otro equipo en la misma red usa la IP del servidor,
por ejemplo `http://192.168.1.6:8765`.

**Celular:** instala el APK (ver sección 5).

### 1.4 Primer ingreso

Al abrir por primera vez aparece la **configuración inicial** (nombre, lema, modo de
comisión y logotipo). Al terminar verás el **selector de rol**:

- **Administrador** → primera vez: crear la contraseña de la administradora. Después,
  entrar con esa contraseña.
- **Vendedor** → usuario o código + contraseña creados por la administradora.
- **Entrar en modo local** → trabajar sin la base central (respaldo temporal).

La contraseña de administradora se guarda cifrada con `bcrypt` en Supabase y la sesión
dura **30 días**. Se puede cambiar en **Configuración → Base de datos central**.

---

## 2. Acceso y permisos

| Rol | Puede ver y hacer |
|---|---|
| **Administradora** | Todo: pedidos, catálogo, inventario, ventas, guías, reservas, vendedores, comisiones, adelantos, reportes, auditoría y configuración. |
| **Vendedor** | Solo su información: catálogo, sus pedidos, sus guías, sus comisiones, sus adelantos y su perfil. No ve ventas locales, otros vendedores ni auditoría. |
| **Modo local** | Datos guardados en ese dispositivo. No se comparten con otros equipos. |

- Cada vendedor recibe automáticamente el siguiente código (`V001`, `V002`…).
- Su **usuario** es el código en minúsculas (`v001`) y también puede entrar con el
  código (`V001`).
- La contraseña de vendedor es **opcional al editar**: si el campo se deja vacío se
  conserva la actual y nunca se muestra la existente.
- **Cambiar de rol** cierra la sesión central y vuelve al selector.

La seguridad no depende del navegador: las tablas están cerradas para las claves
públicas y todo pasa por funciones `security definer` que validan un **token de sesión**.
El servidor valida cada pedido creado por un vendedor:

- lo guarda con su propio `vendorId`,
- lo deja en estado `pendiente`,
- recalcula precios, subtotal y comisión con los productos del catálogo,
- ignora cualquier precio o comisión enviados por el vendedor,
- no permite aprobarlo ni modificarlo desde el portal.

El vendedor **sí elige productos reales y cantidades**; esos productos se asignan al
pedido y el inventario se descuenta cuando la administradora lo aprueba.

---

## 3. Sincronización

- **Administradora:** sube y baja todas las tablas.
- **Vendedor:** sube solo sus pedidos pendientes y baja solo lo que le corresponde.
- Los cambios se envían **0,9 s después** de guardar y se consultan cada **45 s**,
  al volver a la app y al recuperar la conexión.
- Si no hay internet, la app sigue funcionando con la copia local y sincroniza al
  reconectar. El chip de la barra superior indica **Central**, **Sin conexión** o
  **Local**.
- Los códigos de pedido, guía, reserva y venta se corrigen en el servidor si dos
  equipos generan el mismo.
- La sincronización es por tablas con huellas (hash) para no reenviar lo que no cambió.

> **Importante:** al entrar por primera vez a una base central **que ya tiene datos**,
> la app reemplaza la copia local con la información central. Si trabajaste en modo
> local y la nube ya no está vacía, descarga un respaldo antes de entrar. Si la nube
> está vacía, la app sube automáticamente los datos locales.

---

## 4. Módulos

### Operación
| Módulo | Qué puedes hacer |
|---|---|
| **Inicio** | Ventas de hoy y del mes, vendedores activos (`x / 50`), comisiones pendientes, stock disponible, adelantos, guías por transportadora y guías pendientes. |
| **Pedidos** | Pedidos de vendedores con datos del cliente, productos reales, cantidades y entrega. **Aprobar** una venta descuenta stock y genera comisión (los productos **bajo pedido** no descuentan). **Rechazar** exige motivo y no descuenta stock. **Eliminar** borra el pedido; si estaba aprobado devuelve las unidades al inventario y elimina sus guías asociadas. |
| **Catálogo** | Productos con foto, categoría, SKU, precio, costo, stock, stock mínimo, comisión y opción **bajo pedido**. Crear, editar, eliminar sin historial, ajustar stock, ampliar/descargar imágenes y descargar el catálogo en PDF/HTML. |
| **Ventas locales** | Ventas directas en tienda o taller. Descuentan inventario al guardar y se pueden anular restaurando el stock. |
| **Ventas vendedores** | Ventas consolidadas por vendedor, detalle de pedidos, comisiones y exportación CSV. |
| **Inventario** | Stock físico, unidades reservadas, stock disponible y valor del inventario. Ajustes con motivo y botón para marcar o quitar **bajo pedido**. Incluye **Plantilla** e **Importar CSV** para cargar catálogos grandes (por ejemplo, 200 productos) y **Ver más productos** para listas largas. |

### Envíos
| Módulo | Qué puedes hacer |
|---|---|
| **Guías** | Guías vinculadas a un pedido o manuales, con destinatario, cédula, teléfono, ciudad, dirección, costo y seguimiento. Historial de estados e **impresión de la guía** en A4 desde el navegador o el APK. |
| **Guías BUS / Servientrega / Laar Courier** | Vistas filtradas por transportadora. |
| **Guías pendientes** | Solo guías por despachar, con filtros por transportadora. |
| **Reservas / Auditoría de reservas** | Apartar stock sin cambiar el inventario físico. Vencimiento, cancelación y conversión a pedido. |

### Red comercial
| Módulo | Qué puedes hacer |
|---|---|
| **Vendedores** | Fichas con código individual, cédula, contacto, zona, usuario, contraseña, estado y comisión propia opcional. Historial de pedidos, adelantos y pagos. |
| **Portal del vendedor** | Catálogo con **productos reales**, precios, comisión estimada y estado **bajo pedido**. El vendedor registra pedidos con el **mismo formulario del administrador**, elige producto y cantidad, ve la **comisión generada** y el **valor a facturar**. Puede repetir pedidos, consultar sus guías, comisiones, adelantos y perfil, **ampliar/descargar imágenes** e **imprimir la guía de envío**. El pedido queda pendiente y descuenta stock solo al aprobarse. |

### Finanzas y sistema
| Módulo | Qué puedes hacer |
|---|---|
| **Comisiones** | Comisión generada, pagada, adelantos y saldo por vendedor. Registrar pagos e historial. |
| **Adelantos** | Entregas anticipadas de comisión, descontadas del saldo. No permite superar el saldo disponible. |
| **Reportes** | Exportar pedidos, ventas locales, guías, reservas, adelantos, comisiones, productos y vendedores a CSV. |
| **Auditoría** | Historial de movimientos con actor, entidad y detalle. |
| **Configuración** | Identidad, moneda, logo, color, modo de comisión, **Base de datos central** (estado, sincronizar, cambiar contraseña, salir), respaldo, restauración y **Eliminar vendedores y ventas**. |

### Inicio limpio
- Catálogo inicial con **16 productos** de ejemplo.
- Configuración predeterminada: nombre, lema, color y modo de comisión.
- **0 vendedores, 0 pedidos, 0 ventas locales, 0 guías, 0 reservas, 0 adelantos y 0 pagos.**

---

## 5. APK Android

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-apk.ps1 -VersionName "1.5.1" -VersionCode 7
```

Genera:

- `dist\DistribuidoraMelys-1.5.1.apk`
- `dist\DistribuidoraMelys.apk` (copia estable)

El APK es un contenedor **WebView nativo** (paquete `com.distribuidoramelys.app`) que
sirve la app desde `https://app.local/`. Incluye permiso `INTERNET` para Supabase y
conserva los datos en el almacenamiento de la app. Las descargas de CSV, respaldos y
catálogo usan el selector de archivos de Android.

- Requiere Android 7.0 o superior.
- Para instalar: copia el APK al teléfono, ábrelo y acepta el origen desconocido.
- La firma usa `android\melys-release.keystore`; **conserva ese archivo** para publicar
  actualizaciones sobre la misma app instalada.
- Compilación sin Gradle ni Android Studio. Toolchain en
  `%LOCALAPPDATA%\Temp\opencode\android-toolchain` (JDK 17, `build-tools` y
  `platforms/android-33`).

Verificación:

```powershell
powershell -ExecutionPolicy Bypass -File tools\inspect-apk.ps1 -Apk dist\DistribuidoraMelys.apk
powershell -ExecutionPolicy Bypass -File tools\check-apk-content.ps1
```

Huellas SHA-256 de la entrega 1.5.1 (para comprobar que el archivo no se dañó al
copiarlo o descargarlo):

```text
APK  dist\DistribuidoraMelys-1.5.1.apk
E43C9F0AD713581746F428560C717E77F073F7D010EC1FEE45C566964F2C54F3   (482.076 bytes)

ZIP  dist\DistribuidoraMelys-web.zip
DD40D122292ECB64C2BB9A85DEEE7A426357220BF4E9B44AE7F549CC92C05F79   (608.809 bytes)

ZIP  dist\DistribuidoraMelys-ios.zip
891CD9523A6884E257524F9CB5A2AD15550C755826CA5657A18E338F6970B793   (60.335 bytes)
```

En Windows se comprueba con `Get-FileHash archivo -Algorithm SHA256`.

La huella de `DistribuidoraMelys-ios.zip` cambia cada vez que vuelves a ejecutar
`tools\build-ipa.ps1`, porque el ZIP se genera de nuevo.

### Descargar el APK por Wi-Fi

El servidor `tools\serve.ps1` también entrega el APK. Si el celular no puede descargarlo,
Windows Firewall debe permitir el puerto **8765**:

```powershell
powershell -ExecutionPolicy Bypass -File tools\habilitar-descarga-lan.ps1
```

Requiere aceptar la elevación de administrador.

### iPhone / iPad (PWA)

Apple no permite instalar un APK en iPhone. La app se publica como **PWA** (aplicación
web instalable), que se abre a pantalla completa y funciona sin internet. No necesita
Mac, Xcode ni cuenta de desarrollador de Apple.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-web.ps1 -Version "1.5.1"
```

Genera:

- `dist\web\` → carpeta lista para publicar.
- `dist\DistribuidoraMelys-web.zip` → paquete para subir a un hosting.

Publicación rápida (una sola vez):

1. Entra a **https://app.netlify.com/drop** (o Cloudflare Pages).
2. Arrastra `dist\DistribuidoraMelys-web.zip` o la carpeta `dist\web`.
3. Copia la dirección **HTTPS** que entrega el servicio.
4. En el iPhone/iPad abre esa dirección en **Safari**.
5. Toca **Compartir → Añadir a pantalla de inicio → Añadir**.
6. Abre el ícono **Mely's**; la app queda instalada como cualquier otra.

Notas:

- La instalación y el service worker **requieren HTTPS**. Una dirección `http://`
  local o una IP de la red Wi-Fi no sirve para instalar en iPhone.
- La app sigue usando **Supabase** como base central. El service worker solo guarda
  los archivos de la app, nunca los datos de la nube.
- Para actualizar, vuelve a ejecutar `tools\build-web.ps1` y sube los archivos al
  mismo sitio. El ícono no cambia de versión, pero la app se actualiza al abrirla.
- En **Configuración → Instalar en iPhone / iPad** están los mismos pasos y un botón
  para copiar el enlace.
- La PWA incluye **pantallas de inicio** propias (fondo de la marca con el nombre), así
  que al abrirla no aparece un destello blanco. Se generan con
  `tools\make-ios-splash.ps1`.

### App iOS nativa (Xcode)

También está el proyecto nativo **SwiftUI + WKWebView** en `ios\`, listo para abrir en
Xcode y compilar un `.ipa`:

- `ios\DistribuidoraMelys.xcodeproj` → abrir en Xcode 15 o superior.
- `ios\README.md` → pasos de firma, instalación, TestFlight y solución de problemas.
- Incluye ícono propio, pantalla de configuración de la URL, descargas por la hoja de
  compartir de iOS, impresión de guías, refresco jalando hacia abajo y navegación
  atrás/adelante.

Pasos rápidos en el Mac:

1. Abre `ios\DistribuidoraMelys.xcodeproj`.
2. En **Signing & Capabilities** elige tu **Team** (Apple ID). Si el identificador
   `com.distribuidoramelys.app` está ocupado, cambia el *Bundle Identifier*.
3. Conecta el iPhone, actívalo en **Modo de desarrollador** y pulsa **Run** (⌘R).
4. En la primera pantalla pega la dirección HTTPS publicada y toca **Abrir la app**.

Verificación del proyecto en Windows (sin compilar):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\check-ios-project.ps1
```

**Requiere un Mac con Xcode**: Apple no permite compilar ni firmar apps iOS en
Windows. Con Apple ID gratis la app se instala en el propio iPhone y la firma dura
7 días; con Apple Developer (99 USD/año) se puede usar TestFlight y Ad Hoc. Si no hay
un Mac disponible, la versión PWA de arriba es la alternativa inmediata.

### Generar el `.ipa`

El archivo `.ipa` solo se puede producir en macOS con Xcode. Hay dos caminos:

**A. Con un Mac** (recomendado si tienes uno):

```bash
./tools/build-ipa.sh                      # .ipa sin firmar
TEAM_ID=XXXXXXXXXX ./tools/build-ipa.sh --signed   # .ipa firmado
```

- Sin firmar: `dist/DistribuidoraMelys-1.5.1-unsigned.ipa`, para firmarlo luego con
  Sideloadly o AltStore.
- Firmado: `dist/DistribuidoraMelys-1.5.1.ipa`, listo para instalar o subir a
  TestFlight (`METHOD=app-store`).

**B. Sin Mac (GitHub Actions + Sideloadly en Windows):**

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build-ipa.ps1
```

Genera `dist\DistribuidoraMelys-ios.zip` con el proyecto y el flujo
`.github/workflows/ios-ipa.yml`. Después:

1. Descomprime el ZIP y súbelo a un repositorio nuevo en **github.com**.
2. **Actions → Compilar IPA (iOS) → Run workflow** (tarda 3–6 minutos).
3. Descarga el artefacto **DistribuidoraMelys-unsigned-ipa**.
4. Fírmalo e instálalo en Windows con **Sideloadly** (https://sideloadly.io) usando
   tu Apple ID. La firma gratuita dura 7 días y Sideloadly la renueva.

Un `.ipa` firmado para **TestFlight** o App Store necesita una cuenta Apple
Developer y un certificado; ese paso sí o sí requiere macOS o un servicio de CI con
tus credenciales.

---

## 6. Reglas de negocio

### Estados del pedido
- **Pendiente:** se registra, no reserva ni descuenta stock.
- **Aprobado:** se confirma. Descuenta inventario y registra la comisión de los productos
  del pedido. Los productos marcados **bajo pedido** se venden sin descontar stock. Si
  falta stock de un producto normal, la aprobación se bloquea e indica cuál falta.
- **Rechazado:** se registra el motivo y **no** descuenta stock.
- **Eliminado:** la administradora puede eliminar cualquier pedido. Si estaba aprobado,
  las unidades vuelven al inventario (salvo las de productos bajo pedido) y se eliminan
  las guías asociadas. La acción queda en auditoría.

Los pedidos creados por un vendedor ya incluyen **producto y cantidad**; por eso
descuentan stock al aprobarse. Los pedidos antiguos sin producto asignado se conservan,
pero no afectan inventario ni comisión.

### Comisiones
Se configuran en **Configuración → Cálculo de comisiones**:

1. **Porcentaje por producto** (por defecto).
2. **Valor fijo por producto**.
3. **Comisión distinta por vendedor**.
4. **Mixto:** `% del producto × factor del vendedor` (ej. 1.20 = +20 %).
5. **Ingreso manual:** la administradora escribe el monto al crear el pedido.

Un vendedor puede tener una **comisión propia** que reemplaza la del producto en los
modos 1 y 2. La comisión se **congela al registrar el pedido**.

**Saldo del vendedor** = comisiones de pedidos aprobados − pagos − adelantos.

### Inventario y reservas
- El stock físico cambia al **aprobar** un pedido, al **registrar una venta local**, al
  **ajustar stock** manualmente o al **eliminar un pedido aprobado** (devuelve las
  unidades). Los productos **bajo pedido** no descuentan stock al aprobar.
- Las **reservas** reducen el stock disponible pero no el físico.
- Al convertir una reserva en pedido, este queda pendiente de aprobación.
- Cada producto tiene stock mínimo; Inicio muestra los que necesitan reposición.
- Las imágenes del catálogo, inventario, pedidos y guías se pueden **ampliar** con un
  clic y **descargar** desde el visor.

### Guías de envío
- Transportadoras fijas: **BUS**, **Servientrega** y **Laar Courier**.
- Estados: pendiente, generada, en tránsito, entregada y novedad.
- Cada cambio queda en el historial de la guía.

---

## 7. Estructura del proyecto

```
index.html                     Estructura del panel y registro de la PWA
manifest.webmanifest           Manifest de instalación (iPhone/Android)
sw.js                          Service worker: app sin internet
icons/                         Íconos de la PWA (180, 192, 512 y maskable)
splash/                        Pantallas de inicio de iOS (iPhone/iPad)
assets/styles.css              Diseño responsive, safe-area iOS y componentes
assets/store.js                Datos locales (IndexedDB) + reglas del negocio
assets/cloud.js                Cliente Supabase (login, sync, push, polling)
assets/cloud-config.js         URL y clave publishable del proyecto
assets/ui.js                   Modales, avisos, formato, CSV, imágenes y compartir
assets/app.js                  Vistas, selector de rol, portal y controladores
db/cloud.sql                   Esquema central obligatorio (ejecutar en Supabase)
db/schema.sql                  Esquema relacional de referencia (no lo usa la app)
tools/serve.ps1                Servidor local/LAN
tools/build-apk.ps1            Compila el APK (aapt2 + javac + d8 + apksigner)
tools/build-web.ps1            Genera dist\web y el ZIP para publicar la PWA
tools/make-pwa-icons.ps1       Genera los íconos de la PWA
tools/make-ios-splash.ps1      Genera las pantallas de inicio de iOS
tools/inspect-apk.ps1          Verifica paquete, compresión y firma
tools/check-apk-content.ps1    Verifica el contenido web embebido
tools/check-ios-project.ps1    Verifica el proyecto iOS (estructura, íconos, plist)
tools/build-ipa.ps1            Prepara el ZIP para compilar el .ipa en GitHub Actions
tools/build-ipa.sh             Compila el .ipa en macOS (sin firmar o firmado)
.github/workflows/ios-ipa.yml  Compila el .ipa sin firmar en un Mac de GitHub
android/                       Proyecto Android nativo (manifiesto, recursos, MainActivity)
ios/                           App iOS nativa SwiftUI + WKWebView (abrir en Xcode)
dist/                          APK firmado y paquete web listos para publicar
```

Almacenamiento local: **IndexedDB** base `moquetapro`, almacén `kv`, clave `db`
(datos y fotos). `localStorage` conserva `moquetapro.db.v3` solo como respaldo y para
migrar desde la versión 1.4.0. Otras claves: `moquetapro.setup.v1` (configuración
inicial) y `moquetapro.portal` (sesión del portal en la pestaña). Claves de la nube:
`melys.cloud.session.v1`, `melys.cloud.hashes.v1` y `melys.cloud.since.v1`.

---

## 8. Problemas frecuentes

| Síntoma | Causa y solución |
|---|---|
| *«Falta ejecutar el script db/cloud.sql»* o error `PGRST202` | Ejecuta `db/cloud.sql` en Supabase → SQL Editor. |
| Los pedidos del vendedor llegan **sin producto, sin comisión y en $0** | La base central tiene una versión anterior del SQL. Ejecuta de nuevo `db/cloud.sql`. En **Configuración → Base de datos central** debe aparecer **Versión del SQL: 1.4.0**; si dice *sin dato*, el SQL no está actualizado. Los pedidos ya guardados sin productos no se recuperan: el vendedor debe registrarlos otra vez. |
| **La administradora no recibe ningún pedido** de sus vendedores | Entra como administradora **con la base central** y abre **Configuración → Base de datos central**. Compara **Vendedores en este equipo** con **Vendedores en la nube**, y **Pedidos en la nube** con los pedidos de este equipo. Si la nube tiene menos, pulsa **Subir datos de este equipo**. Después pide a cada vendedor cerrar sesión y entrar de nuevo por la base central. Revisa que **Pedidos en la nube** suba de 0 a 1 al registrar un pedido de prueba. |
| El vendedor no ve la opción de elegir producto | Su celular tiene instalado el APK anterior. Instala el APK 1.5.1 (`versionCode` 7). |
| La app dice *«El almacenamiento del dispositivo está lleno»* | Abre **Configuración → Datos y respaldo**, pulsa **Optimizar fotos** y descarga un respaldo. En iPhone/iPad elimina fotos o videos grandes del teléfono. |
| **Importar CSV** no carga productos | Descarga primero **Inventario → Plantilla** y usa ese formato. Debe existir la columna **Producto** con el nombre. Guarda el archivo como **CSV UTF-8** (no como Excel `.xlsx`) y usa punto o coma como separador. |
| En iPhone no aparece **Añadir a pantalla de inicio** | La página debe abrirse en **Safari** y con **HTTPS**. No funciona desde Chrome en iOS ni desde una dirección `http://` local. Publica `dist\web` en Netlify Drop o Cloudflare Pages. |
| La PWA muestra una versión anterior después de publicar | Cierra la app, vuelve a abrirla con internet o sube la versión del caché en `sw.js` (`melys-app-v1.5.1`). |
| *«La sesión venció. Vuelve a ingresar.»* | El token de 30 días expiró o se cerró en otro equipo. Entra de nuevo. |
| *«Base central no disponible»* | Revisa internet, la URL/clave de `assets/cloud-config.js` y el estado del proyecto Supabase. |
| El vendedor no ve sus datos | Confirma que entró con el usuario correcto y que la administradora ya sincronizó. |
| El celular no descarga el APK por Wi-Fi | Ejecuta `tools\habilitar-descarga-lan.ps1` y acepta la elevación. |
| La app no actualiza en el APK | Vuelve a compilar; el APK embebe los archivos web. |

---

## 9. Limitaciones conocidas

- **No hay tiempo real:** la consulta es cada 45 s o al abrir/volver a la app. Los
  cambios tardan unos segundos en aparecer en otros equipos.
- **Modo local:** sus cambios no se comparten y pueden perderse al entrar por primera
  vez a una nube que ya tiene datos. Descarga un respaldo antes.
- **Respaldo manual:** usa **Configuración → Descargar respaldo** con frecuencia. Si se
  borran los datos del navegador o de la app, se pierde la copia no respaldada.
- **Fotos:** se guardan optimizadas dentro de los datos (IndexedDB). Para un catálogo
  muy grande, conviene moverlas a Supabase Storage. El botón **Optimizar fotos** reduce
  el espacio, pero no reemplaza un respaldo.
- **iPhone/iPad:** hay dos caminos. Sin Mac, la app se instala como **PWA** desde
  Safari publicando `dist\web` en un hosting HTTPS. Con Mac y Xcode 15+, se compila el
  proyecto nativo de `ios\` (SwiftUI + WKWebView) y se instala en el iPhone; Apple no
  permite compilar ni firmar apps iOS en Windows.
- **La auditoría automática del servidor** puede generar un `id` distinto al `data.id`
  de la fila. No afecta la operación.
- **Comisión manual:** solo aplica al crear el pedido; no se edita después.
