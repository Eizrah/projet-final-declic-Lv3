import 'package:uuid/uuid.dart';

class Article {
  String idArticle;
  String nom;
  double prix;
  String description;
  String image;
  bool isFavorite;

  static final Uuid _uuid = Uuid();

  // Constructeur principal
  Article({
    required this.nom,
    required this.prix,
    required this.description,
    required this.image,
    this.isFavorite = false,
  }) : idArticle = _uuid.v4();

  // Constructeur avec id (utile quand l'id vient de Firestore ou d’un JSON)
  Article.avecId({
    required this.idArticle,
    required this.nom,
    required this.prix,
    required this.description,
    required this.image,
    required this.isFavorite,
  });

  // Conversion en JSON (pour sauvegarder dans Firestore par ex.)
  Map<String, dynamic> toJson() {
    return {
      'idArticle': idArticle,
      'nom': nom,
      'prix': prix,
      'description': description,
      'image': image,
      'isFavorite': isFavorite,
    };
  }

  // Création depuis JSON (utile si tu stockes ton article en local ou REST API)
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article.avecId(
      idArticle: json['idArticle'],
      nom: json['nom'],
      prix: (json['prix'] as num).toDouble(),
      description: json['description'],
      image: json['image'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // ✅ Création depuis Map Firestore (doc.data())
  factory Article.fromMap(Map<String, dynamic> map) {
    return Article.avecId(
      idArticle: map['idArticle'] ?? _uuid.v4(), // si pas d’id en base → on en génère un
      nom: map['nom'] ?? '',
      prix: (map['prix'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  // CopyWith (pour cloner et modifier un seul champ)
  Article copyWith({
    String? idArticle,
    String? nom,
    double? prix,
    String? description,
    String? image,
    bool? isFavorite,
  }) {
    return Article.avecId(
      idArticle: idArticle ?? this.idArticle,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      description: description ?? this.description,
      image: image ?? this.image,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  String toString() {
    return 'Article{idArticle: $idArticle, nom: $nom, prix: $prix, isFavorite: $isFavorite}';
  }
}
