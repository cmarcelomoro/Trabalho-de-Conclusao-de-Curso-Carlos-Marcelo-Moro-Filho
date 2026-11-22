import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/ConexaoBluetooth/ConexaoBluetooth.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';
import 'package:gerenciamento_de_rebanho/Negocio/AnimalNG.dart';
import 'package:gerenciamento_de_rebanho/Negocio/ConfiguracoesApp.dart';

class FormAnimal extends StatefulWidget {
  final Animal? animal;
  final String? codigo_lote;

  const FormAnimal({super.key, this.animal, this.codigo_lote});

  @override
  State<FormAnimal> createState() => _FormAnimalState();
}

class _FormAnimalState extends State<FormAnimal> {
  final _formKey = GlobalKey<FormState>();
  final _ng = AnimalNG();
  final _ble = ConexaoBluetooth();
  final _config = ConfiguracoesApp();

  bool _carregando = false;
  StreamSubscription<String>? _bluetoothSub;

  late TextEditingController _brincoController;
  late TextEditingController _identificacaoController;
  final _dataController = TextEditingController();
  DateTime? _dataNascimento;

  bool get isEdicao => widget.animal != null && widget.animal!.codigo != null;

  @override
  void initState() {
    super.initState();

    _ble.estaNoFormularioAnimal = true;

    final brincoInicial = widget.animal?.brinco?.toString() ?? "";
    _brincoController = TextEditingController(text: brincoInicial);

    _identificacaoController = TextEditingController(
      text: widget.animal?.identificacao ?? "",
    );

    if (widget.animal?.data_nascimento != null) {
      _dataNascimento = widget.animal!.data_nascimento;
      _dataController.text = _config.formatarDataNascimento(_dataNascimento);
    }

    // Escuta novas leituras de brinco apenas para atualizar o banner informativo, SEM preencher automaticamente
    _bluetoothSub = _ble.receberDados().listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ble.estaNoFormularioAnimal = false;
    _bluetoothSub?.cancel();
    _brincoController.dispose();
    _identificacaoController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (data != null) {
      setState(() {
        _dataNascimento = data;
        _dataController.text = _config.formatarDataNascimento(data);
      });
    }
  }

  void _definirHoje() {
    setState(() {
      _dataNascimento = DateTime.now();
      _dataController.text = _config.formatarDataNascimento(DateTime.now());
    });
  }

  Future<void> salvar() async {
    final brinco = int.tryParse(_brincoController.text.trim());

    if (brinco == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informe um brinco numérico válido."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _carregando = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final animal = Animal(
        codigo: widget.animal?.codigo,
        codigo_lote: widget.codigo_lote ?? widget.animal?.codigo_lote,
        brinco: brinco,
        identificacao: _identificacaoController.text.trim(),
        data_nascimento: _dataNascimento,
      );

      if (isEdicao) {
        await _ng.Alterar(animal);
      } else {
        await _ng.Inserir(animal);
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEdicao
                  ? "Animal atualizado com sucesso!"
                  : "Animal cadastrado com sucesso!",
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
            content: Text(e.toString()),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? "Editar Animal" : "Cadastro de Animal"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner informativo sobre conexão Bluetooth (apenas exibe o último lido para consulta)
              ValueListenableBuilder<bool>(
                valueListenable: _ble.conexaoNotifier,
                builder: (context, conectado, _) {
                  if (!conectado) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.lightGreen.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.nfc, color: Colors.green, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ValueListenableBuilder<String?>(
                            valueListenable: _ble.ultimoBrincoNotifier,
                            builder: (context, ultimoBrinco, _) {
                              return Text(
                                ultimoBrinco != null
                                    ? "Leitor conectado. Último lido: $ultimoBrinco"
                                    : "Leitor RFID conectado e pronto.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                        ValueListenableBuilder<String?>(
                          valueListenable: _ble.ultimoBrincoNotifier,
                          builder: (context, ultimoBrinco, _) {
                            if (ultimoBrinco == null || ultimoBrinco.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return TextButton(
                              onPressed: () {
                                setState(() {
                                  _brincoController.text = ultimoBrinco;
                                });
                              },
                              child: const Text("Inserir"),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              TextFormField(
                controller: _brincoController,
                decoration: InputDecoration(
                  labelText: "Brinco *",
                  hintText: "Digite o número do brinco",
                  suffixIcon: ValueListenableBuilder<bool>(
                    valueListenable: _ble.conexaoNotifier,
                    builder: (context, conectado, _) {
                      return Icon(
                        conectado ? Icons.bluetooth_connected : Icons.tag,
                        color: conectado ? Colors.lightGreen : Colors.grey,
                      );
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _identificacaoController,
                decoration: const InputDecoration(
                  labelText: "Identificação (Nome / Apelido)",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dataController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Data de Nascimento ou Aquisição",
                        suffixIcon: Icon(Icons.calendar_month),
                      ),
                      onTap: _selecionarData,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
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
              const SizedBox(height: 24),
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
                        isEdicao ? "Salvar Alterações" : "Confirmar Cadastro",
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
