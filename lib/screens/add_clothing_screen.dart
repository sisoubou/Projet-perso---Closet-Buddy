import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../models/user.dart';
import '../models/clothing_item.dart';

class AddClothingScreen extends StatefulWidget {
  final User user;
  final Function(ClothingItem) onAdd;

  const AddClothingScreen({super.key, required this.user, required this.onAdd});

  @override
  _AddClothingScreenState createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _category = '';
  String _color = '';
  File? _imageFile; 

  /// --- Fonction pour choisir une image depuis la galerie ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String imageUrl = '';

      // Si une image a été sélectionnée, on la télécharge sur Firebase Storage
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('wardrobe_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final newItem = ClothingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name,
        category: _category,
        imageUrl: imageUrl.isNotEmpty 
          ? imageUrl 
          : 'https://via.placeholder.com/150',
        color: _color,
      );

      await FirebaseFirestore.instance.collection('clothing_items').add({
        'id': newItem.id,
        'name': newItem.name,
        'category': newItem.category,
        'imageUrl': newItem.imageUrl,
        'color': newItem.color,
        'userId': widget.user.id,
      });

      widget.onAdd(newItem);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un vêtement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Catégorie'),
                onSaved: (value) => _category = value ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Couleur'),
                onSaved: (value) => _color = value ?? '',
              ),

              const SizedBox(height: 20),

              // --- Aperçu image ---
              _imageFile != null
                  ? Image.file(
                      _imageFile!,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : const Text('Aucune image sélectionnée'),

              const SizedBox(height: 10),

              // --- Bouton pour choisir une image ---
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Choisir depuis la galerie'),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveForm,
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
