import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:semaine6/screen/Login.dart';

class Mdpforget extends StatelessWidget {
  const Mdpforget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mot de passe oublié',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(0, 11, 75, 214),
        ),
      ),
      home: const InterfaceMdpF(),
    );
  }
}

class InterfaceMdpF extends StatefulWidget {
  const InterfaceMdpF({super.key});

  @override
  State<InterfaceMdpF> createState() => _InterfaceMdpFState();
}

class _InterfaceMdpFState extends State<InterfaceMdpF> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Email de réinitialisation envoyé ✅ Vérifiez votre boîte mail"),
        ),
      );

      // Optionnel : retourner à l'écran de login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Erreur lors de l'envoi de l'email";
      if (e.code == 'user-not-found') {
        message = "Aucun utilisateur trouvé avec cet email ❌";
      } else if (e.code == 'invalid-email') {
        message = "Email invalide ❌";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 231, 231, 235),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 231, 231, 235),
      body: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "E-Shop",
              style: GoogleFonts.inriaSerif(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2A51A6),
              ),
            ),
            const SizedBox(height: 100),
            const Text(
              "Veuillez entrer votre adresse email pour réinitialiser votre mot de passe",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 120),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Email field
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!value.contains('@')) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 50),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 32, 88, 219),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(330, 50),
                          ),
                          onPressed: _sendPasswordResetEmail,
                          child: const Text('Valider'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
