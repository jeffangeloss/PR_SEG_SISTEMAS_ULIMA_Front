// test/bienvenida/bienvenida_atras_test.dart
//
// UNITARIA · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-13. El atrás del sistema hace lo mismo que el enlace secundario de
// cada turno. La Tarea 25 suma los turnos del test.
// Archivo probado lib/pages/bienvenida/bienvenida_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';

import '../HU36_jeff/dobles_de_red.dart';
import '../HU36_jeff/dobles_del_controlador.dart' show respuestasEnOrden;
import 'apoyo_bienvenida.dart';

typedef _T = TurnoDeLaBienvenida;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('el atrás en el inicio de sesión (RF-BIEN-13)', () {
    test('E2 vuelve a E1, con el código escrito', () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo();
      b.login.codeController.text = '20230001';
      c.enviarCodigo();
      expect(c.turno.value, _T.e2Contrasena);
      c.atras();
      expect(c.turno.value, _T.e1Codigo);
      expect(b.login.codeController.text, '20230001');
    });
  });

  group('el atrás en el test (RF-BIEN-13)', () {
    test('T0 y el resultado no hacen nada, las preguntas son «Pregunta '
        'anterior»', () async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
        apiDelTest: ApiFalsaDelTest(),
      );
      await b.visitar();
      final c = b.controlador..ulisesAterrizoConSesion();
      await pumpEventQueue();
      c.atras();
      expect(c.turno.value, _T.t0Invitacion);
      expect(c.atrasSaleDeLaApp, isFalse);
      c.empezarElTest();
      c
        ..responderAlTest('top', conLector: true)
        ..siguiente()
        ..atras();
      expect(c.test!.paso.value, 0);
      expect(b.delAlumno.last, 'Pregunta anterior');

      // Hasta el resultado, donde el atrás no responde ni sale.
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await pumpEventQueue();
      expect(c.turno.value, _T.resultado);
      final entradas = c.entradas.length;
      final respuestas = b.delAlumno.length;
      c.atras();
      expect(c.turno.value, _T.resultado);
      expect(c.atrasSaleDeLaApp, isFalse);
      expect(c.entradas, hasLength(entradas));
      expect(b.delAlumno, hasLength(respuestas));
    });
  });
}
