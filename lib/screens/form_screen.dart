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
  
  // Dados auxiliares carregados do banco
  List<Map<String, dynamic>> _todasCategorias = [];
  List<Map<String, dynamic>> _todasBandeiras = [];
  
  // Estado do formulário
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
    
    // 1. Carrega listas de opções
    final cats = await db.query('categorias');
    final bands = await db.query('bandeiras');

    // 2. Se for edição, preenche os campos
    if (widget.estabelecimento != null) {
      _nomeController.text = widget.estabelecimento!.nome;
      _categoriaSelecionadaId = widget.estabelecimento!.idCategoria;
      _bandeirasSelecionadasIds.addAll(widget.estabelecimento!.bandeirasIds);
    } else if (cats.isNotEmpty) {
      // Se for novo, seleciona a primeira categoria por padrão
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

    // Prepara o mapa de dados
    final estData = {
      'id': widget.estabelecimento?.id, // Null se for novo
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Local salvo com sucesso!")));
      Navigator.pop(context); // Volta para o mapa
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.estabelecimento == null ? "Novo Local" : "Editar Local"),
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
                  // --- Nome ---
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: "Nome do Estabelecimento",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Digite um nome" : null,
                  ),
                  const SizedBox(height: 20),

                  // --- Categoria (Dropdown) ---
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

                  // --- Bandeiras (Multi-select Chips) ---
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
                      child: const Text("SALVAR LOCAL", style: TextStyle(fontSize: 18)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }
}