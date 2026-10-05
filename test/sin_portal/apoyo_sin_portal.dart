// test/sin_portal/apoyo_sin_portal.dart
//
// Apoyo de las pruebas de la variante de laboratorio sin portal (ver
// LABORATORIO.md). No termina en _test.dart, así que `flutter test` no lo
// corre como suite. Todo dato es inventado, porque el repo es público.

import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';

/// Un cliente HTTP que no sale a la red. Anota cada petición como
/// `GET /ruta` y responde `200` con un objeto JSON vacío, salvo que
/// [respuestas] traiga la clave de la petición, como `GET /alerts/me`, o que
/// [estados] fije otro código para ella.
class EspiaDeRed extends http.BaseClient {
  EspiaDeRed({
    this.respuestas = const <String, Object>{},
    this.estados = const <String, int>{},
  });

  /// El JSON que devuelve cada petición, por clave `MÉTODO /ruta`.
  final Map<String, Object> respuestas;

  /// El código HTTP de cada petición, por clave `MÉTODO /ruta`. Sin clave, 200.
  final Map<String, int> estados;

  /// Cada petición, en orden, sin la query.
  final List<String> peticiones = <String>[];

  /// Las rutas que la variante de laboratorio ya no pide nunca.
  static final RegExp _retiradas = RegExp(
    r'/auth/register|/portal-sync|/academic-record|/grades/me/ulima'
    r'|/config$',
  );

  /// Las peticiones a rutas retiradas.
  List<String> get retiradas =>
      peticiones.where((p) => _retiradas.hasMatch(p)).toList();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final clave = '${request.method} ${request.url.path}';
    peticiones.add(clave);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(jsonEncode(respuestas[clave] ?? {}))),
      estados[clave] ?? 200,
      headers: <String, String>{'content-type': 'application/json'},
    );
  }

  /// Corre [cuerpo] con este espía como el cliente HTTP de todo el paquete.
  Future<T> correr<T>(Future<T> Function() cuerpo) =>
      http.runWithClient<Future<T>>(cuerpo, () => this);
}

UserModel alumna({String code = '20230001'}) => UserModel(
  code: code,
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-2',
  setupComplete: true,
);

UserModel docente() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  currentCycle: '2026-2',
  setupComplete: true,
);

class AuthFalso extends AuthService {
  AuthFalso(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Registra a [user] como el usuario actual.
AuthFalso loguear(UserModel? user) {
  final auth = AuthFalso(user);
  Get.put<AuthService>(auth);
  return auth;
}

/// `ApiClient` falso que anota cada llamada como `MÉTODO /ruta`, sin la
/// query, y responde con un mapa vacío. Con [calcularPromedio],
/// `POST /grades/me/calculate` suma valor · peso / 100 como el backend.
class ApiFalsa extends ApiClient {
  ApiFalsa({this.calcularPromedio = false})
    : super(configuredBaseUrl: 'http://test');

  final bool calcularPromedio;

  /// Cada llamada, como `GET /grades/me/notes`, en orden.
  final List<String> llamadas = <String>[];

  /// El cuerpo de cada POST, en orden, junto a su ruta.
  final List<(String, Map<String, dynamic>)> cuerpos =
      <(String, Map<String, dynamic>)>[];

  int veces(String clave) => llamadas.where((l) => l == clave).length;

  List<Map<String, dynamic>> cuerposDe(String ruta) =>
      cuerpos.where((c) => c.$1 == ruta).map((c) => c.$2).toList();

  static String _ruta(String path) => path.split('?').first;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
  }) async {
    llamadas.add('GET ${_ruta(path)}');
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final ruta = _ruta(path);
    llamadas.add('POST $ruta');
    cuerpos.add((ruta, body));
    if (!calcularPromedio || ruta != '/grades/me/calculate') {
      return <String, dynamic>{};
    }
    var promedio = 0.0;
    var suma = 0.0;
    for (final n in (body['notas'] as List).cast<Map>()) {
      final peso = (n['peso'] as num).toDouble();
      promedio += (n['valor'] as num).toDouble() * peso / 100;
      suma += peso;
    }
    return <String, dynamic>{'promedio': promedio, 'sumaPesos': suma};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) async {
    llamadas.add('DELETE ${_ruta(path)}');
    return <String, dynamic>{};
  }
}
