import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Filtros/FiltroAnimal.dart';

class AnimalBD{

  final CollectionReference _colecao =
      FirebaseFirestore.instance.collection('animais');

  Animal _fromDoc(DocumentSnapshot doc){
    final dados = doc.data() as Map<String, dynamic>;
    return Animal(
      codigo: doc.id,
      brinco: dados['brinco'],
      identificacao: dados['identificacao'],
      codigo_lote: dados['codigo_lote'],
      data_nascimento: dados['data_nascimento'] != null
          ? DateTime.parse(dados['data_nascimento'])
          : null,
      data_insercao: dados['data_insercao'] != null
          ? DateTime.parse(dados['data_insercao'])
          : null,
    );
  }

  Map<String, dynamic> _toMap(Animal animal){
    return {
      'brinco': animal.brinco,
      'identificacao': animal.identificacao,
      'codigo_lote': animal.codigo_lote,
      'data_nascimento': animal.data_nascimento?.toIso8601String(),
      'data_insercao': DateTime.now().toIso8601String(),
      'usuario_uid': FirebaseAuth.instance.currentUser!.uid,
    };
  }

  Future<String> inserir(Animal animal) async{
    final doc = await _colecao.add(_toMap(animal));
    return doc.id;
  }

  Future<void> alterar(Animal animal) async {
    final dadosAtualizacao = <String, dynamic>{
      'brinco': animal.brinco,
      'identificacao': animal.identificacao,
      'data_nascimento': animal.data_nascimento?.toIso8601String(),
    };
    if (animal.codigo_lote != null) {
      dadosAtualizacao['codigo_lote'] = animal.codigo_lote;
    }
    await _colecao.doc(animal.codigo).update(dadosAtualizacao);
  }

  Future<void> excluir(String codigo) async {
    await _colecao.doc(codigo).delete();
  }

  Future<Animal?> buscarPorBrinco(int brinco) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snapshot = await _colecao
        .where('usuario_uid', isEqualTo: uid)
        .where('brinco', isEqualTo: brinco)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return _fromDoc(snapshot.docs.first);
    }
    return null;
  }

  Future<List<Animal>> listarTodos(FiltroAnimal filtro) async{
    Query consulta = _colecao.where(
      'usuario_uid',
      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
    );

    if (filtro.codigo_lote != null) {
      consulta = consulta.where('codigo_lote', isEqualTo: filtro.codigo_lote);
    }

    final snapshot = await consulta.get();
    return snapshot.docs.map((doc) => _fromDoc(doc)).toList();
  }

  Stream<int> streamQuantidadePorLote(String codigoLote) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _colecao
        .where('usuario_uid', isEqualTo: uid)
        .where('codigo_lote', isEqualTo: codigoLote)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
