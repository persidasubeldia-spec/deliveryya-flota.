# App Android (Trusted Web Activity)

Abre `https://deliveryya-flota.pages.dev/app.html` a pantalla completa. El rol lo define el correo.

- Paquete: `py.deliveryya.flota` (no se puede cambiar nunca).
- Antes de cada versión nueva: subir `versionCode` y `versionName` en `app/build.gradle`.
- Compilar (la clave de subida NO está en el repositorio):

```
export ANDROID_HOME=/ruta/android-sdk DYF_KEYSTORE=/ruta/upload.jks DYF_KS_PASS='contraseña'
echo "sdk.dir=$ANDROID_HOME" > local.properties
gradle bundleRelease   # → app/build/outputs/bundle/release/app-release.aab
```

- `/.well-known/assetlinks.json` del sitio debe tener la huella SHA-256 de la clave de subida **y** la de firma de Google Play
  (Play Console › Prueba y lanzamiento › Configuración › Integridad de la app). Sin la de Play, la app muestra la barra del navegador.
