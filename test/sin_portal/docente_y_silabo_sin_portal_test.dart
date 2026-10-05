// test/sin_portal/docente_y_silabo_sin_portal_test.dart
//
// WIDGET · Variante de laboratorio sin portal (ver LABORATORIO.md), el riesgo
// de asistencia del docente y el visor de sílabos. La hoja de sección del
// docente trae el botón del riesgo de asistencia y pide `/attendance-risk`,
// y `AtRiskStudentsPage` abre la lista. El visor de sílabos abre solo
// enlaces de Drive: ante cualquier otra URL dice «Sílabo no disponible» y no
// abre el navegador.
// Archivos probados lib/pages/horario/horario.dart,
// lib/pages/teacher/at_risk_students_page.dart,
// lib/pages/silabo/silabo_viewer_controller.dart y
// lib/pages/silabo/silabo_viewer_page.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/silabo/silabo_link.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/silabo/silabo_viewer_controller.dart';
import 'package:ulima_plus/pages/silabo/silabo_viewer_page.dart';
import 'package:ulima_plus/pages/teacher/at_risk_students_controller.dart';
import 'package:ulima_plus/pages/teacher/at_risk_students_page.dart';
import 'package:ulima_plus/services/silabo_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import '../HU36_jeff/dobles_de_red.dart';
import 'apoyo_sin_portal.dart';

const String _tooltipDelRiesgo = 'Alumnos impedidos y en riesgo';

const String _urlDrive =
    'https://drive.google.com/file/d/1SilaboLabIsw2xxxxxxxxxxxxxxxx003/view';
const String _urlAjena = 'https://ejemplo.test/silabos/silabo-de-prueba.pdf';

Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _ServicioFalso extends SilaboService {
  _ServicioFalso(this._respuesta);

  final Future<Uint8List> Function() _respuesta;
  int llamadas = 0;

  @override
  Future<Uint8List> obtenerPdf(SilaboLink link, {bool forzarDescarga = false}) {
    llamadas++;
    return _respuesta();
  }
}

Widget _visor(_ServicioFalso servicio, String url) => GetMaterialApp(
  initialRoute: '/',
  getPages: [
    GetPage(
      name: '/',
      page: () => Scaffold(
        body: TextButton(
          onPressed: () => Get.toNamed<void>(
            '/silabo',
            arguments: {'url': url, 'titulo': 'Ingeniería de Software II'},
          ),
          child: const Text('abrir silabo'),
        ),
      ),
    ),
    GetPage(
      name: '/silabo',
      page: () => const SilaboViewerPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SilaboViewerController(service: servicio));
      }),
    ),
  ],
);

/// Anota cada llamada al canal de `url_launcher`.
List<MethodCall> _espiarElNavegador() {
  final llamadas = <MethodCall>[];
  const canal = MethodChannel('plugins.flutter.io/url_launcher');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(canal, (llamada) async {
        llamadas.add(llamada);
        return true;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null),
  );
  return llamadas;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('el riesgo de asistencia del docente', () {
    setUp(() {
      Get.put<StorageService>(AlmacenDePrueba());
      loguear(docente());
    });

    testWidgets('la hoja de sección trae el botón del riesgo y lo pide una '
        'vez', (tester) async {
      final espia = EspiaDeRed();
      await espia.correr(() async {
        await tester.pumpWidget(
          GetMaterialApp(
            theme: const MaterialTheme(TextTheme()).light(),
            home: const Scaffold(
              body: TeacherCourseDetailSheet(
                idSeccion: '301',
                courseName: 'CURSO DE PRUEBA A',
                sectionCode: '801',
              ),
            ),
          ),
        );
        await _asentar(tester);
      });
      expect(find.text('CURSO DE PRUEBA A'), findsOneWidget);
      expect(find.byTooltip(_tooltipDelRiesgo), findsOneWidget);
      expect(
        espia.peticiones.where((p) => p.contains('/attendance-risk')),
        hasLength(1),
      );
      expect(espia.retiradas, isEmpty);
    });

    testWidgets('la pantalla del riesgo abre la lista y la pide', (
      tester,
    ) async {
      final espia = EspiaDeRed();
      await espia.correr(() async {
        await tester.pumpWidget(
          GetMaterialApp(
            theme: const MaterialTheme(TextTheme()).light(),
            home: const AtRiskStudentsPage(
              sectionId: '301',
              courseName: 'CURSO DE PRUEBA A',
              sectionCode: '801',
            ),
          ),
        );
        await _asentar(tester);
      });
      expect(Get.isRegistered<AtRiskStudentsController>(), isTrue);
      expect(find.text('CURSO DE PRUEBA A'), findsOneWidget);
      expect(
        espia.peticiones.where((p) => p.contains('/attendance-risk')),
        isNotEmpty,
      );
    });
  });

  group('el visor de sílabos', () {
    testWidgets('una URL que no es de Drive dice «Sílabo no disponible», sin '
        'botones y sin abrir el navegador', (tester) async {
      final navegador = _espiarElNavegador();
      final servicio = _ServicioFalso(
        () => fail('no debe pedir el PDF con un enlace que no es de Drive'),
      );
      await tester.pumpWidget(_visor(servicio, _urlAjena));
      await tester.tap(find.text('abrir silabo'));
      await tester.pumpAndSettle();

      expect(find.text(SilaboViewerController.sinSilabo), findsOneWidget);
      expect(find.text('Abrir en Drive'), findsNothing);
      expect(find.text('Reintentar'), findsNothing);
      expect(servicio.llamadas, 0);

      await Get.find<SilaboViewerController>().abrirEnDrive();
      expect(navegador, isEmpty);
    });

    testWidgets('sin URL tampoco hay navegador', (tester) async {
      final navegador = _espiarElNavegador();
      final servicio = _ServicioFalso(() => fail('sin PDF'));
      await tester.pumpWidget(_visor(servicio, ''));
      await tester.tap(find.text('abrir silabo'));
      await tester.pumpAndSettle();
      expect(find.text(SilaboViewerController.sinSilabo), findsOneWidget);
      await Get.find<SilaboViewerController>().abrirEnDrive();
      expect(navegador, isEmpty);
    });

    testWidgets('un enlace de Drive pide el PDF', (tester) async {
      final servicio = _ServicioFalso(() => Completer<Uint8List>().future);
      await tester.pumpWidget(_visor(servicio, _urlDrive));
      await tester.tap(find.text('abrir silabo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(servicio.llamadas, 1);
      expect(find.text(SilaboViewerController.sinSilabo), findsNothing);
    });

    testWidgets('con un fallo de descarga, el respaldo abre la vista de '
        'Drive', (tester) async {
      final navegador = _espiarElNavegador();
      final servicio = _ServicioFalso(
        () => Future.error(const SilaboDescargaException()),
      );
      await tester.pumpWidget(_visor(servicio, _urlDrive));
      await tester.tap(find.text('abrir silabo'));
      await tester.pumpAndSettle();
      expect(find.text('Abrir en Drive'), findsOneWidget);
      await Get.find<SilaboViewerController>().abrirEnDrive();
      expect(navegador, hasLength(1));
      expect(
        (navegador.single.arguments as Map<Object?, Object?>)['url'],
        _urlDrive,
      );
    });
  });
}
