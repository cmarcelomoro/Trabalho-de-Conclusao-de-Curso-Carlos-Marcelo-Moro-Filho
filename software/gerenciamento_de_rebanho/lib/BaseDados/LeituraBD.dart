import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gerenciamento_de_rebanho/Entidades/LeituraRFID.dart';

class LeituraBD {
  final CollectionReference _colecao =
      FirebaseFirestore.instance.collection('leituras_rfid');

  Map<String, dynamic> _toMap(LeituraRFID l) {
    return {
      'brinco': l.brinco,
      'data_hora': l.dataHora.toIso8601String(),
      'usuario_uid': FirebaseAuth.instance.currentUser?.uid,
    };
  }

  LeituraRFID _fromDoc(DocumentSnapshot doc) {
    final dados = doc.data() as Map<String, dynamic>;
    return LeituraRFID(
      codigo: doc.id,
      brinco: dados['brinco'] is int
          ? dados['brinco']
          : int.tryParse(dados['brinco'].toString()) ?? 0,
      dataHora: dados['data_hora'] != null
          ? DateTime.parse(dados['data_hora'])
          : DateTime.now(),
    );
  }

  Future<String> registrar(LeituraRFID leitura) async {
    final doc = await _colecao.add(_toMap(leitura));
    return doc.id;
  }

  Stream<List<LeituraRFID>> streamTodas() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _colecao
        .where('usuario_uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final lista = snapshot.docs.map((d) => _fromDoc(d)).toList();
      lista.sort((a, b) => b.dataHora.compareTo(a.dataHora));
      return lista;
    });
  }

  Future<void> excluir(String codigo) async {
    await _colecao.doc(codigo).delete();
  }
}

