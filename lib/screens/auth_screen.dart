import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'wardrobe_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _name = '';
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      fb_auth.UserCredential userCredential;
      if (_isLogin) {
        userCredential = await fb_auth.FirebaseAuth.instance
            .signInWithEmailAndPassword(email: _email, password: _password);
      } else {
        userCredential = await fb_auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: _email, password: _password);

        await userCredential.user!.updateDisplayName(_name);

        // Création document Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _email,
          'name': _name,
          'createdAt': Timestamp.now(),
        });
      }

      // Construction du User local
      final localUser = User(
        id: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? _email.split('@')[0],
        email: userCredential.user!.email ?? '',
        password: '',
        wardrobe: [],
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WardrobeScreen(user: localUser)),
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      final message = e.message ?? 'Erreur, veuillez réessayer';
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur inattendue')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Connexion' : 'Inscription')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isLogin)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nom requis' : null,
                  onSaved: (v) => _name = v!,
                ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Email invalide' : null,
                onSaved: (v) => _email = v!.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.length < 6 ? '6 caractères minimum' : null,
                onSaved: (v) => _password = v!.trim(),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? 'Se connecter' : 'S\'inscrire'),
                ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin
                    ? 'Créer un compte'
                    : 'Déjà un compte ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
