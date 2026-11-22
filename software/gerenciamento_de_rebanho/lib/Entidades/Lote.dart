import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';

class Lote{
  String? codigo;
  String? descricao;
  List<Animal> animais = [];
  DateTime? data_insercao;


Lote({this.codigo,
      required this.descricao,
      required this.animais,
      this.data_insercao
      });
}
