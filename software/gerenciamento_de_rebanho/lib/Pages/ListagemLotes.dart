import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Lote.dart';
import 'package:gerenciamento_de_rebanho/Negocio/LoteNG.dart';
import 'package:gerenciamento_de_rebanho/Widgets/CardLote.dart';
import 'package:gerenciamento_de_rebanho/Widgets/CardAdicionarLote.dart';

class ListagemLotes extends StatefulWidget {
  const ListagemLotes({super.key});

  @override
  State<ListagemLotes> createState() => _ListagemLotesState();
}

class _ListagemLotesState extends State<ListagemLotes> {
  final _ng = LoteNG();
  String _filtroPesquisa = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Listagem de Lotes"),
      ),
      body: Column(
        children: [
          // Caixa de Pesquisa de Lotes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Pesquisar lote por descrição...",
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

          // Lista de Lotes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _ng.streamLotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erro ao carregar lotes: ${snapshot.error}"),
                  );
                }

                final dados = snapshot.data?.docs ?? [];
                final lotes = dados.map((doc) {
                  final map = doc.data() as Map<String, dynamic>;
                  return Lote(
                    codigo: doc.id,
                    descricao: map['descricao'],
                    animais: [],
                  );
                }).toList();

                final lotesFiltrados = lotes.where((l) {
                  final termo = _filtroPesquisa.trim().toLowerCase();
                  if (termo.isEmpty) return true;
                  final desc = l.descricao?.toLowerCase() ?? "";
                  return desc.contains(termo);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  itemCount: lotesFiltrados.length + 1,
                  itemBuilder: (context, index) {
                    if (index == lotesFiltrados.length) {
                      return const CardAdicionarLote();
                    }
                    return CardLote(lote: lotesFiltrados[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
