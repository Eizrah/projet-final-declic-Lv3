// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// //import 'package:app_links/app_links.dart';
// import 'package:semaine6/screen/Acceuil.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const MonApp());
// }

// class MonApp extends StatefulWidget {
//   const MonApp({super.key});

//   @override
//   State<MonApp> createState() => _MonAppState();
// }

// class _MonAppState extends State<MonApp> {
//   late final AppLinks _appLinks;

//   @override
//   void initState() {
//     super.initState();
//     _initDeepLinks();
//   }

//   Future<void> _initDeepLinks() async {
//     _appLinks = AppLinks();

//     // Écoute les liens reçus pendant que l’app est ouverte
//     _appLinks.uriLinkStream.listen((Uri? uri) {
//       if (uri != null) {
//         debugPrint('Lien reçu : $uri');
//         // Exemple : rediriger vers la page Panier après paiement
//         if (uri.scheme == 'eshop' && uri.host == 'payment') {
//           // TODO : navigation selon le statut de paiement
//           debugPrint('Redirection vers paiement : ${uri.queryParameters}');
//         }
//       }
//     });

//     // Vérifie si l’app a été lancée via un lien
//     final Uri? initialLink = await _appLinks.getInitialLink();
//     if (initialLink != null) {
//       debugPrint('Lien initial : $initialLink');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'E-Shop',
//       debugShowCheckedModeBanner: false,
//       home: const Acceuil(),
//     );
//   }
// }


import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// import 'package:app_links/app_links.dart'; // 👈 REMOVE THIS IMPORT
import 'package:semaine6/screen/Acceuil.dart';
import 'package:semaine6/modele/DatabaseManager.dart'; // 👈 Importez le gestionnaire de base de données


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

// 👇 SIMPLIFY THIS CLASS
class _MonAppState extends State<MonApp> {
  // late final AppLinks _appLinks;  // 👈 REMOVE

  @override
  void initState() {
    super.initState();
    // _initDeepLinks(); // 👈 REMOVE
  }

  // Future<void> _initDeepLinks() async { ... } // 👈 REMOVE THIS ENTIRE METHOD

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Shop',
      debugShowCheckedModeBanner: false,
      home: const Acceuil(),
    );
  }
}