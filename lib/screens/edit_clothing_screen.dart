import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:io';

import '../models/user.dart';
import '../models/clothing_item.dart';

class EditClothingScreen extends StatefulWidget {
  final User user;
  final ClothingItem clothingItem;
  final Function(ClothingItem) onUpdate;

  const EditClothingScreen({
    super.key,
    required this.user,
    required this.clothingItem,
    required this.onUpdate,
  });

  @override
  EditClothingScreenState createState() => EditClothingScreenState();
}

class EditClothingScreenState extends State<EditClothingScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _category;
  late String _color;
  File? _imageFile;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = widget.clothingItem.name;
    _category = widget.clothingItem.category;
    _color = widget.clothingItem.color;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    String imageUrl = widget.clothingItem.imageUrl;

    if (_imageFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('wardrobe_images')
          .child('${widget.clothingItem.id}.jpg');

      // Log current auth and App Check token presence to help diagnose failures
      final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
      debugPrint('Current user uid: ${currentUser?.uid}');
      final appCheckToken = await FirebaseAppCheck.instance.getToken(false);
      final appCheckTokenPresent =
          appCheckToken != null && appCheckToken.toString().isNotEmpty && appCheckToken.toString() != 'null';
      debugPrint('AppCheck token present: $appCheckTokenPresent');

      if (currentUser == null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez être connecté pour ajouter une image.')),
        );
        return;
      }

      try {
        final TaskSnapshot snapshot = await storageRef.putFile(_imageFile!);
        debugPrint('Upload completed: state=${snapshot.state}, bytesTransferred=${snapshot.bytesTransferred}/${snapshot.totalBytes}');
        debugPrint('Snapshot ref fullPath: ${snapshot.ref.fullPath}');
        debugPrint('Snapshot ref bucket: ${snapshot.ref.bucket ?? FirebaseStorage.instance.ref().bucket}');
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
      } on FirebaseException catch (e) {
        debugPrint('Storage FirebaseException: ${e.code} - ${e.message}');
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload image : ${e.message ?? e.code}')),
        );
        return;
      } catch (e) {
        debugPrint('Upload failed: $e');
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur upload image')),
        );
        return;
      }
    }

    final updatedItem = widget.clothingItem.copyWith(
      name: _name,
      category: _category,
      color: _color,
      imageUrl: imageUrl,
    );

    await FirebaseFirestore.instance
        .collection('clothing_items')
        .doc(widget.clothingItem.id)
        .update({
      'name': updatedItem.name,
      'category': updatedItem.category,
      'color': updatedItem.color,
      'imageUrl': updatedItem.imageUrl,
    });

    widget.onUpdate(updatedItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier un vêtement')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                      onSaved: (value) => _name = value!,
                    ),

                    TextFormField(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                      onSaved: (value) => _category = value ?? '',
                    ),

                    TextFormField(
                      initialValue: _color,
                      decoration: const InputDecoration(labelText: 'Couleur'),
                      onSaved: (value) => _color = value ?? '',
                    ),

                    const SizedBox(height: 20),

                    // Image affichée
                    _imageFile != null
                        ? Image.file(
                            _imageFile!,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : widget.clothingItem.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.clothingItem.imageUrl,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 150,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child:
                                    const Text('Aucune image disponible'),
                              ),

                    const SizedBox(height: 10),

                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Choisir depuis la galerie'),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _saveForm,
                      child: const Text('Mettre à jour'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
