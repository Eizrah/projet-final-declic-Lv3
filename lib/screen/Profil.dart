import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:semaine6/modele/DatabaseManager.dart';
import 'package:semaine6/screen/FavList.dart';
import 'package:semaine6/screen/HomeA.dart';
import 'package:semaine6/screen/Login.dart';
import 'package:semaine6/screen/Panier.dart';
import 'package:semaine6/modele/User.dart' as MonUtilisateur;

class Profil extends StatelessWidget {
  const Profil({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profil',
      debugShowCheckedModeBanner: false,
      home: InterfaceProf(),
    );
  }
}

class InterfaceProf extends StatefulWidget {
  const InterfaceProf({super.key});

  @override
  State<InterfaceProf> createState() => _InterfaceProf();
}

class _InterfaceProf extends State<InterfaceProf> {
  int _currentIndex = 3;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _imageFile;
  String? _photoUrlLocal;
  bool _isLoading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final User? authUser = _auth.currentUser;
    if (authUser != null) {
      // Récupérer les données de l'utilisateur depuis Firebase
      final doc = await _firestore.collection('User').doc(authUser.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nom.text = data['nom'] ?? '';
        _prenom.text = data['prenom'] ?? '';
        _emailController.text = data['email'] ?? '';
      }

      //  Récupérer l'URL de la photo depuis SQFlite
      _photoUrlLocal = await DatabaseManager.getUserPhotoUrl(authUser.uid);

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final User? authUser = _auth.currentUser;
    if (authUser == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (pickedFile != null) {
      // Sauvegarder la photo en local
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final newPath = p.join(appDir.path, '${authUser.uid}_$fileName');
      final savedImage = await File(pickedFile.path).copy(newPath);

      // Créer un objet User pour l'insertion SQFlite
      final userWithPhoto = MonUtilisateur.User.withId(
        idUser: authUser.uid,
        nom: _nom.text,
        prenom: _prenom.text,
        email: _emailController.text,
        mdp: '', // Le mot de passe n'est pas nécessaire ici
        favoris: [],
        panier: [],
        photoUrl: savedImage.path,
      );

      //Sauvegarder le chemin dans SQFlite
      await DatabaseManager.insertOrUpdateUserPhoto(userWithPhoto);

      //Mettre à jour l'état de l'UI
      setState(() {
        _imageFile = savedImage;
        _photoUrlLocal = savedImage.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo de profil mise à jour localement ✅")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 231, 231, 235),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(17),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 70),
                    Center(
                      child: Text(
                        "Profil",
                        style: GoogleFonts.inriaSerif(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2A51A6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: _takePhoto,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.purple[100],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider<Object>?
                            : (_photoUrlLocal != null
                                ? FileImage(File(_photoUrlLocal!)) as ImageProvider<Object>?
                                : null),
                        child: _imageFile == null && _photoUrlLocal == null
                            ? const Icon(Icons.person, size: 60, color: Colors.black54)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
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
                          TextFormField(
                            controller: _prenom,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person),
                              labelText: 'Prenom',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                              ),
                              filled: true,
                              fillColor: Color(0xFFFAF8F8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            readOnly: true,
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
                          const SizedBox(height: 30),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 32, 88, 219),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(330, 50),
                            ),
                            onPressed: _updateUserData,
                            child: const Text('Valider les modifications'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.power_settings_new, color: Colors.red),
                            label: const Text("Déconnexion"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              minimumSize: const Size(330, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100]!,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.favorite, 'Favoris', 1),
            _buildNavItem(Icons.shopping_cart, 'Panier', 2),
            _buildNavItem(Icons.person, 'Profil', 3),
          ],
          selectedItemColor: const Color(0xFF2A51A6),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _currentIndex == index
              ? const Color(0xFF2A51A6).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Homea()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Favlist()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Panier()));
    }
  }

  Future<void> _updateUserData() async {
    final User? authUser = _auth.currentUser;
    if (authUser == null) return;

    if (!_formKey.currentState!.validate()) return;

    try {
      await _firestore.collection('User').doc(authUser.uid).update({
        'nom': _nom.text.trim(),
        'prenom': _prenom.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour : $e")),
      );
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (Route<dynamic> route) => false,
    );
  }
}