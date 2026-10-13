import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'formato_numeros.dart';
import '../modelos/combo.dart';
import '../modelos/combo_item.dart';

class CompartirCombo {
  static List<ComboItem> productosCompartibles(Combo combo) {
    return combo.items
        .where(
          (item) =>
              item.activo &&
              item.cantidad != null &&
              item.cantidad! > 0,
        )
        .toList(growable: false);
  }

  static bool tieneProductosCompartibles(Combo combo) {
    return productosCompartibles(combo).isNotEmpty;
  }

  static String crearMensaje(Combo combo) {
    final productos = productosCompartibles(combo);

    final listaProductos = productos
        .map((item) => '${item.cantidad} ${item.nombreProducto}')
        .join('\n');

    return '${combo.nombre.toUpperCase()}\n\n'
        '$listaProductos\n\n'
        'Precio: ${FormatoNumeros.moneda(combo.precioCombo)}';
  }

  static Future<void> compartir(
    BuildContext context,
    Combo combo,
  ) async {
    if (!tieneProductosCompartibles(combo)) return;

    final mensaje = crearMensaje(combo);

    final uri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(mensaje)}',
    );

    var abierto = false;

    try {
      abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      abierto = false;
    }

    if (abierto || !context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: const Text(
          'WhatsApp no está instalado\nen este teléfono.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );
  }
}
