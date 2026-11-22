import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ConfiguracoesApp {
  static final ConfiguracoesApp _instance = ConfiguracoesApp._internal();
  factory ConfiguracoesApp() => _instance;
  ConfiguracoesApp._internal();

  // Opções: 'dia_mes_ano' (dd/MM/yyyy) ou 'mes_ano' (MM/yyyy)
  final ValueNotifier<String> formatoDataNascimento =
      ValueNotifier<String>('dia_mes_ano');

  bool _carregado = false;

  Future<void> carregar() async {
    if (_carregado) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('config')
          .doc('preferencias')
          .get();

      if (doc.exists && doc.data() != null) {
        final dados = doc.data()!;
        if (dados['formato_data_nascimento'] != null) {
          formatoDataNascimento.value = dados['formato_data_nascimento'];
        }
      }
      _carregado = true;
    } catch (e) {
      debugPrint("Erro ao carregar preferências: $e");
    }
  }

  Future<void> salvarFormatoDataNascimento(String formato) async {
    formatoDataNascimento.value = formato;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('config')
          .doc('preferencias')
          .set({
        'formato_data_nascimento': formato,
        'atualizado_em': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Erro ao salvar preferências no Firestore: $e");
    }
  }

  String formatarDataNascimento(DateTime? data) {
    if (data == null) return "Não informada";
    if (formatoDataNascimento.value == 'mes_ano') {
      return "${data.month.toString().padLeft(2, '0')}/${data.year}";
    }
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }
}

