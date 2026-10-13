import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'formato_numeros.dart';
import '../modelos/combo.dart';
import '../modelos/combo_item.dart';

class CompartirCombo {
  static List<ComboItem> productosCompartibles(Combo combo) {
    return combo.items
        .where(
          (item) => item.cantidad != null && item.cantidad! > 0,
        )
        .toList(growable: false);
  }

  static bool tieneProductosCompartibles(Combo combo) {
    return productosCompartibles(combo).isNotEmpty;
  }

  /// El precio del combo incluye a los productos inactivos, así que no se
  /// comparte hasta quitarlos: el mensaje y el precio no coincidirían.
  static List<ComboItem> productosInactivos(Combo combo) {
    return combo.items.where((item) => !item.activo).toList(growable: false);
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

    final inactivos = productosInactivos(combo);
    if (inactivos.isNotEmpty) {
      final nombres = inactivos.map((item) => '• ${item.nombreProducto}').join('\n');
      await _avisar(
        context,
        'Este combo tiene productos inactivos:\n\n$nombres\n\n'
        'Quítalos del combo antes de compartirlo.',
      );
      return;
    }

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

    if (abierto) return;

    // Sin WhatsApp, se abre el menú de compartir de Android (Telegram, SMS, etc.).
    try {
      await SharePlus.instance.share(ShareParams(text: mensaje));
    } catch (_) {
      if (context.mounted) {
        await _avisar(context, 'No se pudo compartir el combo.');
      }
    }
  }

  static Future<void> _avisar(BuildContext context, String texto) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Text(texto),
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
