import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'models/estabelecimento.dart';
import 'screens/login_screen.dart';
import 'session_manager.dart';

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
      home: const LoginScreen(), 
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
  final LatLng _posicaoInicial = const LatLng(-5.088544, -42.811238); 
  Set<Marker> _marcadores = {}; 
  List<Estabelecimento> _todosEstabelecimentos = [];

  // Filtros
  String _busca = "";

  @override
  void initState() {
    super.initState();
    _carregarDados(); 
  }

  Future<void> _carregarDados() async {
    // Agora usamos o método especial que já traz as bandeiras
    final dados = await DatabaseHelper().buscarTodosEstabelecimentos();

    setState(() {
      _todosEstabelecimentos = List.generate(dados.length, (i) {
        // Converte o Map do banco para o Objeto usando o helper
        return Estabelecimento.fromMap(
          dados[i], 
          dados[i]['bandeirasIds'] // Passa a lista de IDs de bandeiras
        );
      });
      _atualizarMarcadores();
    });
  }

  void _atualizarMarcadores() {
    Set<Marker> novosMarcadores = {};
    for (var est in _todosEstabelecimentos) {
      if (_busca.isEmpty || est.nome.toLowerCase().contains(_busca.toLowerCase())) {
        novosMarcadores.add(
          Marker(
            markerId: MarkerId(est.id.toString()),
            position: LatLng(est.latitude, est.longitude),
            infoWindow: InfoWindow(
              title: est.nome,
              snippet: "Toque para editar",
              onTap: () => _abrirFormulario(estabelecimento: est),
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
    mapController = controller; 
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              SessionManager().logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Buscar estabelecimento...",
                fillColor: Colors.white, filled: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
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
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(target: _posicaoInicial, zoom: 14.0), 
        markers: _marcadores, 
        onTap: _onMapTap, 
        myLocationEnabled: true, 
      ),
    );
  }
}

// --- TELA DE CADASTRO/EDIÇÃO (PROVISÓRIA PARA COMPILAR) ---
// Na próxima fase vamos melhorar este formulário com os checkboxes
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
  int _categoriaId = 1; // Default
  // Nota: Ainda não colocamos a UI das bandeiras aqui para não complicar este passo.
  // O app vai salvar, mas sem bandeiras por enquanto.
  
  @override
  void initState() {
    super.initState();
    if (widget.estabelecimento != null) {
      _nomeController.text = widget.estabelecimento!.nome;
      _categoriaId = widget.estabelecimento!.idCategoria;
    }
  }

  Future<void> _salvar() async {
    final lat = widget.estabelecimento?.latitude ?? widget.posicaoInicial!.latitude;
    final lng = widget.estabelecimento?.longitude ?? widget.posicaoInicial!.longitude;

    final estData = {
      'id': widget.estabelecimento?.id, // Null se for novo
      'nome': _nomeController.text,
      'latitude': lat,
      'longitude': lng,
      'id_categoria': _categoriaId,
      'criado_por': SessionManager().usuarioLogadoId,
    };

    // Por enquanto salvamos com lista vazia de bandeiras, pois a UI não existe ainda
    List<int> bandeirasSelecionadas = widget.estabelecimento?.bandeirasIds ?? [];

    if (widget.estabelecimento == null) {
      await DatabaseHelper().inserirEstabelecimento(estData, bandeirasSelecionadas);
    } else {
      await DatabaseHelper().atualizarEstabelecimento(estData, bandeirasSelecionadas);
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
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome do Estabelecimento"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _salvar, child: const Text("Salvar (Simplificado)"))
            ],
          ),
        ),
      ),
    );
  }
}