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

class _DetailarticleState extends State<Detailarticle> {
  final TextEditingController quantiteController = TextEditingController();

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

  Future<void> _addToPanier(int quantite) async {
    final userRef = FirebaseFirestore.instance
        .collection('User')
        .doc(FirebaseAuth.instance.currentUser!.uid);

    await userRef.update({
      'panier': FieldValue.arrayUnion([widget.article.idArticle]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ajouté au panier : ${widget.article.nom} x$quantite"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ✅ Image avec Hero
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

          // ✅ Bouton retour
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

          // ✅ Bouton favoris
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

          // ✅ Bloc détails en bas
          Align(
            alignment: Alignment.bottomCenter,
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
                  // Nom + Prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.article.nom,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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

                  // Description
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.article.description,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quantité
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

                  // Bouton
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
        ],
      ),
    );
  }
}
