import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:semaine6/screen/HomeA.dart';

import 'Login.dart';

class Inscription extends StatelessWidget {
  const Inscription({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inscription',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(0, 11, 75, 214),
        ),
      ),
      home: const InterfaceInsc(),
    );
  }
}

class InterfaceInsc extends StatefulWidget {
  const InterfaceInsc({super.key});

  @override
  State<InterfaceInsc> createState() => _InterfaceInsc();
}

class _InterfaceInsc extends State<InterfaceInsc> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///Inscription Email + Mot de passe
  Future<void> _registerWithEmail() async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // hachage le mot de passe avant stockage (pour + de securite ) 
      String motDePasseHash = sha256
          .convert(utf8.encode(_passwordController.text.trim()))
          .toString();

      await _firestore.collection("User").doc(userCred.user!.uid).set({
        "id_user": userCred.user!.uid,
        "nom": _nom.text.trim(),
        "prenom": _prenom.text.trim(),
        "email": _emailController.text.trim(),
        "mdp": motDePasseHash,
        "favoris": [],
        "panier": [],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte créé avec succès ✅")),
      );

      // Redirection vers Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Homea()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

///Connexion Google
Future<void> _signInWithGoogle() async {
  try {
    //On instancie GoogleSignIn
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    //On déconnecte pour forcer la popup de choix de compte
    await googleSignIn.signOut();

    // affichage de la liste  des comptes disponibles sur le téléphone
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) return; // si l’utilisateur annule

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCred = await _auth.signInWithCredential(credential);

    // 🔹 Vérifie si c’est un nouvel utilisateur
    if (userCred.additionalUserInfo!.isNewUser) {
      await _firestore.collection("User").doc(userCred.user!.uid).set({
        "id_user": userCred.user!.uid,
        "nom": googleUser.displayName?.split(" ").last ?? "",
        "prenom": googleUser.displayName?.split(" ").first ?? "",
        "email": googleUser.email,
        "mdp": "", // vide car géré par Google
        "favoris": [],
        "panier": [],
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Connexion Google réussie ✅")),
    );

    // 🔹 Redirection vers Home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Homea()),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur Google : $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 231, 231, 235),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 231, 231, 235),
      body: Padding(
        padding: const EdgeInsets.all(17),
        child: ListView(
          children: [
            Column(
              children: [
                const SizedBox(height: 70),
                Text(
                  "E-Shop",
                  style: GoogleFonts.inriaSerif(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A51A6),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Créer un compte",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 80),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nom
                      TextFormField(
                        controller: _nom,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          labelText: 'Nom',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          filled: true,
                          fillColor: Color(0xFFFAF8F8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Prénom
                      TextFormField(
                        controller: _prenom,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          labelText: 'Prénom',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          filled: true,
                          fillColor: Color(0xFFFAF8F8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          filled: true,
                          fillColor: Color(0xFFFAF8F8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: const Color(0xFFFAF8F8),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      // Bouton créer un compte
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 32, 88, 219),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(330, 50),
                        ),
                        onPressed: _registerWithEmail,
                        child: const Text('Créer un compte'),
                      ),
                      const SizedBox(height: 40),
                      // Séparateur "OU"
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color.fromARGB(255, 105, 103, 103),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OU',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color.fromARGB(255, 105, 103, 103),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Google
                      ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Image.asset("assets/images/google.jpg", height: 24),
                        label: const Text("Connexion avec Google"),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
