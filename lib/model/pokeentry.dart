class PokedexEntry {
  String number;
  String name;
  String imageUrl;
  List<String> types;
  List<String> evolutionChain;

  PokedexEntry({
    required this.number,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.evolutionChain,
  });
}
