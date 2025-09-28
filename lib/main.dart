import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ma_surveillance_app/services/security_service.dart';

void main() {
  // Assurez-vous que les bindings Flutter sont initialisés avant de lancer l'application
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ma Surveillance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Activez l'intégration Material 3 si vous le souhaitez
        // useMaterial3: true,
      ),
      home: const SecurityHomePage(),
    );
  }
}

class SecurityHomePage extends StatefulWidget {
  const SecurityHomePage({super.key});

  @override
  State<SecurityHomePage> createState() => _SecurityHomePageState();
}

class _SecurityHomePageState extends State<SecurityHomePage> {
  final SecurityService _securityService = SecurityService();
  bool _isDeviceAdminActive = false;
  String _statusMessage = "Application prête.";
  String _lastEvent = "Aucun événement récent.";
  // Pré-remplissez l'email de destination ici.
  // Assurez-vous que cette adresse est valide et que vous y avez accès.
  final TextEditingController _emailController =
      TextEditingController(text: "votre_email_cible@example.com");

  @override
  void initState() {
    super.initState();
    _checkDeviceAdminStatus();
    _listenToUnlockAttempts();
  }

  /// Vérifie si l'administrateur d'appareil est actif au démarrage.
  Future<void> _checkDeviceAdminStatus() async {
    bool isActive = await _securityService.isDeviceAdminActive();
    setState(() {
      _isDeviceAdminActive = isActive;
      _statusMessage = isActive
          ? "Administrateur d'appareil activé."
          : "Administrateur d'appareil désactivé.";
    });
  }

  /// Active l'administrateur d'appareil en appelant la méthode native.
  Future<void> _activateDeviceAdmin() async {
    try {
      String result = await _securityService.activateDeviceAdmin();
      setState(() {
        _statusMessage = result;
      });
      // Donnez un petit délai pour que le système mette à jour le statut,
      // puis vérifiez à nouveau.
      await Future.delayed(const Duration(seconds: 2));
      _checkDeviceAdminStatus();
    } on PlatformException catch (e) {
      setState(() {
        _statusMessage = "Erreur lors de l'activation: ${e.message}";
      });
    }
  }

  /// Écoute les tentatives de déverrouillage échouées depuis le service natif.
  void _listenToUnlockAttempts() {
    _securityService.listenToUnlockAttempts().listen((event) async {
      setState(() {
        _lastEvent = "Nouvel événement: $event";
        _statusMessage = "Détection d'une tentative de déverrouillage.";
      });

      // 1. Prendre une photo silencieuse
      String? photoPath = await _securityService.takeSilentPhoto();
      // 2. Obtenir la localisation actuelle
      String location = await _securityService.getLocation();

      // 3. Préparer le contenu de l'email
      String subject =
          "Alerte de sécurité - Tentative de déverrouillage échouée";
      String body =
          "Une tentative de déverrouillage de votre téléphone a échoué.\n"
          "Événement détecté: $event\n"
          "Localisation: $location\n";

      if (photoPath != null) {
        body +=
            "Une photo a été prise. Elle devrait être jointe à cet email.\n";
        body += "Chemin local de la photo (pour information) : $photoPath";
      } else {
        body += "Aucune photo n'a pu être prise ou sauvegardée.\n";
      }

      // 4. Envoyer l'email automatiquement avec la photo jointe (via mailer)
      if (_emailController.text.isNotEmpty) {
        await _securityService.sendEmailWithAttachment(
            // Appel de la fonction d'envoi automatique
            _emailController.text,
            subject,
            body,
            photoPath); // On passe le chemin de la photo
        setState(() {
          _statusMessage = "Alerte de sécurité envoyée automatiquement !";
        });
      } else {
        setState(() {
          _statusMessage =
              "Adresse email non configurée, impossible d'envoyer l'alerte.";
        });
      }
    }, onError: (error) {
      setState(() {
        _statusMessage = "Erreur de détection: $error";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Surveillance App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statut de l\'application:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email de destination",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isDeviceAdminActive ? null : _activateDeviceAdmin,
              child: Text(_isDeviceAdminActive
                  ? 'Administrateur d\'appareil ACTIF'
                  : 'Activer l\'administrateur d\'appareil'),
            ),
            const SizedBox(height: 24),
            Text(
              'Dernier événement détecté:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _lastEvent,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Instructions:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Cliquez sur "Activer l\'administrateur d\'appareil" et suivez les instructions.\n'
              '2. Assurez-vous que l\'application a les permissions pour la caméra et la localisation.\n'
              '3. Verrouillez votre téléphone et entrez plusieurs fois un mauvais code pour tester.\n'
              '4. L\'email avec la photo et la localisation devrait être envoyé automatiquement.',
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ ATTENTION : Si l\'email n\'arrive pas, vérifiez le dossier SPAM et assurez-vous que le "Mot de passe d\'application" GMail est correct.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
