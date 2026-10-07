import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/auth_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (user.emailVerified) {
            // Check if onboarding is complete
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return const AuthScreen(); // Fallback to login if there's a DB error
                }
                
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                
                final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                if (userData == null || userData['isOnboardingComplete'] != true) {
                  return const OnboardingScreen();
                }
                
                return const MainNavigation();
              },
            );
          }
        }
        return const AuthScreen();
      },
    );
  }
}