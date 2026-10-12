import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logica/formato_numeros.dart';
import '../../modelos/combo.dart';
import '../../modelos/combo_item.dart';
import '../../providers/combo_provider.dart';
import '../../temas/colores.dart';
import '../../widgets/boton_volver.dart';
import '../../widgets/dialogo_confirmacion.dart';
import '../../widgets/dialogo_editar_numero.dart';
import '../anadir_producto_combo/anadir_producto_combo.dart';

class DetalleCombo extends StatelessWidget {
  const DetalleCombo({super.key, required this.comboId});
  final int comboId;

  Future<void> _renombrar(BuildContext context, Combo combo) async {
    final controller = TextEditingController(text: combo.nombre);
    String? error;
    bool comprobando = false;
    final nombre = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('RENOMBRAR COMBO'),
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
                      final nuevoNombre = controller.text.trim();
                      setDialogState(() { comprobando = true; error = null; });
                      final existe = await context.read<ComboProvider>().existeNombre(nuevoNombre, excluirId: combo.id);
                      if (!dialogContext.mounted) return;
                      setDialogState(() => comprobando = false);
                      if (existe) {
                        setDialogState(() => error = 'Ya existe un combo con ese nombre');
                      } else {
                        Navigator.pop(dialogContext, nuevoNombre);
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
    final ok = await context.read<ComboProvider>().renombrar(combo.id, nombre);
    if (!ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya existe un combo con ese nombre')));
  }

  Future<void> _editarCantidad(BuildContext context, ComboItem item) async {
    final valor = await DialogoEditarNumero.mostrar(context, titulo: 'CANTIDAD', etiqueta: 'Cantidad', valorInicial: item.cantidad?.toString() ?? '', entero: true, mayorQueCero: true);
    if (valor == null || !context.mounted) return;
    await context.read<ComboProvider>().actualizarCantidad(item.id, valor.toInt());
  }

  Future<void> _editarPrecioFila(BuildContext context, ComboItem item) async {
    final valor = await DialogoEditarNumero.mostrar(context, titulo: 'PRECIO', etiqueta: 'Precio de la fila', valorInicial: item.precioFila == null ? '' : FormatoNumeros.moneda(item.precioFila!), permitirVacio: false);
    if (valor == null || !context.mounted) return;
    await context.read<ComboProvider>().actualizarPrecioFila(item.id, valor);
  }

  Future<void> _editarTotal(BuildContext context, Combo combo, String campo) async {
    final inicial = switch (campo) {
      'precio' => combo.precioCombo,
      'costo' => combo.costoProductos,
      _ => combo.ganancia,
    };
    final valor = await DialogoEditarNumero.mostrar(context, titulo: campo == 'precio' ? 'PRECIO DEL COMBO' : campo == 'costo' ? 'COSTO DE LOS PRODUCTOS' : 'GANANCIA', etiqueta: 'Valor', valorInicial: FormatoNumeros.moneda(inicial));
    if (valor == null || !context.mounted) return;
    final provider = context.read<ComboProvider>();
    if (campo == 'precio') await provider.editarPrecio(combo.id, valor);
    else if (campo == 'costo') await provider.editarCosto(combo.id, valor);
    else await provider.editarGanancia(combo.id, valor);
  }

  Future<void> _quitarItem(BuildContext context, ComboItem item) async {
    final confirmado = await DialogoConfirmacion.mostrar(context, titulo: 'Quitar producto', mensaje: '¿Quitar ${item.nombreProducto} del combo?');
    if (confirmado && context.mounted) await context.read<ComboProvider>().eliminarItem(item.id);
  }

  Future<void> _eliminarCombo(BuildContext context, Combo combo) async {
    final confirmado = await DialogoConfirmacion.mostrar(context, titulo: 'Eliminar combo', mensaje: '¿Eliminar el combo ${combo.nombre}?');
    if (!confirmado || !context.mounted) return;
    await context.read<ComboProvider>().eliminar(combo.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComboProvider>();
    final combo = provider.porId(comboId);
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    if (combo == null) return Scaffold(appBar: AppBar(leadingWidth: 112, leading: const BotonVolver()), body: const Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 112,
        leading: const BotonVolver(),
        title: Text(combo.nombre.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [IconButton(tooltip: 'Renombrar combo', onPressed: () => _renombrar(context, combo), icon: const Icon(Icons.edit_outlined))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
        children: [
          if (combo.items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('Este combo todavía no tiene productos.')),
          ...combo.items.map((item) => _filaProducto(context, item, oscuro)),
          const SizedBox(height: 14),
          _campoTotal(context, 'PRECIO DEL COMBO', FormatoNumeros.moneda(combo.precioCombo), () => _editarTotal(context, combo, 'precio')),
          const SizedBox(height: 14),
          _campoTotal(context, 'COSTO DE LOS PRODUCTOS', FormatoNumeros.moneda(combo.costoProductos), () => _editarTotal(context, combo, 'costo')),
          const SizedBox(height: 14),
          _campoTotal(context, 'GANANCIA', FormatoNumeros.moneda(combo.ganancia), () => _editarTotal(context, combo, 'ganancia'), color: oscuro ? ColoresApp.gananciaOscura : ColoresApp.gananciaClaro),
        ],
      ),
      bottomNavigationBar: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          OutlinedButton.icon(onPressed: () => _eliminarCombo(context, combo), icon: const Icon(Icons.close), label: const Text('ELIMINAR COMBO'), style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error, minimumSize: const Size(double.infinity, 48))),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnadirProductoCombo(comboId: combo.id))), icon: const Icon(Icons.add), label: const Text('AÑADIR PRODUCTO'), style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50))),
        ]),
      )),
    );
  }

  Widget _filaProducto(BuildContext context, ComboItem item, bool oscuro) {
    final colorNombre = item.activo ? Theme.of(context).colorScheme.onSurface : (oscuro ? ColoresApp.rojoOscuro : ColoresApp.alerta);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${item.nombreProducto}${item.activo ? '' : '  ⚠️'}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: colorNombre))),
            TextButton(onPressed: () => _editarCantidad(context, item), child: Text('Cant: ${item.cantidad ?? '—'}')),
          ]),
          Row(children: [
            Expanded(child: InkWell(onTap: () => _editarPrecioFila(context, item), borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2), child: Text('Precio: ${item.precioFila == null ? '—' : FormatoNumeros.moneda(item.precioFila!)}', style: Theme.of(context).textTheme.bodyLarge)))),
            IconButton(tooltip: 'Vaciar cantidad y precio', onPressed: () => context.read<ComboProvider>().limpiarFila(item.id), icon: const Icon(Icons.cleaning_services_outlined)),
            IconButton(tooltip: 'Quitar del combo', onPressed: () => _quitarItem(context, item), icon: const Icon(Icons.delete_outline)),
          ]),
        ]),
      ),
      Divider(height: 1, color: Theme.of(context).dividerColor),
    ]);
  }

  Widget _campoTotal(BuildContext context, String titulo, String valor, VoidCallback onTap, {Color? color}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(titulo, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 7),
    Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Text(valor, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color)),
      )),
    ),
  ]);
}
