
import 'package:chat/components/button.dart';
import 'package:chat/components/textField.dart';
import 'package:chat/pages/loginPage.dart';
import 'package:chat/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void signUp() async {
    showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator())
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim()
      );

      await userCredential.user?.updateDisplayName(nameController.text.trim());

      Navigator.of(context).pop();

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed'))
      );
    }
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
                            style: GoogleFonts.outfit(fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8,),
                          Text(
                            'Enter a short Subtitle here',
                            style: GoogleFonts.outfit(fontSize: 14,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 20,),
                          TextFieldInput(
                            textEditingController: nameController,
                            fieldName: 'Name',
                            hintText: 'Enter your name',
                          ),
                          const SizedBox(height: 20,),
                          TextFieldInput(
                            textEditingController: emailController,
                            fieldName: 'Email',
                            hintText: 'Enter your email',
                          ),
                          const SizedBox(height: 20,),
                          TextFieldInput(
                            textEditingController: passwordController,
                            fieldName: 'Password',
                            hintText: 'Enter your password',
                          ),
                          const SizedBox(height: 28,),
                          MyButton(onTap: signUp, text: 'Sign Up'),
                          SizedBox(height: size.height/17,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(fontSize: 16,
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
                                  style: TextStyle(fontSize: 16,
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