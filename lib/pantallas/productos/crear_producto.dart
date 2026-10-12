import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logica/formato_numeros.dart';
import '../../modelos/configuracion.dart';
import '../../providers/configuracion_provider.dart';
import '../../providers/producto_provider.dart';
import '../../widgets/boton_volver.dart';

class CrearProducto extends StatefulWidget {
  const CrearProducto({super.key});
  @override
  State<CrearProducto> createState() => _CrearProductoState();
}

class _CrearProductoState extends State<CrearProducto> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _compra = TextEditingController();
  final _venta = TextEditingController();
  bool _ventaManual = false;

  @override
  void dispose() { _nombre.dispose(); _compra.dispose(); _venta.dispose(); super.dispose(); }

  void _recalcularVenta(String texto, Configuracion config) {
    final compra = FormatoNumeros.leerNumero(texto);
    if (compra == null || compra < 0) {
      _venta.clear();
    } else {
      final valor = context.read<ProductoProvider>().precioVentaCalculado(compra, config);
      _venta.value = TextEditingValue(text: FormatoNumeros.moneda(valor), selection: TextSelection.collapsed(offset: FormatoNumeros.moneda(valor).length));
    }
    _ventaManual = false;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final compra = FormatoNumeros.leerNumero(_compra.text) ?? 0;
    final config = context.read<ConfiguracionProvider>().configuracion;
    // El campo visible se trunca a dos decimales; en modo automático guardamos
    // el valor completo de la fórmula y no el texto redondeado/truncado visual.
    final venta = _ventaManual
        ? (FormatoNumeros.leerNumero(_venta.text) ?? context.read<ProductoProvider>().precioVentaCalculado(compra, config))
        : context.read<ProductoProvider>().precioVentaCalculado(compra, config);
    await context.read<ProductoProvider>().crear(nombre: _nombre.text.trim(), precioCompra: compra, precioVenta: venta, precioVentaManual: _ventaManual);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfiguracionProvider>().configuracion;
    return Scaffold(
      appBar: AppBar(leadingWidth: 112, leading: const BotonVolver(), title: const Text('CREAR PRODUCTO')),
      body: SafeArea(child: Form(key: _formKey, child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
        Text('NOMBRE', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(controller: _nombre, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Escribe el nombre'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Debes escribir un nombre' : null),
        const SizedBox(height: 22),
        Text('PRECIO DE COMPRA', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(controller: _compra, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Escribe el precio'), onChanged: (v) => setState(() => _recalcularVenta(v, config)), validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Debes escribir el precio de compra';
          final n = FormatoNumeros.leerNumero(v); if (n == null || !n.isFinite || n < 0) return 'Escribe un precio válido'; return null;
        }),
        const SizedBox(height: 22),
        Text('PRECIO DE VENTA', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(controller: _venta, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(hintText: 'Se calcula automáticamente'), onChanged: (_) => _ventaManual = true, validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final n = FormatoNumeros.leerNumero(v); if (n == null || !n.isFinite || n < 0) return 'Escribe un precio válido'; return null;
        }),
      ]))),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 14), child: FilledButton(onPressed: _guardar, child: const Text('GUARDAR PRODUCTO')))),
    );
  }
}
