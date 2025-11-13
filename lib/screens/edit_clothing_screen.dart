import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
      required this.onUpdate
  });

  @override
  _EditClothingScreenState createState() => _EditClothingScreenState();
}

class _EditClothingScreenState extends State<EditClothingScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _category;
  late String _color;
  File? _imageFile; 

  @override
  void initState() {
    super.initState();
    _name = widget.clothingItem.name;
    _category = widget.clothingItem.category;
    _color = widget.clothingItem.color;
  }

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

      String imageUrl = widget.clothingItem.imageUrl;

      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('wardrobe_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final updateItem = widget.clothingItem.copyWith(
        name: _name,
        category: _category,
        imageUrl: imageUrl,
        color: _color,
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('clothing_items')
          .where('id', isEqualTo: widget.clothingItem.id)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'name': updateItem.name,
          'category': updateItem.category,
          'imageUrl': updateItem.imageUrl,
          'color': updateItem.color,
        });
      }

      widget.onUpdate(updateItem);
      Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier un vêtement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
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
                onSaved: (value) {
                  _name = value!;
                },
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

              _imageFile != null
                  ? Image.file(
                      _imageFile!,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : const Text('Aucune image sélectionnée'),

              const SizedBox(height: 10),

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
