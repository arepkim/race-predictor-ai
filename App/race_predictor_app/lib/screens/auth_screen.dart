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

  // --- Password Strength State ---
  double _strength = 0;
  String _strengthText = "Weak";
  Color _strengthColor = Colors.red;

  void _checkPasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    setState(() {
      _strength = strength;
      if (strength < 0.4) {
        _strengthText = "Very Weak";
        _strengthColor = Colors.red;
      } else if (strength < 0.7) {
        _strengthText = "Moderate";
        _strengthColor = Colors.orange;
      } else if (strength < 0.9) {
        _strengthText = "Strong";
        _strengthColor = Colors.blue;
      } else {
        _strengthText = "Very Strong";
        _strengthColor = Colors.green;
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  Future<void> _submit() async {
    // 1. Email Validation
    if (!_isValidEmail(_emailController.text.trim())) {
      setState(() => _errorMessage = "Please enter a valid email address.");
      return;
    }

    // 2. Signup Specific Validations
    if (!_isLogin) {
      if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
        setState(() => _errorMessage = "Please enter your full name.");
        return;
      }
      if (_ageController.text.isEmpty) {
        setState(() => _errorMessage = "Please enter your age.");
        return;
      }
      // Password Complexity Requirement
      if (_strength < 0.7) {
        setState(() => _errorMessage = "Password is too weak. Please use a combination of upper/lower case, numbers, and symbols.");
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        // --- Requirement: Email Verification Check on Login ---
        if (!cred.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          setState(() => _errorMessage = "Please verify your email address before logging in. Check your inbox.");
          return;
        }
      } else {
        // Register AND save all profile data to Firestore
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'gender_encoded': _genderEncoded,
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'isOnboardingComplete': false, // NEW
        });

        // --- Requirement: Send Email Verification & Inform User ---
        await cred.user!.sendEmailVerification();
        await FirebaseAuth.instance.signOut(); // Sign out until they verify
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Verify Your Email"),
              content: const Text("A verification link has been sent to your email. Please check your inbox (and spam) to activate your account before logging in."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() => _isLogin = true);
                  },
                  child: const Text("OK"),
                )
              ],
            ),
          );
        }
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

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
                onChanged: _checkPasswordStrength,
              ),

              // --- Requirement: Password Strength Indicator ---
              if (!_isLogin && _passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _strength,
                  backgroundColor: Colors.grey.shade300,
                  color: _strengthColor,
                  minHeight: 5,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Strength: $_strengthText",
                    style: TextStyle(color: _strengthColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],

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
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
              TextButton(
                onPressed: () => setState(() {
                  _isLogin = !_isLogin;
                  _errorMessage = null; 
                  _passwordController.clear();
                  _strength = 0;
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