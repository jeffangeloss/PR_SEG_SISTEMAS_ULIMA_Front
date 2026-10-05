// lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/components/chatbot_bubble.dart';

import '../horario/horario_controller.dart';
import '../splash/estado_de_la_capa.dart';
import 'home_controller.dart';
import 'home_shell_config.dart';

/// La clave del argumento de ruta que elige la pestaña inicial (RF-SPL-20).
const String argumentoDePestana = 'pestana';

/// Lo pasan la intro del splash y la bienvenida al llegar a /home (S-31).
const Map<String, String> abrirEnHorario = <String, String>{
  argumentoDePestana: 'horario',
};

/// El índice con el que abre el shell. Con `{'pestana': 'horario'}` es la
/// pestaña Horario, que se busca por su etiqueta y así sirve para todos los
/// roles (S-24). Sin argumento, o con otro valor, es la primera (S-25).
int indiceDePestanaInicial(Object? argumentos, List<String> etiquetas) {
  if (argumentos is Map && argumentos[argumentoDePestana] == 'horario') {
    final i = etiquetas.indexOf('Horario');
    if (i >= 0) return i;
  }
  return 0;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<DeviceOrientation> _portraitOnly = [
    DeviceOrientation.portraitUp,
  ];
  static const List<DeviceOrientation> _scheduleOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  final HomeController control = Get.put(HomeController());
  final user = AuthService.to.currentUser;

  int _currentIndex = 0;

  late final HomeShellConfig _config = HomeShellConfig.forUser(user);

  /// Índice del tab de Horario, derivado de las pestañas reales (para un JP la
  /// pestaña "Calificar" no existe, así que Horario/Asesorías se corren).
  int get _horarioTabIndex =>
      _config.footerItems.indexWhere((i) => i.label == 'Horario');

  bool get _isHorarioTabActive => _currentIndex == _horarioTabIndex;

  /// Índice de la pestaña Chats del alumno, o -1 para el docente, que no la
  /// tiene (RF-CHAT-5).
  int get _chatsTabIndex =>
      _config.footerItems.indexWhere((i) => i.label == 'Chats');

  Widget _buildBody() {
    return _config.pages[_currentIndex];
  }

  Future<void> _applyPreferredOrientations() {
    return SystemChrome.setPreferredOrientations(
      _isHorarioTabActive ? _scheduleOrientations : _portraitOnly,
    );
  }

  bool _argumentoLeido = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentoLeido) return;
    _argumentoLeido = true;
    // El argumento se lee una sola vez, al montarse (RF-SPL-20).
    _currentIndex = indiceDePestanaInicial(
      ModalRoute.of(context)?.settings.arguments,
      [for (final i in _config.footerItems) i.label],
    );
    // Bajo la capa del arranque la app sigue en vertical, y las orientaciones
    // se piden cuando la capa se retira (S-26).
    if (EstadoDeLaCapa.cubre.value) {
      EstadoDeLaCapa.cubre.addListener(_alRetirarseLaCapa);
    } else {
      _applyPreferredOrientations();
    }
  }

  void _alRetirarseLaCapa() {
    if (EstadoDeLaCapa.cubre.value) return;
    EstadoDeLaCapa.cubre.removeListener(_alRetirarseLaCapa);
    if (mounted) _applyPreferredOrientations();
  }

  void _onTabTap(int index) {
    final previous = _currentIndex;
    setState(() {
      _currentIndex = index;
    });
    _applyPreferredOrientations();
    // Si el usuario cambia al tab de Horario, recargamos los datos
    // para reflejar asesorías creadas o modificadas recientemente. Chats hace
    // lo mismo, porque su bandeja lee las secciones de ese controller
    // (RF-CHAT-6).
    // Para docentes: también recargamos si venían del tab de Asesorías (su
    // índice se deriva de las pestañas reales, que varían para un JP).
    final isTeacher = user?.isTeacher ?? false;
    final asesoriasIndex = _config.footerItems.indexWhere(
      (i) => i.label == 'Asesorias',
    );
    final comingFromAsesorias =
        isTeacher && asesoriasIndex != -1 && previous == asesoriasIndex;
    if (index == _horarioTabIndex ||
        index == _chatsTabIndex ||
        comingFromAsesorias) {
      try {
        Get.find<HorarioController>().reload();
      } catch (_) {
        // El controller aún no existe (primera visita): onInit lo cargará, sin
        // un reload() aparte que repita la carga.
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(_portraitOnly);
    EstadoDeLaCapa.cubre.removeListener(_alRetirarseLaCapa);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final u = user;
    final isScheduleLandscape =
        _isHorarioTabActive &&
        MediaQuery.of(context).orientation == Orientation.landscape;
    final showBubble = u != null && !u.isTeacher && !isScheduleLandscape;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          if (!isScheduleLandscape)
            AppHeader(isScheduleTab: _isHorarioTabActive),
          Expanded(
            // La burbuja del chatbot va en un Stack sobre el body (no en el slot
            // fijo del FAB) para poder arrastrarla; las zonas vacías del Stack
            // dejan pasar los toques al contenido de abajo.
            child: Stack(
              children: [_buildBody(), if (showBubble) const ChatbotBubble()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isScheduleLandscape
          ? null
          : AppFooter(
              currentIndex: _currentIndex,
              items: _config.footerItems,
              onTap: _onTabTap,
            ),
    );
  }
}
