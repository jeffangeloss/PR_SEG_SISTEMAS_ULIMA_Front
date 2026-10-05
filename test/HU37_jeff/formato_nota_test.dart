// test/HU37_jeff/formato_nota_test.dart
//
// UNITARIA · Formato del peso y de la nota de la calculadora (D10 de
// specs/features/recarga-portal/recarga-portal.spec.md).
// Archivo probado lib/domain/calculadora/formato_nota.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/calculadora/formato_nota.dart';

void main() {
  group('UNITARIA · formato del peso (D10)', () {
    test('entero sin decimales y con hasta dos si los tiene', () {
      expect(formatoPeso(20), '20%');
      expect(formatoPeso(20.0), '20%');
      expect(formatoPeso(12.5), '12.5%');
      expect(formatoPeso(12.25), '12.25%');
      expect(formatoPeso(12.10), '12.1%');
      expect(numeroDePeso(12.5), '12.5');
    });
  });

  group('UNITARIA · formato de la nota (D10)', () {
    test('en la calculadora, siempre un decimal', () {
      expect(formatoNotaCalculadora(14.25), '14.3');
      expect(formatoNotaCalculadora(15), '15.0');
    });
  });
}
