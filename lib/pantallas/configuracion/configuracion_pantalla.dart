import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logica/formato_numeros.dart';
import '../../logica/respaldo.dart';
import '../../modelos/resultado_importacion.dart';
import '../../providers/combo_provider.dart';
import '../../providers/configuracion_provider.dart';
import '../../providers/producto_provider.dart';
import '../../widgets/boton_volver.dart';
import '../../widgets/dialogo_confirmacion.dart';
import '../../widgets/dialogo_editar_numero.dart';

class ConfiguracionPantalla extends StatelessWidget {
  const ConfiguracionPantalla({super.key});

  Future<void> _editarMargen(BuildContext context, double actual) async {
    final valor = await DialogoEditarNumero.mostrar(context, titulo: 'MARGEN', etiqueta: 'Margen', valorInicial: FormatoNumeros.moneda(actual), mayorQueCero: true);
    if (valor == null || !context.mounted) return;
    await _ejecutar(context, () => context.read<ConfiguracionProvider>().cambiarMargen(valor));
  }

  Future<void> _editarTasa(BuildContext context, double actual) async {
    final valor = await DialogoEditarNumero.mostrar(context, titulo: 'TASA DE REFERENCIA', etiqueta: 'Tasa', valorInicial: FormatoNumeros.moneda(actual), mayorQueCero: true);
    if (valor == null || !context.mounted) return;
    await _ejecutar(context, () => context.read<ConfiguracionProvider>().cambiarTasa(valor));
  }

  Future<void> _ejecutar(BuildContext context, Future<void> Function() accion) async {
    try { await accion(); }
    catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar el cambio: $e'))); }
  }

  Future<void> _exportar(BuildContext context) async {
    try {
      final bytes = await context.read<RespaldoService>().crearRespaldo();
      final ahora = DateTime.now();
      final fecha = '${ahora.year.toString().padLeft(4, '0')}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
      final hora = '${ahora.hour.toString().padLeft(2, '0')}-${ahora.minute.toString().padLeft(2, '0')}-${ahora.second.toString().padLeft(2, '0')}';
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Guardar respaldo',
        fileName: 'combo_manager_respaldo_${fecha}_$hora.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uri == null ? 'Exportación cancelada' : 'Respaldo exportado correctamente')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al exportar el respaldo')));
    }
  }

  Future<void> _importar(BuildContext context) async {
    try {
      final archivo = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
      if (archivo == null || !context.mounted) return;
      final confirmar = await DialogoConfirmacion.mostrar(
        context,
        titulo: 'Importar respaldo',
        mensaje: 'Se agregarán los productos y combos que no tengas todavía. Los que ya tengas se conservan.',
      );
      if (!confirmar || !context.mounted) return;
      final bytes = await archivo.readAsBytes();
      final resultado = await context.read<RespaldoService>().importar(bytes);
      await context.read<ProductoProvider>().recargar();
      await context.read<ComboProvider>().recargar();
      if (context.mounted) await _mostrarResumen(context, resultado);
    } on RespaldoVersionNueva {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El respaldo es de una versión más nueva')));
    } on RespaldoInvalido {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El archivo no es un respaldo válido')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al importar el respaldo. No se modificó nada.')));
    }
  }

  Future<void> _mostrarResumen(BuildContext context, ResultadoImportacion resultado) async {
    await showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) => AlertDialog(
      title: const Text('Importación completada'),
      content: Text('Productos agregados: ${resultado.productosAgregados}\nCombos agregados: ${resultado.combosAgregados}\nProductos existentes: ${resultado.productosExistentes}\nCombos existentes: ${resultado.combosExistentes}'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ACEPTAR'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConfiguracionProvider>();
    final config = provider.configuracion;
    return Scaffold(
      appBar: AppBar(leadingWidth: 112, leading: const BotonVolver(), title: const Text('CONFIGURACIÓN')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 24), children: [
        Text('MARGEN', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _ControlNumero(valor: FormatoNumeros.moneda(config.margen), onMenos: config.margen - 0.1 > 0 ? () => _ejecutar(context, () => provider.cambiarMargen(double.parse((config.margen - 0.1).toStringAsFixed(8)))) : null, onMas: () => _ejecutar(context, () => provider.cambiarMargen(double.parse((config.margen + 0.1).toStringAsFixed(8)))), onTap: () => _editarMargen(context, config.margen)),
        const SizedBox(height: 22),
        Text('TASA DE REFERENCIA', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _ControlNumero(valor: FormatoNumeros.moneda(config.tasaReferencia), onMenos: config.tasaReferencia - 5 > 0 ? () => _ejecutar(context, () => provider.cambiarTasa(config.tasaReferencia - 5)) : null, onMas: () => _ejecutar(context, () => provider.cambiarTasa(config.tasaReferencia + 5)), onTap: () => _editarTasa(context, config.tasaReferencia)),
        const SizedBox(height: 20),
        const Divider(),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('MODO OSCURO'), value: config.modoOscuro, onChanged: (v) => _ejecutar(context, () => provider.cambiarModoOscuro(v))),
        const Divider(),
        const SizedBox(height: 8),
        Text('RESPALDO', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => _exportar(context), child: const Text('EXPORTAR RESPALDO')),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () => _importar(context), child: const Text('IMPORTAR RESPALDO')),
      ]),
    );
  }
}

class _ControlNumero extends StatelessWidget {
  const _ControlNumero({required this.valor, required this.onMenos, required this.onMas, required this.onTap});
  final String valor;
  final VoidCallback? onMenos;
  final VoidCallback onMas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor), color: Theme.of(context).colorScheme.surface),
    child: Row(children: [
      IconButton(onPressed: onMenos, tooltip: 'Restar', icon: const Icon(Icons.remove), constraints: const BoxConstraints(minWidth: 52, minHeight: 52)),
      Expanded(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(valor, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)))),),
      IconButton(onPressed: onMas, tooltip: 'Sumar', icon: const Icon(Icons.add), constraints: const BoxConstraints(minWidth: 52, minHeight: 52)),
    ]),
  );
}
