// lib/pages/bienvenida/widgets/franja_con_sello.dart
// La franja con el sello (RF-BIEN-4).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../components/logo/sello_del_logo.dart';
import '../../../configs/themes.dart';

class FranjaConSello extends StatelessWidget {
  const FranjaConSello({
    super.key,
    required this.latido,
    this.radioInferior = 26,
    this.claveDelSello,
    this.selloVisible = true,
  });

  final ValueListenable<double> latido;
  final double radioInferior;

  /// La clave con la que la subida del recibimiento mide el sello.
  final GlobalKey? claveDelSello;

  /// Oculto mientras el recibimiento dibuja el suyo en el mismo lugar.
  final bool selloVisible;

  @override
  Widget build(BuildContext context) => CabeceraConSello(
    color: MaterialTheme.bienvenidaFranja(Theme.brightnessOf(context)),
    radioInferior: radioInferior,
    sello: Opacity(
      opacity: selloVisible ? 1 : 0,
      child: SelloDelLogo(key: claveDelSello, latido: latido),
    ),
  );
}
