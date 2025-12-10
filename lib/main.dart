import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'database_helper.dart';
import 'models/estabelecimento.dart';
import 'screens/login_screen.dart';
import 'screens/form_screen.dart'; // <--- Importamos o novo formulário
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

  String _busca = "";

  @override
  void initState() {
    super.initState();
    _carregarDados(); 
  }

  Future<void> _carregarDados() async {
    final dados = await DatabaseHelper().buscarTodosEstabelecimentos();

    setState(() {
      _todosEstabelecimentos = List.generate(dados.length, (i) {
        return Estabelecimento.fromMap(
          dados[i], 
          dados[i]['bandeirasIds'] 
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

  // Agora chama o FormScreen que está no ficheiro separado
  void _abrirFormulario({Estabelecimento? estabelecimento, LatLng? latLong}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormScreen(
          estabelecimento: estabelecimento,
          posicaoInicial: latLong,
        ),
      ),
    );
    _carregarDados(); // Recarrega o mapa ao voltar
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