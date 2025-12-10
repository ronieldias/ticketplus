import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'database_helper.dart';
import 'gps_util.dart';
import 'models/estabelecimento.dart';
import 'screens/login_screen.dart';
import 'screens/form_screen.dart';
import 'session_manager.dart';
import 'widgets/filtros_modal.dart'; // Importando o widget que criamos

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TicketPlus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.deepPurple,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        )
      ),
      home: const LoginScreen(), 
    );
  }
}

class MapaPrincipal extends StatefulWidget {
  const MapaPrincipal({super.key});
  @override
  State<MapaPrincipal> createState() => _MapaPrincipalState();
}

class _MapaPrincipalState extends State<MapaPrincipal> {
  GoogleMapController? mapController;
  
  // Posição inicial (Padrão: Centro de Teresina, PI - ou genérico)
  LatLng _centroMapa = const LatLng(-5.08921, -42.8016); 
  LatLng? _minhaPosicao;

  // Dados em memória
  List<Estabelecimento> _todosEstabelecimentos = [];
  List<Map<String, dynamic>> _categoriasCache = [];
  List<Map<String, dynamic>> _bandeirasCache = [];

  // Filtros ativos
  int? _filtroCategoriaId;
  List<int> _filtroBandeirasIds = [];
  
  // Marcadores no mapa
  Set<Marker> _marcadores = {}; 

  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    // 1. Carregar dados auxiliares (Categorias e Bandeiras) para exibição
    final db = await DatabaseHelper().database;
    _categoriasCache = await db.query('categorias');
    _bandeirasCache = await db.query('bandeiras');

    // 2. Tentar pegar GPS
    try {
      final pos = await GpsUtil.obterLocalizacaoAtual();
      if (pos != null) {
        setState(() {
          _minhaPosicao = pos;
          _centroMapa = pos; // Centraliza no usuário
        });
      }
    } catch (e) {
      debugPrint("Erro ao obter GPS: $e");
    }

