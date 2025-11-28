import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Para calculo de distancia
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'models/estabelecimento.dart';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const LoginScreen(), // Começa no Login
    );
  }
}

// --- TELA DE LOGIN SIMPLES ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text("Entrar (Login Simulado)"),
          onPressed: () {
            // Em um app real, verificariamos a tabela 'usuarios' aqui
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MapaPrincipal()));
          },
        ),
      ),
    );
  }
}

// --- TELA DO MAPA (PRINCIPAL) ---
class MapaPrincipal extends StatefulWidget {
  const MapaPrincipal({super.key});
  @override
  State<MapaPrincipal> createState() => _MapaPrincipalState();
}

class _MapaPrincipalState extends State<MapaPrincipal> {
  GoogleMapController? mapController;
  final LatLng _posicaoInicial = const LatLng(-5.088544, -42.811238); // Exemplo do PDF (IFPI) [cite: 30]
  Set<Marker> _marcadores = {}; // Conjunto de marcadores [cite: 21]
  List<Estabelecimento> _todosEstabelecimentos = [];

  // Filtros
  double _raioKm = 10.0;
  String _busca = "";

  @override
  void initState() {
    super.initState();
    _carregarDados(); // Carrega marcadores ao iniciar [cite: 12]
  }

  // Função para buscar dados do SQLite e criar marcadores
  Future<void> _carregarDados() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('estabelecimentos');

    setState(() {
      _todosEstabelecimentos = List.generate(maps.length, (i) => Estabelecimento.fromMap(maps[i]));
      _atualizarMarcadores();
    });
  }

  void _atualizarMarcadores() {
    Set<Marker> novosMarcadores = {};
    for (var est in _todosEstabelecimentos) {
      // Filtro simples de distância (usando Geolocator ou calculo manual)
      // Aqui aplicamos apenas se a busca por nome bater
      if (_busca.isEmpty || est.nome.toLowerCase().contains(_busca.toLowerCase())) {
        novosMarcadores.add(
          Marker(
            markerId: MarkerId(est.id.toString()),
            position: LatLng(est.latitude, est.longitude),
            // A ação de clique vai DENTRO do InfoWindow
            infoWindow: InfoWindow(
              title: est.nome,
              snippet: "Clique para editar",
              onTap: () => _abrirFormulario(estabelecimento: est), // <--- Corrigido
            ),
          ),
        );
      }
    }
    setState(() {
      _marcadores = novosMarcadores;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller; // [cite: 57, 267]
  }

  // Interação com o mapa para criar novo [Requisito: Cadastro interagindo com mapa]
  void _onMapTap(LatLng position) {
    _abrirFormulario(latLong: position);
  }

  void _abrirFormulario({Estabelecimento? estabelecimento, LatLng? latLong}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioEstabelecimento(
          estabelecimento: estabelecimento,
          posicaoInicial: latLong,
        ),
      ),
    );
    _carregarDados(); // Recarrega ao voltar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TicketPlus"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Buscar estabelecimento...",
                fillColor: Colors.white, filled: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                _busca = val;
                _atualizarMarcadores();
              },
            ),
          ),
        ),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated, // [cite: 54]
        initialCameraPosition: CameraPosition(target: _posicaoInicial, zoom: 14.0), // [cite: 56]
        markers: _marcadores, // [cite: 60]
        onTap: _onMapTap, // Clique longo ou tap para adicionar
        myLocationEnabled: true, // [cite: 55]
      ),
    );
  }
}

// --- TELA DE CADASTRO/EDIÇÃO ---
class FormularioEstabelecimento extends StatefulWidget {
  final Estabelecimento? estabelecimento;
  final LatLng? posicaoInicial;

  const FormularioEstabelecimento({super.key, this.estabelecimento, this.posicaoInicial});

  @override
  State<FormularioEstabelecimento> createState() => _FormularioEstabelecimentoState();
}

class _FormularioEstabelecimentoState extends State<FormularioEstabelecimento> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  int _bandeiraId = 1; // Default
  int _categoriaId = 1; // Default

  @override
  void initState() {
    super.initState();
    if (widget.estabelecimento != null) {
      _nomeController.text = widget.estabelecimento!.nome;
      _bandeiraId = widget.estabelecimento!.idBandeira;
      _categoriaId = widget.estabelecimento!.idCategoria;
    }
  }

  Future<void> _salvar() async {
    final db = await DatabaseHelper().database;
    final lat = widget.estabelecimento?.latitude ?? widget.posicaoInicial!.latitude;
    final lng = widget.estabelecimento?.longitude ?? widget.posicaoInicial!.longitude;

    final novoEst = Estabelecimento(
      id: widget.estabelecimento?.id,
      nome: _nomeController.text,
      latitude: lat,
      longitude: lng,
      idBandeira: _bandeiraId,
      idCategoria: _categoriaId,
    );

    if (widget.estabelecimento == null) {
      await db.insert('estabelecimentos', novoEst.toMap());
    } else {
      await db.update('estabelecimentos', novoEst.toMap(), where: 'id = ?', whereArgs: [novoEst.id]);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.estabelecimento == null ? "Novo Local" : "Editar Local")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Localização: ${widget.estabelecimento?.latitude ?? widget.posicaoInicial?.latitude}"),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome do Estabelecimento"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _salvar, child: const Text("Salvar"))
            ],
          ),
        ),
      ),
    );
  }
}