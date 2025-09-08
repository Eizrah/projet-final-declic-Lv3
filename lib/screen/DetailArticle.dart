import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:semaine6/modele/Article.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Detailarticle extends StatefulWidget {
  final Article article;

  const Detailarticle({super.key, required this.article});

  @override
  State<Detailarticle> createState() => _DetailarticleState();
}

class _DetailarticleState extends State<Detailarticle>
    with SingleTickerProviderStateMixin {
  final TextEditingController quantiteController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final favRef = FirebaseFirestore.instance
        .collection('User')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('favoris')
        .doc(widget.article.idArticle);

    final doc = await favRef.get();
    if (doc.exists) {
      await favRef.delete();
    } else {
      await favRef.set(widget.article.toJson());
    }
  }





// fonction pour ajouter  les articles
Future<void> _addToPanier(int quantite) async {
  // Vérification que la quantité est positive
  if (quantite <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("La quantité doit être supérieure à 0."),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return; // Sécurité pour s'assurer que l'utilisateur est connecté

  final userRef = FirebaseFirestore.instance.collection('User').doc(user.uid);

  try {
    // Utilisation d'une transaction pour garantir la fiabilité de l'opération
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);

      // On récupère le panier existant ou on en crée un nouveau.
      // Le '?? []' gère le cas où le champ 'panier' n'existe pas encore.
      final panierData = userDoc.data()?['panier'] ?? [];
      
      // On s'assure de manipuler une liste de maps
      final panier = List<Map<String, dynamic>>.from(panierData);

      final existingItemIndex =
          panier.indexWhere((item) => item['id'] == widget.article.idArticle);

      if (existingItemIndex != -1) {
        // L'article existe déjà : on met à jour la quantité
        panier[existingItemIndex]['quantite'] += quantite;
      } else {
        // L'article n'existe pas : on l'ajoute à la liste
        panier.add({'id': widget.article.idArticle, 'quantite': quantite});
      }

      // On utilise 'set' avec 'merge: true' dans la transaction.
      // C'est la méthode la plus sûre pour créer le champ s'il n'existe pas
      // ou le mettre à jour sans écraser les autres données de l'utilisateur.
      transaction.set(userRef, {'panier': panier}, SetOptions(merge: true));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ajouté au panier : ${widget.article.nom} x$quantite"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print("Erreur détaillée lors de l'ajout au panier : $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Une erreur est survenue. Vérifiez la console pour les détails."),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SizedBox(
            height: size.height * 0.5,
            width: double.infinity,
            child: Hero(
              tag: widget.article.idArticle,
              child: Image.network(
                widget.article.image,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            top: 40,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('User')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('favoris')
                    .doc(widget.article.idArticle)
                    .snapshots(),
                builder: (context, snapshot) {
                  final isFav = snapshot.hasData && snapshot.data!.exists;
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: _toggleFavorite,
                  );
                },
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _animation,
              child: Container(
                height: size.height * 0.5,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.article.nom,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "${widget.article.prix.toStringAsFixed(0)} Ar",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          widget.article.description,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Text("Quantité : ",
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          height: 38,
                          child: TextField(
                            controller: quantiteController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "1",
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final quantite =
                              int.tryParse(quantiteController.text) ?? 1;
                          _addToPanier(quantite);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Ajouter au panier",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}