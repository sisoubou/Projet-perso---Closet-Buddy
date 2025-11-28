import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

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
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(currentUser.uid)
            .child('wardrobe')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        debugPrint("Erreur upload image : $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi de l'image.")),
        );
        return;
      }
    }

    final newItem = ClothingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
