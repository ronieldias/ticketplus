import 'package:flutter/material.dart';

class FiltrosModal extends StatefulWidget {
  final List<Map<String, dynamic>> todasCategorias;
  final List<Map<String, dynamic>> todasBandeiras;
  
  // Estado atual dos filtros
  final int? categoriaSelecionada;
  final List<int> bandeirasSelecionadas;

  final Function(int? cat, List<int> bands) onAplicar;

  const FiltrosModal({
    super.key,
    required this.todasCategorias,
    required this.todasBandeiras,
    required this.categoriaSelecionada,
    required this.bandeirasSelecionadas,
    required this.onAplicar,
  });

  @override
  State<FiltrosModal> createState() => _FiltrosModalState();
}

class _FiltrosModalState extends State<FiltrosModal> {
  int? _catTemp;
  final List<int> _bandsTemp = [];

  @override
  void initState() {
    super.initState();
    // Inicializa com o que veio da tela principal
    _catTemp = widget.categoriaSelecionada;
    _bandsTemp.addAll(widget.bandeirasSelecionadas);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7, // Ocupa 70% da tela
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Filtrar Resultados", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(),
          
          Expanded(
            child: ListView(
              children: [
                // --- Filtro de Categoria ---
                const Text("Categoria:", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text("Todas"),
                      selected: _catTemp == null,
                      onSelected: (bool selected) {
                        setState(() => _catTemp = null);
                      },
                    ),
                    ...widget.todasCategorias.map((cat) {
                      return ChoiceChip(
                        label: Text(cat['nome']),
                        selected: _catTemp == cat['id'],
                        onSelected: (bool selected) {
                          setState(() => _catTemp = selected ? cat['id'] : null);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Filtro de Bandeiras ---
                const Text("Bandeiras Aceitas (pelo menos uma):", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: widget.todasBandeiras.map((band) {
                    final isSelected = _bandsTemp.contains(band['id']);
                    return FilterChip(
                      label: Text(band['nome']),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _bandsTemp.add(band['id']);
                          } else {
                            _bandsTemp.remove(band['id']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // --- Botões de Ação ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _catTemp = null;
                      _bandsTemp.clear();
                    });
                  },
                  child: const Text("Limpar Filtros"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onAplicar(_catTemp, _bandsTemp);
                    Navigator.pop(context);
                  },
                  child: const Text("Aplicar"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}