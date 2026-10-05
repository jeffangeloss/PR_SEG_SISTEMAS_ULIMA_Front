import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/storage_service.dart';

/// Qué 401s se tratan como sesión caducada y cuáles no (HU33).

/// Cuenta los cierres de sesión sin tocar el llavero ni SharedPreferences:
/// ninguno de los dos existe en un test unitario.
class _StorageEspia extends StorageService {
  int cierres = 0;

  @override
  Future<void> clearSession() async => cierres++;

  @override
  Future<String?> get savedToken async => 'token-guardado';
}

/// Pide una ruta contra un servidor falso que siempre responde 401 y devuelve
/// cuántas veces se cerró la sesión por el camino.
///
/// `runWithClient` sustituye el `Client()` que `Request.send()` construye por
/// dentro, así que no hace falta ningún servidor de verdad. `offAllToLogin()`
/// no navega porque `Get.context` es null sin un GetMaterialApp montado; lo que
/// destruye la sesión es el `clearSession()`.
Future<int> _cierresTrasUn401(String ruta) {
  final espia = _StorageEspia();
  Get.put<StorageService>(espia);
  final servidor = MockClient(
    (_) async => http.Response(
      jsonEncode({
        'error': {'code': 'UNAUTHORIZED', 'message': 'Token inválido'},
      }),
      401,
      headers: {'content-type': 'application/json'},
    ),
  );

  return http.runWithClient(() async {
    final api = ApiClient(configuredBaseUrl: 'http://test');
    Object? lanzado;
    try {
      await api.getJson(ruta, token: 'jwt');
    } catch (e) {
      lanzado = e;
    }
    expect(lanzado, isA<ApiException>(),
        reason: 'el 401 llega al llamador como ApiException');
    return espia.cierres;
  }, () => servidor);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('UNITARIA · esRuta401Exenta (HU33)', () {
    test('caso 1: /auth/register ya no existe y no queda exento', () {
      expect(esRuta401Exenta('/auth/register'), isFalse);
    });

    test('caso 2: /auth/login sigue exento, como antes', () {
      expect(esRuta401Exenta('/auth/login'), isTrue);
    });

    test('caso 3: una ruta autenticada NO queda exenta', () {
      expect(esRuta401Exenta('/auth/me'), isFalse);
      expect(esRuta401Exenta('/academic-profile/careers'), isFalse);
    });

    test('caso 4: /auth/logout no entra por acá; su excepción es la de navegar', () {
      expect(esRuta401Exenta('/auth/logout'), isFalse);
    });
  });

  group('UNITARIA · ApiClient ante un 401 (HU33)', () {
    test('caso 1: el 401 de una ruta autenticada cierra la sesión', () async {
      // La conducta de `login()` y `finishGoogleLogin()`: ahí un 401 del
      // catálogo significa que la sesión murió.
      final cierres = await _cierresTrasUn401('/academic-profile/careers');
      expect(cierres, equals(1));
    });
  });
}
