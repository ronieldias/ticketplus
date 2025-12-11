import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../session_manager.dart';
import '../main.dart'; // acessa mapa principal
 
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  void _fazerLogin() async {
    setState(() => _isLoading = true);
    
    // Valida entrada consultando tabela de usuários
    final db = await DatabaseHelper().database;
    final List<Map> users = await db.query('usuarios', 
      where: 'email = ? AND senha = ?', 
      whereArgs: [_emailController.text.trim(), _senhaController.text.trim()]
    );

    setState(() => _isLoading = false);

    if (users.isNotEmpty) {
      // Login Sucesso
      SessionManager().login(users.first['id'], users.first['email']);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MapaPrincipal()));
      }
    } else {
      // Login Falha
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email ou senha inválidos")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login TicketPlus")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _senhaController,
              decoration: const InputDecoration(labelText: "Senha"),
              obscureText: true, //Senha não visível
            ),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _fazerLogin,
                  child: const Text("Entrar"),
                ),
            const SizedBox(height: 10),
            const Text("Dica: use admin / 123", style: TextStyle(color: Colors.grey))
          ],
        ),
      ),
    );
  }
}