import 'package:flutter/material.dart';

class BotonVolver extends StatelessWidget {
  const BotonVolver({super.key, this.texto = 'VOLVER'});
  final String texto;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back),
        label: Text(texto),
        style: TextButton.styleFrom(minimumSize: const Size(80, 48), padding: const EdgeInsets.symmetric(horizontal: 8)),
      );
}
