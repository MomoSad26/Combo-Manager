class FormatoNumeros {
  /// Trunca visualmente a dos decimales (no redondea), como exige la especificación.
  static String moneda(num valor) {
    if (!valor.isFinite || valor == 0) return '0';
    final double truncado = (valor.toDouble() * 100).truncateToDouble() / 100;
    if (truncado == 0) return '0';
    var salida = truncado.toStringAsFixed(2);
    salida = salida.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return salida == '-0' ? '0' : salida;
  }

  static double? leerNumero(String texto) =>
      double.tryParse(texto.trim().replaceAll(' ', '').replaceAll(',', '.'));
}
