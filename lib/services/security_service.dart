// lib/services/security_service.dart

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
// IMPORTS POUR MAILER (assurez-vous qu'ils sont présents)
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

class SecurityService {
  // Canaux de communication avec le code natif Android
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.ma_surveillance_app/device_admin_method');
  static const EventChannel _eventChannel =
      EventChannel('com.example.ma_surveillance_app/unlock_attempts_event');

  late List<CameraDescription> _cameras;
  bool _camerasInitialized = false;

  SecurityService() {
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
      _camerasInitialized = true;
    } catch (e) {
      // ignore_for_file: avoid_print
      print("Erreur lors de l'initialisation des caméras: $e");
      _camerasInitialized = false;
    }
  }

  /// Active l'administrateur d'appareil via le canal de méthode natif.
  Future<String> activateDeviceAdmin() async {
    try {
      final String result =
          await _methodChannel.invokeMethod('activateDeviceAdmin');
      return result;
    } on PlatformException catch (e) {
      return "Échec de l'activation de l'administrateur d'appareil: ${e.message}";
    }
  }

  /// Vérifie si l'administrateur d'appareil est actif.
  Future<bool> isDeviceAdminActive() async {
    try {
      final bool isActive =
          await _methodChannel.invokeMethod('isDeviceAdminActive');
      return isActive;
    } on PlatformException catch (e) {
      print(
          "Erreur lors de la vérification du statut de l'administrateur d'appareil: ${e.message}");
      return false;
    }
  }

  /// Écoute les événements de tentatives de déverrouillage échouées depuis le canal d'événements natif.
  Stream<String> listenToUnlockAttempts() {
    return _eventChannel
        .receiveBroadcastStream()
        .map((data) => data.toString());
  }

  /// Prend une photo silencieuse avec la caméra frontale.
  Future<String?> takeSilentPhoto() async {
    if (!_camerasInitialized || _cameras.isEmpty) {
      print('Caméras non initialisées ou non disponibles.');
      return null;
    }

    final frontCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first, // Fallback si pas de caméra frontale
    );

    final CameraController controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false, // Tente de désactiver le son de capture si possible
    );

    try {
      await controller.initialize();
      final path = join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      final XFile file = await controller.takePicture();
      await file.saveTo(path); // Sauvegarder la photo
      await controller.dispose(); // Libérer la caméra

      print('Photo prise et sauvegardée à : $path');
      return path;
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  /// Obtient la position GPS actuelle.
  Future<String> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Les services de localisation sont désactivés.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Les permissions de localisation sont refusées.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Les permissions de localisation sont refusées à jamais. Veuillez les activer dans les paramètres.';
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit:
              const Duration(seconds: 20)); // <-- DÉLAI AUGMENTÉ À 20 SECONDES
      return 'Lat: ${position.latitude}, Lng: ${position.longitude}';
    } catch (e) {
      // Afficher plus de détails si c'est un TimeoutException
      if (e is TimeoutException) {
        return 'Erreur lors de l\'obtention de la localisation: Délai dépassé (${e.message ?? "Aucun message"}). Vérifiez le signal GPS et les permissions.';
      }
      return 'Erreur lors de l\'obtention de la localisation: $e';
    }
  }

  /// Envoie un email avec une pièce jointe via SMTP (envoi automatique).
  Future<void> sendEmailWithAttachment(String recipientEmail, String subject,
      String body, String? attachmentPath) async {
    // TRÈS IMPORTANT : REMPLACEZ 'VOTRE_MOT_DE_PASSE_APPLICATION_GMAIL' par le mot de passe à 16 caractères généré.
    final smtpServer =
        gmail('Aliyoussoufali235@gmail.com', 'pjgk qvmz tvqp vqqx');

    final message = Message()
      ..from =
          const Address('Aliyoussoufali235@gmail.com', 'Ma Surveillance App')
      ..recipients.add(recipientEmail)
      ..subject = subject
      ..text = body;

    if (attachmentPath != null && File(attachmentPath).existsSync()) {
      message.attachments.add(FileAttachment(File(attachmentPath)));
      print('Pièce jointe ajoutée: $attachmentPath');
    } else {
      print('Aucune pièce jointe ou fichier non trouvé à: $attachmentPath');
    }

    try {
      final sendReport = await send(message, smtpServer);

      // Ancien code (qui causait l'erreur 'results' et 'SendingStatus') :
      // bool allSentSuccessfully = true;
      // if (sendReport.results != null && sendReport.results.isNotEmpty) {
      //   for (final result in sendReport.results) {
      //     if (result.status != SendingStatus.success) {
      //       allSentSuccessfully = false;
      //       print('Problème lors de l\'envoi à ${result.recipient}: Statut: ${result.status}, Message: ${result.message}');
      //     }
      //   }
      // } else {
      //   print('Le rapport d\'envoi ne contient pas de résultats individuels.');
      // }

      // NOUVEAU CODE : On se base uniquement sur l'absence d'exception pour le succès.
      print(
          'Email envoyé avec succès à $recipientEmail (vérifié par absence d\'exception Mailer)');
    } on MailerException catch (e) {
      print(
          'Erreur Mailer: Échec de l\'envoi de l\'email à $recipientEmail. ${e.message}');
      for (var p in e.problems) {
        print('Problème spécifique de MailerException: ${p.code}: ${p.msg}');
      }
    } catch (e) {
      print(
          'Une erreur inattendue est survenue lors de l\'envoi de l\'email: $e');
    }
  }
}
