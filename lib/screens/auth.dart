import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_app/widgets/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogIn = true;
  final _formKey = GlobalKey<FormState>();
  var _email = '';
  var _password = '';
  File? _selectedImage;
  bool _isAuthenticating = false;
  var _name = '';

  void _submit() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid || !_isLogIn && _selectedImage == null) {
      return;
    }

    _formKey.currentState!.save();

    try {
      if (_isLogIn) {
        setState(() {
          _isAuthenticating = true;
        });

        final userLoginInfo = await _firebase.signInWithEmailAndPassword(
            email: _email, password: _password);
      } else {
        final userSignUpInfo = await _firebase.createUserWithEmailAndPassword(
            email: _email, password: _password);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profile_image')
            .child('${userSignUpInfo.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        print('ImageUrl - $imageUrl');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userSignUpInfo.user!.uid)
            .set({
          'user_name': _name,
          'email': _email,
          'image_url': imageUrl
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        ///
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authentication Failed')));

      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    top: 30, bottom: 20, right: 20, left: 20),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogIn)
                            UserImagePicker(
                              onPickedImage: (pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),
                          if (!_isLogIn)
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'User Name'),
                              enableSuggestions: false,
                              autocorrect: false,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter the User Name';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _name = value!;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                                labelText: 'Email Address'),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _email = value!;
                            },
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Password must be 6 characters long';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _password = value!;
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          _isAuthenticating
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer),
                                  child: Text(_isLogIn ? 'Login' : 'Sign Up'),
                                ),
                          if (!_isAuthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogIn = !_isLogIn;
                                });
                              },
                              child: Text(_isLogIn
                                  ? 'Create an account'
                                  : 'Already have an account.'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
