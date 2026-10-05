// test/HU37_jeff/filas_calculadora_test.dart
//
// UNITARIA · Las filas de la calculadora, que en la variante de laboratorio
// es solo simulada (ver LABORATORIO.md).
// Archivos probados lib/domain/calculadora/filas_calculadora.dart y el
// guardado de lib/pages/calculadora/calculadora_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/calculadora/filas_calculadora.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';

import '../sin_portal/apoyo_sin_portal.dart';

Map<String, dynamic> _simulada(String id, {int peso = 20, double valor = 16}) =>
    {
      'titulo': 'Simulada $id',
      'peso': peso,
      'valor': valor,
      'evaluacionId': id,
    };

void main() {
  group('UNITARIA · filas visibles', () {
    test('el orden sigue al sílabo, con las ajenas al final en su orden de '
        'hoy', () {
      final filas = filasVisibles(
        simuladas: [
          _simulada('9001'),
          _simulada('5012'),
          _simulada('9000'),
          _simulada('5011'),
        ],
        ordenSilabo: ['5012', '5011', '5013'],
      );

      expect(filas.map((f) => f.evaluacionId), [
        '5012',
        '5011',
        '9001',
        '9000',
      ]);
    });

    test("cada fila lleva su índice en curso['notas'] por evaluacionId", () {
      final simuladas = [_simulada('5012'), _simulada('5011')];
      final filas = filasVisibles(
        simuladas: simuladas,
        ordenSilabo: ['5011', '5012'],
      );

      expect(filas[0].evaluacionId, '5011');
      expect(filas[0].indiceSimulada, 1);
      expect(filas[1].evaluacionId, '5012');
      expect(filas[1].indiceSimulada, 0);
    });

    test('el promedio recibe el valor y el peso de cada fila', () {
      final filas = filasVisibles(
        simuladas: [_simulada('5011', peso: 25, valor: 14.5)],
      );

      expect(filas.single.valorParaPromedio, 14.5);
      expect(notasParaPromedio(filas), [
        {'valor': 14.5, 'peso': 25.0},
      ]);
    });

    test('un curso cuenta solo si tiene notas simuladas', () {
      expect(tieneFilasVisibles({'notas': <Object?>[]}), isFalse);
      expect(tieneFilasVisibles(<String, Object?>{}), isFalse);
      expect(
        tieneFilasVisibles({
          'notas': [_simulada('5011')],
        }),
        isTrue,
      );
    });
  });

  group('UNITARIA · el guardado de la calculadora', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
      loguear(alumna());
    });
    tearDown(Get.reset);

    test('guarda las simuladas y calcula el promedio con ellas', () async {
      final api = ApiFalsa(calcularPromedio: true);
      final c = CalculadoraController(apiClient: api);
      c.cursos.add({
        'id': '81',
        'nombre': 'TALLER DE PROTOTIPADO',
        'ciclo': '2026-2',
        'codigoSeccion': '812',
        'notas': <Map<String, dynamic>>[_simulada('5011')].obs,
        '_promedio': 0.0,
        '_sumaPesos': 0.0,
      });

      c.agregarNota(0, 'Práctica', 25, 16, '5012');
      await Future<void>.delayed(Duration.zero);

      final guardado = api.cuerposDe('/grades/me/notes').single;
      expect(guardado, {
        'cursos': [
          {
            'sectionId': 81,
            'notas': [
              {'assessmentId': 5011, 'valor': 16.0},
              {'assessmentId': 5012, 'valor': 16.0},
            ],
          },
        ],
      });
      expect(api.cuerposDe('/grades/me/calculate').last, {
        'notas': [
          {'valor': 16.0, 'peso': 20.0},
          {'valor': 16.0, 'peso': 25.0},
        ],
      });
    });
  });
}
