import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/Negocio/ConfiguracoesApp.dart';
import 'package:gerenciamento_de_rebanho/Negocio/UsuarioNG.dart';

class PageOpcoes extends StatefulWidget {
  const PageOpcoes({super.key});

  @override
  State<PageOpcoes> createState() => _PageOpcoesState();
}

class _PageOpcoesState extends State<PageOpcoes> {
  final ConfiguracoesApp _config = ConfiguracoesApp();
  final UsuarioNG _usuarioNG = UsuarioNG();

  @override
  void initState() {
    super.initState();
    _config.carregar();
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

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "Usuário";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Opções do Aplicativo"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Seção: Formato de Data
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ValueListenableBuilder<String>(
                valueListenable: _config.formatoDataNascimento,
                builder: (context, formatoAtual, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.green.shade800),
                          const SizedBox(width: 8),
                          const Text(
                            "Data de Nascimento ou Aquisição",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Escolha como a data de nascimento ou aquisição dos animais deve ser exibida e registrada:",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const Divider(height: 20),
                      RadioListTile<String>(
                        title: const Text("Dia / Mês / Ano"),
                        subtitle: const Text("Exemplo: 30/10/2026"),
                        value: 'dia_mes_ano',
                        groupValue: formatoAtual,
                        activeColor: Colors.lightGreen,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (novo) {
                          if (novo != null) {
                            _config.salvarFormatoDataNascimento(novo);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text("Apenas Mês / Ano"),
                        subtitle: const Text("Exemplo: 10/2026"),
                        value: 'mes_ano',
                        groupValue: formatoAtual,
                        activeColor: Colors.lightGreen,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (novo) {
                          if (novo != null) {
                            _config.salvarFormatoDataNascimento(novo);
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Seção: Conta do Usuário
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.green.shade800),
                      const SizedBox(width: 8),
                      const Text(
                        "Conta",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Conectado como:",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _confirmarLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Encerrar Sessão"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

