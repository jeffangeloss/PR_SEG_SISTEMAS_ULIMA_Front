# ULima++ App · variante de laboratorio sin portal

La rama `laboratorio/sin-portal` deriva de la versión 2.1.0 de la app y retira la integración con el portal institucional de la Universidad de Lima (miUlima y los sílabos publicados en el servidor de la universidad), junto con las funciones que dependían de ella y el interruptor del modo estático. La variante sirve como entorno de laboratorio para una auditoría de seguridad de la app y funciona contra un backend de laboratorio cuyas cuentas y datos salen de un seed sintético. `specs/`, `docs/`, `CHANGELOG.md` y `README.md` conservan la descripción de la versión 2.1.0, así que lo que dicen sobre el portal, el modo estático o el workflow de release corresponde a esa versión y no a esta rama. En este repositorio esos documentos solo cambian en los datos personales que trata la sección «Datos personales», y el `README.md` lleva al comienzo un aviso que remite a este archivo.

## Origen de este repositorio

Este repositorio parte de la versión v2.1.0 de https://github.com/meltiruiz/ULima_Frontend_IS2 (tag `v2.1.0`, commit `a03da58`) más un commit de laboratorio, `39bfcc6`, hecho en la rama local `laboratorio/sin-portal` de un clon de análisis. Ni ese commit ni esa rama están publicados en el repositorio original. Su contenido llega sin el historial de git, y el historial hasta v2.1.0 queda en el repositorio original.

## Datos personales

Los códigos, usuarios y nombres de personas reales que aparecen en las pruebas, los comentarios del código y los documentos de la versión 2.1.0 se reemplazan aquí por valores ficticios, con el mismo formato para que las pruebas sigan pasando. Lo mismo vale para los nombres y el código de alumno visibles en tres maquetas de `docs/images/UI/`, que son `Asesorias.png`, `Contactos.png` y `Perfil.png`. La tabla de contribuyentes del `README.md` conserva solo el nombre de pila o el alias de cada integrante.

## Qué se retiró

| Función | Qué deja de existir en la app |
|:---|:---|
| Carga de ciclo desde el portal | La ruta `/portal-sync`, su servicio y sus modelos, el aviso del inicio que ofrecía cargar los cursos y la tarjeta del Perfil que repetía la carga |
| Registro con credenciales del portal | La rama «Soy nuevo» de la bienvenida con sus cinco pasos, el consentimiento del portal, el envío del registro y la píldora con el pulso del sello que lo acompañaba |
| Récord académico | La ruta `/mi-record`, su servicio, su modelo, la tarjeta del Perfil y la opción para borrar el récord |
| Notas publicadas por la universidad | La ruta `/mis-notas`, la recarga de notas y asistencia desde el portal, las filas con la marca «ULima» de la calculadora y la fila «Notas oficiales» |
| Delegados pendientes | Las tarjetas de delegados que el portal publicaba sin cuenta en la app. Los contactos muestran el rol que entrega el backend |
| Modo estático | `ModoEstatico`, el interruptor remoto, la consulta de `GET /config`, la clave `modo_estatico_conocido` de `shared_preferences`, el middleware que ocultaba rutas y la bandera `MODO_ESTATICO` de `--dart-define` |

La razón es la misma en todos los casos. El laboratorio no tiene acceso al portal ni a credenciales institucionales, y las cuentas existen solo por el seed sintético del backend, así que estas funciones no tienen con qué operar y su código quedaría muerto.

## Qué cambia en lo que se queda

Donde el modo estático elegía entre dos comportamientos, esta rama conserva uno solo. La bienvenida ofrece únicamente «Sí, entrar» y sigue por el código o Google, la contraseña de ULima++ y el test de especialidad. La calculadora trabaja solo con notas simuladas, y sus archivos de dominio pasan de `lib/domain/recarga_ulima/` a `lib/domain/calculadora/`. El visor de sílabos abre solo enlaces de Drive y, ante cualquier otra URL, muestra «Sílabo no disponible» sin abrir el navegador. El Perfil del alumno queda con el carnet de networking, la carrera, la configuración académica, el restablecimiento de contraseña y el cierre de sesión.

