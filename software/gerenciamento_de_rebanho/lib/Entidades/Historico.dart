class Historico {
  String? codigo;
  String tipo; // 'Manejo' ou 'Ocorrência'
  String descricao;
  DateTime data;
  bool isAgendamento;
  bool isConcluido;
  String? codigo_lote;
  String? descricao_lote;
  String? codigo_animal;
  int? brinco_animal;
  List<String> animais_codigos;
  DateTime? data_insercao;

  Historico({
    this.codigo,
    required this.tipo,
    required this.descricao,
    required this.data,
    this.isAgendamento = false,
    this.isConcluido = false,
    this.codigo_lote,
    this.descricao_lote,
    this.codigo_animal,
    this.brinco_animal,
    this.animais_codigos = const [],
    this.data_insercao,
  });

  bool get isManejo => tipo == 'Manejo';
  bool get isOcorrencia => tipo == 'Ocorrência';
}
