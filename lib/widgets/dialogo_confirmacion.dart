import 'package:flutter/material.dart';

class DialogoConfirmacion {
  static Future<bool> mostrar(
    BuildContext context, {
    required String mensaje,
    String titulo = 'Confirmar',
    String aceptar = 'ACEPTAR',
    String cancelar = 'CANCELAR',
  }) async {
    final respuesta = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(aceptar)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(cancelar)),
        ],
      ),
    );
    return respuesta ?? false;
  }
}
