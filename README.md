# Combo Manager

Aplicación Android en Flutter para administrar productos y combos de un negocio. Los datos se almacenan localmente en SQLite. La app no incorpora cuentas, servidores, anuncios, rastreo ni permisos de Internet.

## Funciones incluidas

- Catálogo de productos con precio de compra, precio de venta automático o manual y estado activo/inactivo.
- Creación y edición de combos, selección de productos activos, cantidades, precios de línea y totales editables.
- Recálculos en cascada centralizados cuando cambian el margen, la tasa o los precios de productos relacionados.
- Valores globales iniciales: margen `1.5` y tasa de referencia `755`.
- Modo claro/oscuro persistente.
- Exportación e importación manual de respaldos JSON. La importación fusiona por nombre y se procesa dentro de una transacción SQLite.
- Listas alfabéticas, mensajes en español y confirmación de operaciones de eliminación.
- Pruebas automatizadas para fórmulas y formato de números.

## Compilar en GitHub y descargar el APK

El flujo de GitHub Actions incluido en `.github/workflows/android-apk.yml` prepara el esqueleto Android, instala Flutter y las dependencias, ejecuta las pruebas y genera el APK de producción. No hace falta subir Flutter SDK ni carpetas temporales al repositorio.

1. Crea un repositorio vacío en GitHub, por ejemplo `combo-manager`.
2. Descarga y descomprime este ZIP en tu computadora.
3. Abre una terminal dentro de la carpeta `combo_manager_project`.
4. Ejecuta estos comandos, sustituyendo `TU-USUARIO` por tu nombre de usuario de GitHub:

   ```bash
   git init
   git add .
   git commit -m "Primera versión de Combo Manager"
   git branch -M main
   git remote add origin https://github.com/TU-USUARIO/combo-manager.git
   git push -u origin main
   ```

5. En GitHub, abre la pestaña **Actions** y entra en **Compilar APK Android**. El flujo también puede iniciarse manualmente con **Run workflow**.
6. Al terminar correctamente, abre la ejecución y descarga el artefacto **Combo-Manager-APK**. Dentro del ZIP del artefacto estará `app-release.apk`.

Cada nuevo `git push` a `main` o `master` vuelve a ejecutar la compilación.

## Compilar en tu computadora (opcional)

Necesitas Flutter estable, Android SDK y Java compatibles con la versión estable de Flutter. Desde la raíz del proyecto:

```bash
flutter create --platforms=android --org com.combomanager --project-name app --no-pub .
python3 scripts/configure_android.py
flutter pub get
flutter test
flutter build apk --release
```

El APK local aparece en `build/app/outputs/flutter-apk/app-release.apk`.

## Estructura del proyecto

- `lib/modelos/`: modelos de producto, combo, línea de combo y configuración.
- `lib/base_datos/`: creación de tablas y consultas SQLite (DAO).
- `lib/repositorios/`: acceso a datos y operaciones de negocio.
- `lib/logica/`: fórmulas, formato numérico y respaldos JSON.
- `lib/providers/`: estado compartido entre pantallas.
- `lib/pantallas/`: menú, configuración, productos, combos y selector de productos.
- `lib/widgets/`: botón volver, tarjetas y diálogos reutilizables.
- `lib/temas/`: colores y temas claro/oscuro centralizados.
- `test/`: pruebas automatizadas.
- `.github/workflows/`: compilación automática del APK.

## Reglas numéricas

Los valores internos se conservan sin redondear. Para la interfaz, `FormatoNumeros` trunca a dos decimales y elimina los ceros finales, de modo que `1.9867` se presenta como `1.98`, `1.90` como `1.9` y `2.00` como `2`.

## Nota honesta sobre la compilación

Este entorno de generación no incluye el SDK de Flutter, por lo que la compilación nativa no se pudo ejecutar aquí. El repositorio contiene un flujo de GitHub Actions para compilarlo en un runner con Flutter y Android SDK. La descarga del APK estará disponible una vez que esa ejecución termine sin errores.
