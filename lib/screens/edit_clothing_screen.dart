import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../models/user.dart';
import '../models/clothing_item.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/network_img.dart';

class EditClothingScreen extends StatefulWidget {
  final User user;
  final ClothingItem clothingItem;
  final Function(ClothingItem) onUpdate;
  final Function(String)? onDelete;

  const EditClothingScreen({
    super.key,
    required this.user,
    required this.clothingItem,
    required this.onUpdate,
    this.onDelete,
  });

  @override
  EditClothingScreenState createState() => EditClothingScreenState();
}

class EditClothingScreenState extends State<EditClothingScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _mainCategory;
  late String _subCategory;
  late List<String> _selectedColors;
  late List<String> _selectedOccasions;
  late String _season;
  late bool _isArchived;
  File? _imageFile;

  List<String> _subCategoryOptions = [];
  final List<String> _mainCategories = ['Hauts', 'Manteaux', 'Bas', 'Robes & Combinaisons', 'Chaussures', 'Accessoires'];
  final Map<String, List<String>> _subCategoriesMap = {
    'Hauts': ['Tops', 'T-shirts', 'Pulls', 'Chemises', 'Sweats', 'Tops de sport'],
    'Manteaux': ['Manteaux', 'Vestes', 'Blousons'],
    'Bas': ['Jeans', 'Jupes', 'Pantalons', 'Shorts', 'Leggings', 'Joggings'],
    'Robes & Combinaisons': ['Robes mini', 'Robes longue', 'Combinaisons'],
    'Chaussures': ['Baskets', 'Bottes', 'Chaussures Plates', 'Talons'],
    'Accessoires': ['Ceintures', 'Sacs', 'Chapeaux', 'Bijoux', 'Accessoires Cheveux', 'Echarpes', 'Gants', 'Lunettes de soleil', 'Chaussettes & Collants'],
  };
  final List<String> _colorOptions = ['Rouge', 'Bleu', 'Vert', 'Noir', 'Blanc', 'Jaune', 'Violet', 'Orange', 'Rose', 'Gris', 'Marron', 'Beige'];
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
    'Beige': const Color.fromARGB(255, 216, 163, 143),
  };
  final Map<String, String> _occasionMap = {
    'casual': 'Décontracté',
    'formal': 'Formel',
    'sport': 'Sportif',
    'party': 'Fête',
  };
  final List<String> _seasonOptions = ['Toutes saisons', 'Hiver', 'Printemps', 'Eté', 'Automne'];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = widget.clothingItem.name;
    _mainCategory = widget.clothingItem.mainCategory;
    _subCategory = widget.clothingItem.subCategory;
    _subCategoryOptions = _subCategoriesMap[_mainCategory] ?? [];
    _selectedColors = List.from(widget.clothingItem.colors);
    _selectedOccasions = List.from(widget.clothingItem.occasions);
    _season = widget.clothingItem.season;
    _isArchived = widget.clothingItem.isArchived;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    String imageUrl = widget.clothingItem.imageUrl;

    if (_imageFile != null) {
      final fb_auth.User? currentUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('wardrobe')
          .child('${widget.clothingItem.id}_edited.jpg');

      try {
        final TaskSnapshot snapshot = await storageRef.putFile(_imageFile!);
        imageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur upload image')),
        );
        return;
      }
    }

    final updatedItem = widget.clothingItem.copyWith(
      name: _name,
      mainCategory: _mainCategory,
      subCategory: _subCategory,
      colors: _selectedColors,
      occasions: _selectedOccasions,
      season: _season,
      imageUrl: imageUrl,
      isArchived: _isArchived,
    );

    await FirestoreService().updateClothingItem(updatedItem);
    widget.onUpdate(updatedItem);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer le vêtement',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        content: Text('Êtes-vous sûr de vouloir supprimer ce vêtement ?',
            style: GoogleFonts.lato(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        await FirestoreService().deleteClothing(widget.clothingItem.id, widget.user.id);
        widget.onDelete?.call(widget.clothingItem.id);
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteItem,
            tooltip: 'Supprimer',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  _ImagePreview(
                    imageFile: _imageFile,
                    imageUrl: widget.clothingItem.imageUrl,
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: 24),
                  _section(
                    title: 'Informations',
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: _name,
                          decoration: const InputDecoration(labelText: 'Nom'),
                          validator: (v) => v == null || v.isEmpty ? 'Veuillez entrer un nom' : null,
                          onSaved: (v) => _name = v!,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _mainCategory.isEmpty ? null : _mainCategory,
                          decoration: const InputDecoration(labelText: 'Catégorie principale'),
                          items: _mainCategories
                              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _mainCategory = val ?? '';
                              _subCategoryOptions = _subCategoriesMap[_mainCategory] ?? [];
                              _subCategory = '';
                            });
                          },
                        ),
                        if (_subCategoryOptions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _subCategory.isEmpty ? null : _subCategory,
                            decoration: const InputDecoration(labelText: 'Sous-catégorie'),
                            items: _subCategoryOptions
                                .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                                .toList(),
                            onChanged: (val) => setState(() => _subCategory = val ?? ''),
                          ),
                        ],
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _season,
                          decoration: const InputDecoration(labelText: 'Saison'),
                          items: _seasonOptions
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (val) => setState(() => _season = val ?? 'Toutes saisons'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    title: 'Couleurs',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _colorOptions.map((colorName) {
                        return _ColorChip(
                          label: colorName,
                          color: _colorMap[colorName]!,
                          selected: _selectedColors.contains(colorName),
                          onTap: () {
                            setState(() {
                              if (_selectedColors.contains(colorName)) {
                                _selectedColors.remove(colorName);
                              } else {
                                _selectedColors.add(colorName);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    title: 'Occasions',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _occasionMap.entries.map((entry) {
                        return _TagChip(
                          label: entry.value,
                          selected: _selectedOccasions.contains(entry.key),
                          onTap: () {
                            setState(() {
                              if (_selectedOccasions.contains(entry.key)) {
                                _selectedOccasions.remove(entry.key);
                              } else {
                                _selectedOccasions.add(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text('Archiver',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Masque ce vêtement sans le supprimer.",
                          style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      value: _isArchived,
                      activeThumbColor: AppColors.primary,
                      onChanged: (bool value) async {
                        // NOUVEAU : Ajout de la Pop-up avant d'archiver
                        if (value) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: Text('Archiver le vêtement',
                                  style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
                              content: Text(
                                  'Ce vêtement sera masqué de votre garde-robe principale. Vous pourrez le retrouver dans vos archives.',
                                  style: GoogleFonts.lato()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Archiver', style: TextStyle(color: AppColors.primary)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() => _isArchived = true);
                          }
                        } else {
                          setState(() => _isArchived = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _isSaving
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: const Text('Sauvegarder les modifications'),
                ),
              ),
            ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File? imageFile;
  final String imageUrl;
  final VoidCallback onTap;

  const _ImagePreview({
    required this.imageFile,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnyImage = imageFile != null || imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: imageFile != null
                    ? Image.file(imageFile!, fit: BoxFit.cover)
                    : imageUrl.isNotEmpty
                        ? NetworkImg(imageUrl, fit: BoxFit.cover)
                        : Container(color: AppColors.surfaceAlt),
              ),
              if (!hasAnyImage)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text('Ajouter une photo',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Changer',
                          style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label,
            style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}
