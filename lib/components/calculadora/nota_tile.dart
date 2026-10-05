import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/calculadora/formato_nota.dart';

class NotaTile extends StatelessWidget {
  final String titulo;
  final num peso;
  final double nota;
  final VoidCallback onDelete;

  const NotaTile({
    super.key,
    required this.titulo,
    required this.peso,
    required this.nota,
    required this.onDelete,
  });

  String get _textoNota => 'Nota: ${formatoNotaCalculadora(nota)}/20';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _fila(context, colors);
  }

  Widget _fila(BuildContext context, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colors.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    children: [
                      TextSpan(text: "Peso: ${formatoPeso(peso)}  •  "),
                      TextSpan(
                        text: _textoNota,
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.error, size: 22),
            onPressed: () {
              Get.defaultDialog(
                title: "Eliminar Nota",
                titleStyle: TextStyle(color: colors.onSurface),
                middleTextStyle: TextStyle(color: colors.onSurfaceVariant),
                backgroundColor: colors.surface,
                middleText: "¿Estás seguro de que quieres eliminar '$titulo'?",
                textConfirm: "Eliminar",
                textCancel: "Cancelar",
                confirmTextColor: colors.onError,
                buttonColor: colors.error,
                onConfirm: () {
                  onDelete();
                  debugPrint(
                    "✅ ÉXITO: Se eliminó la nota '$titulo' correctamente.",
                  );
                  Get.back();
                },
              );
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