La asistencia se conserva. La ficha del curso muestra el bloque de asistencia con las horas que entrega el backend, que en el laboratorio llena el seed, sin la marca de la última lectura ni botones para recargarla. La hoja de sección del docente mantiene el botón de alumnos impedidos y en riesgo con su contador, y `AtRiskStudentsPage` sigue disponible. El buzón y la campana muestran también las alertas «Alerta de inasistencias», que el backend crea a partir de esas horas.

El horario, la malla, los chats, el chatbot, los bloques de horario, el test de especialidad, el networking, el avatar y el aviso de versión nueva no cambian. El chat en tiempo real sigue sobre Firebase y el aviso de versión sigue leyendo el `version.json` del release publicado en GitHub, igual que en la versión 2.1.0.

## Endpoints que la app ya no llama

- `GET /config`
- `GET /portal-sync/status`, `POST /portal-sync/import` y `POST /portal-sync/refresh`
- `GET /grades/me/ulima`
- `GET /academic-record/me` y `DELETE /academic-record/me`
- `POST /auth/register`

La app sigue llamando a `/attendance-risk` para el riesgo de asistencia del docente. De la respuesta de las secciones deja de leer `asistenciaLeidaEn`, y de la de contactos deja de leer `representantesPendientes`.

## Cómo correr la app contra el backend de laboratorio

El backend de laboratorio se levanta con las instrucciones del `LABORATORIO.md` de su repositorio y escucha en el puerto 3000. La app recibe su dirección con `--dart-define=API_BASE_URL`.

```bash
flutter pub get

# Web (Chrome), con el backend en el mismo equipo
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:3000

# Emulador de Android, que llega al equipo anfitrión por 10.0.2.2
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Solo Android, iOS y Web arrancan, igual que en la versión 2.1.0. El arranque llama siempre a `Firebase.initializeApp` ([`lib/pages/splash/carga_del_arranque.dart`](lib/pages/splash/carga_del_arranque.dart)) y `DefaultFirebaseOptions.currentPlatform` lanza `UnsupportedError` en macOS, Windows y Linux ([`lib/firebase_options.dart`](lib/firebase_options.dart)), porque Firebase no está configurado para esas plataformas, así que en escritorio la app se queda en la pantalla de arranque.

Las cuentas de prueba son las que crea el seed sintético del backend. La app no ofrece registro público.

En VS Code, `.vscode/launch.json` conserva solo la configuración contra el backend local en `10.0.2.2:3000`. Las dos configuraciones que en la versión 2.1.0 apuntan al backend de producción no se incluyen, así que lo que el `README.md` dice sobre «las tres configuraciones» corresponde a esa versión.

## El workflow de release

En este repositorio `.github/workflows/build-apk.yml` no existe. En el repositorio original ese workflow compila la app contra la URL del backend de producción, firma el APK y lo publica como release de GitHub, por lo que no forma parte de la variante. La integración continua de `.github/workflows/ci.yml` se conserva y corre `flutter analyze` y `flutter test` en los pull requests hacia `develop` y `main` y en cada push a `develop`.

## Verificación

`flutter analyze` termina sin errores ni advertencias, con los mismos avisos informativos de la versión 2.1.0, y `flutter test` pasa entero. Las pruebas de `test/sin_portal/` comprueban que ningún archivo de `lib/` menciona las rutas, servicios ni llamadas retiradas, que el workflow de release no existe mientras `ci.yml` se conserva, y que el arranque y el cierre de sesión no piden ninguna ruta retirada. También cubren el bloque de asistencia de la ficha, el botón de riesgo del docente, las alertas de inasistencias, la calculadora simulada y el visor de sílabos. Las pruebas que solo cubren lo retirado no forman parte de la variante, entre ellas `test/aviso_version/aviso_version_workflow_test.dart`, que prueba el workflow de release.
