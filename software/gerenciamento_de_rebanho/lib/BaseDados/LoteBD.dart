import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Lote.dart';

class LoteBD{

  final CollectionReference _colecao =
      FirebaseFirestore.instance.collection('lotes');

  Map<String, dynamic> _toMap(Lote lote){
    return {
      'descricao': lote.descricao,
      'data_insercao': DateTime.now().toIso8601String(),
      'usuario_uid': FirebaseAuth.instance.currentUser!.uid,
    };
  }

  Lote _fromDoc(DocumentSnapshot doc){
    final dados = doc.data() as Map<String, dynamic>;
    return Lote(
      codigo: doc.id,
      descricao: dados['descricao'],
      animais: [],
    );
  }

  Future<String> inserir(Lote lote) async{
    final doc = await _colecao.add(_toMap(lote));
    return doc.id;
  }

  Future<void> alterar(Lote lote) async {
    await _colecao.doc(lote.codigo).update({
      'descricao': lote.descricao,
    });
  }

  Future<void> excluir(String codigo) async {
    await _colecao.doc(codigo).delete();
  }

  Stream<QuerySnapshot> streamTodos(){
    return _colecao
        .where('usuario_uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots();
  }

  Future<List<Lote>> listarTodos() async{
    final snapshot = await _colecao
        .where('usuario_uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();
    return snapshot.docs.map((doc) => _fromDoc(doc)).toList();
  }

  Future<List<Lote>> listarPorIds(List<String> ids) async{
    final snapshot = await _colecao
        .where('usuario_uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return snapshot.docs.map((doc) => _fromDoc(doc)).toList();
  }

  Future<Lote?> Buscar(String id) async{
    final doc = await _colecao.doc(id).get();
    if (doc.exists) {
      return _fromDoc(doc);
    }
    return null;
  }
}
