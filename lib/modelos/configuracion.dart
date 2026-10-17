class Configuracion {
  const Configuracion({required this.margen, required this.tasaReferencia, required this.modoOscuro, this.detalleComboCompacto = true});

  final double margen;
  final double tasaReferencia;
  final bool modoOscuro;
  final bool detalleComboCompacto;

  factory Configuracion.fromMap(Map<String, Object?> map) => Configuracion(
        margen: (map['margen'] as num).toDouble(),
        tasaReferencia: (map['tasa_referencia'] as num).toDouble(),
        modoOscuro: (map['modo_oscuro'] as num? ?? 0) == 1,
        detalleComboCompacto: (map['detalle_combo_compacto'] as num? ?? 1) == 1,
      );
}
