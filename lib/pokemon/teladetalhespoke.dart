import 'package:flutter/material.dart';
import 'package:pokedex/model/pokeentry.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PokemonDetailsScreen extends StatelessWidget {
  final PokedexEntry pokemon;

  PokemonDetailsScreen({required this.pokemon});

  Future<Map<String, dynamic>> fetchPokemonDetails() async {
    final response = await http.get(Uri.parse(
        'https://pokeapi.co/api/v2/pokemon/${pokemon.name.toLowerCase()}'));
    if (response.statusCode == 200) {
      final details = json.decode(response.body);
      final speciesResponse =
          await http.get(Uri.parse(details['species']['url']));
      final speciesData = json.decode(speciesResponse.body);

      // Fetching evolution chain
      final evolutionChainResponse =
          await http.get(Uri.parse(speciesData['evolution_chain']['url']));
      final evolutionChainData = json.decode(evolutionChainResponse.body);
      final evolutionNamesAndUrls =
          _getEvolutionNamesAndUrls(evolutionChainData['chain']);

      return {
        'image': details['sprites']['front_default'] ??
            'https://via.placeholder.com/100',
        'height': details['height'] / 10, // metros
        'weight': details['weight'] / 10, // kg
        'types': (details['types'] as List)
            .map((type) => type['type']['name'].toUpperCase())
            .toList(),
        'abilities': (details['abilities'] as List)
            .map((ability) => ability['ability']['name'].toUpperCase())
            .toList(),
        'gender': speciesData['gender_rate'] == -1 ? 'N/A' : 'Male/Female',
        'generation': speciesData['generation']['name']
            .replaceFirst('generation-', '')
            .toUpperCase(),
        'moves': (details['moves'] as List)
            .map((move) => move['move']['name'].toUpperCase())
            .toList(),
        'evolution': evolutionNamesAndUrls,
      };
    } else {
      throw Exception('Erro ao buscar detalhes do Pokémon');
    }
  }

  // Recursively fetch names and URLs from the evolution chain
  List<Map<String, String>> _getEvolutionNamesAndUrls(
      Map<String, dynamic> chain) {
    List<Map<String, String>> evolutionNamesAndUrls = [
      {
        'name': chain['species']['name'],
        'url': 'https://pokeapi.co/api/v2/pokemon/${chain['species']['name']}'
      }
    ];
    if (chain['evolves_to'].isNotEmpty) {
      for (var evolution in chain['evolves_to']) {
        evolutionNamesAndUrls.addAll(_getEvolutionNamesAndUrls(evolution));
      }
    }
    return evolutionNamesAndUrls;
  }

  // Function to fetch Pokémon image
  Future<String> _fetchPokemonImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final pokemonData = json.decode(response.body);
      return pokemonData['sprites']['front_default'] ??
          'https://via.placeholder.com/100';
    } else {
      throw Exception('Erro ao buscar imagem do Pokémon');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Image.asset(
          'assets/images/logopoke.png',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchPokemonDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Erro ao carregar detalhes do Pokémon',
                style: TextStyle(color: Colors.grey[400]),
              ),
            );
          } else {
            final data = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Image.network(
                            data['image'],
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: 16),
                          Text(
                            pokemon.name.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            pokemon.number,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: data['types'].map<Widget>((type) {
                              return Chip(
                                backgroundColor: _getTypeColor(type),
                                label: Text(
                                  type,
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                    'Altura', '${data['height']} m'),
                                _buildDetailRow('Peso', '${data['weight']} kg'),
                                _buildDetailRow('Gênero', data['gender']),
                                _buildDetailRow('Geração', data['generation']),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildSectionTitle('Linha Evolutiva'),
                    SizedBox(height: 8),
                    _buildEvolutionChain(data['evolution']),
                    SizedBox(height: 16),
                    _buildSectionTitle('Lista de Ataques'),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data['moves']
                          .map<Widget>(
                            (move) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                '- $move',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChain(List<Map<String, String>> evolutionNamesAndUrls) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: evolutionNamesAndUrls
          .map((evolution) => Column(
                children: [
                  FutureBuilder<String>(
                    future: _fetchPokemonImage(evolution['url']!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return Icon(Icons.error, color: Colors.white);
                      } else {
                        return Image.network(
                          snapshot.data!,
                          height: 80,
                          width: 80,
                        );
                      }
                    },
                  ),
                  Text(
                    evolution['name']!.toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                  if (evolution != evolutionNamesAndUrls.last)
                    Icon(Icons.arrow_downward, color: Colors.white),
                ],
              ))
          .toList(),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'grass':
        return Colors.green;
      case 'poison':
        return Colors.purple;
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
