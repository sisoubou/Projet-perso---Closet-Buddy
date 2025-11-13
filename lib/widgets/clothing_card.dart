import 'dart:io';
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';

class ClothingCard extends StatelessWidget{
  final ClothingItem item;
  final VoidCallback? onTap;

  const ClothingCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLocalImage = !item.imageUrl.startsWith('http');

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: isLocalImage
                  ? Image.file( File(item.imageUrl), fit: BoxFit.cover, width: double.infinity)
                  : Image.network(item.imageUrl, fit: BoxFit.cover, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(item.category, style: const TextStyle(color: Colors.grey)),
                ],
              )
            ),
          ],
        )
      ),
    );
  }
}