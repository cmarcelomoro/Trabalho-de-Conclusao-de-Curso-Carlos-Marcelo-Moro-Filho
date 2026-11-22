import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gerenciamento_de_rebanho/ConexaoBluetooth/ConexaoBluetooth.dart';

class PageConexao extends StatefulWidget {
  const PageConexao({super.key});

  @override
  State<PageConexao> createState() => _PageConexaoState();
}

class _PageConexaoState extends State<PageConexao> {
  final ConexaoBluetooth _ble = ConexaoBluetooth();

  List<ScanResult> dispositivos = [];
  bool buscando = false;

  StreamSubscription? scanSub;

  @override
  void initState() {
    super.initState();
  }

  void iniciarBusca() {
    setState(() {
      buscando = true;
      dispositivos.clear();
    });

    scanSub?.cancel();

    scanSub = _ble.buscarDispositivos().listen(
      (results) {
        if (!mounted) return;
        setState(() {
          dispositivos = results;
          buscando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${results.length} dispositivo(s) encontrado(s)"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onError: (erro) {
        if (!mounted) return;
        setState(() {
          buscando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro na busca: $erro"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
    );
  }

  void conectar(ScanResult result) async {
    try {
      await _ble.conectar(result.device);

      final String nome = result.advertisementData.advName.isNotEmpty
          ? result.advertisementData.advName
          : (result.device.platformName.isNotEmpty
              ? result.device.platformName
              : result.device.remoteId.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Conectado a $nome"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao conectar: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void desconectar() async {
    try {
      await _ble.desconectar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Dispositivo desconectado"),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao desconectar: $e"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    scanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conexão com Leitor RFID"),
      ),
      body: Column(
        children: [
          // Card de status atual e último brinco lido
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ValueListenableBuilder<bool>(
              valueListenable: _ble.conexaoNotifier,
              builder: (context, conectado, _) {
                final nomeDispositivo = _ble.dispositivoConectado != null
                    ? (_ble.dispositivoConectado!.platformName.isNotEmpty
                        ? _ble.dispositivoConectado!.platformName
                        : (_ble.dispositivoConectado!.advName.isNotEmpty
                            ? _ble.dispositivoConectado!.advName
                            : _ble.dispositivoConectado!.remoteId.toString()))
                    : "";

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: conectado ? Colors.lightGreen : Colors.grey.shade300,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              conectado ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                              color: conectado ? Colors.green : Colors.grey,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    conectado ? "Conectado" : "Desconectado",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: conectado ? Colors.green.shade800 : Colors.grey.shade700,
                                    ),
                                  ),
                                  if (conectado)
                                    Text(
                                      nomeDispositivo,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (conectado)
                              OutlinedButton(
                                onPressed: desconectar,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                child: const Text("Desconectar"),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Área com o último brinco lido em destaque
                        ValueListenableBuilder<String?>(
                          valueListenable: _ble.ultimoBrincoNotifier,
                          builder: (context, ultimoBrinco, _) {
                            return Row(
                              children: [
                                const Icon(Icons.nfc, color: Colors.lightGreen),
                                const SizedBox(width: 8),
                                const Text(
                                  "Último Brinco Lido: ",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  ultimoBrinco ?? "Nenhum ainda",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ultimoBrinco != null
                                        ? Colors.green.shade900
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Botão para escanear novos dispositivos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: buscando ? null : iniciarBusca,
                    icon: buscando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(buscando ? "Buscando..." : "Buscar Dispositivos"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Dispositivos Encontrados",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),

          const Divider(),

          Expanded(
            child: dispositivos.isEmpty
                ? Center(
                    child: Text(
                      buscando
                          ? "Procurando leitores RFID próximos..."
                          : "Nenhum dispositivo na lista.\nToque em 'Buscar Dispositivos'.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    itemCount: dispositivos.length,
                    itemBuilder: (context, index) {
                      final result = dispositivos[index];
                      final device = result.device;
                      final isCurrent = _ble.dispositivoConectado?.remoteId == device.remoteId;

                      // Prioriza o nome anunciado no pacote BLE (advName) e depois o do sistema (platformName)
                      final String nomeDispositivo = result.advertisementData.advName.isNotEmpty
                          ? result.advertisementData.advName
                          : (device.platformName.isNotEmpty
                              ? device.platformName
                              : (device.advName.isNotEmpty
                                  ? device.advName
                                  : "Dispositivo sem nome"));

                      return ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: isCurrent ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          nomeDispositivo,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          "${device.remoteId}\nSinal: ${result.rssi} dBm",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          onPressed: isCurrent ? null : () => conectar(result),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrent ? Colors.grey : Colors.lightGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isCurrent ? "Conectado" : "Conectar"),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
