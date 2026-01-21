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
  String _mainCategory = '';
  String _subCategory = '';
  String _color = '';
  String _selectedSeason = 'Toutes saisons';
  String _occasion = 'casual';
  File? _imageFile;
  List<String> _subCategoryOptions = [];
  final List<String> _mainCategories = ['Haut', 'Bas', 'Chaussures', 'Accessoires'];
  final Map<String, List<String>> _subCategoriesMap = {
    'Haut': ['T-shirt', 'Pull', 'Chemise', 'Veste'],
    'Bas': ['Jean', 'Jupe', 'Pantalon', 'Short'],
    'Chaussures': ['Baskets', 'Bottes', 'Sandales', 'Talons'],
    'Accessoires': ['Ceinture', 'Sac', 'Chapeau'],
  };
  final List<String> _colorOptions = ['Rouge', 'Bleu', 'Vert', 'Noir', 'Blanc', 'Jaune', 'Violet', 'Orange', 'Rose', 'Gris', 'Marron', 'Multicoulore'];
  final Map<String, Color> _colorMap = {
    'Rouge': Colors.red,
    'Bleu': Colors.blue,
    'Vert': Colors.green,
    'Noir': Colors.black,
    'Blanc': Colors.white,
    'Jaune': Colors.yellow,
    'Violet': Colors.purple,
    'Orange': Colors.orange,
    'Rose': Colors.pink,
    'Gris': Colors.grey,
    'Marron': Colors.brown,
    'Multicoulore': Colors.transparent,
  };
  final Map<String, String> _occasionMap = {
    'casual': 'Décontracté',
    'formal': 'Formel',
    'sport': 'Sportif',
    'party': 'Fête',
  };
  final List<String> _seasonOptions = ['Toutes saisons', 'Hiver', 'Printemps', 'Eté', 'Automne'];


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
      mainCategory: _mainCategory,
      subCategory: _subCategory,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : '',
      color: _color,
      occasion: _occasion,
      season: _selectedSeason,
    );

    try {
      await FirebaseFirestore.instance.collection('clothing_items').add({
        "id": newItem.id,
        "name": newItem.name,
        "mainCategory": newItem.mainCategory,
        "subCategory": newItem.subCategory,
        "imageUrl": newItem.imageUrl,
        "color": newItem.color,
        "userId": currentUser.uid,
        "occasion": newItem.occasion,
        "season" : newItem.season,
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

              Text('Couleur', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colorOptions.map((colorName) {
                  final color = _colorMap[colorName]!;
                  final isSelected = _color == colorName;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _color = colorName;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }).toList(),
              ),


              DropdownButtonFormField<String>(
                initialValue: _mainCategory.isEmpty ? null : _mainCategory,
                decoration: const InputDecoration(labelText: 'Catégorie principale'),
                items: _mainCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _mainCategory = val ?? '';
                    _subCategoryOptions = _subCategoriesMap[_mainCategory] ?? [];
                    _subCategory = '';
                  });
                },
                validator: (v) => v == null || v.isEmpty ? 'Choisissez une catégorie' : null,
              ),

              if (_subCategoryOptions.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _subCategory.isEmpty ? null : _subCategory,
                  decoration: const InputDecoration(labelText: 'Sous-catégorie'),
                  items: _subCategoryOptions.map((sub) {
                    return DropdownMenuItem(
                      value: sub,
                      child: Text(sub),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _subCategory = val ?? '';
                    });
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Choisissez une sous-catégorie' : null,
                ),

              DropdownButtonFormField<String>(
                value: _occasion,
                decoration: const InputDecoration(labelText: 'Occasion'),
                items: _occasionMap.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _occasion = val ?? 'casual';
                  });
                },
              ),

              DropdownButtonFormField<String>(
                value: _selectedSeason,
                decoration: const InputDecoration(labelText: 'Saison'),
                items: _seasonOptions.map((season) {
                  return DropdownMenuItem(
                    value: season,
                    child: Text(season),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSeason = val ?? 'Toutes saisons';
                  });
                },
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
