import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormLote.dart';


class CardAdicionarLote extends StatelessWidget {
  const CardAdicionarLote({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FormLote()),
          );
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Lote cadastrado com sucesso!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        },

        child: const SizedBox(
          height: 80,
          child: Center(
            child: Icon(
              Icons.add_circle_outline,
              size: 40,
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}
