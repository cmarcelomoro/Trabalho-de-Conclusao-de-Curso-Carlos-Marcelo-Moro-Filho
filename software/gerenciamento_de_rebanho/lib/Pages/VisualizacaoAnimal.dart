import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Historico.dart';
import 'package:gerenciamento_de_rebanho/Negocio/AnimalNG.dart';
import 'package:gerenciamento_de_rebanho/Negocio/ConfiguracoesApp.dart';
import 'package:gerenciamento_de_rebanho/Negocio/HistoricoNG.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormAnimal.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormHistorico.dart';
import 'package:gerenciamento_de_rebanho/Widgets/CardHistorico.dart';

class VisualizacaoAnimal extends StatefulWidget {
  final Animal animal;

  const VisualizacaoAnimal({
    super.key,
    required this.animal,
  });

  @override
  State<VisualizacaoAnimal> createState() => _VisualizacaoAnimalState();
}

class _VisualizacaoAnimalState extends State<VisualizacaoAnimal> {
  late Animal _animal;
  final _historicoNG = HistoricoNG();
  final _animalNG = AnimalNG();

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  String _formatarData(DateTime? data) {
    if (data == null) return "Não informada";
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }

  String _calcularIdade(DateTime? nascimento) {
    if (nascimento == null) return "";
    final hoje = DateTime.now();
    int meses = (hoje.year - nascimento.year) * 12 + hoje.month - nascimento.month;
    if (hoje.day < nascimento.day) meses--;

    if (meses <= 0) return "Recém-nascido";
    if (meses < 12) return "$meses mês(es)";
    final anos = meses ~/ 12;
    final restoMeses = meses % 12;
    if (restoMeses == 0) return "$anos ano(s)";
    return "$anos ano(s) e $restoMeses m";
  }

  Future<void> _editarAnimal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormAnimal(
          animal: _animal,
          codigo_lote: _animal.codigo_lote,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmarExclusao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Animal"),
        content: Text(
          "Deseja realmente excluir o animal de brinco '${_animal.brinco}'?\n"
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

    if (confirmar == true && _animal.codigo != null && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      try {
        await _animalNG.Excluir(_animal.codigo!);
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Animal excluído com sucesso."),
            backgroundColor: Colors.grey,
          ),
        );
        nav.pop(true);
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Animal Nº ${_animal.brinco ?? "-"}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Editar Animal",
            onPressed: _editarAnimal,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Excluir Animal",
            onPressed: _confirmarExclusao,
          ),
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: "Novo Manejo / Ocorrência",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormHistorico(animal: _animal),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Card de Identificação do Animal
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.lightGreen.shade100,
                          child: const Icon(Icons.tag, color: Colors.green, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Brinco Nº ${_animal.brinco ?? "S/N"}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_animal.identificacao != null && _animal.identificacao!.isNotEmpty)
                                Text(
                                  _animal.identificacao!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(
                          "Lote",
                          _animal.lote?.descricao ?? "Sem lote",
                          Icons.grid_view,
                        ),
                        _buildInfoItem(
                          "Nasc./Aquisição",
                          ConfiguracoesApp().formatarDataNascimento(_animal.data_nascimento),
                          Icons.calendar_month,
                          subinfo: _calcularIdade(_animal.data_nascimento),
                        ),
                        _buildInfoItem(
                          "Cadastro",
                          _formatarData(_animal.data_insercao),
                          Icons.event_note,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Título da Seção do Histórico
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Histórico de Manejo e Ocorrências",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormHistorico(animal: _animal),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Registrar"),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de Histórico do Animal
          Expanded(
            child: StreamBuilder<List<Historico>>(
              stream: _animal.codigo != null
                  ? _historicoNG.streamPorAnimal(_animal.codigo!)
                  : Stream.value([]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erro ao carregar histórico: ${snapshot.error}"),
                  );
                }

                final registros = snapshot.data ?? [];

                if (registros.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 44,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Nenhum manejo ou ocorrência registrado para este animal.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    return CardHistorico(historico: registros[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String titulo, String valor, IconData icone, {String subinfo = ""}) {
    return Column(
      children: [
        Icon(icone, size: 18, color: Colors.lightGreen.shade800),
        const SizedBox(height: 4),
        Text(
          titulo,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        Text(
          valor,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        if (subinfo.isNotEmpty)
          Text(
            subinfo,
            style: TextStyle(fontSize: 11, color: Colors.green.shade700),
          ),
      ],
    );
  }
}
