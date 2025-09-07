import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:semaine6/modele/Article.dart';
import 'package:semaine6/screen/DetailArticle.dart';
import 'package:semaine6/screen/Favlist.dart';
import 'package:semaine6/screen/Panier.dart';
import 'package:semaine6/screen/Profil.dart';

class Homea extends StatefulWidget {
  const Homea({super.key});

  @override
  State<Homea> createState() => _HomeaState();
}

class _HomeaState extends State<Homea> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _search = TextEditingController();

  String _searchQuery = ''; // 👈 Variable d'état pour la recherche

  int _currentIndex = 0;

  final List<String> imgList = [
    'assets/images/J1Low.jpeg',
    'assets/images/J1Lowvert.jpeg',
    'assets/images/jone.jpeg',
    'assets/images/jordan42.jpeg',
  ];

  final Color _backgroundColor = Colors.grey[100]!;
  final Color _selectedItemColor = const Color(0xFF2A51A6);
  final Color _unselectedItemColor = Colors.grey;

  Set<String> favoriteIds = {}; // ids des articles favoris

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favSnapshot = await _firestore
        .collection('User')
        .doc(userId)
        .collection('favoris')
        .get();

    setState(() {
      favoriteIds = favSnapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  //fonction ajoute à favoris
  void toggleFavorite(String articleId, Article article) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favRef = _firestore.collection('User').doc(userId).collection('favoris');

    final doc = await favRef.doc(articleId).get();

    if (doc.exists) {
      // Supprimer des favoris
      await favRef.doc(articleId).delete();
    } else {
      // Ajouter aux favoris
      await favRef.doc(articleId).set(article.toJson());
    }
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon,
      String label,
      int index,
      ) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _currentIndex == index
              ? _selectedItemColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);

    Widget page;
    if (index == 0)
      page = const Homea();
    else if (index == 1)
      page = const Favlist();
    else if (index == 2)
      page = const Panier();
    else
      page = const Profil();

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 231, 231, 235),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "E-Shop",
                    style: GoogleFonts.inriaSerif(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A51A6),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _search,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value; // à revoir ici 
                        });
                      },
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.search_sharp),
                        labelText: 'Rechercher',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        filled: true,
                        fillColor: Color(0xFFFAF8F8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CarouselSlider(
                    options: CarouselOptions(
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      aspectRatio: 16 / 9,
                      enlargeCenterPage: true,
                      viewportFraction: 0.9,
                    ),
                    items: imgList
                        .map(
                          (item) => ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(15),
                            ),
                            child: Image.asset(
                              item,
                              fit: BoxFit.cover,
                              width: 1000,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _searchQuery.isEmpty
                    ? _firestore.collection('article').snapshots()
                    : _firestore
                        .collection('article')
                        .where('nom', isGreaterThanOrEqualTo: _searchQuery)
                        .where('nom', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("❌ Une erreur est survenue"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final articleDocs = snapshot.data!.docs;
                  if (articleDocs.isEmpty && _searchQuery.isNotEmpty) {
                    return const Center(child: Text("Aucun article trouvé pour cette recherche."));
                  } else if (articleDocs.isEmpty) {
                    return const Center(child: Text("Aucun article disponible"));
                  }

                  final articles = articleDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final article = Article.fromMap({...data, 'idArticle': doc.id});
                    return article;
                  }).toList();

                  return ResponsiveGridList(
                    horizontalGridSpacing: 16,
                    verticalGridSpacing: 16,
                    minItemWidth: 180,
                    minItemsPerRow: 2,
                    children: articles.map((article) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Detailarticle(article: article),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: article.image.startsWith("http")
                                    ? Image.network(
                                        article.image,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        article.image,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.nom,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${article.prix.toStringAsFixed(0)} Ar",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            favoriteIds.contains(article.idArticle)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            final userId = FirebaseAuth.instance.currentUser!.uid;
                                            final favRef = FirebaseFirestore.instance.collection('User').doc(userId).collection('favoris');

                                            if (favoriteIds.contains(article.idArticle)) {
                                              await favRef.doc(article.idArticle).delete();
                                              setState(() {
                                                favoriteIds.remove(article.idArticle);
                                              });
                                            } else {
                                              await favRef.doc(article.idArticle).set(article.toJson());
                                              setState(() {
                                                favoriteIds.add(article.idArticle);
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
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
          selectedItemColor: _selectedItemColor,
          unselectedItemColor: _unselectedItemColor,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }
}