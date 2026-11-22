import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/ConexaoBluetooth/ConexaoBluetooth.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/LeituraRFID.dart';
import 'package:gerenciamento_de_rebanho/Negocio/AnimalNG.dart';
import 'package:gerenciamento_de_rebanho/Negocio/LeituraNG.dart';
import 'package:gerenciamento_de_rebanho/Negocio/UsuarioNG.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormAnimal.dart';
import 'package:gerenciamento_de_rebanho/Pages/FormHistorico.dart';
import 'package:gerenciamento_de_rebanho/Pages/VisualizacaoAnimal.dart';

class PaginaHome extends StatefulWidget {
  const PaginaHome({super.key});

  @override
  State<PaginaHome> createState() => _PaginaHomeState();
}

class _PaginaHomeState extends State<PaginaHome> {
  final ConexaoBluetooth _ble = ConexaoBluetooth();
  final LeituraNG _leituraNG = LeituraNG();
  final AnimalNG _animalNG = AnimalNG();
  final UsuarioNG _usuarioNG = UsuarioNG();

  // Stream única criada uma única vez no initState para evitar recriação e perda de posição de scroll
  late final Stream<List<LeituraRFID>> _streamLeituras;

  // Cache do animal associado ao último brinco lido
  Animal? _animalUltimoBrinco;
  String? _ultimoBrincoEmCache;
  VoidCallback? _ultimoBrincoListener;

  // Modo de exibição: 'hoje', 'todas' ou 'custom'
  String _modoFiltro = 'hoje';
  DateTime? _dataFiltroCustomizada;
  bool _agruparPorDia = false;

  // Conjunto de IDs de leituras selecionadas pelo usuário
  final Set<String> _leiturasSelecionadasIds = <String>{};
  final Map<String, int> _mapaLeituraBrinco = <String, int>{};

  @override
  void initState() {
    super.initState();
    // Fixa a stream para não recriar a conexão do Firestore a cada setState
    _streamLeituras = _leituraNG.streamTodas();

    // Listener para o último brinco lido com cache do animal
    _ultimoBrincoListener = () {
      final novoBrinco = _ble.ultimoBrincoNotifier.value;
      if (novoBrinco != _ultimoBrincoEmCache) {
        _ultimoBrincoEmCache = novoBrinco;
        _buscarAnimalDoUltimoBrinco(novoBrinco);
      }
    };
    _ble.ultimoBrincoNotifier.addListener(_ultimoBrincoListener!);

    final brincoInicial = _ble.ultimoBrincoNotifier.value;
    if (brincoInicial != null) {
      _ultimoBrincoEmCache = brincoInicial;
      _buscarAnimalDoUltimoBrinco(brincoInicial);
    }
  }

  @override
  void dispose() {
    if (_ultimoBrincoListener != null) {
      _ble.ultimoBrincoNotifier.removeListener(_ultimoBrincoListener!);
    }
    super.dispose();
  }

  Future<void> _buscarAnimalDoUltimoBrinco(String? brincoStr) async {
    if (brincoStr == null || brincoStr.isEmpty) {
      if (mounted) setState(() => _animalUltimoBrinco = null);
      return;
    }
    final brincoNum = int.tryParse(brincoStr);
    if (brincoNum == null) {
      if (mounted) setState(() => _animalUltimoBrinco = null);
      return;
    }

    final animal = await _animalNG.buscarPorBrinco(brincoNum);
    if (mounted) {
      setState(() {
        _animalUltimoBrinco = animal;
      });
    }
  }

