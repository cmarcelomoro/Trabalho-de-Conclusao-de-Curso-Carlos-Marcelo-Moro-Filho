import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Historico.dart';
import 'package:gerenciamento_de_rebanho/Negocio/HistoricoNG.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormHistorico.dart';

class CardHistorico extends StatelessWidget {
  final Historico historico;
  final bool permitirExcluir;

  const CardHistorico({
    super.key,
    required this.historico,
    this.permitirExcluir = true,
  });

  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Registro"),
        content: const Text("Deseja realmente remover este registro do histórico?"),
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

    if (confirmar == true && historico.codigo != null) {
      try {
        await HistoricoNG().Excluir(historico.codigo!);
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Registro excluído com sucesso."),
            backgroundColor: Colors.grey,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Erro ao excluir: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _abrirEdicao(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormHistorico(historico: historico),
      ),
    );
  }

  Future<void> _alternarConclusao(BuildContext context) async {
    if (historico.codigo == null) return;
    final novoEstado = !historico.isConcluido;
    await HistoricoNG().MarcarConcluido(historico.codigo!, novoEstado);
  }

  @override
  Widget build(BuildContext context) {
    final bool isManejo = historico.isManejo;
    final bool isAgendado = historico.isAgendamento;
    final bool isConcluido = historico.isConcluido;

    // Se for agendado e estiver concluído, a cor deve ficar VERDE
    final Color corPrimaria = isAgendado
        ? (isConcluido ? Colors.green.shade700 : Colors.blue.shade700)
        : (isManejo ? Colors.green.shade700 : Colors.orange.shade800);

    final IconData icone = isAgendado
        ? (isConcluido ? Icons.check_circle_outline : Icons.event)
        : (isManejo ? Icons.assignment_outlined : Icons.warning_amber_rounded);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: corPrimaria.withAlpha(80)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _abrirEdicao(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com Badges / Chips
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: corPrimaria.withAlpha(30),
                    child: Icon(icone, color: corPrimaria, size: 18),
                  ),
                  const SizedBox(width: 8),

                  // Chip de Tipo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: corPrimaria.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      historico.tipo,
                      style: TextStyle(
                        color: corPrimaria,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Badge de Agendamento (Azul se pendente, Verde se concluído)
                  if (isAgendado)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isConcluido ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isConcluido ? Colors.green.shade400 : Colors.blue.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isConcluido)
                            const Icon(Icons.check, size: 12, color: Colors.green),
                          if (isConcluido) const SizedBox(width: 2),
                          Text(
                            isConcluido ? "Concluído" : "Agendado",
                            style: TextStyle(
                              color: isConcluido ? Colors.green.shade800 : Colors.blue.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Data do evento
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatarData(historico.data),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 4),

                  if (permitirExcluir)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: "Excluir",
                      onPressed: () => _confirmarExclusao(context),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Descrição
              Text(
                historico.descricao,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              // Se for agendado, botão de ação rápida "Concluir" / "Concluído"
              if (isAgendado)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _alternarConclusao(context),
                        icon: Icon(
                          isConcluido ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16,
                          color: isConcluido ? Colors.green.shade800 : Colors.white,
                        ),
                        label: Text(
                          isConcluido ? "Manejo Concluído" : "Marcar como Concluído",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isConcluido ? Colors.green.shade900 : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConcluido ? Colors.green.shade100 : Colors.blue.shade700,
                          foregroundColor: isConcluido ? Colors.green.shade900 : Colors.white,
                          elevation: isConcluido ? 0 : 2,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),

              // Origem (Lote ou Animal) + Dica de edição (sem overflow)
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (historico.codigo_lote != null) ...[
                          Icon(Icons.grid_view, size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              historico.descricao_lote != null
                                  ? "Lote: ${historico.descricao_lote}"
                                  : "Aplicado no Lote",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (historico.brinco_animal != null) ...[
                          Icon(Icons.badge_outlined, size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "Brinco: ${historico.brinco_animal}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text(
                        "Editar",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
