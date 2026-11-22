import 'package:firebase_auth/firebase_auth.dart';
import 'package:gerenciamento_de_rebanho/Entidades/Usuario.dart';

class UsuarioBD {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Usuario> login(String email, String senha) async {
    final credencial = await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );
    return _fromFirebaseUser(credencial.user!);
  }

  Future<Usuario> cadastrar(String email, String senha) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
    return _fromFirebaseUser(credencial.user!);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Usuario? getUsuarioAtual() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fromFirebaseUser(user);
  }

  Stream<Usuario?> streamUsuario() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return _fromFirebaseUser(user);
    });
  }

  Usuario _fromFirebaseUser(User user) {
    return Usuario(
      id: user.uid,
      email: user.email,
      nome: user.displayName,
    );
  }
}
