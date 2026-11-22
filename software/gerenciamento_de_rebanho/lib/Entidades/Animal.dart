import 'package:gerenciamento_de_rebanho/Entidades/Lote.dart';

class Animal{
  String? codigo;
  int? brinco;
  String? codigo_lote;
  String? identificacao;
  DateTime? data_nascimento;
  DateTime? data_insercao;
  Lote? lote;

  Animal({this.codigo,
          this.brinco,
          this.identificacao,
          this.codigo_lote,
          this.data_insercao,
          this.data_nascimento,
          this.lote});
}
