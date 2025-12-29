import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_app_check/firebase_app_check.dart';

import '../models/user.dart';
import '../models/clothing_item.dart';

class AddClothingScreen extends StatefulWidget {
  final User user;
  final Function(ClothingItem) onAdd;

  const AddClothingScreen({super.key, required this.user, required this.onAdd});

  @override
  AddClothingScreenState createState() => AddClothingScreenState();
}

class AddClothingScreenState extends State<AddClothingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _category = '';
  String _color = '';
  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Vérification utilisateur connecté
    final fb_auth.User? currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun utilisateur n'est connecté.")),
      );
      return;
    }

    String imageUrl = '';

    if (_imageFile != null) {
      // Log auth and App Check state
      debugPrint('Current user uid: ${currentUser.uid}');
      final appCheckToken = await FirebaseAppCheck.instance.getToken(false);
      final appCheckTokenPresent =
          appCheckToken != null && appCheckToken.toString().isNotEmpty && appCheckToken.toString() != 'null';
      debugPrint('AppCheck token present: $appCheckTokenPresent');

      try {
        
        final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://closetbuddy27.firebasestorage.app',
        );

        final storageRef = storage
            .ref()
            .child('users')
            .child(currentUser.uid)
            .child('wardrobe')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        debugPrint('Bucket utilisé: ${storageRef.bucket}');
        debugPrint('Chemin complet: ${storageRef.fullPath}');

        final localSize = await _imageFile!.length();
        debugPrint('Taille du fichier local: $localSize bytes');
        if (localSize == 0) {
          throw Exception('Fichier local vide');
        }

        final metadata = SettableMetadata(contentType: 'image/jpeg');

        final TaskSnapshot snapshot = await storageRef.putFile(_imageFile!, metadata).whenComplete(() {});
        debugPrint('Upload completed: state=${snapshot.state}, bytes=${snapshot.bytesTransferred}/${snapshot.totalBytes}');

        final meta = await storageRef.getMetadata();
        debugPrint('getMetadata success: fullPath=${meta.fullPath}, size=${meta.size}');

        imageUrl = await storageRef.getDownloadURL();
        debugPrint('Download URL: $imageUrl');

        debugPrint('Upload completed: state=${snapshot.state}, bytesTransferred=${snapshot.bytesTransferred}/${snapshot.totalBytes}');
        debugPrint('Snapshot ref fullPath: ${snapshot.ref.fullPath}');
        debugPrint('Snapshot ref bucket: ${snapshot.ref.bucket}');
        try {
          final meta = await snapshot.ref.getMetadata();
          debugPrint('getMetadata success: fullPath=${meta.fullPath}, size=${meta.size}');
        } on FirebaseException catch (metaErr) {
          debugPrint('getMetadata failed: ${metaErr.code} - ${metaErr.message}');
        } catch (metaErr) {
          debugPrint('getMetadata unexpected error: $metaErr');
        }

        // Try to fetch download URL; retry briefly on object-not-found (transient)
        try {
          imageUrl = await snapshot.ref.getDownloadURL();
          debugPrint('Download URL: $imageUrl');
        } on FirebaseException catch (e) {
          if (e.code == 'object-not-found') {
            debugPrint('getDownloadURL returned object-not-found; retrying...');
            bool got = false;
            for (int i = 0; i < 5; i++) {
              await Future.delayed(const Duration(milliseconds: 500));
              try {
                imageUrl = await snapshot.ref.getDownloadURL();
                got = true;
                debugPrint('Download URL after retry: $imageUrl');
                break;
              } catch (e) {
                // ignore and retry
              }
            }
            if (!got) rethrow;
          } else {
            rethrow;
          }
        }
      } on FirebaseException catch (e, stack) {
        debugPrint("Storage FirebaseException: ${e.code} - ${e.message}");
        debugPrint(stack.toString());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload image : ${e.message ?? e.code}')),
        );
        return;
      } catch (e, stack) {
        debugPrint("Erreur upload image : $e");
        debugPrint(stack.toString());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi de l'image.")),
        );
        return;
      }
    }

    final newItem = ClothingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser.uid,
      name: _name,
      category: _category,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : '',
      color: _color,
    );

    try {
      await FirebaseFirestore.instance.collection('clothing_items').add({
        "id": newItem.id,
        "name": newItem.name,
        "category": newItem.category,
        "imageUrl": newItem.imageUrl,
        "color": newItem.color,
        "userId": currentUser.uid,
      });

      widget.onAdd(newItem);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Erreur Firestore : $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'enregistrement.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un vêtement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom du vêtement'),
                validator: (v) =>
                    v == null || v.isEmpty ? "Nom requis" : null,
                onSaved: (v) => _name = v!,
              ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Catégorie'),
                onSaved: (v) => _category = v ?? '',
              ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Couleur'),
                onSaved: (v) => _color = v ?? '',
              ),

              const SizedBox(height: 20),

              _imageFile != null
                  ? Image.file(_imageFile!, height: 150, fit: BoxFit.cover)
                  : const Text("Aucune image sélectionnée"),

              TextButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text("Choisir une image"),
                onPressed: _pickImage,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveForm,
                child: const Text("Ajouter"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
