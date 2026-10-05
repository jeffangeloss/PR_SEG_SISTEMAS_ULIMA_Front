// lib/domain/calculadora/filas_calculadora.dart
//
// Las filas de la calculadora. En la variante de laboratorio la calculadora es
// solo simulada: todas las filas salen de `curso['notas']`.

/// Una fila visible de la calculadora.
class FilaCalculadora {
  const FilaCalculadora({
    required this.titulo,
    required this.peso,
    required this.valor,
    required this.evaluacionId,
    this.indiceSimulada,
  });

  final String titulo;
  final num peso;
  final double valor;
  final String evaluacionId;

  /// La posición de la simulada en `curso['notas']`, que es la que pide
  /// `eliminarNota`.
  final int? indiceSimulada;

  double get valorParaPromedio => valor;
}

String _id(Object? nota) => nota is Map ? '${nota['evaluacionId']}' : '';

/// Las filas visibles de un curso. El orden es el de [ordenSilabo], con las
/// que no están en el sílabo al final y en su orden de hoy.
List<FilaCalculadora> filasVisibles({
  required List<Object?> simuladas,
  List<String> ordenSilabo = const [],
}) {
  final filas = <FilaCalculadora>[
    for (final s in simuladas.whereType<Map>())
      FilaCalculadora(
        titulo: '${s['titulo']}',
        peso: (s['peso'] as num?) ?? 0,
        valor: (s['valor'] as num?)?.toDouble() ?? 0,
        evaluacionId: _id(s),
        indiceSimulada: simuladas.indexWhere((n) => _id(n) == _id(s)),
      ),
  ];
  final posicion = {
    for (var i = 0; i < ordenSilabo.length; i++) ordenSilabo[i]: i,
  };
  final conOrden = filas.asMap().entries.toList()
    ..sort((a, b) {
      final pa = posicion[a.value.evaluacionId] ?? ordenSilabo.length;
      final pb = posicion[b.value.evaluacionId] ?? ordenSilabo.length;
      return pa != pb ? pa.compareTo(pb) : a.key.compareTo(b.key);
    });
  return [for (final e in conOrden) e.value];
}

/// Lo que recibe `POST /grades/me/calculate`.
List<Map<String, double>> notasParaPromedio(List<FilaCalculadora> filas) => [
  for (final f in filas)
    {'valor': f.valorParaPromedio, 'peso': f.peso.toDouble()},
];

/// Si el curso tiene alguna fila visible.
bool tieneFilasVisibles(Map<dynamic, dynamic> curso) =>
    (curso['notas'] as List?)?.isNotEmpty ?? false;
