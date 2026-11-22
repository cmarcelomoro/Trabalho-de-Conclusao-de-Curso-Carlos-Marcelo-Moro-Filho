import 'package:gerenciamento_de_rebanho/BaseDados/AnimalBD.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Animal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Filtros/FiltroAnimal.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Filtros/FiltroLote.dart';
import 'package:gerenciamento_de_rebanho/Negocio/LoteNG.dart';

class AnimalNG{
  AnimalBD bd = AnimalBD();
  LoteNG _loteNG = LoteNG();

  Future<bool> Inserir(Animal animal) async {
    final retorno = await bd.inserir(animal);
    return retorno.isNotEmpty;
  }

  Future<void> Alterar(Animal animal) async {
    if (animal.codigo == null || animal.codigo!.isEmpty) {
      throw Exception('Código do animal inválido para edição.');
    }
    await bd.alterar(animal);
  }

  Future<void> Excluir(String codigo) async {
    await bd.excluir(codigo);
  }

  Future<Animal?> buscarPorBrinco(int brinco) async {
    final animal = await bd.buscarPorBrinco(brinco);
    if (animal != null) {
      await CarregarDependencias([animal]);
    }
    return animal;
  }

  Future<List<Animal>> Listar(FiltroAnimal filtro) async{
    final listaAnimais = await bd.listarTodos(filtro);
    await CarregarDependencias(listaAnimais);

    return listaAnimais;
  }

  Future<void> CarregarDependencias(List<Animal> animais) async{
    final codigos = animais
        .map((a) => a.codigo_lote)
        .where((codigo) => codigo != null)
        .toSet()
        .toList();

    if (codigos.isEmpty) return;

    final filtroLote = FiltroLote(codigos: codigos);

    final lotes = await _loteNG.Listar(filtroLote);

    final mapaLotes = {
      for(var lote in lotes) lote.codigo: lote
    };

    for(var animal in animais)
      animal.lote = mapaLotes[animal.codigo_lote];
  }

  Stream<int> streamQuantidadePorLote(String codigoLote) {
    return bd.streamQuantidadePorLote(codigoLote);
  }
}
