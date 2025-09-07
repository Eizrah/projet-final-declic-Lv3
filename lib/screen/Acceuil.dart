import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:semaine6/screen/Login.dart';

class Acceuil extends StatelessWidget {
  const Acceuil({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Acceuil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(0, 11, 75, 214)),
      ),
      home: const InterfaceAcc(),
    );
  } 
}

class InterfaceAcc extends StatefulWidget {
  const InterfaceAcc({super.key});

  @override
  State<InterfaceAcc> createState() => _InterfaceAccState();
}

class _InterfaceAccState extends State<InterfaceAcc> with SingleTickerProviderStateMixin {
  late AnimationController _controller; //initialise un controlleur d'animation
  late List<Animation<double>> _dotAnimations; // initialise une liste d'animation
  bool _showLogin = false;

  @override
  void initState() {
    super.initState();
    
    // Initialiser le contrôleur d'animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Créer des animations pour chaque point
    _dotAnimations = List.generate(3, (index) {
      final delay = index * 200; // Délai pour chaque point
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            delay / 1500,
            1.0,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
    
    // Simuler une vérification de connexion
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    // Simuler un délai de vérification de connexion
    await Future.delayed(const Duration(seconds: 3));
    
    // Arrêter l'animation
    _controller.stop();
    
    // Afficher l'écran de connexion
    setState(() {
      _showLogin = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si la vérification est terminée, afficher l'écran de connexion
    if (_showLogin) {
      return Login(); // Remplacez par votre écran de connexion
    }
    
    // Sinon, afficher l'animation de chargement
    return Scaffold(
      backgroundColor: const Color(0xFF2A51A6), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo E-Shop
            RichText(
              text: TextSpan(
                text: "E-",
                style: GoogleFonts.inriaSerif(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: "Shop",
                    style: GoogleFonts.inriaSerif(
                      color: const Color.fromARGB(255, 247, 247, 247),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Animation des points
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _dotAnimations[index],
                  builder: (context, child) {
                    return Opacity(
                      opacity: _dotAnimations[index].value,
                      child: Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

