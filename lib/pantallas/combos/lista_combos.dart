import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logica/formato_numeros.dart';
import '../../providers/combo_provider.dart';
import '../../temas/colores.dart';
import '../../widgets/boton_volver.dart';
import 'detalle_combo.dart';

class ListaCombos extends StatelessWidget {
  const ListaCombos({super.key});

  Future<void> _crearCombo(BuildContext context) async {
    final controller = TextEditingController();
    String? error;
    bool comprobando = false;
    final nombre = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('CREAR COMBO'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setDialogState(() => error = null),
            decoration: InputDecoration(labelText: 'Nombre', errorText: error),
          ),
          actions: [
            TextButton(
              onPressed: controller.text.trim().isEmpty || comprobando
                  ? null
                  : () async {
                      final nombreEscrito = controller.text.trim();
                      setDialogState(() { comprobando = true; error = null; });
                      final existe = await context.read<ComboProvider>().existeNombre(nombreEscrito);
                      if (!dialogContext.mounted) return;
                      setDialogState(() => comprobando = false);
                      if (existe) {
                        setDialogState(() => error = 'Ya existe un combo con ese nombre');
                      } else {
                        Navigator.pop(dialogContext, nombreEscrito);
                      }
                    },
              child: const Text('ACEPTAR'),
            ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCELAR')),
          ],
        ),
      ),
    );
    controller.dispose();
    if (nombre == null || !context.mounted) return;
    final id = await context.read<ComboProvider>().crear(nombre);
    if (!context.mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya existe un combo con ese nombre')));
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleCombo(comboId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComboProvider>();
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(leadingWidth: 112, leading: const BotonVolver(), title: const Text('COMBOS')),
      body: provider.cargando
          ? const Center(child: CircularProgressIndicator())
          : provider.combos.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No hay combos todavía. Presiona + CREAR COMBO para comenzar.', textAlign: TextAlign.center)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: provider.combos.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
                  itemBuilder: (context, index) {
                    final combo = provider.combos[index];
                    return InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleCombo(comboId: combo.id))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(combo.nombre, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          if (combo.items.isEmpty) Text('Sin productos', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
                          ...combo.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text('• ${item.cantidad ?? '—'} ${item.nombreProducto}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: item.activo ? null : (oscuro ? ColoresApp.rojoOscuro : ColoresApp.alerta))),
                          )),
                          const SizedBox(height: 8),
                          Text('Venta: ${FormatoNumeros.moneda(combo.precioCombo)}    Costo: ${FormatoNumeros.moneda(combo.costoProductos)}', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 3),
                          Text('Ganancia: ${FormatoNumeros.moneda(combo.ganancia)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: oscuro ? ColoresApp.gananciaOscura : ColoresApp.gananciaClaro, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 14), child: FilledButton.icon(onPressed: () => _crearCombo(context), icon: const Icon(Icons.add), label: const Text('CREAR COMBO')))),
    );
  }
}
