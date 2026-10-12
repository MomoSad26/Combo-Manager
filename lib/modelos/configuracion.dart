class Configuracion {
  const Configuracion({required this.margen, required this.tasaReferencia, required this.modoOscuro});

  final double margen;
  final double tasaReferencia;
  final bool modoOscuro;

  factory Configuracion.fromMap(Map<String, Object?> map) => Configuracion(
        margen: (map['margen'] as num).toDouble(),
        tasaReferencia: (map['tasa_referencia'] as num).toDouble(),
        modoOscuro: (map['modo_oscuro'] as num? ?? 0) == 1,
      );
}
