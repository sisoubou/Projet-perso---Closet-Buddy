import 'package:flutter/material.dart';
import '../models/clothing_item.dart';

class ClothingCard extends StatelessWidget{
  final ClothingItem item;
  final VoidCallback? onTap;

  const ClothingCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = item.imageUrl.isNotEmpty && item.imageUrl.startsWith('http');

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
              child: isNetworkImage
                  ? Image.network(item.imageUrl, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${item.mainCategory}${item.subCategory.isNotEmpty ? ' · ${item.subCategory}' : ''}', style: const TextStyle(color: Colors.grey)),
                ],
              )
            ),
          ],
        )
      ),
    );
  }
}