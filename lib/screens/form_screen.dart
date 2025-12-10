import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../database_helper.dart';
import '../models/estabelecimento.dart';
import '../session_manager.dart';

class FormScreen extends StatefulWidget {
  final Estabelecimento? estabelecimento;
  final LatLng? posicaoInicial;

  const FormScreen({super.key, this.estabelecimento, this.posicaoInicial});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  
  List<Map<String, dynamic>> _todasCategorias = [];
  List<Map<String, dynamic>> _todasBandeiras = [];
  
  int? _categoriaSelecionadaId;
  final List<int> _bandeirasSelecionadasIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    final db = await DatabaseHelper().database;
    final cats = await db.query('categorias');
    final bands = await db.query('bandeiras');

    if (widget.estabelecimento != null) {
      _nomeController.text = widget.estabelecimento!.nome;
      _categoriaSelecionadaId = widget.estabelecimento!.idCategoria;
      _bandeirasSelecionadasIds.addAll(widget.estabelecimento!.bandeirasIds);
    } else if (cats.isNotEmpty) {
      _categoriaSelecionadaId = cats.first['id'] as int;
    }

    setState(() {
      _todasCategorias = cats;
      _todasBandeiras = bands;
      _isLoading = false;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSelecionadaId == null) return;

    final lat = widget.estabelecimento?.latitude ?? widget.posicaoInicial!.latitude;
    final lng = widget.estabelecimento?.longitude ?? widget.posicaoInicial!.longitude;

    final estData = {
      'id': widget.estabelecimento?.id,
      'nome': _nomeController.text,
      'latitude': lat,
      'longitude': lng,
      'id_categoria': _categoriaSelecionadaId,
      'criado_por': SessionManager().usuarioLogadoId,
    };

    if (widget.estabelecimento == null) {
      await DatabaseHelper().inserirEstabelecimento(estData, _bandeirasSelecionadasIds);
    } else {
      await DatabaseHelper().atualizarEstabelecimento(estData, _bandeirasSelecionadasIds);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Local salvo!")));
      Navigator.pop(context);
    }
  }

  // --- FUNÇÃO DE DELETAR ---
  Future<void> _deletar() async {
    if (widget.estabelecimento == null) return;

    // Confirmação
    final confirmar = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Local?"),
        content: const Text("Essa ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirmar == true) {
      await DatabaseHelper().deletarEstabelecimento(widget.estabelecimento!.id!);
      if (mounted) {
        Navigator.pop(context); // Volta para o mapa
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.estabelecimento == null ? "Novo Local" : "Editar Local"),
        actions: [
           // Opção extra de deletar na barra superior também, se desejar
           if (widget.estabelecimento != null)
             IconButton(icon: const Icon(Icons.delete), onPressed: _deletar),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: "Nome", border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? "Digite um nome" : null,
                  ),
                  const SizedBox(height: 20),

                  const Text("Categoria:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _categoriaSelecionadaId,
                    items: _todasCategorias.map((cat) {
                      return DropdownMenuItem<int>(
                        value: cat['id'] as int,
                        child: Text(cat['nome'] as String),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _categoriaSelecionadaId = val),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),

                  const Text("Bandeiras Aceitas:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _todasBandeiras.map((band) {
                      final id = band['id'] as int;
                      final nome = band['nome'] as String;
                      final estaSelecionado = _bandeirasSelecionadasIds.contains(id);

                      return FilterChip(
                        label: Text(nome),
                        selected: estaSelecionado,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _bandeirasSelecionadasIds.add(id);
                            } else {
                              _bandeirasSelecionadasIds.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white
                      ),
                      child: const Text("SALVAR LOCAL", style: TextStyle(fontSize: 18)),
                    ),
                  ),

                  // Botão Excluir grande no final
                  if (widget.estabelecimento != null) ...[
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _deletar,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text("Excluir Local", style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
    );
  }
}