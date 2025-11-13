import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../models/clothing_item.dart';
import 'add_clothing_screen.dart';
import '../widgets/clothing_card.dart';
import 'edit_clothing_screen.dart';

class WardrobeScreen extends StatefulWidget {
  final User user;
  const WardrobeScreen({super.key, required this.user});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  void _addNewItem(ClothingItem item) {
    setState(() {
      widget.user.addClothing(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Garde-robe de ${widget.user.name}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clothing_items')
            .where('userId', isEqualTo: widget.user.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          final items = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return ClothingItem(
              id: data['id'],
              name: data['name'],
              category: data['category'],
              color: data['color'],
              imageUrl: data['imageUrl'],
            );
          }).toList();

          if (items.isEmpty) {
            return const Center(child: Text('Aucun vêtement pour le moment 👕'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => ClothingCard(
              item: items[index], 
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditClothingScreen(
                      user: widget.user,
                      clothingItem: items[index],
                      onUpdate: (updatedItem) {
                        setState(() {
                          widget.user.updateClothing(updatedItem);
                        });
                      },
                    ),
                  ),
                );
            }),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddClothingScreen(
              user: widget.user,
              onAdd: _addNewItem,
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

}