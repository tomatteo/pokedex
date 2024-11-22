import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pokedex/model/pokeentry.dart';
import 'package:pokedex/pokemon/teladetalhespoke.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PokedexPage(),
    );
  }
}

class PokedexPage extends StatefulWidget {
  @override
  _PokedexPageState createState() => _PokedexPageState();
}

class _PokedexPageState extends State<PokedexPage> {
  bool isLoading = false;
  ScrollController scrollController = ScrollController();
  int offset = 0;
  int maxOffset = 1118;
  List<PokedexEntry> allPokemon = [];

  @override
  void initState() {
    super.initState();
    fetchPokemonPage(offset);
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent * 0.7 &&
          !isLoading) {
        fetchPokemonPage(offset);
      }
    });
  }

  Future<void> fetchPokemonPage(int currentOffset) async {
    if (isLoading || currentOffset >= maxOffset) return;

    setState(() {
      isLoading = true;
    });

    final response = await http.get(Uri.parse(
        'https://pokeapi.co/api/v2/pokemon?limit=10&offset=$currentOffset'));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      List results = data['results'] as List;

      for (var item in results) {
        var details = await fetchPokemonDetails(item['url']);
        var pokemonDetails = details['details'];
        var evolutionChain = details['evolutionChain'];

        PokedexEntry pokemon = PokedexEntry(
          number: 'Nº${allPokemon.length + 1}',
          name: item['name'].toString().toUpperCase(),
          imageUrl: pokemonDetails['sprites']['front_default'] ??
              'https://via.placeholder.com/100',
          types: (pokemonDetails['types'] as List)
              .map((type) => type['type']['name'].toString())
              .toList(),
          evolutionChain: evolutionChain,
        );
        setState(() {
          allPokemon.add(pokemon);
        });
      }

      offset += 10;
    } else {
      throw Exception('Falha ao carregar os dados');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<Map> fetchPokemonDetails(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final details = json.decode(response.body);

      // Obter a URL da espécie
      final speciesUrl = details['species']['url'];
      final evolutionChain = await fetchEvolutionChain(speciesUrl);

      return {
        'details': details,
        'evolutionChain': evolutionChain,
      };
    } else {
      throw Exception('Falha ao carregar os detalhes do Pokémon');
    }
  }

  Future<List<String>> fetchEvolutionChain(String speciesUrl) async {
    final speciesResponse = await http.get(Uri.parse(speciesUrl));
    if (speciesResponse.statusCode == 200) {
      final speciesData = json.decode(speciesResponse.body);
      final evolutionUrl = speciesData['evolution_chain']['url'];

      final evolutionResponse = await http.get(Uri.parse(evolutionUrl));
      if (evolutionResponse.statusCode == 200) {
        final evolutionData = json.decode(evolutionResponse.body);

        // Processar cadeia de evoluções
        List<String> evolutionNames = [];
        var current = evolutionData['chain'];
        while (current != null) {
          evolutionNames.add(current['species']['name']);
          if (current['evolves_to'].isNotEmpty) {
            current = current['evolves_to'][0];
          } else {
            current = null;
          }
        }
        return evolutionNames;
      } else {
        throw Exception('Falha ao carregar a cadeia de evolução');
      }
    } else {
      throw Exception('Falha ao carregar os dados da espécie');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Center(
          child: Image.asset(
            'assets/images/logopoke.png',
            height: 40,
          ),
        ),
      ),
      body: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.all(16),
        itemCount: allPokemon.length + 1,
        itemBuilder: (context, index) {
          if (index == allPokemon.length) {
            return isLoading
                ? Center(child: CircularProgressIndicator())
                : SizedBox.shrink();
          }
          final pokemon = allPokemon[index];
          return PokemonCard(pokemon: pokemon);
        },
      ),
    );
  }
}

class PokemonCard extends StatelessWidget {
  final PokedexEntry pokemon;

  PokemonCard({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PokemonDetailsScreen(pokemon: pokemon),
          ),
        );
      },
      child: Card(
        color: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.network(
                pokemon.imageUrl,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 8),
              Text(
                pokemon.number,
                style: TextStyle(color: Colors.grey[500]),
              ),
              Text(
                pokemon.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: pokemon.types.map((type) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: _getTypeDecoration(type),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
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
          gradient: LinearGradient(
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
            colors: [Colors.yellow, Colors.brown[200]!],
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
          color: const Color.fromARGB(255, 63, 211, 71)!,
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
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.orange],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(8),
        );
      case 'dark':
        return BoxDecoration(
          color: Colors.grey[800]!,
          borderRadius: BorderRadius.circular(8),
        );
      case 'water':
        return BoxDecoration(
          color: Colors.blue,
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
