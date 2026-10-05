// test/sin_portal/sin_portal_test.dart
//
// UNITARIA · Variante de laboratorio sin portal (ver LABORATORIO.md).
// La app ya no tiene rutas, servicios ni llamadas de la integración con el
// portal institucional, ni el interruptor del modo estático. El código se lee
// como texto, y este repositorio no trae el workflow de release.
// Archivos probados lib/**, .github/workflows/,
// lib/pages/splash/carga_del_arranque.dart y lib/services/auth_service.dart.

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/pages/splash/carga_del_arranque.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';
import 'package:ulima_plus/services/storage_service.dart';
import 'package:ulima_plus/services/time_blocks_service.dart';

import '../HU36_jeff/dobles_de_red.dart';
import 'apoyo_sin_portal.dart';

/// Lo que ningún archivo de lib/ puede mencionar.
const List<String> _retirados = <String>[
  'ModoEstatico',
  'MODO_ESTATICO',
  'InterruptorRemoto',
  "'/config'",
  '/portal-sync',
  '/auth/register',
  '/academic-record',
  '/grades/me/ulima',
  '/mi-record',
  '/mis-notas',
  'PortalSync',
  'RecargaUlima',
  'RegistroService',
  'AcademicRecord',
  'representantesPendientes',
  'RepresentantePendiente',
  'asistenciaLeidaEn',
  'miUlima',
  'webaloe',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('el código de lib/', () {
    test('ninguna ruta de la app es del portal ni del registro', () {
      final rutas = paginasDeLaApp.map((p) => p.name).toList();
      for (final ruta in [
        '/portal-sync',
        '/mi-record',
        '/mis-notas',
        '/registro',
      ]) {
        expect(rutas, isNot(contains(ruta)), reason: ruta);
      }
    });

    test('ningún archivo menciona lo retirado', () {
      final archivos = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      expect(archivos, isNotEmpty);
      final hallazgos = <String>[
        for (final archivo in archivos)
          for (final retirado in _retirados)
            if (archivo.readAsStringSync().contains(retirado))
              '${archivo.path}: $retirado',
      ];
      expect(hallazgos, isEmpty);
    });
  });

  group('los workflows de GitHub Actions', () {
    test('build-apk.yml no existe en este repositorio', () {
      expect(File('.github/workflows/build-apk.yml').existsSync(), isFalse);
    });

    test('ci.yml se conserva', () {
      expect(File('.github/workflows/ci.yml').existsSync(), isTrue);
    });
  });

  group('el arranque y el cierre de sesión', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
    });
    tearDown(Get.reset);

    test('registra los servicios de siempre sin pedir nada', () async {
      final espia = EspiaDeRed();
      await espia.correr(() async {
        registrarLosServicios();
      });
      expect(espia.peticiones, isEmpty);
      expect(Get.isRegistered<AuthService>(), isTrue);
      expect(Get.isRegistered<AlertService>(), isTrue);
      expect(Get.isRegistered<MallaService>(), isTrue);
      expect(Get.isRegistered<TimeBlocksService>(), isTrue);
      expect(Get.isRegistered<SpecialtyTestService>(), isTrue);
    });

    test('cargar el arranque sin sesión no pide nada retirado y termina en '
        '/login', () async {
      final espia = EspiaDeRed();
      final ruta = await espia.correr(
        () => cargarElArranque(iniciarFirebase: () async {}),
      );
      expect(ruta, '/login');
      expect(espia.retiradas, isEmpty);
      expect(espia.peticiones, isNot(contains('GET /config')));
      expect(Get.isRegistered<StorageService>(), isTrue);
    });

    test('el cierre de sesión no pide nada retirado', () async {
      registrarLosServicios();
      Get.put<StorageService>(AlmacenDePrueba());
      final espia = EspiaDeRed();
      await expectLater(espia.correr(AuthService.to.logout), completes);
      expect(espia.retiradas, isEmpty);
    });
  });
}
