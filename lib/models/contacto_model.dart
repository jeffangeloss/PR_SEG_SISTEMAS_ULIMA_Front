import 'package:ulima_plus/models/user_model.dart';

import 'networking_model.dart';

class ContactoCurso {
  final UserModel user;
  final String roleInSection;
  final NetworkingCardDto? networking;

  /// Foto del compañero. Va acá y no dentro de `user` porque el endpoint de
  /// contactos la manda al nivel del contacto.
  final String? avatarUrl;

  ContactoCurso({
    required this.user,
    required this.roleInSection,
    this.networking,
    this.avatarUrl,
  });

  void operator [](String other) {}
}
