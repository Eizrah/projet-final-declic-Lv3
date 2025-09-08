
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:semaine6/Paypal/Payement.dart';
import 'package:semaine6/modele/Article.dart';
import 'package:semaine6/screen/FavList.dart';
import 'package:semaine6/screen/HomeA.dart';
import 'package:semaine6/screen/Profil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'dart:async'; 
import 'package:app_links/app_links.dart';

class Panier extends StatelessWidget {
  const Panier({super.key});

  @override
  Widget build(BuildContext context) {
    return const InterfacePan();
  }
}

class InterfacePan extends StatefulWidget {
  const InterfacePan({super.key});

  @override
  State<InterfacePan> createState() => _InterfacePanState();
}

class _InterfacePanState extends State<InterfacePan> {
  int _currentIndex = 2;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener(); 
  }

  @override
  void dispose() {
    _sub?.cancel(); 
    super.dispose();
  }

  void _initDeepLinkListener() {
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        if (mounted) {
          if (uri.host == "paypalpay") {
            if (uri.path.contains("success")) {
              print("✅ Paiement validé !");
              _showPaymentSuccessDialog();
              _viderPanierApresPaiement();
            } else if (uri.path.contains("cancel")) {
              print("❌ Paiement annulé");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Le paiement a été annulé.")),
              );
            }
          }
        }
      },
      onError: (err) {
        print("Erreur deep link: $err");
      },
    );
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Paiement Réussi"),
          content: const Text("Votre commande a été validée avec succès !"),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
            ),
          ],
        );
      },
    );
  }




// VEUILLEZ REMPLACER VOTRE FONCTION _getPanierArticlesWithQuantities PAR CELLE-CI
Stream<Map<Article, int>> _getPanierArticlesWithQuantities() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // Si l'utilisateur n'est pas connecté, on retourne un flux vide.
    return Stream.value({});
  }

  final userRef = FirebaseFirestore.instance.collection('User').doc(user.uid);

  return userRef.snapshots().asyncMap((doc) async {
    if (!doc.exists || doc.data()?['panier'] == null) {
      return {}; // L'utilisateur n'existe pas ou n'a pas de panier
    }
    
    // On s'assure que le champ 'panier' est bien une liste.
    final panierData = doc.data()!['panier'];
    if (panierData is! List) return {};
    
    // On s'assure que les éléments de la liste sont bien des Maps.
    final panierList = panierData.whereType<Map<String, dynamic>>().toList();

    if (panierList.isEmpty) {
      return {}; // Le panier est vide
    }

    // On récupère les IDs des articles pour la requête
    final articleIds = panierList.map((item) => item['id'] as String).toList();
    if (articleIds.isEmpty) return {};

    // On récupère les documents des articles correspondants
    final articlesSnapshot = await FirebaseFirestore.instance
        .collection('article')
        .where(FieldPath.documentId, whereIn: articleIds)
        .get();

    // On crée une map pour un accès rapide aux articles par leur ID (plus efficace)
    final articlesById = {for (var doc in articlesSnapshot.docs) doc.id: doc};
    
    final articlesWithQuantities = <Article, int>{};

    for (var item in panierList) {
      final articleDoc = articlesById[item['id']];
      if (articleDoc != null) {
        final article = Article.fromMap({...articleDoc.data(), 'idArticle': articleDoc.id});
        articlesWithQuantities[article] = item['quantite'] as int;
      }
    }
    
    return articlesWithQuantities;
  });
}

//fonction pour supprimer un article dans panier
  Future<void> _removeFromPanier(String articleId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('User').doc(userId);
    final userDoc = await userRef.get();
    
    if (userDoc.exists) {
      final panierList = List<Map<String, dynamic>>.from(userDoc.data()!['panier'] ?? []);
      
      panierList.removeWhere((item) => item['id'] == articleId);
      
      await userRef.update({'panier': panierList});
    }
  }

  Future<void> _viderPanierApresPaiement() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('User').doc(userId);

    await userRef.update({'panier': []});
  }

  double _calculateTotal(Map<Article, int> panier) {
    double total = 0.0;
    panier.forEach((article, quantite) {
      total += article.prix * quantite;
    });
    return total;
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homea()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Favlist()),
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Profil()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 231, 231, 235),
      body: Padding(
        padding: const EdgeInsets.all(17),
        child: StreamBuilder<Map<Article, int>>(
          stream: _getPanierArticlesWithQuantities(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final panier = snapshot.data ?? {};
            if (panier.isEmpty) {
              return Center(
                child: Text(
                  "Votre panier est vide.",
                  style: GoogleFonts.inriaSerif(fontSize: 18),
                ),
              );
            }
            final totalEnAr = _calculateTotal(panier);
            final totalEnUSD = totalEnAr / 4500; 
            
            final panierList = panier.keys.toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 70),
                Text(
                  "Panier (${panierList.length} articles)",
                  style: GoogleFonts.inriaSerif(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A51A6),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: panierList.length,
                    itemBuilder: (context, index) {
                      final article = panierList[index];
                      final quantite = panier[article]!;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Hero(
                            tag: article.idArticle,
                            child: Image.network(article.image, width: 50),
                          ),
                          title: Text("${article.nom} x$quantite"),
                          subtitle: Text("${article.prix} Ar"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.black54),
                                onPressed: () => _removeFromPanier(article.idArticle),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Total : ${totalEnAr.toStringAsFixed(2)} Ar", 
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "(environ ${totalEnUSD.toStringAsFixed(2)} USD)", 
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A51A6),
                    disabledBackgroundColor: Colors.grey,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: totalEnUSD <= 0
                      ? null
                      : () async {
                          final paypal = PayPalService(clientId: cliid, secret: sct);
                          final approvalUrl = await paypal.createOrder(
                            totalEnUSD,
                          );

                          if (approvalUrl != null) {
                            try {
                              await launchUrl(
                                Uri.parse(approvalUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Impossible d'ouvrir la page de paiement"),
                                ),
                              );
                            }
                          }
                        },
                  child: const Text(
                    "Valider la commande avec PayPal",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favoris"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Panier",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
        selectedItemColor: const Color(0xFF2A51A6),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}