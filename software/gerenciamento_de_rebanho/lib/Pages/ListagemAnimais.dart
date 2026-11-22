import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Filtros/FiltroAnimal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Lote.dart';
import 'package:gerenciamento_de_rebanho/Negocio/AnimalNG.dart';
import 'package:gerenciamento_de_rebanho/Negocio/LoteNG.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormAnimal.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormHistorico.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormLote.dart';
import 'package:gerenciamento_de_rebanho/Pages/ListagemHistorico.dart';
import 'package:gerenciamento_de_rebanho/Widgets/CardAnimal.dart';

class ListagemAnimais extends StatefulWidget {
  final Lote lote;

  const ListagemAnimais({
    super.key,
    required this.lote,
  });

  @override
  State<ListagemAnimais> createState() => _ListagemAnimaisState();
}

class _ListagemAnimaisState extends State<ListagemAnimais> {
  List<Animal> animais = [];
  bool _carregando = true;
  String _filtroPesquisa = "";
  final AnimalNG _ng = AnimalNG();
  final LoteNG _loteNG = LoteNG();

  @override
  void initState() {
    super.initState();
    carregarAnimais();
  }

  Future<void> carregarAnimais() async {
    setState(() => _carregando = true);
    final filtroAnimal = FiltroAnimal(codigo_lote: widget.lote.codigo);
    final lista = await _ng.Listar(filtroAnimal);

    if (mounted) {
      setState(() {
        animais = lista;
        _carregando = false;
      });
    }
  }

  void _abrirHistoricoLote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListagemHistorico(lote: widget.lote),
      ),
    );
  }

  void _abrirNovoManejoLote() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormHistorico(lote: widget.lote),
      ),
    );
    if (resultado == true && mounted) {
      carregarAnimais();
    }
  }

  Future<void> _editarLote() async {
    final atualizado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormLote(lote: widget.lote),
      ),
    );
    if (atualizado == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmarExclusaoLote() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Lote"),
        content: Text(
          "Deseja realmente excluir o lote '${widget.lote.descricao}'?\n"
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

    if (confirmar == true && widget.lote.codigo != null && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      try {
        await _loteNG.Excluir(widget.lote.codigo!);
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Lote excluído com sucesso."),
            backgroundColor: Colors.grey,
          ),
        );
        nav.pop(true);
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
    // Aplica o filtro de pesquisa por brinco ou identificação
    final listaFiltrada = animais.where((a) {
      final termo = _filtroPesquisa.trim().toLowerCase();
      if (termo.isEmpty) return true;
      final brincoStr = a.brinco?.toString().toLowerCase() ?? "";
      final idStr = a.identificacao?.toLowerCase() ?? "";
      return brincoStr.contains(termo) || idStr.contains(termo);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lote.descricao ?? "Animais do Lote"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Histórico do Lote",
            onPressed: _abrirHistoricoLote,
          ),
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: "Registrar no Lote",
            onPressed: _abrirNovoManejoLote,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (opcao) {
              if (opcao == 'editar') {
                _editarLote();
              } else if (opcao == 'excluir') {
                _confirmarExclusaoLote();
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
        ],
      ),
      body: Column(
        children: [
          // Banner do Lote (sem o texto excessivo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.lightGreen.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "${animais.length} ${animais.length == 1 ? "animal" : "animais"}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _abrirHistoricoLote,
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text("Histórico"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade800,
                    side: BorderSide(color: Colors.green.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _abrirNovoManejoLote,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Manejo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Caixa de Pesquisa de Animais
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Pesquisar por brinco ou identificação...",
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _filtroPesquisa.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _filtroPesquisa = "";
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                isDense: true,
              ),
              onChanged: (val) {
                setState(() {
                  _filtroPesquisa = val;
                });
              },
            ),
          ),

          const Divider(height: 1),

          // Lista de animais
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : listaFiltrada.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tag,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _filtroPesquisa.isNotEmpty
                                  ? "Nenhum animal encontrado para '$_filtroPesquisa'."
                                  : "Nenhum animal cadastrado neste lote.",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            if (_filtroPesquisa.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FormAnimal(
                                        codigo_lote: widget.lote.codigo,
                                      ),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    carregarAnimais();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Cadastrar Primeiro Animal"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: carregarAnimais,
                        child: ListView.builder(
                          itemCount: listaFiltrada.length,
                          itemBuilder: (context, index) {
                            return CardAnimal(
                              animal: listaFiltrada[index],
                              onAtualizado: carregarAnimais,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightGreen,
        foregroundColor: Colors.white,
        tooltip: "Adicionar Animal ao Lote",
        child: const Icon(Icons.add),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormAnimal(codigo_lote: widget.lote.codigo),
            ),
          );
          if (result == true && mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text("Animal cadastrado com sucesso!"),
                backgroundColor: Colors.green,
              ),
            );
            carregarAnimais();
          }
        },
      ),
    );
  }
}
