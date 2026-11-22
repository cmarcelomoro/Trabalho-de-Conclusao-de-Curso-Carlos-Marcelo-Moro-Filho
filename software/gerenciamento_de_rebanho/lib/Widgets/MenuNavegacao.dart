import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gerenciamento_de_rebanho/ConexaoBluetooth/ConexaoBluetooth.dart';
import 'package:gerenciamento_de_rebanho/Negocio/ConfiguracoesApp.dart';
import 'package:gerenciamento_de_rebanho/Negocio/LeituraNG.dart';
import 'package:gerenciamento_de_rebanho/Pages/PageConexao.dart';
import 'package:gerenciamento_de_rebanho/Pages/ListagemLotes.dart';
import 'package:gerenciamento_de_rebanho/Pages/PageOpcoes.dart';
import 'package:gerenciamento_de_rebanho/Widgets/PaginaHome.dart';
import 'package:gerenciamento_de_rebanho/main.dart';

class MenuNavegacao extends StatefulWidget {
  const MenuNavegacao({super.key});

  @override
  State<MenuNavegacao> createState() => _MenuNavegacaoState();
}

class _MenuNavegacaoState extends State<MenuNavegacao> {
  int paginaAtual = 0;
  StreamSubscription<String>? _dadosBluetoothSub;
  final ConexaoBluetooth _ble = ConexaoBluetooth();

  @override
  void initState() {
    super.initState();
    // Carrega preferências do usuário
    ConfiguracoesApp().carregar();

    // Escuta global de dados RFID recebidos via Bluetooth
    _dadosBluetoothSub = _ble.receberDados().listen((brinco) {
      // Registra a leitura no banco de dados para o histórico
      LeituraNG().registrarLeitura(brinco);

      final estaNoForm = _ble.estaNoFormularioAnimal;
      GerenciamentoDeRebanho.exibirNotificacaoBrinco(
        brinco,
        preenchidoNoFormulario: estaNoForm,
      );
    });
  }

  @override
  void dispose() {
    _dadosBluetoothSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> paginas = const [
      PaginaHome(),
      PageOpcoes(),
      ListagemLotes(),
      PageConexao(),
    ];

    return Scaffold(
      body: paginas[paginaAtual],
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: _ble.conexaoNotifier,
        builder: (context, isConectado, _) {
          return NavigationBar(
            onDestinationSelected: (int pagina) {
              setState(() {
                paginaAtual = pagina;
              });
            },
            indicatorColor: Colors.lightGreen,
            selectedIndex: paginaAtual,
            destinations: <Widget>[
              const NavigationDestination(
                selectedIcon: Icon(Icons.home),
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              const NavigationDestination(
                selectedIcon: Icon(Icons.tune),
                icon: Icon(Icons.tune_outlined),
                label: 'Opções',
              ),
              const NavigationDestination(
                selectedIcon: Icon(Icons.grid_view),
                icon: Icon(Icons.grid_view_outlined),
                label: 'Lotes',
              ),
              NavigationDestination(
                selectedIcon: Badge(
                  isLabelVisible: isConectado,
                  backgroundColor: Colors.green,
                  smallSize: 8,
                  child: const Icon(Icons.bluetooth_connected),
                ),
                icon: Badge(
                  isLabelVisible: isConectado,
                  backgroundColor: Colors.green,
                  smallSize: 8,
                  child: const Icon(Icons.bluetooth),
                ),
                label: 'Conexão',
              ),
            ],
          );
        },
      ),
    );
  }
}
