
---

#  Panadería Delicia – App en Flutter

Aplicación móvil desarrollada en **Flutter** para la panadería *Delicia*, con soporte para usuarios y administradores. La app permite gestionar ventas, inventario, producción, pedidos y más, usando **Firebase** como backend.

---

##  Documentación Oficial

Toda la documentación del proyecto (manuales, informes, avances, etc.) está disponible en el siguiente enlace:

 **Documentación completa:**
[https://continentaledupe-my.sharepoint.com/:f:/g/personal/71850190_continental_edu_pe/IgAWM0dFaKZcTYf5S7KDG0NNAffxIkm6v26Prqrlnprs8TE?e=R3BTXG](https://continentaledupe-my.sharepoint.com/:f:/g/personal/71850190_continental_edu_pe/IgAWM0dFaKZcTYf5S7KDG0NNAffxIkm6v26Prqrlnprs8TE?e=R3BTXG)

---

##  Descargas (APK & AAB)

Puedes descargar la aplicación compilada aquí:

*  **APK (Android):** *[https://continentaledupe-my.sharepoint.com/:f:/g/personal/71850190_continental_edu_pe/IgAWM0dFaKZcTYf5S7KDG0NNAffxIkm6v26Prqrlnprs8TE?e=R3BTXG](https://continentaledupe-my.sharepoint.com/:f:/g/personal/71850190_continental_edu_pe/IgAWM0dFaKZcTYf5S7KDG0NNAffxIkm6v26Prqrlnprs8TE?e=R3BTXG)*
*  **AAB (Android App Bundle):** *[https://continentaledupe-my.sharepoint.com/:f:/g/personal/71850190_continental_edu_pe/IgAWM0dFaKZcTYf5S7KDG0NNAffxIkm6v26Prqrlnprs8TE?e=R3BTXG](https://continentaledupe-my.sharepoint.com/:f:/g/personal/71850190_continental_edu_pe/IgAWM0dFaKZcTYf5S7KDG0NNAffxIkm6v26Prqrlnprs8TE?e=R3BTXG)*

---

##  Funcionalidades principales

###  Usuarios

* Navegar por el **catálogo** de productos.
* Agregar productos al **carrito**.
* Realizar **checkout** de pedidos.
* Visualizar y editar su **perfil**.
* Iniciar sesión vía **Firebase Authentication**.

###  Administradores

Incluye todo lo anterior y además:

* **CRUD de productos** (crear/editar/eliminar).
* Gestión de **producción** diaria.
* **Gestión de pedidos** en tiempo real.
* **Reportes y ventas** del negocio.

---

##  Tecnologías principales

* Flutter
* Dart
* Firebase Authentication
* Firebase Firestore
* Firebase Core

---

## 📱 Pantallas del sistema

| Pantalla             | Función                            |
| -------------------- | ---------------------------------- |
| CatalogoScreen       | Lista de productos.                |
| CarritoScreen        | Carrito del usuario.               |
| CheckoutScreen       | Confirmación del pedido.           |
| LoginScreen          | Autenticación.                     |
| PerfilScreen         | Datos del usuario.                 |
| CRUDScreen           | Gestión de productos.              |
| ProduccionScreen     | Control de producción.             |
| GestionPedidosScreen | Gestión de órdenes en tiempo real. |
| VentasAdminScreen    | Panel de ventas y reportes.        |
| PedidoDetalleScreen  | Detalle de un pedido.              |

---

##  Roles del sistema

Los roles se obtienen desde Firestore:

```
usuarios/{uid}/admin: true | false
```

* Admin → Acceso total
* Usuario → Solo catálogo, carrito y perfil

Si el usuario no está autenticado:

* Puede ver catálogo
* Si entra a carrito o perfil → se envía a Login

---

##  Estructura del proyecto

```
lib/
│
├── main.dart
│
├── screens/
│   ├── login_screen.dart
│   ├── catalogo_screen.dart
│   ├── carrito_screen.dart
│   ├── checkout_screen.dart
│   ├── perfil_screen.dart
│   ├── CRUD_screen.dart
│   ├── produccion_screen.dart
│   ├── ventas_admin_screen.dart
│   ├── gestion_pedidos_screen.dart
│   └── pedido_detalle_screen.dart
│
└── widgets/
    └── (componentes reutilizables)
```

---

## 🔧 Instalación y Configuración

### 1️ Clonar

```bash
git clone https://github.com/usuario/delicia-app.git
cd delicia-app
```

### 2️ Instalar dependencias

```bash
flutter pub get
```

### 3️ Configurar Firebase

Agregar:

**Android:**

```
android/app/google-services.json
```

**iOS:**

```
ios/Runner/GoogleService-Info.plist
```

Habilitar:

* Email/Password Auth
* Cloud Firestore

---

## ▶Ejecutar la app

```bash
flutter run
```

---

##  Dependencias principales

```yaml
firebase_core: ^latest
firebase_auth: ^latest
cloud_firestore: ^latest
flutter:
  sdk: flutter
```

---

##  Flujo de navegación

1. Carga del rol del usuario
2. Render del menú según el rol
3. Usuario no logueado → catálogo y login obligatorio
4. Administrador → acceso completo
5. Logout desde el AppBar

---

##  Objetivo del Proyecto

* Modernizar la operación de ventas en la panadería “Delicia”.
* Agilizar producción, pedidos y administración.
* Simplificar ventas presenciales o digitales.
* Unificar todo en una sola plataforma móvil.

---

##  Mejoras futuras

* Notificaciones push
* Pago integrado
* Dashboard avanzado
* Control de stock automatizado
* Analytics con Firebase

---

