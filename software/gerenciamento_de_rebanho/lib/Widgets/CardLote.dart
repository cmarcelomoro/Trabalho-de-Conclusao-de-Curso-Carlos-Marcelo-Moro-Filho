import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Lote.dart';
import 'package:gerenciamento_de_rebanho/Negocio/AnimalNG.dart';
import 'package:gerenciamento_de_rebanho/Negocio/LoteNG.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormLote.dart';
import 'package:gerenciamento_de_rebanho/Pages/ListagemAnimais.dart';

class CardLote extends StatelessWidget {
  final Lote lote;

  const CardLote({
    super.key,
    required this.lote,
  });

  Future<void> _confirmarExclusao(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Lote"),
        content: Text(
          "Deseja realmente excluir o lote '${lote.descricao}'?\n"
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

    if (confirmar == true && lote.codigo != null) {
      try {
        await LoteNG().Excluir(lote.codigo!);
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Lote excluído com sucesso."),
            backgroundColor: Colors.grey,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Erro ao excluir lote: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.lightGreen.shade100,
          child: const Icon(Icons.grid_view, color: Colors.green),
        ),
        title: Text(
          lote.descricao ?? "",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: StreamBuilder<int>(
          stream: AnimalNG().streamQuantidadePorLote(lote.codigo ?? ""),
          builder: (context, snapshot) {
            final qtd = snapshot.data ?? 0;
            return Text(
              qtd == 1 ? "1 animal cadastrado" : "$qtd animais cadastrados",
              style: TextStyle(color: Colors.grey.shade600),
            );
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (opcao) {
                if (opcao == 'editar') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormLote(lote: lote),
                    ),
                  );
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
                      Text("Editar Lote"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'excluir',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Excluir Lote"),
                    ],
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListagemAnimais(lote: lote),
            ),
          );
        },
      ),
    );
  }
}
