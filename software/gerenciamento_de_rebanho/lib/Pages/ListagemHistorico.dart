import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Historico.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Lote.dart';
import 'package:gerenciamento_de_rebanho/Negocio/HistoricoNG.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormHistorico.dart';
import 'package:gerenciamento_de_rebanho/Widgets/CardHistorico.dart';

class ListagemHistorico extends StatefulWidget {
  final Lote? lote;
  final Animal? animal;

  const ListagemHistorico({
    super.key,
    this.lote,
    this.animal,
  }) : assert(lote != null || animal != null, "Informe um Lote ou um Animal.");

  @override
  State<ListagemHistorico> createState() => _ListagemHistoricoState();
}

class _ListagemHistoricoState extends State<ListagemHistorico> {
  final _ng = HistoricoNG();
  String _filtroSelecionado = 'Todos'; // 'Todos', 'Manejos', 'Ocorrências', 'Agendamentos'

  Stream<List<Historico>> _obterStream() {
    if (widget.lote != null && widget.lote!.codigo != null) {
      return _ng.streamPorLote(widget.lote!.codigo!);
    } else if (widget.animal != null && widget.animal!.codigo != null) {
      return _ng.streamPorAnimal(widget.animal!.codigo!);
    }
    return Stream.value([]);
  }

  List<Historico> _filtrarLista(List<Historico> lista) {
    if (_filtroSelecionado == 'Manejos') {
      return lista.where((h) => h.isManejo && !h.isAgendamento).toList();
    } else if (_filtroSelecionado == 'Ocorrências') {
      return lista.where((h) => h.isOcorrencia).toList();
    } else if (_filtroSelecionado == 'Agendamentos') {
      return lista.where((h) => h.isAgendamento).toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLote = widget.lote != null;
    final String titulo = isLote
        ? "Histórico: ${widget.lote!.descricao ?? "Lote"}"
        : "Histórico: Brinco ${widget.animal?.brinco ?? "-"}";

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: Column(
        children: [
          // Barra de Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildFiltroChip('Todos'),
                const SizedBox(width: 8),
                _buildFiltroChip('Manejos'),
                const SizedBox(width: 8),
                _buildFiltroChip('Ocorrências'),
                const SizedBox(width: 8),
                _buildFiltroChip('Agendamentos'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista Reativa de Registros do Firestore
          Expanded(
            child: StreamBuilder<List<Historico>>(
              stream: _obterStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erro ao carregar histórico: ${snapshot.error}"),
                  );
                }

                final todosRegistros = snapshot.data ?? [];
                final listaFiltrada = _filtrarLista(todosRegistros);

                if (listaFiltrada.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          todosRegistros.isEmpty
                              ? "Nenhum manejo ou ocorrência registrado."
                              : "Nenhum registro para o filtro '$_filtroSelecionado'.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FormHistorico(
                                  lote: widget.lote,
                                  animal: widget.animal,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Registrar Agora"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: listaFiltrada.length,
                  itemBuilder: (context, index) {
                    final h = listaFiltrada[index];
                    return CardHistorico(historico: h);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormHistorico(
                lote: widget.lote,
                animal: widget.animal,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Novo Registro"),
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFiltroChip(String label) {
    final bool selecionado = _filtroSelecionado == label;
    return ChoiceChip(
      label: Text(label),
      selected: selecionado,
      selectedColor: Colors.lightGreen.shade200,
      onSelected: (bool sel) {
        if (sel) {
          setState(() {
            _filtroSelecionado = label;
          });
        }
      },
    );
  }
}

