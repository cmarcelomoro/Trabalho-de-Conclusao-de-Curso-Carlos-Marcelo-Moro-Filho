import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Historico.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Lote.dart';
import 'package:gerenciamento_de_rebanho/Negocio/HistoricoNG.dart';

class FormHistorico extends StatefulWidget {
  final Lote? lote;
  final Animal? animal;
  final Historico? historico;

  const FormHistorico({
    super.key,
    this.lote,
    this.animal,
    this.historico,
  }) : assert(
          lote != null || animal != null || historico != null,
          "Informe um Lote, Animal ou um Histórico existente.",
        );

  @override
  State<FormHistorico> createState() => _FormHistoricoState();
}

class _FormHistoricoState extends State<FormHistorico> {
  final _formKey = GlobalKey<FormState>();
  final _ng = HistoricoNG();

  late String _tipo;
  late final TextEditingController _descricaoController;
  late final TextEditingController _dataController;
  late DateTime _data;
  late bool _isAgendamento;
  bool _carregando = false;

  bool get isEdicao => widget.historico != null && widget.historico!.codigo != null;

  @override
  void initState() {
    super.initState();
    if (isEdicao) {
      _tipo = widget.historico!.tipo;
      _descricaoController = TextEditingController(text: widget.historico!.descricao);
      _data = widget.historico!.data;
      _isAgendamento = widget.historico!.isAgendamento;
    } else {
      _tipo = 'Manejo';
      _descricaoController = TextEditingController();
      _data = DateTime.now();
      _isAgendamento = false;
    }
    _dataController = TextEditingController(text: _formatarData(_data));
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }

  Future<void> _selecionarData() async {
    final DateTime hoje = DateTime.now();
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = _tipo == 'Manejo'
        ? DateTime(hoje.year + 5)
        : DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selecionada != null) {
      setState(() {
        _data = selecionada;
        _dataController.text = _formatarData(selecionada);

        if (_tipo == 'Manejo') {
          final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
          if (selecionada.isAfter(inicioHoje)) {
            _isAgendamento = true;
          }
        }
      });
    }
  }

  void _definirHoje() {
    setState(() {
      _data = DateTime.now();
      _dataController.text = _formatarData(_data);
    });
  }

  Future<void> salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (isEdicao) {
        final h = widget.historico!;
        h.tipo = _tipo;
        h.descricao = _descricaoController.text.trim();
        h.data = _data;
        h.isAgendamento = _tipo == 'Manejo' ? _isAgendamento : false;

        await _ng.Alterar(h);
      } else {
        final historico = Historico(
          tipo: _tipo,
          descricao: _descricaoController.text.trim(),
          data: _data,
          isAgendamento: _tipo == 'Manejo' ? _isAgendamento : false,
          codigo_lote: widget.lote?.codigo ?? widget.animal?.codigo_lote,
          descricao_lote: widget.lote?.descricao,
          codigo_animal: widget.animal?.codigo,
          brinco_animal: widget.animal?.brinco,
        );

        await _ng.Inserir(historico);
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEdicao
                  ? "Registro atualizado com sucesso!"
                  : (_tipo == 'Manejo'
                      ? (_isAgendamento
                          ? "Manejo agendado com sucesso!"
                          : "Manejo registrado com sucesso!")
                      : "Ocorrência registrada com sucesso!"),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar registro: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLote = widget.lote != null || (isEdicao && widget.historico?.codigo_lote != null);
    final nomeLote = widget.lote?.descricao ?? widget.historico?.descricao_lote ?? "Lote";
    final brinco = widget.animal?.brinco ?? widget.historico?.brinco_animal;

    final tituloAlvo = isLote
        ? "Lote: $nomeLote"
        : "Animal Brinco: ${brinco ?? "-"}";

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao
            ? "Editar $_tipo"
            : (isLote ? "Registrar no Lote" : "Registrar no Animal")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card informativo de destino
              Card(
                color: Colors.lightGreen.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.lightGreen.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        isLote ? Icons.grid_view : Icons.badge_outlined,
                        color: Colors.green.shade800,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tituloAlvo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.green.shade900,
                              ),
                            ),
                            if (isLote)
                              Text(
                                "Vinculado aos animais deste lote.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade800,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Seletor de Tipo: Manejo vs Ocorrência
              const Text(
                "Tipo de Registro",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'Manejo',
                    label: Text("Manejo"),
                    icon: Icon(Icons.assignment),
                  ),
                  ButtonSegment<String>(
                    value: 'Ocorrência',
                    label: Text("Ocorrência"),
                    icon: Icon(Icons.warning_amber_rounded),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (Set<String> novo) {
                  setState(() {
                    _tipo = novo.first;
                    if (_tipo == 'Ocorrência') {
                      _isAgendamento = false;
                      if (_data.isAfter(DateTime.now())) {
                        _data = DateTime.now();
                        _dataController.text = _formatarData(_data);
                      }
                    }
                  });
                },
              ),

              const SizedBox(height: 20),

              // Campo de Descrição
              TextFormField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _tipo == 'Manejo'
                      ? "Descrição do Manejo *"
                      : "Descrição da Ocorrência *",
                  hintText: _tipo == 'Manejo'
                      ? "Ex.: Inseminação artificial, Vacinação aftosa, Pesagem..."
                      : "Ex.: Animal com manqueira, Perda de brinco, Febre...",
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return "A descrição é obrigatória.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Campo de Data
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dataController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: _isAgendamento
                            ? "Data Prevista (Agendamento) *"
                            : "Data da Realização *",
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: _selecionarData,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _definirHoje,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Hoje"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Opção de Agendamento (Somente visível para Manejo)
              if (_tipo == 'Manejo')
                SwitchListTile(
                  title: const Text("É um agendamento?"),
                  subtitle: const Text(
                    "Marque caso este manejo seja programado para ser realizado futuramente.",
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isAgendamento,
                  activeThumbColor: Colors.lightGreen,
                  onChanged: (val) {
                    setState(() {
                      _isAgendamento = val;
                    });
                  },
                ),

              const SizedBox(height: 24),

              // Botão Salvar
              ElevatedButton(
                onPressed: _carregando ? null : salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdicao ? "Salvar Alterações" : "Salvar Registro",
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
