import 'package:flutter/material.dart';
import 'models/user.dart';
import 'models/clothing_item.dart';
import 'screens/wardrobe_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // nécessaire pour init asynchrone
  await Firebase.initializeApp( );

  final user = User(
    id: 'user1',
    name: 'Serena',
    email: 'serena.@example.com',
    password: 'securepassword',
    wardrobe: [
      ClothingItem(
        id: 'item1',
        name: 'Blue T-Shirt',
        category: 'top',
        imageUrl: 'https://example.com/images/blue_tshirt.png',
        color: 'blue',
        occasion: 'casual',
      ),
      ClothingItem(
        id: 'item2',
        name: 'Black Jeans',
        category: 'bottom',
        imageUrl: 'https://example.com/images/black_jeans.png',
        color: 'black',
        occasion: 'casual',
      ),
      ClothingItem(
        id: 'item3',
        name: 'White Sneakers',
        category: 'shoes',
        imageUrl: 'https://example.com/images/white_sneakers.png',
        color: 'white',
        occasion: 'casual',
      ),
    ],
  );

  runApp(MyApp(user: user));
}

class MyApp extends StatelessWidget {
  final User user;
  
  const MyApp({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ma Garde-robe',
      theme: ThemeData.dark(),
      home: WardrobeScreen(user: user),
    );
  }
}
