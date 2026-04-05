import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // --- NEW: Name Controllers ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  final _ageController = TextEditingController();
  int _genderEncoded = 1; // 1 for Male, 0 for Female

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    // Validation for sign up
    if (!_isLogin) {
      if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
        setState(() => _errorMessage = "Please enter your full name.");
        return;
      }
      if (_ageController.text.isEmpty) {
        setState(() => _errorMessage = "Please enter your age.");
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Register AND save all profile data to Firestore
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'firstName': _firstNameController.text.trim(), // NEW
          'lastName': _lastNameController.text.trim(),   // NEW
          'age': int.parse(_ageController.text.trim()),
          'gender_encoded': _genderEncoded,
          'email': _emailController.text.trim(),
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // --- NEW: Name fields only show during Sign Up ---
              if (!_isLogin) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person_outline)),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Last Name'),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                obscureText: true,
              ),
              
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageController,
                        decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _genderEncoded,
                        decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.transgender)),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Male')),
                          DropdownMenuItem(value: 0, child: Text('Female')),
                        ],
                        onChanged: (v) => setState(() => _genderEncoded = v!),
                      ),
                    ),
                  ],
                ),
              ],

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center,),
                ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_isLogin ? 'Login' : 'Sign Up', style: const TextStyle(fontSize: 16)),
                    ),
              TextButton(
                onPressed: () => setState(() {
                  _isLogin = !_isLogin;
                  _errorMessage = null; 
                }),
                child: Text(_isLogin ? 'New user? Create an account' : 'Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}