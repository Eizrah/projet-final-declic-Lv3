// Payement.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Import pour kDebugMode

// --- Sécurité Améliorée ---
// TODO: NE JAMAIS stocker les identifiants en clair dans le code.
// Utilisez des variables d'environnement pour plus de sécurité.
const String cliid = "AbTFQpZlme5A6-PZYhMsnqtqZD0d2JtDYaTkQuZkC25mXKVxEiFqgT_TRJGn2fo614KYTSQfyMcJfaP7";
const String sct = "EOEc21HpVE_cZzazLbvZkjHJbw9QadEijdGmw5SOmV68sVvwU92c6otYG4e2cX3qZ5_7I7j4POGuohf2";

class PayPalService {
  final String clientId;
  final String secret;
  final String baseUrl = "https://api-m.sandbox.paypal.com"; // URL pour le mode test

  // --- Constructeur ---
  // Permet de fournir les identifiants lors de la création du service.
  PayPalService({required this.clientId, required this.secret});

  /// Obtient un token d'accès OAuth2 auprès de l'API PayPal.
  Future<String?> _getAccessToken() async {
    try {
      final basicAuth = 'Basic ${base64Encode(utf8.encode('$clientId:$secret'))}';
      final response = await http.post(
        Uri.parse("$baseUrl/v1/oauth2/token"),
        headers: {
          "Authorization": basicAuth,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: "grant_type=client_credentials",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["access_token"];
      } else {
        // --- Amélioration du log d'erreur ---
        // Affiche le statut et le corps de la réponse pour un débogage facile.
        if (kDebugMode) {
          print("Erreur d'obtention du token: ${response.statusCode}");
          print("Réponse de l'API: ${response.body}");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Exception lors de l'obtention du token: $e");
      }
      return null;
    }
  }

  /// Crée une commande PayPal et retourne l'URL d'approbation pour le paiement.
  Future<String?> createOrder(double amount) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      if (kDebugMode) {
        print("Impossible de créer la commande car le token d'accès est nul.");
      }
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v2/checkout/orders"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "intent": "CAPTURE",
          "purchase_units": [
            {
              "amount": {
                "currency_code": "USD", // Assurez-vous que c'est la bonne devise
                // --- Correction Critique ---
                // S'assure que le montant est toujours une chaîne avec deux décimales.
                "value": amount.toStringAsFixed(2),
              },
            },
          ],
          "application_context": {
            "return_url": "eshop://paypalpay/success",
            "cancel_url": "eshop://paypalpay/cancel",
            "user_action": "PAY_NOW",
          },
        }),
      );

      if (response.statusCode == 201) { // 201 Created est le code de succès
        final data = jsonDecode(response.body);
        final links = data["links"] as List?; // Rendre la liste nullable

        if (links != null) {
          final approveUrl = links.firstWhere(
            (link) => link["rel"] == "approve",
            orElse: () => null,
          );

          if (approveUrl != null && approveUrl["href"] != null) {
            return approveUrl["href"];
          }
        }
        if (kDebugMode) {
          print("Le lien d'approbation est introuvable dans la réponse.");
        }
        return null; // Retourne null si le lien n'est pas trouvé
      } else {
        // --- Amélioration du log d'erreur ---
        if (kDebugMode) {
          print("Erreur lors de la création de la commande: ${response.statusCode}");
          print("Réponse de l'API: ${response.body}");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Exception lors de la création de la commande: $e");
      }
      return null;
    }
  }
}