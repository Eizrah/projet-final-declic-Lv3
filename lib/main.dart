import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:semaine6/screen/Acceuil.dart';
import 'package:semaine6/modele/DatabaseManager.dart'; //  Importation le gestionnaire de base de données


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await DatabaseManager.initialisation(); 
  runApp(const MonApp());
}

class MonApp extends StatefulWidget {
  const MonApp({super.key});

  @override
  State<MonApp> createState() => _MonAppState();
}


class _MonAppState extends State<MonApp> {
  

  @override
  void initState() {
    super.initState();
  
  }

 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Shop',
      debugShowCheckedModeBanner: false,
      home: const Acceuil(),
    );
  }
}