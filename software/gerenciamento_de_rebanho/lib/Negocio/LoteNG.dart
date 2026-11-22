import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gerenciamento_de_rebanho/BaseDados/LoteBD.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Filtros/FiltroLote.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Lote.dart';


class LoteNG{

  LoteBD bd = LoteBD();

  Future<String> Inserir(Lote lote) async {
    final existentes = await bd.listarTodos();
    final duplicado = existentes.any((l) =>
        l.descricao?.toLowerCase() == lote.descricao?.toLowerCase());
    if (duplicado) {
      throw Exception('Já existe um lote com essa descrição.');
    }
    return await bd.inserir(lote);
  }

  Future<void> Alterar(Lote lote) async {
    if (lote.descricao == null || lote.descricao!.trim().isEmpty) {
      throw Exception('Informe a descrição do lote.');
    }
    final existentes = await bd.listarTodos();
    final duplicado = existentes.any((l) =>
        l.codigo != lote.codigo &&
        l.descricao?.toLowerCase() == lote.descricao?.toLowerCase());
    if (duplicado) {
      throw Exception('Já existe outro lote com essa descrição.');
    }
    await bd.alterar(lote);
  }

  Future<void> Excluir(String codigo) async {
    await bd.excluir(codigo);
  }

  Stream<QuerySnapshot> streamLotes() {
    return bd.streamTodos();
  }

  Future<List<Lote>> Listar(FiltroLote filtro) async{
    if (filtro.codigos != null && filtro.codigos!.isNotEmpty) {
      return await bd.listarPorIds(filtro.codigos!.cast<String>());
    }
    return await bd.listarTodos();
  }

  Future<Lote?> Buscar(String id) async{
    return await bd.Buscar(id);
  }

}
