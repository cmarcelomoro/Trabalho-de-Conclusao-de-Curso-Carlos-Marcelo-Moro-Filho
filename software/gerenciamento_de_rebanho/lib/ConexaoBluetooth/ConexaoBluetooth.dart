import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConexaoBluetooth {
  static final ConexaoBluetooth _instance = ConexaoBluetooth._internal();

  factory ConexaoBluetooth() => _instance;

  ConexaoBluetooth._internal();

  bool get isConectado =>
      dispositivoConectado != null && dispositivoConectado!.isConnected;

  BluetoothDevice? dispositivoConectado;
  BluetoothCharacteristic? caracteristica;

  final String serviceUUID = "12345678-1234-1234-1234-1234567890ab";
  final String charUUID = "abcd1234-5678-90ab-cdef-1234567890ab";

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  final StreamController<List<ScanResult>> _scanController =
      StreamController.broadcast();

  final StreamController<String> _dadosController =
      StreamController.broadcast();

  // Armazena e notifica sobre o último brinco lido
  final ValueNotifier<String?> ultimoBrincoNotifier = ValueNotifier<String?>(null);
  String? get ultimoBrincoLido => ultimoBrincoNotifier.value;

  // Notificador de estado da conexão
  final ValueNotifier<bool> conexaoNotifier = ValueNotifier<bool>(false);

  // Buffer para montagem de pacotes fragmentados (MTU)
  String _bufferAcumulado = "";
  Timer? _bufferTimer;

  // Indica se a tela de cadastro está ativa para contextualizar avisos
  bool estaNoFormularioAnimal = false;

  /// Sanitiza a string recebida do leitor RFID
  static String sanitizarBrinco(String texto) {
    // Remove caracteres de controle e quebras de linha
    String limpo = texto.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();

    // Se vier com prefixos como "RFID: 123456" ou "ID: 123456", tenta extrair o número
    final match = RegExp(r'\d+').firstMatch(limpo);
    if (match != null && match.group(0)!.isNotEmpty) {
      return match.group(0)!;
    }

    // Caso não seja puramente numérico, retorna a primeira palavra não-vazia
    final partes = limpo.split(' ');
    for (final p in partes) {
      final item = p.trim();
      if (item.isNotEmpty) {
        return item;
      }
    }

    return limpo;
  }

  /// 🔍 Buscar dispositivos BLE
  Stream<List<ScanResult>> buscarDispositivos() async* {
    // Garante que o bluetooth está ligado
    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first;

    // Inicia scan
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanController.add(results);
    });

    yield* _scanController.stream;
  }

  /// 🔌 Conectar ao dispositivo RFID
  Future<void> conectar(BluetoothDevice device) async {
    await device.connect(license: License.free);
    dispositivoConectado = device;
    conexaoNotifier.value = true;

    // Monitora desconexão inesperada
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        dispositivoConectado = null;
        caracteristica = null;
        conexaoNotifier.value = false;
      }
    });

    List<BluetoothService> services = await device.discoverServices();
    BluetoothCharacteristic? charAlvo;

    // 1. Tenta encontrar pelo serviceUUID e charUUID pré-definidos
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
        for (var c in service.characteristics) {
          if (c.uuid.toString().toLowerCase() == charUUID.toLowerCase()) {
            charAlvo = c;
            break;
          }
        }
      }
      if (charAlvo != null) break;
    }

    // 2. Se não encontrou, busca qualquer característica com Notify ou Indicate
    // (comum em bastões RFID comerciais e módulos BLE UART)
    if (charAlvo == null) {
      for (var service in services) {
        for (var c in service.characteristics) {
          if (c.properties.notify || c.properties.indicate) {
            charAlvo = c;
            break;
          }
        }
        if (charAlvo != null) break;
      }
    }

    if (charAlvo == null) {
      throw Exception("Nenhuma característica com leitura/notificação encontrada no dispositivo");
    }

    caracteristica = charAlvo;

    // Ativa notificação no dispositivo
    await charAlvo.setNotifyValue(true);

    // Cancela listener anterior se houver
    await _notifySubscription?.cancel();

    // Escuta dados recebidos com buffer
    _notifySubscription = charAlvo.onValueReceived.listen((bytes) {
      _processarBytesRecebidos(bytes);
    });
  }

  /// Processa e acumula bytes recebidos do leitor
  void _processarBytesRecebidos(List<int> bytes) {
    if (bytes.isEmpty) return;

    try {
      final texto = utf8.decode(bytes, allowMalformed: true);
      _bufferAcumulado += texto;

      // Se contém quebra de linha (\r ou \n), o leitor encerrou o envio do brinco
      if (_bufferAcumulado.contains('\n') || _bufferAcumulado.contains('\r')) {
        _bufferTimer?.cancel();
        _emitirBuffer();
      } else {
        // Se não possui quebra de linha, aguarda até 250ms para reunir pacotes divididos pelo MTU
        _bufferTimer?.cancel();
        _bufferTimer = Timer(const Duration(milliseconds: 250), () {
          _emitirBuffer();
        });
      }
    } catch (e) {
      debugPrint("Erro ao decodificar bytes do Bluetooth: $e");
    }
  }

  /// Emite o dado final sanitizado para o aplicativo
  void _emitirBuffer() {
    final dadoCru = _bufferAcumulado;
    _bufferAcumulado = "";

    final brincoSanitizado = sanitizarBrinco(dadoCru);
    if (brincoSanitizado.isNotEmpty) {
      ultimoBrincoNotifier.value = brincoSanitizado;
      _dadosController.add(brincoSanitizado);
      HapticFeedback.vibrate();
    }
  }

  /// 📡 Stream para receber os dados do brinco sanitizado
  Stream<String> receberDados() {
    return _dadosController.stream;
  }

  /// ❌ Desconectar
  Future<void> desconectar() async {
    _bufferTimer?.cancel();
    _bufferAcumulado = "";
    await _notifySubscription?.cancel();
    await _connectionStateSubscription?.cancel();
    await dispositivoConectado?.disconnect();
    dispositivoConectado = null;
    caracteristica = null;
    conexaoNotifier.value = false;
  }

  /// 🧹 Limpar recursos
  void dispose() {
    _bufferTimer?.cancel();
    _scanSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _scanController.close();
    _dadosController.close();
    ultimoBrincoNotifier.dispose();
    conexaoNotifier.dispose();
  }
}
