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

      // evolucao
      final evolutionChainResponse =
          await http.get(Uri.parse(speciesData['evolution_chain']['url']));
      final evolutionChainData = json.decode(evolutionChainResponse.body);
      final evolutionNamesAndUrls =
          _getEvolutionNamesAndUrls(evolutionChainData['chain']);

      // PP e damage
      List<Map<String, dynamic>> detailedMoves = [];
      for (var move in details['moves']) {
        final moveDetailsResponse =
            await http.get(Uri.parse(move['move']['url']));
        final moveDetails = json.decode(moveDetailsResponse.body);

        int pp = moveDetails['pp'];
        int power = moveDetails['power'] ?? 0;

        detailedMoves.add({
          'name': move['move']['name'].toUpperCase(),
          'pp': pp,
          'power': power,
        });
      }

      return {
        'image': details['sprites']['front_default'] ??
            'https://via.placeholder.com/100',
        'height': details['height'] / 10,
        'weight': details['weight'] / 10,
        'types': (details['types'] as List)
            .map((type) => type['type']['name'].toUpperCase())
            .toList(),
        'abilities': (details['abilities'] as List)
            .map((ability) => ability['ability']['name'].toUpperCase())
            .toList(),
        'gender': speciesData['gender_rate'] == -1 ? 'N/A' : 'Male/Female',
        'generation': speciesData['generation']['name']
            .replaceFirst('generation-', ' ')
            .toUpperCase(),
        'moves': detailedMoves,
        'evolution': evolutionNamesAndUrls,
      };
    } else {
      throw Exception('Erro ao buscar detalhes do Pokémon');
    }
  }

  //seção de evoluções
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Color.fromARGB(255, 253, 253, 253),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 250,
                                width: 250,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                        'assets/images/backfoto.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              Image.network(
                                data['image'],
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ],
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
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration:
                                    _getTypeDecoration(type.toLowerCase()),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              );
                            }).toList(),
                          ),

                          //pequenos detalhes dos pokemons
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
                    SizedBox(height: 40),
                    _buildSectionTitle('Lista de Ataques'),
                    SizedBox(height: 13),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data['moves']
                          .map<Widget>(
                            (move) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '- ${move['name']}',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'PP: ${move['pp']}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Dano: ${move['power'] == 0 ? 'N/A' : move['power']}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: evolutionNamesAndUrls.map<Widget>((evolution) {
        return Column(
          children: [
            FutureBuilder<String>(
              future: _fetchPokemonImage(evolution['url']!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Icon(Icons.error, color: Colors.red);
                } else {
                  return Column(
                    children: [
                      Image.network(
                        snapshot.data!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                      Text(
                        evolution['name']!.toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                }
              },
            ),
            if (evolution != evolutionNamesAndUrls.last)
              Icon(Icons.arrow_downward,
                  color: Colors.white), // Setas para baixo
            SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  BoxDecoration _getTypeDecoration(String type) {
    switch (type) {
      case 'grass':
        return BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(8),
        );
      case 'fire':
        return BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        );
      case 'flying':
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.grey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(8),
        );
      case 'electric':
        return BoxDecoration(
          color: Colors.yellow,
          borderRadius: BorderRadius.circular(8),
        );
      case 'ground':
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow, Colors.brown[600]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(8),
        );
      case 'fairy':
        return BoxDecoration(
          color: Colors.pink[200]!,
          borderRadius: BorderRadius.circular(8),
        );
      case 'bug':
        return BoxDecoration(
          color: const Color.fromARGB(255, 63, 211, 71),
          borderRadius: BorderRadius.circular(8),
        );
      case 'fighting':
        return BoxDecoration(
          color: Colors.deepOrange,
          borderRadius: BorderRadius.circular(8),
        );
      case 'psychic':
        return BoxDecoration(
          color: const Color.fromARGB(255, 231, 65, 162),
          borderRadius: BorderRadius.circular(8),
        );
      case 'steel':
        return BoxDecoration(
          color: Colors.grey[600]!,
          borderRadius: BorderRadius.circular(8),
        );
      case 'ghost':
        return BoxDecoration(
          color: const Color.fromARGB(255, 78, 19, 88),
          borderRadius: BorderRadius.circular(8),
        );
      case 'rock':
        return BoxDecoration(
          color: const Color.fromARGB(255, 184, 134, 11),
          borderRadius: BorderRadius.circular(8),
        );
      case 'ice':
        return BoxDecoration(
          color: Colors.lightBlueAccent,
          borderRadius: BorderRadius.circular(8),
        );
      case 'dragon':
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.orange],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(8),
        );
      case 'dark':
        return BoxDecoration(
          color: const Color.fromARGB(255, 26, 26, 26),
          borderRadius: BorderRadius.circular(8),
        );
      case 'water':
        return BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        );
      case 'normal':
        return BoxDecoration(
          color: const Color.fromARGB(255, 156, 156, 156),
          borderRadius: BorderRadius.circular(8),
        );
      default:
        return BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(8),
        );
    }
  }
}
