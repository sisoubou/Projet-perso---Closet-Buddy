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

      await storageRef.putFile(_imageFile!);
      imageUrl = await storageRef.getDownloadURL();
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
