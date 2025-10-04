
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
// import 'profile_screen.dart'; // No longer directly navigating here
import 'login_screen.dart'; // Import LoginScreen for navigation

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  static const String id = 'registration_screen'; // For named navigation

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false; // For loading indicator
  bool _isPasswordVisible = false; // For password visibility toggle
  bool _isConfirmPasswordVisible = false; // For confirm password visibility toggle

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async { // Make async
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Registration successful
        print('Registered user: ${userCredential.user?.uid}');
        
        // Sign out the user immediately after registration
        // so they have to manually log in through the login screen
        await FirebaseAuth.instance.signOut();
        
        if (mounted) { // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please sign in with your credentials.')),
          );
          // Navigate to login screen after successful registration
          Navigator.pushReplacementNamed(context, LoginScreen.id);
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          message = 'The account already exists for that email.';
        } else {
          message = 'An error occurred: ${e.message}';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: $e')),
          );
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Logo and welcome text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.person_add_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Create Account',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join GSTEase to simplify your GST management',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                            hintText: 'Enter your email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            hintText: 'Enter your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible 
                                    ? Icons.visibility_off 
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Confirm Password field
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            hintText: 'Confirm your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible 
                                    ? Icons.visibility_off 
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_isConfirmPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Register button
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _registerUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 56),
                                  ),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Login link
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            Navigator.pushReplacementNamed(context, LoginScreen.id);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: "Already have an account? "),
                                TextSpan(
                                  text: "Sign In",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
