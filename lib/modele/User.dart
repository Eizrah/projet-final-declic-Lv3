import 'package:uuid/uuid.dart';

class User {
  String idUser;
  String nom;
  String prenom;
  String email;
  String mdp;
  String? photoUrl; // Nouvelle propriété
  List<String> favoris;
  List<String> panier;

  User({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.mdp,
    this.photoUrl, // Mis à jour
    List<String>? favoris,
    List<String>? panier,
  })  : idUser = Uuid().v4(),
        favoris = favoris ?? [],
        panier = panier ?? [];

  User.withId({
    required this.idUser,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.mdp,
    required this.favoris,
    required this.panier,
    this.photoUrl, // Mis à jour
  });


//utilser pour sqflite
  Map<String, dynamic> toMap() {
    return {
      'idUser': idUser,
      'photoUrl': photoUrl,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'idUser': idUser,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'mdp': mdp,
      'photoUrl': photoUrl, // Mis à jour
      'favoris': favoris,
      'panier': panier,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User.withId(
      idUser: json['idUser'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      mdp: json['mdp'],
      favoris: List<String>.from(json['favoris'] ?? []),
      panier: List<String>.from(json['panier'] ?? []),
      photoUrl: json['photoUrl'], // Mis à jour
    );
  }

  User copyWith({
    String? idUser,
    String? nom,
    String? prenom,
    String? email,
    String? mdp,
    List<String>? favoris,
    List<String>? panier,
    String? photoUrl, //Mis à jour
  }) {
    return User.withId(
      idUser: idUser ?? this.idUser,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      mdp: mdp ?? this.mdp,
      favoris: favoris ?? this.favoris,
      panier: panier ?? this.panier,
      photoUrl: photoUrl ?? this.photoUrl, //Mis à jour
    );
  }

  @override
  String toString() {
    return 'User{idUser: $idUser, nom: $nom, prenom: $prenom, email: $email, favoris: $favoris, panier: $panier, photoUrl: $photoUrl}';
  }
}