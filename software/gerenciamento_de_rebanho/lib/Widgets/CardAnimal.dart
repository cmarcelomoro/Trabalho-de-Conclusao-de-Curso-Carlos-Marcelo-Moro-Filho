import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';
import 'package:gerenciamento_de_rebanho/Negocio/AnimalNG.dart';
import 'package:gerenciamento_de_rebanho/Negocio/ConfiguracoesApp.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormAnimal.dart';
import 'package:gerenciamento_de_rebanho/Pages/VisualizacaoAnimal.dart';

class CardAnimal extends StatelessWidget {
  final Animal animal;
  final VoidCallback? onAtualizado;

  const CardAnimal({
    super.key,
    required this.animal,
    this.onAtualizado,
  });

  Future<void> _confirmarExclusao(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Animal"),
        content: Text(
          "Deseja realmente excluir o animal de brinco '${animal.brinco}'?\n"
          "Esta ação não pode ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirmar == true && animal.codigo != null) {
      try {
        await AnimalNG().Excluir(animal.codigo!);
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Animal excluído com sucesso."),
            backgroundColor: Colors.grey,
          ),
        );
        onAtualizado?.call();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Erro ao excluir animal: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ConfiguracoesApp();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.lightGreen.shade100,
          child: const Icon(Icons.tag, color: Colors.green),
        ),
        title: Text(
          "Brinco: ${animal.brinco ?? "S/N"}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (animal.identificacao != null && animal.identificacao!.isNotEmpty)
              Text("Identificação: ${animal.identificacao}"),
            ValueListenableBuilder<String>(
              valueListenable: config.formatoDataNascimento,
              builder: (ctx, _, child) {
                return Text(
                  "Nasc./Aquisição: ${config.formatarDataNascimento(animal.data_nascimento)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                );
              },
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (opcao) async {
                if (opcao == 'editar') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormAnimal(
                        animal: animal,
                        codigo_lote: animal.codigo_lote,
                      ),
                    ),
                  );
                  if (result == true) {
                    onAtualizado?.call();
                  }
                } else if (opcao == 'excluir') {
                  _confirmarExclusao(context);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Editar Animal"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'excluir',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Excluir Animal"),
                    ],
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () async {
          final atualizado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VisualizacaoAnimal(animal: animal),
            ),
          );
          if (atualizado == true) {
            onAtualizado?.call();
          }
        },
      ),
    );
  }
}
