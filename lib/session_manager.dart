// Responsável pelo gerenciamento (em memória) de sessões ativas
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // atributos responsáveis pelo gerenciamento de sessões do usuário.
  int? usuarioLogadoId;
  String? usuarioEmail;

  void login(int id, String email) {
    usuarioLogadoId = id;
    usuarioEmail = email;
  }

  void logout() {
    usuarioLogadoId = null;
    usuarioEmail = null;
  }
  
  bool get isLoggedIn => usuarioLogadoId != null;
}