    // 3. Carregar estabelecimentos
    await _carregarEstabelecimentos();
  }

  Future<void> _carregarEstabelecimentos() async {
    final dados = await DatabaseHelper().buscarTodosEstabelecimentos();
    
    setState(() {
      _todosEstabelecimentos = dados.map((d) => 
        Estabelecimento.fromMap(d, d['bandeirasIds'])
      ).toList();
      
      _aplicarFiltrosEAtualizarMapa();
    });
  }

  // Lógica central de filtro e busca
  List<Estabelecimento> _filtrarLocais(String termoBusca) {
    return _todosEstabelecimentos.where((est) {
      // 1. Filtro de Texto (Nome)
      bool nomeOk = termoBusca.isEmpty || est.nome.toLowerCase().contains(termoBusca.toLowerCase());
      
      // 2. Filtro de Categoria
      bool catOk = _filtroCategoriaId == null || est.idCategoria == _filtroCategoriaId;

      // 3. Filtro de Bandeiras (Se selecionou alguma, o local TEM que ter pelo menos uma das selecionadas)
      bool bandOk = true;
      if (_filtroBandeirasIds.isNotEmpty) {
        // Verifica se há intersecção entre as bandeiras do local e as selecionadas
        bandOk = est.bandeirasIds.any((id) => _filtroBandeirasIds.contains(id));
      }

      return nomeOk && catOk && bandOk;
    }).toList();
  }

  void _aplicarFiltrosEAtualizarMapa() {
    // Filtra sem termo de busca para mostrar os pinos no mapa
    final locaisFiltrados = _filtrarLocais(""); 
    
    setState(() {
      _marcadores = locaisFiltrados.map((est) {
        return Marker(
          markerId: MarkerId(est.id.toString()),
          position: LatLng(est.latitude, est.longitude),
          // Mudamos o onTap para abrir nosso modal customizado
          onTap: () => _mostrarDetalhesLocal(est),
        );
      }).toSet();
    });
  }

  // Mostra um Modal inferior com os detalhes (Bandeiras, Categoria, Botão Editar)
  void _mostrarDetalhesLocal(Estabelecimento est) {
    // Buscar nomes para exibição
    final nomeCategoria = _categoriasCache
        .firstWhere((c) => c['id'] == est.idCategoria, orElse: () => {'nome': '?'})['nome'];
    
    final nomesBandeiras = _bandeirasCache
        .where((b) => est.bandeirasIds.contains(b['id']))
        .map((b) => b['nome'].toString())
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(est.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(nomeCategoria, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              const SizedBox(height: 15),
              const Text("Aceita:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Wrap(
                spacing: 8,
                children: nomesBandeiras.map((nome) => Chip(
                  label: Text(nome),
                  backgroundColor: Colors.green[100],
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context); // Fecha o modal
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormScreen(estabelecimento: est),
                      ),
                    );
                    _carregarEstabelecimentos(); // Recarrega ao voltar da edição
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Editar Informações"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FiltrosModal(
        todasCategorias: _categoriasCache,
        todasBandeiras: _bandeirasCache,
        categoriaSelecionada: _filtroCategoriaId,
        bandeirasSelecionadas: _filtroBandeirasIds,
        onAplicar: (cat, bands) {
          setState(() {
            _filtroCategoriaId = cat;
            _filtroBandeirasIds = bands;
          });
          _aplicarFiltrosEAtualizarMapa();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Drawer para Logout e infos extras (opcional)
      drawer: Drawer(
        child: ListView(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("TicketPlus"),
              accountEmail: Text("Versão 1.0"),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text("Sair"),
              onTap: () {
                SessionManager().logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            )
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("TicketPlus"),
      ),
      body: Stack(
        children: [
          // 1. O Mapa
          GoogleMap(
            onMapCreated: (c) => mapController = c,
            initialCameraPosition: CameraPosition(target: _centroMapa, zoom: 14.0),
            markers: _marcadores,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Vamos criar nosso próprio botão se precisar
            zoomControlsEnabled: false,
            onTap: (latLng) async {
              // Adicionar novo local ao tocar no mapa vazio
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormScreen(posicaoInicial: latLng),
                ),
              );
              _carregarEstabelecimentos();
            },
          ),

          // 2. Barra de Busca Flutuante (Autocomplete)
          Positioned(
            top: 10, left: 15, right: 15,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
                    ),
                    // O Autocomplete do Flutter
                    child: Autocomplete<Estabelecimento>(
                      optionsBuilder: (TextEditingValue textValue) {
                        // 1. Filtra baseado no texto digitado E nos filtros de categoria/bandeira
                        final opcoes = _filtrarLocais(textValue.text);
                        
                        // 2. Ordena por proximidade se tivermos GPS
                        if (_minhaPosicao != null) {
                          opcoes.sort((a, b) {
                            double distA = GpsUtil.calcularDistancia(_minhaPosicao!, LatLng(a.latitude, a.longitude));
                            double distB = GpsUtil.calcularDistancia(_minhaPosicao!, LatLng(b.latitude, b.longitude));
                            return distA.compareTo(distB);
                          });
                        }
                        return opcoes;
                      },
                      displayStringForOption: (est) => est.nome,
                      onSelected: (est) {
                        // Ao selecionar na lista, move a câmera e abre detalhes
                        mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(est.latitude, est.longitude), 16));
                        _mostrarDetalhesLocal(est);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: const InputDecoration(
                            hintText: "Buscar local...",
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Botão de Filtro
                Container(
                  decoration: BoxDecoration(
                    color: (_filtroCategoriaId != null || _filtroBandeirasIds.isNotEmpty) ? Colors.deepPurple : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
                  ),
                  child: IconButton(
                    icon: Icon(Icons.tune, color: (_filtroCategoriaId != null || _filtroBandeirasIds.isNotEmpty) ? Colors.white : Colors.black54),
                    onPressed: _abrirFiltros,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Adicionar no local atual do usuário ou no centro do mapa
          final pos = _minhaPosicao ?? _centroMapa;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormScreen(posicaoInicial: pos),
            ),
          );
          _carregarEstabelecimentos();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}