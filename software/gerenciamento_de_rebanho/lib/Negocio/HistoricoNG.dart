import 'package:gerenciamento_de_rebanho/BaseDados/HistoricoBD.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Filtros/FiltroAnimal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Historico.dart';
import 'package:gerenciamento_de_rebanho/Negocio/AnimalNG.dart';

class HistoricoNG {
  final HistoricoBD bd = HistoricoBD();
  final AnimalNG _animalNG = AnimalNG();

  Future<String> Inserir(Historico historico) async {
    if (historico.descricao.trim().isEmpty) {
      throw Exception('Informe a descrição do histórico.');
    }

    // Regra: Ocorrências não podem ser agendamentos
    if (historico.tipo == 'Ocorrência') {
      historico.isAgendamento = false;
    }

    // Se for cadastrado para o lote, vincula a todos os animais que pertencem a esse lote
    if (historico.codigo_lote != null && historico.codigo_lote!.isNotEmpty) {
      final animaisDoLote = await _animalNG.Listar(
        FiltroAnimal(codigo_lote: historico.codigo_lote),
      );

      final codigosAnimais = animaisDoLote
          .map((a) => a.codigo)
          .where((codigo) => codigo != null && codigo.isNotEmpty)
          .cast<String>()
          .toList();

      historico.animais_codigos = codigosAnimais;
    } else if (historico.codigo_animal != null && historico.codigo_animal!.isNotEmpty) {
      // Se for cadastrado individualmente para um animal
      historico.animais_codigos = [historico.codigo_animal!];
    }

    return await bd.inserir(historico);
  }

  Future<void> Alterar(Historico historico) async {
    if (historico.codigo == null || historico.codigo!.isEmpty) {
      throw Exception('Código do registro inválido.');
    }
    if (historico.descricao.trim().isEmpty) {
      throw Exception('Informe a descrição do histórico.');
    }
    if (historico.tipo == 'Ocorrência') {
      historico.isAgendamento = false;
      historico.isConcluido = false;
    }
    await bd.alterar(historico);
  }

  Future<void> MarcarConcluido(String codigo, bool concluido) async {
    await bd.marcarConcluido(codigo, concluido);
  }

  Stream<List<Historico>> streamPorLote(String codigoLote) {
    return bd.streamPorLote(codigoLote);
  }

  Stream<List<Historico>> streamPorAnimal(String codigoAnimal) {
    return bd.streamPorAnimal(codigoAnimal);
  }

  Future<void> Excluir(String codigo) async {
    await bd.excluir(codigo);
  }
}

