import 'package:flutter/material.dart';
import '../logica/formato_numeros.dart';

class DialogoEditarNumero {
  static Future<double?> mostrar(
    BuildContext context, {
    required String titulo,
    required String valorInicial,
    String etiqueta = 'Valor',
    bool entero = false,
    bool mayorQueCero = false,
    bool permitirVacio = false,
  }) async {
    final controlador = TextEditingController(text: valorInicial);
    String? error;
    final resultado = await showDialog<double?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (contextInterno, setDialogState) => AlertDialog(
          title: Text(titulo),
          content: TextField(
            controller: controlador,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: !entero, signed: !entero),
            decoration: InputDecoration(labelText: etiqueta, errorText: error),
            onSubmitted: (_) {
              final valor = _validar(controlador.text, entero, mayorQueCero, permitirVacio);
              if (valor != null) Navigator.pop(dialogContext, valor);
              else setDialogState(() => error = 'Introduce un valor válido');
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                final valor = _validar(controlador.text, entero, mayorQueCero, permitirVacio);
                if (valor == null) {
                  setDialogState(() => error = mayorQueCero ? 'El valor debe ser mayor que cero' : 'Introduce un número válido');
                } else {
                  Navigator.pop(dialogContext, valor);
                }
              },
              child: const Text('ACEPTAR'),
            ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCELAR')),
          ],
        ),
      ),
    );
    controlador.dispose();
    return resultado;
  }

  static double? _validar(String texto, bool entero, bool mayorQueCero, bool permitirVacio) {
    if (permitirVacio && texto.trim().isEmpty) return 0;
    final valor = FormatoNumeros.leerNumero(texto);
    if (valor == null || !valor.isFinite || (mayorQueCero && valor <= 0)) return null;
    if (entero && valor % 1 != 0) return null;
    return valor;
  }
}
