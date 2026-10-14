class FormatoNumeros {
  /// Trunca visualmente a dos decimales (no redondea), como exige la especificación.
  static String moneda(num valor) {
    if (!valor.isFinite || valor == 0) return '0';
    // Antes de truncar se descarta el ruido de coma flotante: 0.29 * 100 da
    // 28.999999999999996 y sin esto se mostraría 0.28 en lugar de 0.29.
    final centavos = double.parse((valor.toDouble() * 100).toStringAsFixed(6));
    final double truncado = centavos.truncateToDouble() / 100;
    if (truncado == 0) return '0';
    var salida = truncado.toStringAsFixed(2);
    salida = salida.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return salida == '-0' ? '0' : salida;
  }

  static double? leerNumero(String texto) =>
      double.tryParse(texto.trim().replaceAll(' ', '').replaceAll(',', '.'));
}
