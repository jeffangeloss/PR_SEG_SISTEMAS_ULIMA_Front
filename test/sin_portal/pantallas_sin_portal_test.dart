// test/sin_portal/pantallas_sin_portal_test.dart
//
// WIDGET · Variante de laboratorio sin portal (ver LABORATORIO.md), las
// pantallas del alumno. Las alertas de inasistencias se muestran como las
// demás. La ficha del curso muestra el bloque de asistencia con las horas
// registradas, sin la última lectura ni botones para traerlas de otro lado.
// La calculadora es solo simulada. El inicio no ofrece cargar cursos y el
// Perfil no trae las tarjetas del récord ni de la carga. El recibimiento
// «si no cabe» ofrece solo «Sí, entrar».
// Archivos probados lib/services/alert_service.dart,
// lib/pages/alertas/alertas_page.dart, lib/pages/descripcion_cursos/**,
// lib/pages/calculadora/**, lib/pages/home/**, lib/pages/perfil/perfil.dart
// y lib/pages/bienvenida/widgets/compositor.dart.
//
// La sección es la 301, código 801, del CURSO DE PRUEBA A. Todo dato es
// inventado.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/pages/alertas/alertas_page.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/recibimiento.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_page.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos_controller.dart';
import 'package:ulima_plus/pages/home/home_controller.dart';
import 'package:ulima_plus/pages/home/home_page.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_controller.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/seccion_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import '../HU36_jeff/dobles_de_red.dart';
import '../bienvenida/apoyo_bienvenida.dart';
import 'apoyo_sin_portal.dart';

const String _tituloDeInasistencias =
    'Alerta de inasistencias - CURSO DE PRUEBA A';
const String _tituloDeCarga = 'Semana de alta carga';

Map<String, Object> _alerta(int id, String titulo, {bool leida = false}) =>
    <String, Object>{
      'id': id,
      'studentId': 1,
      'type': 'academic_risk',
      'title': titulo,
      'message': 'Mensaje de prueba $id.',
      'isRead': leida,
      'createdAt': '2026-09-30T12:00:00.000Z',
    };

Map<String, Object> get _alertas => <String, Object>{
  'alerts': <Object>[
    _alerta(1, _tituloDeInasistencias),
    _alerta(2, _tituloDeCarga),
    _alerta(3, 'Alerta de inasistencias - CURSO DE PRUEBA B', leida: true),
  ],
};

Map<String, dynamic> _seccionJson({bool conDatos = true}) => <String, dynamic>{
  'idSeccion': '301',
  'codigoSeccion': '801',
  'curso': 'CURSO DE PRUEBA A',
  'asistido': conDatos ? 12 : 0,
  'inasistencia': conDatos ? 2 : 0,
  'total': conDatos ? 30 : 0,
  'asistenciaDisponible': conDatos,
  'horasTranscurridas': conDatos ? 14 : 0,
};

/// La ficha con la sección fija y sin red en las pestañas.
class _Ficha extends DescripCursosController {
  _Ficha(this._inicial) : super(seccionService: SeccionService());

  final Seccion _inicial;

  @override
  Future<void> cargarDatosCurso(String idSeccion) async {
    seccionActual.value = _inicial;
    secciones.value = <Seccion>[_inicial];
  }

  @override
  Future<void> fetchAnuncios(String idSeccion) async {}

  @override
  Future<void> fetchAsesorias(String idSeccion) async {}

  @override
  Future<void> fetchContactos(String idSeccion) async {}
}

/// La calculadora con un curso sembrado y sin la carga remota.
class _CalculadoraDePrueba extends CalculadoraController {
  _CalculadoraDePrueba(ApiFalsa api) : super(apiClient: api);

  @override
  // ignore: must_call_super
  void onInit() {
    cursos.add({
      'id': '81',
      'nombre': 'TALLER DE PROTOTIPADO',
      'ciclo': '2026-2',
      'codigoSeccion': '812',
      'notas': <Map<String, dynamic>>[
        {'titulo': 'Práctica', 'peso': 25, 'valor': 14.0, 'evaluacionId': '1'},
      ].obs,
      '_promedio': 0.0,
      '_sumaPesos': 0.0,
    });
  }
}

class _MallaSinRed extends MallaService {
  @override
  Future<void> load() async {}
}

class _AlertasSinRed extends AlertService {
  @override
  Future<void> fetchAlerts() async {}
}

class _HorarioSinRed extends HorarioController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

