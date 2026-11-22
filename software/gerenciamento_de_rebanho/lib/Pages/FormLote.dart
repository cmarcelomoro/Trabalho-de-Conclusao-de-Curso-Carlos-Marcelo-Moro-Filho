import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Lote.dart';
import 'package:gerenciamento_de_rebanho/Negocio/LoteNG.dart';

class FormLote extends StatefulWidget {
  final Lote? lote;

  const FormLote({super.key, this.lote});

  @override
  State<FormLote> createState() => _FormLoteState();
}

class _FormLoteState extends State<FormLote> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController descricaoController;
  final _ng = LoteNG();
  bool _carregando = false;

  bool get isEdicao => widget.lote != null;

  @override
  void initState() {
    super.initState();
    descricaoController = TextEditingController(
      text: widget.lote?.descricao ?? "",
    );
  }

  @override
  void dispose() {
    descricaoController.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _carregando = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (isEdicao) {
        widget.lote!.descricao = descricaoController.text.trim();
        await _ng.Alterar(widget.lote!);
      } else {
        final lote = Lote(
          descricao: descricaoController.text.trim(),
          animais: [],
        );
        await _ng.Inserir(lote);
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEdicao
                  ? "Lote atualizado com sucesso!"
                  : "Lote cadastrado com sucesso!",
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
        title: Text(isEdicao ? "Editar Lote" : "Cadastrar Lote"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: descricaoController,
                decoration: const InputDecoration(
                  labelText: "Descrição do lote *",
                  hintText: "Ex.: Piquete 1, Novilhas Nelore, Confinamento A...",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? "Informe uma descrição"
                        : null,
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
                        isEdicao ? "Salvar Alterações" : "Salvar Lote",
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
