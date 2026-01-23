import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import 'item_selection_screen.dart';

class OutfitCreatorScreen extends StatefulWidget {
  final User user;
  const OutfitCreatorScreen({super.key, required this.user});

  @override
 State<OutfitCreatorScreen> createState() => _OutfitCreatorScreenState();
}

class _OutfitCreatorScreenState extends State<OutfitCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  String _outfitName = '';
  
  ClothingItem? _selectedTop;
  ClothingItem? _selectedBottom;
  ClothingItem? _selectedShoes;
  ClothingItem? _selectedAccessory;

  bool _isSaving = false;

  Future<void> _pickItem(String category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemSelectionScreen(userId: widget.user.id, category: category),
      ),
    );

    if (result != null && result is ClothingItem) {
      setState(() {
        if (category == 'Haut') _selectedTop = result;
        if (category == 'Bas') _selectedBottom = result;
        if (category == 'Chaussures') _selectedShoes = result;
        if (category == 'Accessoires') _selectedAccessory = result;
      });
    }
  }

  Future<void> _saveOutfit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTop == null || _selectedBottom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il faut au moins un haut et un bas !')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    try {
      final newOutfit = Outfit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _outfitName,
        dateCreation: DateTime.now(),
        top: _selectedTop!,
        bottom: _selectedBottom!,
        shoes: _selectedShoes,
        accessory: _selectedAccessory,
        occasions: 'casual',
      );

      await FirestoreService().saveOutfit(newOutfit, widget.user.id);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tenue sauvegardée !')));
      
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Widget _buildSlot(String label, String category, ClothingItem? item) {
    return GestureDetector(
      onTap: () => _pickItem(category),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
          image: item != null && item.imageUrl.isNotEmpty
              ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
              : null,
        ),
        child: item == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 40, color: Colors.grey.shade600),
                  Text("Ajouter $label", style: TextStyle(color: Colors.grey.shade600)),
                ],
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une tenue')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom de la tenue (ex: Tenue Lundi)'),
                validator: (v) => v!.isEmpty ? 'Donnez un nom' : null,
                onSaved: (v) => _outfitName = v!,
              ),
              const SizedBox(height: 20),
              
              _buildSlot("un Haut", 'Haut', _selectedTop),
              _buildSlot("un Bas", 'Bas', _selectedBottom),
              _buildSlot("des Chaussures", 'Chaussures', _selectedShoes),
              _buildSlot("un Accessoire", 'Accessoires', _selectedAccessory),

              const SizedBox(height: 20),
              
              _isSaving 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveOutfit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: const Text('Sauvegarder la tenue', style: TextStyle(fontSize: 18)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}