  String _formatarData(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year}";
  }

  String _formatarHora(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}:"
        "${dt.second.toString().padLeft(2, '0')}";
  }

  bool _isMesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _selecionarDataCustomizada() async {
    final agora = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataFiltroCustomizada ?? agora,
      firstDate: DateTime(2020),
      lastDate: agora,
    );

    if (selecionada != null) {
      setState(() {
        _dataFiltroCustomizada = selecionada;
        _modoFiltro = 'custom';
      });
    }
  }

  Future<void> _confirmarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sair da Conta"),
        content: const Text("Deseja realmente encerrar a sessão?"),
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
            child: const Text("Sair"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _usuarioNG.Logout();
    }
  }

  Future<void> _criarLoteComSelecionados() async {
    final brincosSelecionados = _leiturasSelecionadasIds
        .map((id) => _mapaLeituraBrinco[id])
        .whereType<int>()
        .toSet()
        .toList();

    if (brincosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nenhum brinco válido selecionado."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nomeLoteController = TextEditingController(
      text: "Lote ${_formatarData(DateTime.now())}",
    );

    final criar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Criar Lote com Selecionados"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Serão incluídos ${brincosSelecionados.length} brinco(s) neste novo lote:",
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              brincosSelecionados.join(", "),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nomeLoteController,
              decoration: const InputDecoration(
                labelText: "Nome / Descrição do Lote *",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text("Criar Lote"),
          ),
        ],
      ),
    );

    if (criar == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final nome = nomeLoteController.text.trim();
      if (nome.isEmpty) return;

      try {
        await _leituraNG.criarLoteComAnimais(
          nomeLote: nome,
          brincos: brincosSelecionados,
        );

        setState(() {
          _leiturasSelecionadasIds.clear();
        });

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              "Lote '$nome' criado com ${brincosSelecionados.length} animal(is) vinculados!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Erro ao criar lote: $e"),
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
        title: const Text("Gerenciamento de Rebanho"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
            onPressed: _confirmarLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Card do Último Brinco Lido no Topo (Usa cache em estado, sem recriar futures)
          _buildCardUltimoBrincoLido(),

          // 2. Cabeçalho de Controle de Leituras
          _buildControleLeituras(),

          const Divider(height: 1),

          // 3. Listagem de Leituras com preservação estrita de Scroll
          Expanded(
            child: StreamBuilder<List<LeituraRFID>>(
              stream: _streamLeituras,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erro ao carregar leituras: ${snapshot.error}"),
                  );
                }

                final todas = snapshot.data ?? [];
                final agora = DateTime.now();

                for (final l in todas) {
                  if (l.codigo != null) {
                    _mapaLeituraBrinco[l.codigo!] = l.brinco;
                  }
                }

                final listaFiltrada = todas.where((l) {
                  if (_modoFiltro == 'hoje') {
                    return _isMesmoDia(l.dataHora, agora);
                  } else if (_modoFiltro == 'custom' && _dataFiltroCustomizada != null) {
                    return _isMesmoDia(l.dataHora, _dataFiltroCustomizada!);
                  }
                  return true;
                }).toList();

                if (listaFiltrada.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.nfc_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _modoFiltro == 'hoje'
                              ? "Nenhuma leitura RFID realizada hoje."
                              : (_modoFiltro == 'custom' && _dataFiltroCustomizada != null
                                  ? "Nenhuma leitura realizada em ${_formatarData(_dataFiltroCustomizada!)}."
                                  : "Nenhuma leitura RFID registrada."),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final todosSelecionados = listaFiltrada.isNotEmpty &&
                    listaFiltrada.every((l) =>
                        l.codigo != null && _leiturasSelecionadasIds.contains(l.codigo));

                return Column(
                  children: [
                    // Barra de seleção rápida
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.grey.shade100,
                      child: Row(
                        children: [
                          Checkbox(
                            value: todosSelecionados,
                            activeColor: Colors.lightGreen,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  for (final l in listaFiltrada) {
                                    if (l.codigo != null) {
                                      _leiturasSelecionadasIds.add(l.codigo!);
                                    }
                                  }
                                } else {
                                  _leiturasSelecionadasIds.clear();
                                }
                              });
                            },
                          ),
                          Text(
                            _leiturasSelecionadasIds.isEmpty
                                ? "Selecionar todos (${listaFiltrada.length})"
                                : "${_leiturasSelecionadasIds.length} selecionado(s)",
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const Spacer(),
                          if (_leiturasSelecionadasIds.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: _criarLoteComSelecionados,
                              icon: const Icon(Icons.add_to_photos, size: 16),
                              label: const Text("Criar Lote"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _agruparPorDia
                          ? _buildListaAgrupada(listaFiltrada)
                          : ListView.builder(
                              key: const PageStorageKey<String>('lista_leituras_scroll_padrao'),
                              itemCount: listaFiltrada.length,
                              itemBuilder: (context, index) {
                                return _buildItemLeitura(listaFiltrada[index]);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Card do Último Brinco Lido com identificação do Animal
  Widget _buildCardUltimoBrincoLido() {
    final ultimoBrinco = _ultimoBrincoEmCache;

    if (ultimoBrinco == null || ultimoBrinco.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Icon(Icons.nfc, color: Colors.grey.shade600, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Aguardando leitura RFID",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _ble.conexaoNotifier,
                        builder: (ctx, conectado, child) {
                          return Text(
                            conectado
                                ? "Leitor conectado. Aproxime o bastão do brinco."
                                : "Leitor desconectado. Conecte na aba Conexão.",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final animal = _animalUltimoBrinco;

    // Animal Encontrado no banco
    if (animal != null) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          elevation: 3,
          color: Colors.lightGreen.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.shade400, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      "Último Brinco Lido",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Cadastrado",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.tag, color: Colors.green),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Brinco Nº ${animal.brinco}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (animal.identificacao != null && animal.identificacao!.isNotEmpty)
                            Text(
                              "Identificação: ${animal.identificacao}",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          Text(
                            "Lote: ${animal.lote?.descricao ?? "Sem lote definido"}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VisualizacaoAnimal(animal: animal),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text("Ver Histórico"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade800,
                          side: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FormHistorico(animal: animal),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_task, size: 16),
                        label: const Text("+ Manejo"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Animal Não Encontrado
    final brincoNum = int.tryParse(ultimoBrinco);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 3,
        color: Colors.amber.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.amber.shade400, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.amber.shade100,
                child: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Brinco Lido: Nº $ultimoBrinco",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Animal não cadastrado no rebanho.",
                      style: TextStyle(fontSize: 12, color: Colors.brown),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormAnimal(
                        animal: Animal(brinco: brincoNum),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Cadastrar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. Controles de Filtros e Agrupamento
  Widget _buildControleLeituras() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                "Leituras RFID",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                tooltip: _agruparPorDia ? "Desagrupar" : "Agrupar por Dia",
                icon: Icon(
                  _agruparPorDia ? Icons.splitscreen : Icons.calendar_view_day,
                  color: _agruparPorDia ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _agruparPorDia = !_agruparPorDia;
                  });
                },
              ),
              IconButton(
                tooltip: "Filtrar por data",
                icon: Icon(
                  Icons.calendar_month,
                  color: _modoFiltro == 'custom' ? Colors.green : Colors.grey,
                ),
                onPressed: _selecionarDataCustomizada,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("Leituras de Hoje"),
                  selected: _modoFiltro == 'hoje',
                  selectedColor: Colors.lightGreen.shade200,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _modoFiltro = 'hoje';
                        _dataFiltroCustomizada = null;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Todas as Leituras"),
                  selected: _modoFiltro == 'todas',
                  selectedColor: Colors.lightGreen.shade200,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _modoFiltro = 'todas';
                        _dataFiltroCustomizada = null;
                      });
                    }
                  },
                ),
                if (_dataFiltroCustomizada != null) ...[
                  const SizedBox(width: 8),
                  InputChip(
                    label: Text("Dia: ${_formatarData(_dataFiltroCustomizada!)}"),
                    selected: _modoFiltro == 'custom',
                    selectedColor: Colors.lightGreen.shade200,
                    onDeleted: () {
                      setState(() {
                        _dataFiltroCustomizada = null;
                        _modoFiltro = 'hoje';
                      });
                    },
                    onSelected: (val) {
                      if (val) {
                        setState(() => _modoFiltro = 'custom');
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Lista Agrupada por Dia
  Widget _buildListaAgrupada(List<LeituraRFID> leituras) {
    final Map<String, List<LeituraRFID>> grupos = {};
    for (final l in leituras) {
      final chave = _formatarData(l.dataHora);
      grupos.putIfAbsent(chave, () => []).add(l);
    }

    final chaves = grupos.keys.toList();

    return ListView.builder(
      key: const PageStorageKey<String>('lista_leituras_scroll_agrupada'),
      itemCount: chaves.length,
      itemBuilder: (context, i) {
        final dataStr = chaves[i];
        final listaDoDia = grupos[dataStr]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.lightGreen.shade50,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    dataStr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    "${listaDoDia.length} leitura(s)",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            ...listaDoDia.map((leitura) => _buildItemLeitura(leitura)),
          ],
        );
      },
    );
  }

  /// Item individual da leitura
  Widget _buildItemLeitura(LeituraRFID leitura) {
    final isSelected = leitura.codigo != null &&
        _leiturasSelecionadasIds.contains(leitura.codigo);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          activeColor: Colors.lightGreen,
          onChanged: (val) {
            setState(() {
              if (val == true && leitura.codigo != null) {
                _leiturasSelecionadasIds.add(leitura.codigo!);
              } else if (leitura.codigo != null) {
                _leiturasSelecionadasIds.remove(leitura.codigo!);
              }
            });
          },
        ),
        title: Text(
          "Brinco Nº ${leitura.brinco}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              "${_formatarData(leitura.dataHora)} às ${_formatarHora(leitura.dataHora)}",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
          tooltip: "Remover Leitura",
          onPressed: () async {
            if (leitura.codigo != null) {
              await _leituraNG.bd.excluir(leitura.codigo!);
            }
          },
        ),
        onTap: () {
          setState(() {
            if (leitura.codigo != null) {
              if (isSelected) {
                _leiturasSelecionadasIds.remove(leitura.codigo!);
              } else {
                _leiturasSelecionadasIds.add(leitura.codigo!);
              }
            }
          });
        },
      ),
    );
  }
}
