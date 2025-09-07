import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:semaine6/screen/HomeA.dart';
import 'package:semaine6/screen/Inscription.dart';
import 'package:semaine6/screen/MdpForget.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(0, 11, 75, 214),
        ),
      ),
      home: const InterfaceLog(),
    );
  }
}

class InterfaceLog extends StatefulWidget {
  const InterfaceLog({super.key});

  @override
  State<InterfaceLog> createState() => _InterfaceLog();
}

class _InterfaceLog extends State<InterfaceLog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Connexion Email/Password 
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc =
          await _firestore.collection("User").doc(userCred.user!.uid).get();

      if (userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connexion réussie ✅")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homea()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur introuvable ❌")),
        );
      }
    } on FirebaseAuthException catch (e) { //gere les erreurs 
      String message = "Erreur de connexion";
      if (e.code == 'user-not-found') {
        message = "Utilisateur non trouvé ❌";
      } else if (e.code == 'wrong-password') {
        message = "Mot de passe incorrect ❌";
      } else if (e.code == 'invalid-email') {
        message = "Email invalide ❌";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur inattendue : $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  //Connexion Google 
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn =
          GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur Google : Token manquant")),
        );
        return;
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await _auth.signInWithCredential(credential);

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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Homea()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur Google : ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur inattendue : $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navMdpF() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Mdpforget()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 231, 231, 235),
      body: Padding(
        padding: const EdgeInsets.all(17),
        child: ListView(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  "Connexion à votre compte",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 80),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Email requis' : null,
                      ),
                      const SizedBox(height: 50),
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
                              _isObscure ? Icons.visibility_off : Icons.visibility,
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
                        validator: (value) => value == null || value.isEmpty
                            ? 'Mot de passe requis'
                            : null,
                      ),
                      const SizedBox(height: 30),
                      // Bouton connexion
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 32, 88, 219),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(330, 50),
                              ),
                              onPressed: _signInWithEmail,
                              child: const Text('Connexion'),
                            ),
                      // Mot de passe oublié
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _navMdpF,
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
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
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OU',
                              style: TextStyle(
                                color: Colors.grey,
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
                      // Connexion avec Google
                      ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Image.asset(
                          "assets/images/google.jpg",
                          height: 24,
                        ),
                        label: const Text("Connexion avec Google"),
                      ),
                      const SizedBox(height: 5),
                      // Bouton création de compte
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Inscription(),
                              ),
                            );
                          },
                          child: const Text('Vous n\'avez pas de compte ?'),
                        ),
                      ),
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

