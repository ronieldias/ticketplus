import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'database_helper.dart';
import 'gps_util.dart';
import 'models/estabelecimento.dart';
import 'screens/login_screen.dart';
import 'screens/form_screen.dart';
import 'session_manager.dart';
import 'widgets/filtros_modal.dart';

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
  
  // Posições
  LatLng _centroMapa = const LatLng(-5.08921, -42.8016); 
  LatLng? _minhaPosicao;
  
  // Variável para guardar onde a mira está apontando
  late LatLng _miraCameraPosition;

  List<Estabelecimento> _todosEstabelecimentos = [];
  List<Map<String, dynamic>> _categoriasCache = [];
  List<Map<String, dynamic>> _bandeirasCache = [];

  int? _filtroCategoriaId;
  List<int> _filtroBandeirasIds = [];
  
  Set<Marker> _marcadores = {}; 
  
  // Controle de visibilidade da UI (Imersão)
  bool _interfaceVisivel = true;

  @override
  void initState() {
    super.initState();
    _miraCameraPosition = _centroMapa; // Inicializa a mira no centro padrão
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    final db = await DatabaseHelper().database;
    _categoriasCache = await db.query('categorias');
    _bandeirasCache = await db.query('bandeiras');

    try {
      final pos = await GpsUtil.obterLocalizacaoAtual();
      if (pos != null) {
        setState(() {
          _minhaPosicao = pos;
          _centroMapa = pos;
          // Se encontrou GPS, move a mira para lá também
          _miraCameraPosition = pos; 
        });
      }
    } catch (e) {
      debugPrint("Erro GPS: $e");
    }

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

  List<Estabelecimento> _filtrarLocais(String termoBusca) {
    return _todosEstabelecimentos.where((est) {
      bool nomeOk = termoBusca.isEmpty || est.nome.toLowerCase().contains(termoBusca.toLowerCase());
      bool catOk = _filtroCategoriaId == null || est.idCategoria == _filtroCategoriaId;
      bool bandOk = true;
      if (_filtroBandeirasIds.isNotEmpty) {
        bandOk = est.bandeirasIds.any((id) => _filtroBandeirasIds.contains(id));
      }
      return nomeOk && catOk && bandOk;
    }).toList();
  }

  void _aplicarFiltrosEAtualizarMapa() {
    final locaisFiltrados = _filtrarLocais(""); 
    
    setState(() {
      _marcadores = locaisFiltrados.map((est) {
        return Marker(
          markerId: MarkerId(est.id.toString()),
          position: LatLng(est.latitude, est.longitude),
          onTap: () => _mostrarDetalhesLocal(est),
        );
      }).toSet();
    });
  }

  void _mostrarDetalhesLocal(Estabelecimento est) {
    final nomeCategoria = _categoriasCache
        .firstWhere((c) => c['id'] == est.idCategoria, orElse: () => {'nome': '?'})['nome'];
    
    final nomesBandeiras = _bandeirasCache
        .where((b) => est.bandeirasIds.contains(b['id']))
        .map((b) => b['nome'].toString())
        .toList();

    setState(() => _interfaceVisivel = true);

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
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormScreen(estabelecimento: est),
                      ),
                    );
                    _carregarEstabelecimentos();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Editar / Excluir"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _abrirFiltros() {
    setState(() => _interfaceVisivel = true);
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

  void _adicionarNovoLocal(LatLng pos) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormScreen(posicaoInicial: pos),
      ),
    );
    _carregarEstabelecimentos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("TicketPlus"),
              accountEmail: Text("Versão 1.2"),
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
      body: Stack(
        children: [
          // 1. O Mapa (Fundo)
          GoogleMap(
            onMapCreated: (c) => mapController = c,
            initialCameraPosition: CameraPosition(target: _centroMapa, zoom: 14.0),
            markers: _marcadores,
            
            // Habilita bolinha azul e botão de localização
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            
            // Remove controles padrão de zoom para limpar a tela
            zoomControlsEnabled: false,
            
            // Atualiza a posição da mira quando o usuário arrasta o mapa
            onCameraMove: (CameraPosition position) {
              _miraCameraPosition = position.target;
            },

            // Toque Simples -> Alterna UI
            onTap: (_) {
              setState(() {
                _interfaceVisivel = !_interfaceVisivel;
              });
            },
            // Toque Longo -> Adiciona Local onde tocou (alternativa à mira)
            onLongPress: (pos) => _adicionarNovoLocal(pos),
          ),

          // 2. MIRA FIXA NO CENTRO (Crosshair)
          // Usamos IgnorePointer para que o toque passe "através" do ícone e mova o mapa
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add, 
                    size: 30, 
                    color: Colors.black.withOpacity(0.7)
                  ),
                  // Pequeno ajuste para compensar o tamanho do ícone, se quiser precisão pixel-perfect
                  const SizedBox(height: 30), 
                ],
              ),
            ),
          ),

          // 3. Elementos Flutuantes (Busca, Menu) com Animação
          AnimatedOpacity(
            opacity: _interfaceVisivel ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_interfaceVisivel,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) => CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: const Icon(Icons.menu, color: Colors.black54),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
                              ),
                              child: Autocomplete<Estabelecimento>(
                                optionsBuilder: (TextEditingValue textValue) {
                                  final opcoes = _filtrarLocais(textValue.text);
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
              ),
            ),
          ),
        ],
      ),
      
      // 4. FAB (Botão de adicionar usando a MIRA)
      floatingActionButton: AnimatedOpacity(
        opacity: _interfaceVisivel ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: !_interfaceVisivel,
          child: FloatingActionButton(
            // AQUI ESTÁ A MUDANÇA: Usa a posição da mira (_miraCameraPosition)
            onPressed: () => _adicionarNovoLocal(_miraCameraPosition),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}