import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:semaine6/Paypal/Payement.dart';
import 'package:semaine6/modele/Article.dart';
import 'package:semaine6/screen/FavList.dart';
import 'package:semaine6/screen/HomeA.dart';
import 'package:semaine6/screen/Profil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Correct, pour lancer l'URL
import 'dart:async'; // Correct, pour StreamSubscription
//import 'package:uni_links/uni_links.dart'; //

import 'package:app_links/app_links.dart';

// Le widget Panier n'a plus besoin d'être un MaterialApp
class Panier extends StatelessWidget {
  const Panier({super.key});

  @override
  Widget build(BuildContext context) {
    // On retourne directement l'interface, sans créer un nouveau MaterialApp
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
  //StreamSubscription? _sub; // Pour écouter les deep links

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener(); // Démarrer l'écouteur au chargement du widget
  }

  @override
  void dispose() {
    _sub?.cancel(); // Arrêter l'écouteur pour éviter les fuites de mémoire
    super.dispose();
  }

  // ✅ Logique pour écouter le retour de PayPal
  // Cette fonction configure l'écouteur de deep link
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
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
              },
            ),
          ],
        );
      },
    );
  }

  Stream<List<Article>> _getPanierArticles() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('User').doc(userId);

    return userRef.snapshots().asyncMap((doc) async {
      if (!doc.exists || !doc.data()!.containsKey('panier')) return [];

      List<String> panierIds = List<String>.from(doc.data()!['panier']);
      if (panierIds.isEmpty) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('article')
          .where(FieldPath.documentId, whereIn: panierIds)
          .get();

      return snapshot.docs.map((d) {
        return Article.fromMap({...d.data(), 'idArticle': d.id});
      }).toList();
    });
  }

  Future<void> _removeFromPanier(String articleId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('User').doc(userId);

    await userRef.update({
      'panier': FieldValue.arrayRemove([articleId]),
    });
  }

  // ✅ Fonction pour vider le panier après le paiement
  Future<void> _viderPanierApresPaiement() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('User').doc(userId);

    // Mettre à jour le champ 'panier' avec un tableau vide
    await userRef.update({'panier': []});
  }

  double _calculateTotal(List<Article> panier) {
    return panier.fold(0.0, (sum, item) => sum + item.prix);
  }

  void _onTabTapped(int index) {
    // La navigation doit être cohérente
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
        // On est déjà sur la page, pas besoin de naviguer
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
        child: StreamBuilder<List<Article>>(
          stream: _getPanierArticles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "Votre panier est vide.",
                  style: GoogleFonts.inriaSerif(fontSize: 18),
                ),
              );
            }
            final panier = snapshot.data!;
            final totalEnAr = _calculateTotal(panier);

            // ⚠️ TODO: Convertir le total en USD avant de l'envoyer à PayPal
            // Par exemple: final totalEnUSD = totalEnAr / TAUX_DE_CHANGE;
            final totalEnUSD = totalEnAr / 4500; // Exemple avec un taux fixe

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 70),
                Text(
                  "Panier (${panier.length} articles)",
                  style: GoogleFonts.inriaSerif(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2A51A6),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: panier.length,
                    itemBuilder: (context, index) {
                      final article = panier[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Hero(
                            tag: article.idArticle,
                            child: Image.network(article.image, width: 50),
                          ),
                          title: Text(article.nom),
                          subtitle: Text("${article.prix} Ar"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.black54,
                                ),
                                onPressed: () =>
                                    _removeFromPanier(article.idArticle),
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
                  "Total : ${totalEnAr.toStringAsFixed(2)} Ar", // `totalEnAr` est déjà calculé
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                //total en usd
                Text(
                  "(environ ${totalEnUSD.toStringAsFixed(2)} USD)", // Affiche la conversion
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade700, // Couleur plus discrète
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A51A6),
                    // Grise le bouton si le total est 0
                    disabledBackgroundColor: Colors.grey,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  // La fonction onPressed est `null` si le total est 0, ce qui désactive le bouton
                  onPressed: totalEnUSD <= 0
                      ? null
                      : () async {
                          //final paypal = PayPalService();
                          final paypal = PayPalService(clientId: cliid, secret: sct);
                          final approvalUrl = await paypal.createOrder(
                            totalEnUSD,
                          );

                              if(approvalUrl != null){
                                try{
                                  await launchUrl(
                                    Uri.parse(approvalUrl),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }catch(e){
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Impossible d'ouvir la page de payement "),
                                      )
                                  );
                                }
                              }
                          // if (approvalUrl != null &&
                          //     await canLaunchUrl(Uri.parse(approvalUrl))) {
                          //   await launchUrl(
                          //     Uri.parse(approvalUrl),
                          //     mode: LaunchMode.externalApplication,
                          //   );
                          // } else {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     const SnackBar(
                          //       content: Text(
                          //         "Erreur lors de la création de la commande PayPal.",
                          //       ),
                          //     ),
                          //   );
                          // }
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
