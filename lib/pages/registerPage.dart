
import 'package:chat/components/button.dart';
import 'package:chat/components/textField.dart';
import 'package:chat/pages/loginPage.dart';
import 'package:chat/services/auth.dart';
import 'package:chat/utils/validation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();

  String? errorMessage = '';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isObscurePassword = true;
  bool _isNameValid = true;

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameFocusNode.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> createUserWithEmailAndPassword() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isEmailValid = Validation.isValidEmail(emailController.text);
      _isPasswordValid = Validation.isValidPassword(passwordController.text);
      _isNameValid = nameController.text.trim().isNotEmpty;
    });

    if (!_isEmailValid || !_isPasswordValid || !_isNameValid) {
      _showValidationErrorDialog();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      UserCredential userCredential = await Auth().createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();

        Navigator.of(context).pop();

        _showEmailVerificationDialog(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();
      _showFirebaseErrorDialog(e.message ?? 'Registration failed');
    }
  }

  void _showEmailVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Your Email'),
        content: Text(
          'A verification link has been sent to ${user.email}. '
              'Please check your email and click the link to complete registration.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await user.reload();

                final currentUser = FirebaseAuth.instance.currentUser;

                if (currentUser != null && currentUser.emailVerified) {
                  await _storeUserDataInFirestore(currentUser);

                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                } else {
                  await user.delete();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Registration failed. Please try again.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                print('Error checking email verification: $e');

                try {
                  await user.delete();
                } catch (deleteError) {
                  print('Error deleting user: $deleteError');
                }

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registration failed. Please try again.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('I have verified my email'),
          ),
          TextButton(
            onPressed: () {
              user.sendEmailVerification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification email resent'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Resend Verification Email'),
          ),
          TextButton(
            onPressed: () {
              user.delete();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel Registration'),
          ),
        ],
      ),
    );
  }

  Future<void> _storeUserDataInFirestore(User user) async {
    try {
      List<String> searchIndex = [];
      String name = nameController.text.trim();
      String email = emailController.text.trim();

      searchIndex.addAll(_generateSearchTokens(name));
      searchIndex.addAll(_generateSearchTokens(email));

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'searchIndex': searchIndex,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error storing user data: $e');
    }
  }

  List<String> _generateSearchTokens(String input) {
    input = input.toLowerCase();
    Set<String> tokens = {};

    tokens.add(input);

    for (int i = 1; i <= input.length; i++) {
      tokens.add(input.substring(0, i));
    }

    return tokens.toList();
  }

  void _showValidationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isNameValid)
              Text(
                'Name cannot be empty',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.red),
              ),
            if (!_isEmailValid)
              Text(
                Validation.getEmailErrorMessage(emailController.text) ?? '',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.red),
              ),
            if (!_isPasswordValid)
              Text(
                Validation.getPasswordErrorMessage(passwordController.text) ?? '',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.red),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFirebaseErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Container(
            color: Colors.black,
            height: size.height,
            child: Column(
              children: [
                Image.asset("assets/images/crowdLinkLogo.png"),
                Expanded(
                  child: Container(
                    width: size.width,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 34, left: 18, right: 20, bottom: 24),
                      child: Column(
                        children: [
                          Text(
                            'Sign Up',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your account',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFieldInput(
                            textEditingController: nameController,
                            focusNode: _nameFocusNode,
                            fieldName: 'Name',
                            hintText: 'Enter your name',
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_emailFocusNode);
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFieldInput(
                            textEditingController: emailController,
                            focusNode: _emailFocusNode,
                            fieldName: 'Email',
                            hintText: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_passwordFocusNode);
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFieldInput(
                            textEditingController: passwordController,
                            focusNode: _passwordFocusNode,
                            fieldName: 'Password',
                            hintText: 'Enter your password',
                            obscureText: _isObscurePassword,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _isObscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscurePassword = !_isObscurePassword;
                                });
                              },
                            ),
                            onSubmitted: (_) {
                              createUserWithEmailAndPassword();
                            },
                          ),
                          const SizedBox(height: 28),
                          MyButton(
                              onTap: createUserWithEmailAndPassword,
                              text: 'Sign Up'
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}