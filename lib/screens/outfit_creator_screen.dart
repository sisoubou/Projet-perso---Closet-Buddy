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
  
  final List<ClothingItem> _selectedItems = [];

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
        _selectedItems.add(result);
      });
    }
  }

  Future<void> _saveOutfit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedItems.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins 2 articles pour créer une tenue !')),
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
        items: _selectedItems,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une tenue')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom de la tenue (ex: Look Hiver)'),
                validator: (v) => v!.isEmpty ? 'Donnez un nom' : null,
                onSaved: (v) => _outfitName = v!,
              ),
              const SizedBox(height: 20),
              
              const Text("Composition de la tenue :", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              Expanded(
                child: _selectedItems.isEmpty 
                  ? Center(child: Text("Aucun vêtement sélectionné", style: TextStyle(color: Colors.grey.shade400)))
                  : ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final item = _selectedItems.removeAt(oldIndex);
                          _selectedItems.insert(newIndex, item);
                        });
                      },
                      children: [
                        for (int i = 0; i < _selectedItems.length; i++)
                          ListTile(
                            key: ValueKey(_selectedItems[i].id),
                            leading: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: _selectedItems[i].imageUrl.isNotEmpty 
                                  ? DecorationImage(image: NetworkImage(_selectedItems[i].imageUrl), fit: BoxFit.cover)
                                  : null,
                                color: Colors.grey[200]
                              ),
                              child: _selectedItems[i].imageUrl.isEmpty ? const Icon(Icons.checkroom) : null,
                            ),
                            title: Text(_selectedItems[i].name),
                            subtitle: Text(_selectedItems[i].subCategory),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => setState(() => _selectedItems.removeAt(i)),
                            ),
                          ),
                      ],
                    ),
              ),
              
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(label: const Text('+ Haut'), onPressed: () => _pickItem('Hauts')),
                  ActionChip(label: const Text('+ Bas'), onPressed: () => _pickItem('Bas')),
                  ActionChip(label: const Text('+ Chaussures'), onPressed: () => _pickItem('Chaussures')),
                  ActionChip(label: const Text('+ Manteau'), onPressed: () => _pickItem('Manteaux')),
                  ActionChip(label: const Text('+ Accessoire'), onPressed: () => _pickItem('Accessoires')),
                ],
              ),

              const SizedBox(height: 20),
              
              _isSaving 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveOutfit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50)),
                    child: const Text('Sauvegarder', style: TextStyle(fontSize: 18)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}