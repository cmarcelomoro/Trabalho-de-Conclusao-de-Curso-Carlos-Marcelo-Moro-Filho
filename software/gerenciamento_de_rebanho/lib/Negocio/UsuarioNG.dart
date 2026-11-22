import 'package:firebase_auth/firebase_auth.dart';
import 'package:gerenciamento_de_rebanho/BaseDados/UsuarioBD.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Usuario.dart';

class UsuarioNG {
  UsuarioBD bd = UsuarioBD();

  Future<Usuario> Login(String email, String senha) async {
    try {
      return await bd.login(email, senha);
    } on FirebaseAuthException catch (e) {
      throw _tratarErro(e);
    }
  }

  Future<Usuario> Cadastrar(String email, String senha) async {
    try {
      return await bd.cadastrar(email, senha);
    } on FirebaseAuthException catch (e) {
      throw _tratarErro(e);
    }
  }

  Future<void> Logout() async {
    await bd.logout();
  }

  Usuario? getUsuarioAtual() {
    return bd.getUsuarioAtual();
  }

  Stream<Usuario?> streamUsuario() {
    return bd.streamUsuario();
  }

  String _tratarErro(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Senha incorreta.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha deve ter no mínimo 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde e tente novamente.';
      case 'operation-not-allowed':
        return 'Operação não permitida. Contate o suporte.';
      default:
        return 'Erro ao autenticar. Tente novamente.';
    }
  }
}
