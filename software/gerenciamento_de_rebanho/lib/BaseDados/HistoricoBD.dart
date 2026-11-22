import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Historico.dart';

class HistoricoBD {
  final CollectionReference _colecao =
      FirebaseFirestore.instance.collection('historicos');

  Map<String, dynamic> _toMap(Historico h) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return {
      'tipo': h.tipo,
      'descricao': h.descricao,
      'data': h.data.toIso8601String(),
      'isAgendamento': h.isAgendamento,
      'isConcluido': h.isConcluido,
      'codigo_lote': h.codigo_lote,
      'descricao_lote': h.descricao_lote,
      'codigo_animal': h.codigo_animal,
      'brinco_animal': h.brinco_animal,
      'animais_codigos': h.animais_codigos,
      'data_insercao': DateTime.now().toIso8601String(),
      'usuario_uid': uid,
    };
  }

  Historico _fromDoc(DocumentSnapshot doc) {
    final dados = doc.data() as Map<String, dynamic>;
    return Historico(
      codigo: doc.id,
      tipo: dados['tipo'] ?? 'Manejo',
      descricao: dados['descricao'] ?? '',
      data: dados['data'] != null ? DateTime.parse(dados['data']) : DateTime.now(),
      isAgendamento: dados['isAgendamento'] ?? false,
      isConcluido: dados['isConcluido'] ?? false,
      codigo_lote: dados['codigo_lote'],
      descricao_lote: dados['descricao_lote'],
      codigo_animal: dados['codigo_animal'],
      brinco_animal: dados['brinco_animal'],
      animais_codigos: List<String>.from(dados['animais_codigos'] ?? []),
      data_insercao: dados['data_insercao'] != null
          ? DateTime.parse(dados['data_insercao'])
          : null,
    );
  }

  Future<String> inserir(Historico h) async {
    final doc = await _colecao.add(_toMap(h));
    return doc.id;
  }

  Future<void> alterar(Historico h) async {
    await _colecao.doc(h.codigo).update({
      'tipo': h.tipo,
      'descricao': h.descricao,
      'data': h.data.toIso8601String(),
      'isAgendamento': h.isAgendamento,
      'isConcluido': h.isConcluido,
    });
  }

  Future<void> marcarConcluido(String codigo, bool concluido) async {
    await _colecao.doc(codigo).update({
      'isConcluido': concluido,
    });
  }

  Stream<List<Historico>> streamPorLote(String codigoLote) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _colecao
        .where('usuario_uid', isEqualTo: uid)
        .where('codigo_lote', isEqualTo: codigoLote)
        .snapshots()
        .map((snapshot) {
      final lista = snapshot.docs.map((doc) => _fromDoc(doc)).toList();
      lista.sort((a, b) => b.data.compareTo(a.data));
      return lista;
    });
  }

  Stream<List<Historico>> streamPorAnimal(String codigoAnimal) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _colecao
        .where('usuario_uid', isEqualTo: uid)
        .where('animais_codigos', arrayContains: codigoAnimal)
        .snapshots()
        .map((snapshot) {
      final lista = snapshot.docs.map((doc) => _fromDoc(doc)).toList();
      lista.sort((a, b) => b.data.compareTo(a.data));
      return lista;
    });
  }

  Future<void> excluir(String codigo) async {
    await _colecao.doc(codigo).delete();
  }
}
