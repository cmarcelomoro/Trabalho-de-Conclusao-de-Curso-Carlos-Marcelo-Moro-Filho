import 'package:gerenciamento_de_rebanho/BaseDados/LeituraBD.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/LeituraRFID.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Lote.dart';
import 'package:gerenciamento_de_rebanho/Negocio/AnimalNG.dart';
import 'package:gerenciamento_de_rebanho/Negocio/LoteNG.dart';

class LeituraNG {
  static final LeituraNG _instance = LeituraNG._internal();
  factory LeituraNG() => _instance;
  LeituraNG._internal();

  final LeituraBD bd = LeituraBD();
  final AnimalNG _animalNG = AnimalNG();
  final LoteNG _loteNG = LoteNG();

  // Controle anti-duplicação rápida (debounce de 3s)
  int? _ultimoBrincoRegistrado;
  DateTime? _ultimaHoraRegistrada;

  Future<void> registrarLeitura(String brincoTexto) async {
    final brinco = int.tryParse(brincoTexto.trim());
    if (brinco == null) return;

    final agora = DateTime.now();
    if (_ultimoBrincoRegistrado == brinco && _ultimaHoraRegistrada != null) {
      if (agora.difference(_ultimaHoraRegistrada!).inSeconds < 3) {
        return; // Evita salvar duplicata imediata
      }
    }

    _ultimoBrincoRegistrado = brinco;
    _ultimaHoraRegistrada = agora;

    final leitura = LeituraRFID(
      brinco: brinco,
      dataHora: agora,
    );

    await bd.registrar(leitura);
  }

  Stream<List<LeituraRFID>> streamTodas() {
    return bd.streamTodas();
  }

  /// Cria um novo lote e cadastra os animais correspondentes aos brincos selecionados
  Future<String> criarLoteComAnimais({
    required String nomeLote,
    required List<int> brincos,
  }) async {
    if (nomeLote.trim().isEmpty) {
      throw Exception("Informe um nome para o lote.");
    }
    if (brincos.isEmpty) {
      throw Exception("Selecione ao menos um brinco.");
    }

    // 1. Cria o novo lote
    final novoLote = Lote(
      descricao: nomeLote.trim(),
      animais: [],
    );
    final idLote = await _loteNG.Inserir(novoLote);

    // 2. Para cada brinco, cadastra o animal no lote (ou atualiza o lote se já existir)
    final listaUnica = brincos.toSet().toList();
    for (final b in listaUnica) {
      final animalExistente = await _animalNG.buscarPorBrinco(b);
      if (animalExistente != null) {
        animalExistente.codigo_lote = idLote;
        await _animalNG.Alterar(animalExistente);
      } else {
        final novoAnimal = Animal(
          brinco: b,
          codigo_lote: idLote,
          data_insercao: DateTime.now(),
        );
        await _animalNG.Inserir(novoAnimal);
      }
    }

    return idLote;
  }
}