Future<void> _montar(WidgetTester tester, Widget pantalla) async {
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: MaterialTheme(ThemeData().textTheme).light(),
      home: pantalla,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('las alertas de inasistencias', () {
    setUp(() {
      Get.put<StorageService>(AlmacenDePrueba());
      loguear(alumna());
    });

    test('AlertService las conserva y las cuenta como sin leer', () async {
      final servicio = Get.put<AlertService>(AlertService());
      final espia = EspiaDeRed(
        respuestas: <String, Object>{'GET /alerts/me': _alertas},
      );
      await espia.correr(servicio.fetchAlerts);
      expect(servicio.hasError, isFalse);
      expect(servicio.alerts, hasLength(3));
      expect(servicio.unreadCount, 2);
    });

    testWidgets('el buzón las muestra', (tester) async {
      Get.put<AlertService>(AlertService());
      final espia = EspiaDeRed(
        respuestas: <String, Object>{'GET /alerts/me': _alertas},
      );
      await espia.correr(() async {
        await _montar(tester, const AlertasPage());
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      });
      expect(find.text(_tituloDeInasistencias), findsOneWidget);
      expect(find.text(_tituloDeCarga), findsOneWidget);
    });
  });

  group('la ficha del curso', () {
    Future<void> abrirFicha(WidgetTester tester, {required bool conDatos}) {
      loguear(alumna());
      Get.put<DescripCursosController>(
        _Ficha(Seccion.fromJson(_seccionJson(conDatos: conDatos))),
      );
      return _montar(tester, DescripCursosPage(idSeccion: '301'));
    }

    testWidgets('con horas registradas, el bloque de asistencia sin la última '
        'lectura ni botones', (tester) async {
      await abrirFicha(tester, conDatos: true);
      expect(find.text('Asistencia'), findsWidgets);
      expect(find.text('12 horas'), findsOneWidget);
      expect(find.text('2 horas'), findsOneWidget);
      expect(find.text('30 horas'), findsOneWidget);
      expect(find.text('14 dictadas hasta hoy'), findsOneWidget);
      expect(find.textContaining('Última lectura'), findsNothing);
      expect(find.textContaining('miUlima'), findsNothing);
      expect(find.textContaining('ULima'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Actualizar'), findsNothing);
      expect(find.text('Anuncios'), findsOneWidget);
    });

    testWidgets('sin horas registradas, un texto neutral y ningún botón', (
      tester,
    ) async {
      await abrirFicha(tester, conDatos: false);
      expect(
        find.text('Sin datos de asistencia para este curso.'),
        findsOneWidget,
      );
      expect(
        find.text('Todavía no hay horas de clase registradas para este curso.'),
        findsOneWidget,
      );
      expect(find.textContaining('miUlima'), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });
  });

  testWidgets('la calculadora es simulada, sin «Notas oficiales» y sin pedir '
      'notas de la universidad', (tester) async {
    loguear(alumna());
    final api = ApiFalsa();
    Get.put<CalculadoraController>(_CalculadoraDePrueba(api));
    await _montar(tester, const CalculadoraPage());
    expect(find.text('Calculadora de Notas'), findsOneWidget);
    expect(find.text('TALLER DE PROTOTIPADO'), findsWidgets);
    expect(find.text('Notas oficiales'), findsNothing);
    expect(find.text('ULima'), findsNothing);
    expect(api.llamadas.where((l) => l.contains('/ulima')), isEmpty);
  });

  testWidgets('el inicio no ofrece cargar cursos y no pide nada retirado', (
    tester,
  ) async {
    loguear(alumna());
    Get.put<AlertService>(_AlertasSinRed());
    Get.put<MallaService>(_MallaSinRed());
    Get.put<MallaListController>(MallaListController());
    Get.put<HorarioController>(_HorarioSinRed());
    final espia = EspiaDeRed();
    await espia.correr(() async {
      Get.put<HomeController>(HomeController());
      await _montar(tester, const HomePage());
    });
    expect(find.textContaining('miUlima'), findsNothing);
    expect(find.text('Cargar'), findsNothing);
    expect(espia.retiradas, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('el Perfil no trae las tarjetas del récord ni de la carga', (
    tester,
  ) async {
    loguear(alumna());
    Get.put<MallaService>(_MallaSinRed());
    final espia = EspiaDeRed();
    await espia.correr(() async {
      await _montar(tester, const Scaffold(body: ProfilePage()));
    });
    expect(find.textContaining('miUlima'), findsNothing);
    expect(find.textContaining('récord'), findsNothing);
    expect(find.text('Seguridad'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(espia.retiradas, isEmpty);
  });

  group('el recibimiento', () {
    setUpAll(cargarRoboto);

    testWidgets('«si no cabe», una sola respuesta rápida: «Sí, entrar»', (
      tester,
    ) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        pantalla: const Size(600, 360),
        escala: 1.3,
      );
      await avanzar(tester, 4500);
      expect(find.byType(Recibimiento), findsNothing);
      expect(find.byType(RespuestaRapida), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.siEntrar), findsOneWidget);
      expect(find.text('Soy nuevo'), findsNothing);
      await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
      await avanzar(tester, 3000);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
    });
  });
}
